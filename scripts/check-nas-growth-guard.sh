#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
source "$REPO_ROOT/config/backup.env"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/nas-ssh.sh"

STAGE="manual"
WARN_ONLY=0

usage() {
  cat <<'EOF'
Usage: check-nas-growth-guard.sh [--stage NAME] [--warn-only]

Read-only ZFS budget check for the configured workflow backup dataset. Exits
nonzero when configured dataset/snapshot/available-space limits are violated
unless --warn-only is set.
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

if [[ "${NAS_GROWTH_GUARD_ENABLED:-1}" != "1" ]]; then
  printf 'growth_guard stage=%s status=disabled dataset=%s\n' "$STAGE" "$NAS_DATASET"
  exit 0
fi

ENFORCE=${NAS_GROWTH_GUARD_ENFORCE:-1}
if [[ "$WARN_ONLY" == "1" ]]; then
  ENFORCE=0
fi

HELPER=${NAS_GROWTH_GUARD_REMOTE_HELPER:-/usr/local/sbin/ws1-wf-growth-guard}
ssh_nas "$HELPER" \
  --dataset "$NAS_DATASET" \
  --availability-dataset "${NAS_AVAILABLE_DATASET:-$NAS_DATASET}" \
  --stage "$STAGE" \
  --max-used "${NAS_DATASET_MAX_USED_BYTES:-0}" \
  --max-snapshot-used "${NAS_DATASET_MAX_SNAPSHOT_BYTES:-0}" \
  --min-available "${NAS_DATASET_MIN_AVAILABLE_BYTES:-0}" \
  --max-snapshot-count "${NAS_DATASET_MAX_SNAPSHOT_COUNT:-0}" \
  --enforce "$ENFORCE"
