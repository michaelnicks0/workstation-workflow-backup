#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
source "$REPO_ROOT/config/backup.env"

DRY_RUN=0
VERBOSE=0
SKIP_WINDOWS=0
SKIP_WSL=0
QUICK_CHECK_SQLITE=0

usage() {
  cat <<'EOF'
Usage: workflow-backup.sh [--dry-run] [--verbose] [--skip-windows] [--skip-wsl] [--quick-check-sqlite]

Runs the 15-minute WORKSTATION1 workflow backup. Default mode is silent on success.
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

mkdir -p "$LOCAL_STATE/logs" "$LOCAL_STATE/sqlite-snapshots"
LOG_FILE="$LOCAL_STATE/logs/workflow-backup-$(date -u +%Y%m%dT%H%M%SZ).log"
LAST_STATUS="$LOCAL_STATE/last-run.json"
LOCK_FILE="$LOCAL_STATE/backup.lock"
START_EPOCH=$(date +%s)
STATUS="running"
ERROR_MESSAGE=""

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  # Another timer run is still active. This is not a failure and should stay silent.
  exit 0
fi

log() {
  local msg="$*"
  printf '%s %s\n' "$(date -Is)" "$msg" >> "$LOG_FILE"
  if [[ "$VERBOSE" == "1" ]]; then
    printf '%s\n' "$msg"
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

ssh_nas() {
  ssh -i "$NAS_SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$NAS_USER@$NAS_HOST" "$@"
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

on_error() {
  local rc=$?
  ERROR_MESSAGE="command failed near line ${BASH_LINENO[0]} with exit code $rc"
  STATUS="failed"
  log "FAILED: $ERROR_MESSAGE"
  write_status || true
  if [[ "$DRY_RUN" != "1" ]]; then
    ssh_nas "mkdir -p $(remote_quote "$NAS_PATH/current/_manifests") && cat > $(remote_quote "$NAS_PATH/current/_manifests/last-run.json")" < "$LAST_STATUS" || true
  fi
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
    -aH --numeric-ids --delete-delay --delete-excluded --partial --human-readable --stats
    --rsync-path=/usr/local/bin/rsync
    -e "ssh -i $NAS_SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/home/mnicks/.ssh/known_hosts"
  )
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
  local win_temp_dir="/mnt/c/Users/$WINDOWS_USER/AppData/Local/Temp/workstation-workflow-backup"
  mkdir -p "$win_temp_dir"
  cp "$SCRIPT_DIR/sync-windows-critical.ps1" "$win_temp_dir/sync-windows-critical.ps1"
  printf 'C:\\Users\\%s\\AppData\\Local\\Temp\\workstation-workflow-backup\\sync-windows-critical.ps1' "$WINDOWS_USER"
}

run_sqlite_snapshots() {
  local -a args=("$SCRIPT_DIR/snapshot-sqlite-dbs.py" --output "$LOCAL_STATE/sqlite-snapshots")
  if [[ "$QUICK_CHECK_SQLITE" == "1" ]]; then
    args+=(--quick-check)
  fi
  log "creating SQLite consistent snapshots"
  run_logged python3 "${args[@]}"
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
  if [[ ! -x "$PS_EXE" ]]; then
    echo "PowerShell executable not found: $PS_EXE" >&2
    return 1
  fi
  local ps_win_path
  ps_win_path=$(copy_windows_helper_to_temp)
  local -a args=(-NoProfile -ExecutionPolicy Bypass -File "$ps_win_path" -NasRoot "$NAS_UNC")
  if [[ "$DRY_RUN" == "1" ]]; then
    args+=(-DryRun)
  fi
  if [[ "$VERBOSE" == "1" ]]; then
    args+=(-VerboseLog)
  fi
  log "Windows phase start"
  run_logged "$PS_EXE" "${args[@]}"
  log "Windows phase done"
}

main() {
  log "backup start dry_run=$DRY_RUN skip_wsl=$SKIP_WSL skip_windows=$SKIP_WINDOWS"
  if [[ "$DRY_RUN" != "1" ]]; then
    ssh_nas "mkdir -p $(remote_quote "$NAS_PATH/current/_manifests")"
  fi

  if [[ "$SKIP_WSL" != "1" ]]; then
    run_wsl_phase
  fi
  if [[ "$SKIP_WINDOWS" != "1" ]]; then
    run_windows_phase
  fi

  STATUS="ok"
  ERROR_MESSAGE=""
  write_status
  if [[ "$DRY_RUN" != "1" ]]; then
    ssh_nas "cat > $(remote_quote "$NAS_PATH/current/_manifests/last-run.json")" < "$LAST_STATUS"
  fi
  log "backup complete status=ok"
  if [[ "$VERBOSE" == "1" ]]; then
    cat "$LAST_STATUS"
  fi
}

main "$@"
