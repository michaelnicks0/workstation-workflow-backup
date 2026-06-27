#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
source "$REPO_ROOT/config/backup.env"

STAGE="manual"
WARN_ONLY=0

usage() {
  cat <<'EOF'
Usage: check-nas-growth-guard.sh [--stage NAME] [--warn-only]

Read-only ZFS budget check for v1/ws1/wf. Exits nonzero
when configured dataset/snapshot/available-space limits are violated unless
--warn-only is set.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stage)
      STAGE=${2:?--stage requires a value}
      shift
      ;;
    --warn-only)
      WARN_ONLY=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

remote_quote() {
  local s=${1//\'/\'\\\'\'}
  printf "'%s'" "$s"
}

ssh_nas() {
  ssh -i "$NAS_SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$NAS_USER@$NAS_HOST" "$@"
}

if [[ "${NAS_GROWTH_GUARD_ENABLED:-1}" != "1" ]]; then
  printf 'growth_guard stage=%s status=disabled dataset=%s\n' "$STAGE" "$NAS_DATASET"
  exit 0
fi

ENFORCE=${NAS_GROWTH_GUARD_ENFORCE:-1}
if [[ "$WARN_ONLY" == "1" ]]; then
  ENFORCE=0
fi

ssh_nas "python3 - $(remote_quote "$NAS_DATASET") $(remote_quote "$STAGE") $(remote_quote "${NAS_DATASET_MAX_USED_BYTES:-0}") $(remote_quote "${NAS_DATASET_MAX_SNAPSHOT_BYTES:-0}") $(remote_quote "${NAS_DATASET_MIN_AVAILABLE_BYTES:-0}") $(remote_quote "${NAS_DATASET_MAX_SNAPSHOT_COUNT:-0}") $(remote_quote "$ENFORCE")" <<'PY'
import subprocess
import sys

DATASET, STAGE, MAX_USED, MAX_SNAP, MIN_AVAIL, MAX_SNAP_COUNT, ENFORCE = sys.argv[1:]
MAX_USED = int(MAX_USED or 0)
MAX_SNAP = int(MAX_SNAP or 0)
MIN_AVAIL = int(MIN_AVAIL or 0)
MAX_SNAP_COUNT = int(MAX_SNAP_COUNT or 0)
ENFORCE = ENFORCE == "1"


def capture(cmd):
    return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)


def fmt(num: int) -> str:
    value = float(num)
    for unit in ("B", "KiB", "MiB", "GiB", "TiB", "PiB"):
        if abs(value) < 1024 or unit == "PiB":
            return f"{value:.2f} {unit}"
        value /= 1024
    raise AssertionError("unreachable")

props = {}
for line in capture(["zfs", "get", "-H", "-p", "-o", "property,value", "used,available,usedbysnapshots", DATASET]).splitlines():
    key, value = line.split("\t", 1)
    props[key] = int(value)

snapshot_lines = capture(["zfs", "list", "-H", "-t", "snapshot", "-o", "name", "-r", DATASET]).splitlines()
snapshot_count = len([line for line in snapshot_lines if line.strip()])

used = props["used"]
available = props["available"]
snapshot_used = props["usedbysnapshots"]
violations = []

if MAX_USED and used > MAX_USED:
    violations.append(f"dataset used {fmt(used)} exceeds max {fmt(MAX_USED)}")
if MAX_SNAP and snapshot_used > MAX_SNAP:
    violations.append(f"snapshot-held data {fmt(snapshot_used)} exceeds max {fmt(MAX_SNAP)}")
if MIN_AVAIL and available < MIN_AVAIL:
    violations.append(f"available space {fmt(available)} is below reserve {fmt(MIN_AVAIL)}")
if MAX_SNAP_COUNT and snapshot_count > MAX_SNAP_COUNT:
    violations.append(f"snapshot count {snapshot_count} exceeds max {MAX_SNAP_COUNT}")

status = "failed" if violations and ENFORCE else "warning" if violations else "ok"
print(
    "growth_guard "
    f"stage={STAGE} status={status} dataset={DATASET} "
    f"used={fmt(used)} max_used={fmt(MAX_USED) if MAX_USED else 'disabled'} "
    f"snapshot_used={fmt(snapshot_used)} max_snapshot_used={fmt(MAX_SNAP) if MAX_SNAP else 'disabled'} "
    f"available={fmt(available)} min_available={fmt(MIN_AVAIL) if MIN_AVAIL else 'disabled'} "
    f"snapshots={snapshot_count} max_snapshots={MAX_SNAP_COUNT if MAX_SNAP_COUNT else 'disabled'}"
)
for violation in violations:
    print(f"growth_guard violation: {violation}")

if violations and ENFORCE:
    sys.exit(75)
PY
