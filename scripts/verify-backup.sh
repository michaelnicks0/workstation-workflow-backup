#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
source "$REPO_ROOT/config/backup.env"

ssh_nas() {
  ssh -i "$NAS_SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$NAS_USER@$NAS_HOST" "$@"
}

printf '== Local timer ==\n'
systemctl --user is-enabled workstation-workflow-backup.timer 2>/dev/null || true
systemctl --user is-active workstation-workflow-backup.timer 2>/dev/null || true
systemctl --user list-timers workstation-workflow-backup.timer --no-pager 2>/dev/null || true
printf '\n== Last local status ==\n'
if [[ -r "${LOCAL_STATE}/last-run.json" ]]; then
  python3 -m json.tool "${LOCAL_STATE}/last-run.json"
else
  echo "No local last-run.json yet at ${LOCAL_STATE}/last-run.json"
fi

printf '\n== NAS dataset / snapshots / manifests ==\n'
ssh_nas "set -e
zfs list -H -o name,mountpoint,used,avail,refer '$NAS_DATASET'
echo '-- recent snapshots --'
zfs list -H -t snapshot -o name,creation,used -r '$NAS_DATASET' | tail -12 || true
echo '-- required paths --'
for p in \
  '$NAS_PATH/current/wsl/home/mnicks/repos' \
  '$NAS_PATH/current/wsl/home/mnicks/.hermes' \
  '$NAS_PATH/current/wsl-sqlite-snapshots/home/mnicks/.hermes/state.db' \
  '$NAS_PATH/current/windows/_manifests/windows-sync-finish.json' \
  '$NAS_PATH/current/_manifests/last-run.json'; do
  if [ -e \"\$p\" ]; then
    ls -ld \"\$p\"
  else
    echo \"MISSING \$p\"
  fi
done
echo '-- snapshot task --'
tmp=/tmp/workstation-workflow-backup-snapshots.json
midclt call pool.snapshottask.query > \"\$tmp\"
python3 - \"\$tmp\" <<'PY'
import json, sys
for task in json.load(open(sys.argv[1], encoding='utf-8')):
    if task.get('dataset') == '$NAS_DATASET':
        print(json.dumps(task, indent=2, sort_keys=True))
PY
rm -f \"\$tmp\"
echo '-- forever snapshot cron jobs --'
tmp=/tmp/workstation-workflow-backup-cron.json
midclt call cronjob.query > \"\$tmp\"
python3 - \"\$tmp\" <<'PY'
import json, sys
for job in json.load(open(sys.argv[1], encoding='utf-8')):
    if str(job.get('description', '')).startswith('WORKSTATION1 workflow backup'):
        print(json.dumps(job, indent=2, sort_keys=True))
PY
rm -f \"\$tmp\"
"
