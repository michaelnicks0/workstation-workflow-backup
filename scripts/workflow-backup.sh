#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
source "$REPO_ROOT/config/backup.env"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/nas-ssh.sh"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/windows-interop.sh"

DRY_RUN=0
VERBOSE=0
SKIP_WINDOWS=0
SKIP_WSL=0
QUICK_CHECK_SQLITE=0

usage() {
  cat <<'EOF'
Usage: workflow-backup.sh [--dry-run] [--verbose] [--skip-windows] [--skip-wsl] [--quick-check-sqlite]

Runs the hourly WORKSTATION1 workflow backup. Default mode is silent on success.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --verbose) VERBOSE=1 ;;
    --skip-windows) SKIP_WINDOWS=1 ;;
    --skip-wsl) SKIP_WSL=1 ;;
    --quick-check-sqlite) QUICK_CHECK_SQLITE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

mkdir -p "$LOCAL_STATE/logs" "$LOCAL_STATE/sqlite-snapshots" "$LOCAL_STATE/nas-export"
LOG_FILE="$LOCAL_STATE/logs/workflow-backup-$(date -u +%Y%m%dT%H%M%SZ).log"
LAST_STATUS="$LOCAL_STATE/last-run.json"
LOCK_FILE="$LOCAL_STATE/backup.lock"
LEDGER_DB="$LOCAL_STATE/runs.sqlite3"
LEDGER_DB_SNAPSHOT="$LOCAL_STATE/nas-export/runs.sqlite3"
LEDGER_HISTORY_JSON="$LOCAL_STATE/nas-export/run-history.json"
STATUS_EXPORT_DIR="$LOCAL_STATE/nas-export/_manifests"
SQLITE_MANIFEST_CACHE="$LOCAL_STATE/current-sqlite-snapshot-manifest.json"
WINDOWS_MANIFEST_CACHE="$LOCAL_STATE/current-windows-sync-finish.json"
WINDOWS_HELPER_TEMP_WSL="/mnt/c/Users/$WINDOWS_USER/AppData/Local/Temp/workstation-workflow-backup"
WINDOWS_MANIFEST_LOCAL_COPY_WSL="$WINDOWS_HELPER_TEMP_WSL/windows-sync-finish.json"
WINDOWS_MANIFEST_LOCAL_COPY_WIN="C:\\Users\\$WINDOWS_USER\\AppData\\Local\\Temp\\workstation-workflow-backup\\windows-sync-finish.json"
RUN_ID="$(hostname)-$(date -u +%Y%m%dT%H%M%SZ)-$$"
START_EPOCH=$(date +%s)
STATUS="running"
ERROR_MESSAGE=""

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  # Another timer run is still active. This is not a failure and should stay silent.
  python3 "$SCRIPT_DIR/record-run-ledger.py" event \
    --db "$LEDGER_DB" \
    --run-id "$RUN_ID" \
    --event-type skipped_lock \
    --status skipped \
    --dry-run "$DRY_RUN" \
    --log-file "$LOG_FILE" >/dev/null 2>&1 || true
  exit 0
fi

log() {
  local msg="$*"
  printf '%s %s\n' "$(date -Is)" "$msg" >> "$LOG_FILE"
  if [[ "$VERBOSE" == "1" ]]; then
    printf '%s\n' "$msg"
  fi
}

prune_old_logs() {
  local days=${LOCAL_LOG_RETENTION_DAYS:-90}
  if [[ "$days" =~ ^[0-9]+$ && "$days" -gt 0 ]]; then
    find "$LOCAL_STATE/logs" -type f -name 'workflow-backup-*.log' -mtime "+$days" -delete 2>/dev/null || true
  fi
}

write_status() {
  local finished_epoch duration
  finished_epoch=$(date +%s)
  duration=$((finished_epoch - START_EPOCH))
  python3 - <<'PY' "$LAST_STATUS" "$STATUS" "$ERROR_MESSAGE" "$LOG_FILE" "$duration" "$DRY_RUN"
import json
import socket
import sys
from datetime import datetime, timezone
path, status, error, log_file, duration, dry_run = sys.argv[1:]
data = {
    "kind": "workflow-backup-last-run",
    "host": socket.gethostname(),
    "finished_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "status": status,
    "error": error,
    "log_file": log_file,
    "duration_seconds": int(duration),
    "dry_run": dry_run == "1",
}
with open(path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=2, sort_keys=True)
    handle.write("\n")
PY
}

remote_quote() {
  local s=${1//\'/\'\\\'\'}
  printf "'%s'" "$s"
}

elapsed_seconds() {
  local finished_epoch
  finished_epoch=$(date +%s)
  printf '%s' "$((finished_epoch - START_EPOCH))"
}

record_ledger_event() {
  local event_type=$1
  local status=$2
  local duration=${3:-}
  local -a args=(
    "$SCRIPT_DIR/record-run-ledger.py" event
    --db "$LEDGER_DB"
    --run-id "$RUN_ID"
    --event-type "$event_type"
    --status "$status"
    --dry-run "$DRY_RUN"
    --log-file "$LOG_FILE"
    --error "$ERROR_MESSAGE"
  )
  if [[ -n "$duration" ]]; then
    args+=(--duration-seconds "$duration")
  fi
  if [[ "$event_type" != "started" ]]; then
    if [[ -r "$SQLITE_MANIFEST_CACHE" ]]; then
      args+=(--sqlite-manifest "$SQLITE_MANIFEST_CACHE")
    fi
    if [[ -r "$WINDOWS_MANIFEST_CACHE" ]]; then
      args+=(--windows-manifest "$WINDOWS_MANIFEST_CACHE")
    fi
  fi

  local rc
  set +e
  python3 "${args[@]}" >> "$LOG_FILE" 2>&1
  rc=$?
  set -e
  if [[ "$rc" != "0" ]]; then
    log "ledger warning: failed to record $event_type event rc=$rc"
    if [[ "$event_type" == "completed" && "${LEDGER_STRICT_FINAL_EVENTS:-1}" == "1" ]]; then
      return "$rc"
    fi
  fi
  return 0
}

refresh_windows_manifest_cache() {
  if [[ "$DRY_RUN" == "1" || "$SKIP_WINDOWS" == "1" ]]; then
    return 0
  fi
  if [[ -r "$WINDOWS_MANIFEST_LOCAL_COPY_WSL" ]]; then
    cp "$WINDOWS_MANIFEST_LOCAL_COPY_WSL" "$WINDOWS_MANIFEST_CACHE"
  else
    log "ledger warning: could not read local Windows manifest copy at $WINDOWS_MANIFEST_LOCAL_COPY_WSL"
  fi
}

sync_status_artifacts() {
  if [[ "$DRY_RUN" == "1" ]]; then
    return 0
  fi
  python3 "$SCRIPT_DIR/record-run-ledger.py" snapshot-db \
    --db "$LEDGER_DB" \
    --output "$LEDGER_DB_SNAPSHOT"
  python3 "$SCRIPT_DIR/record-run-ledger.py" export-json \
    --db "$LEDGER_DB" \
    --output-json "$LEDGER_HISTORY_JSON" \
    --limit 100
  rm -rf "$STATUS_EXPORT_DIR"
  mkdir -p "$STATUS_EXPORT_DIR"
  cp "$LAST_STATUS" "$STATUS_EXPORT_DIR/last-run.json"
  cp "$LEDGER_DB_SNAPSHOT" "$STATUS_EXPORT_DIR/runs.sqlite3"
  cp "$LEDGER_HISTORY_JSON" "$STATUS_EXPORT_DIR/run-history.json"
  rsync_to_nas "$STATUS_EXPORT_DIR/" "_manifests" general
}

run_logged() {
  local rc
  set +e
  if [[ "$VERBOSE" == "1" ]]; then
    "$@" 2>&1 | tee -a "$LOG_FILE"
    rc=${PIPESTATUS[0]}
  else
    "$@" >> "$LOG_FILE" 2>&1
    rc=$?
  fi
  set -e
  return "$rc"
}

run_growth_guard() {
  local stage=$1
  if [[ "${NAS_GROWTH_GUARD_ENABLED:-1}" != "1" ]]; then
    log "growth guard disabled: stage=$stage"
    return 0
  fi
  log "growth guard check start: stage=$stage"
  if ! run_logged "$SCRIPT_DIR/check-nas-growth-guard.sh" --stage "$stage"; then
    ERROR_MESSAGE="NAS growth guard failed at stage=$stage; see $LOG_FILE"
    return 75
  fi
  log "growth guard check done: stage=$stage"
}

run_integrity_manifest() {
  if [[ "$DRY_RUN" == "1" || "${NAS_INTEGRITY_MANIFEST_ENABLED:-1}" != "1" ]]; then
    return 0
  fi
  local helper=${NAS_INTEGRITY_REMOTE_HELPER:-/usr/local/sbin/ws1-wf-integrity-manifest}
  local output="$NAS_PATH/current/_manifests/integrity-manifest.json"
  log "integrity manifest start: scope=${NAS_INTEGRITY_SCOPE:-critical}"
  run_logged ssh_nas "$helper" \
    --dataset-path "$NAS_PATH" \
    --scope "${NAS_INTEGRITY_SCOPE:-critical}" \
    --output "$output" \
    --max-file-bytes "${NAS_INTEGRITY_MAX_FILE_BYTES:-0}"
  log "integrity manifest done"
}

on_error() {
  local rc=$?
  if [[ -z "$ERROR_MESSAGE" ]]; then
    ERROR_MESSAGE="command failed near line ${BASH_LINENO[0]} with exit code $rc"
  fi
  STATUS="failed"
  log "FAILED: $ERROR_MESSAGE"
  write_status || true
  record_ledger_event failed failed "$(elapsed_seconds)" || true
  sync_status_artifacts || true
  exit "$rc"
}
trap on_error ERR

COMMON_EXCLUDES=(
  'node_modules/' '.venv/' 'venv/' '__pycache__/' '.pytest_cache/' '.mypy_cache/' '.ruff_cache/'
  '.tox/' '.cache/' '.npm/_cacache/' '.pnpm-store/' '*.pyc' '.DS_Store'
)
SQLITE_EXCLUDES=(
  '*.db' '*.db-wal' '*.db-shm' '*.db-journal' '*.sqlite' '*.sqlite-wal' '*.sqlite-shm'
  '*.sqlite3' '*.sqlite3-wal' '*.sqlite3-shm'
)

rsync_to_nas() {
  local src=$1
  local dest_rel=$2
  local mode=${3:-general}
  local src_display=${src%/}
  if [[ ! -e "$src_display" ]]; then
    log "skip missing optional source: $src"
    return 0
  fi

  local remote_dest="$NAS_PATH/current/$dest_rel"
  log "sync start: $src -> $NAS_HOST:$remote_dest"
  if [[ "$DRY_RUN" != "1" ]]; then
    ssh_nas "mkdir -p $(remote_quote "$remote_dest")"
  fi

  local -a args=(
    -aH --delete-delay --delete-excluded --partial --human-readable --stats
    "--rsync-path=${NAS_REMOTE_RSYNC:-/usr/local/bin/rsync}"
    -e "$(nas_rsync_rsh)"
  )
  if [[ "${RSYNC_PRESERVE_OWNER_GROUP:-0}" == "1" ]]; then
    args+=(--numeric-ids)
  else
    args+=(--no-owner --no-group)
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    args+=(--dry-run --itemize-changes)
  fi
  for pattern in "${COMMON_EXCLUDES[@]}"; do
    args+=(--exclude "$pattern")
  done
  if [[ "$mode" == "sqlite_excludes" ]]; then
    for pattern in "${SQLITE_EXCLUDES[@]}"; do
      args+=(--exclude "$pattern")
    done
  fi

  local rc
  local -a rsync_cmd=(rsync)
  if [[ "${RSYNC_USE_SUDO:-0}" == "1" ]]; then
    rsync_cmd=(sudo -n rsync)
  fi
  set +e
  if [[ "$VERBOSE" == "1" ]]; then
    "${rsync_cmd[@]}" "${args[@]}" "$src" "$NAS_USER@$NAS_HOST:$remote_dest/" 2>&1 | tee -a "$LOG_FILE"
    rc=${PIPESTATUS[0]}
  else
    "${rsync_cmd[@]}" "${args[@]}" "$src" "$NAS_USER@$NAS_HOST:$remote_dest/" >> "$LOG_FILE" 2>&1
    rc=$?
  fi
  set -e

  if [[ "$rc" == "24" ]]; then
    log "sync warning accepted: vanished files while syncing $src"
    return 0
  fi
  if [[ "$rc" != "0" ]]; then
    log "sync failed: $src rc=$rc"
    return "$rc"
  fi
  log "sync done: $src"
}

copy_windows_helper_to_temp() {
  mkdir -p "$WINDOWS_HELPER_TEMP_WSL"
  cp "$SCRIPT_DIR/sync-windows-critical.ps1" "$WINDOWS_HELPER_TEMP_WSL/sync-windows-critical.ps1"
  rm -f "$WINDOWS_MANIFEST_LOCAL_COPY_WSL"
  printf 'C:\\Users\\%s\\AppData\\Local\\Temp\\workstation-workflow-backup\\sync-windows-critical.ps1' "$WINDOWS_USER"
}

run_sqlite_snapshots() {
  local -a args=("$SCRIPT_DIR/snapshot-sqlite-dbs.py" --output "$LOCAL_STATE/sqlite-snapshots")
  if [[ "$QUICK_CHECK_SQLITE" == "1" ]]; then
    args+=(--quick-check)
  fi
  log "creating SQLite consistent snapshots"
  run_logged python3 "${args[@]}"
  cp "$LOCAL_STATE/sqlite-snapshots/_manifest.json" "$SQLITE_MANIFEST_CACHE"
  rsync_to_nas "$LOCAL_STATE/sqlite-snapshots/" "wsl-sqlite-snapshots" general
}

run_wsl_phase() {
  log "WSL phase start"
  run_sqlite_snapshots
  rsync_to_nas "/home/mnicks/repos/" "wsl/home/mnicks/repos" general
  rsync_to_nas "/home/mnicks/.hermes/" "wsl/home/mnicks/.hermes" sqlite_excludes
  rsync_to_nas "/home/mnicks/.ssh/" "wsl/home/mnicks/.ssh" general
  rsync_to_nas "/home/mnicks/.config/systemd/user/" "wsl/home/mnicks/.config/systemd/user" general
  rsync_to_nas "/home/mnicks/.local/share/lifelog/" "wsl/home/mnicks/.local/share/lifelog" sqlite_excludes
  rsync_to_nas "/home/mnicks/.local/share/browser-memory-daemon/" "wsl/home/mnicks/.local/share/browser-memory-daemon" sqlite_excludes
  rsync_to_nas "/home/mnicks/brain-code/" "wsl/home/mnicks/brain-code" general
  log "WSL phase done"
}

run_windows_phase() {
  local -a windows_launcher
  resolve_windows_launcher "$PS_EXE"
  windows_launcher=("${WINDOWS_LAUNCHER[@]}")

  local ps_win_path
  ps_win_path=$(copy_windows_helper_to_temp)
  local -a args=(-NoProfile -ExecutionPolicy Bypass -File "$ps_win_path" -NasRoot "$NAS_UNC" -LocalManifestCopy "$WINDOWS_MANIFEST_LOCAL_COPY_WIN")
  if [[ "$DRY_RUN" == "1" ]]; then
    args+=(-DryRun)
  fi
  if [[ "$VERBOSE" == "1" ]]; then
    args+=(-VerboseLog)
  fi
  log "Windows phase start launcher=$WINDOWS_LAUNCHER_MODE"
  run_logged "${windows_launcher[@]}" "${args[@]}"
  refresh_windows_manifest_cache
  log "Windows phase done"
}

main() {
  prune_old_logs
  rm -f "$SQLITE_MANIFEST_CACHE" "$WINDOWS_MANIFEST_CACHE"
  log "backup start run_id=$RUN_ID dry_run=$DRY_RUN skip_wsl=$SKIP_WSL skip_windows=$SKIP_WINDOWS"
  record_ledger_event started running
  run_growth_guard pre

  if [[ "$SKIP_WSL" != "1" ]]; then
    run_wsl_phase
  fi
  if [[ "$SKIP_WINDOWS" != "1" ]]; then
    run_windows_phase
  fi

  run_growth_guard post

  STATUS="ok"
  ERROR_MESSAGE=""
  write_status
  record_ledger_event completed ok "$(elapsed_seconds)"
  sync_status_artifacts
  run_integrity_manifest
  log "backup complete status=ok"
  if [[ "$VERBOSE" == "1" ]]; then
    cat "$LAST_STATUS"
  fi
}

main "$@"
