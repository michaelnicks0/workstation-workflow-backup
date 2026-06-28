#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
source "$REPO_ROOT/config/backup.env"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/nas-ssh.sh"

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

printf '\n== Local run ledger ==\n'
if [[ -r "${LOCAL_STATE}/runs.sqlite3" ]]; then
  python3 "$SCRIPT_DIR/record-run-ledger.py" status --db "${LOCAL_STATE}/runs.sqlite3" --limit 12
else
  echo "No local runs.sqlite3 yet at ${LOCAL_STATE}/runs.sqlite3"
fi

printf '\n== NAS growth guard ==\n'
"$SCRIPT_DIR/check-nas-growth-guard.sh" --stage verify

printf '\n== NAS dataset / snapshots / manifests ==\n'
ssh_nas_admin "set -e
zfs list -H -o name,mountpoint,used,avail,refer,refquota '$NAS_DATASET'
echo '-- recent snapshots --'
zfs list -H -t snapshot -o name,creation,used -r '$NAS_DATASET' | tail -12 || true
echo '-- required paths --'
for p in \
  '$NAS_PATH/current/wsl/home/mnicks/repos' \
  '$NAS_PATH/current/wsl/home/mnicks/.hermes' \
  '$NAS_PATH/current/wsl-sqlite-snapshots/home/mnicks/.hermes/state.db' \
  '$NAS_PATH/current/windows/_manifests/windows-sync-finish.json' \
  '$NAS_PATH/current/_manifests/last-run.json' \
  '$NAS_PATH/current/_manifests/runs.sqlite3' \
  '$NAS_PATH/current/_manifests/run-history.json' \
  '$NAS_PATH/current/_manifests/integrity-manifest.json'; do
  if [ -e \"\$p\" ]; then
    ls -ld \"\$p\"
  else
    echo \"MISSING \$p\"
  fi
done
echo '-- integrity manifest summary --'
if [ -r '$NAS_PATH/current/_manifests/integrity-manifest.json' ]; then
  python3 - '$NAS_PATH/current/_manifests/integrity-manifest.json' <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    data = json.load(handle)
print(json.dumps({
    'kind': data.get('kind'),
    'scope': data.get('scope'),
    'entry_count': data.get('entry_count'),
    'skipped_count': data.get('skipped_count'),
    'duration_seconds': data.get('duration_seconds'),
}, indent=2, sort_keys=True))
PY
fi
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
echo '-- retired snapshot cron jobs (should be disabled) --'
tmp=/tmp/workstation-workflow-backup-cron.json
midclt call cronjob.query > \"\$tmp\"
python3 - \"\$tmp\" <<'PY'
import json, sys
for job in json.load(open(sys.argv[1], encoding='utf-8')):
    description = str(job.get('description', ''))
    command = str(job.get('command', ''))
    if description.startswith('WORKSTATION1 workflow backup') or 'create-retained-snapshot.py' in command:
        print(json.dumps(job, indent=2, sort_keys=True))
PY
rm -f \"\$tmp\"
"
