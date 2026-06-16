#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
source "$REPO_ROOT/config/backup.env"

ssh_nas() {
  ssh -i "$NAS_SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$NAS_USER@$NAS_HOST" "$@"
}

ssh_nas python3 - "$NAS_DATASET" "$SMB_SHARE_NAME" <<'PY'
import json
import os
import subprocess
import sys
from pathlib import Path

DATASET = sys.argv[1]
SHARE_NAME = sys.argv[2]
MOUNTPOINT = Path('/mnt') / DATASET
HOURLY_SCHEMA = 'workflow-hourly-%Y-%m-%d_%H-%M'
DAILY_SCHEMA = 'workflow-daily-%Y-%m-%d_%H-%M'
WEEKLY_CRON_DESCRIPTION = 'WORKSTATION1 workflow backup weekly ZFS snapshot forever'
MONTHLY_CRON_DESCRIPTION = 'WORKSTATION1 workflow backup monthly ZFS snapshot forever'


def run(cmd, check=True):
    print('+ ' + ' '.join(cmd))
    return subprocess.run(cmd, text=True, check=check, capture_output=False)


def capture(cmd):
    return subprocess.check_output(cmd, text=True)


def zfs_exists(dataset: str) -> bool:
    return subprocess.run(['zfs', 'list', '-H', dataset], text=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def zfs_set(prop: str, value: str, dataset: str) -> None:
    run(['zfs', 'set', f'{prop}={value}', dataset])


def midclt(method: str, *args):
    cmd = ['midclt', 'call', method] + [json.dumps(arg) for arg in args]
    out = subprocess.check_output(cmd, text=True)
    if not out.strip():
        return None
    return json.loads(out)


def ensure_snapshot_task(tasks, schema: str, payload: dict) -> dict:
    matching = [task for task in tasks if task.get('dataset') == DATASET and task.get('naming_schema') == schema]
    if matching:
        task = matching[0]
        print(f'snapshot task exists: id={task["id"]} schema={schema}')
        updated = midclt('pool.snapshottask.update', task['id'], payload)
        return updated if isinstance(updated, dict) else task
    created = midclt('pool.snapshottask.create', payload)
    print(f'created snapshot task: {created.get("id") if isinstance(created, dict) else created} schema={schema}')
    return created


def ensure_cron_job(description: str, command: str, schedule: dict) -> dict:
    jobs = midclt('cronjob.query')
    matching = [job for job in jobs if job.get('description') == description]
    payload = {
        'enabled': True,
        'stderr': True,
        'stdout': False,
        'schedule': schedule,
        'command': command,
        'description': description,
        'user': 'root',
    }
    if matching:
        job = matching[0]
        print(f'cron job exists: id={job["id"]} description={description}')
        updated = midclt('cronjob.update', job['id'], payload)
        return updated if isinstance(updated, dict) else job
    created = midclt('cronjob.create', payload)
    print(f'created cron job: {created.get("id") if isinstance(created, dict) else created} description={description}')
    return created


if not zfs_exists(DATASET):
    run(['zfs', 'create', '-o', 'compression=lz4', '-o', 'atime=off', '-o', 'acltype=nfsv4', '-o', 'aclmode=passthrough', DATASET])
else:
    print(f'dataset exists: {DATASET}')

for prop, value in {
    'compression': 'lz4',
    'atime': 'off',
    'acltype': 'nfsv4',
    'aclmode': 'passthrough',
    'snapdir': 'hidden',
}.items():
    zfs_set(prop, value, DATASET)

MOUNTPOINT.mkdir(parents=True, exist_ok=True)
run(['chown', 'mnicks:wheel', str(MOUNTPOINT)], check=False)
run(['chmod', '775', str(MOUNTPOINT)], check=False)

shares = midclt('sharing.smb.query')
share = next((s for s in shares if s.get('name') == SHARE_NAME or s.get('path') == str(MOUNTPOINT)), None)
share_payload = {
    'path': str(MOUNTPOINT),
    'name': SHARE_NAME,
    'purpose': 'DEFAULT_SHARE',
    'comment': 'WORKSTATION1 15-minute workflow backup target',
    'enabled': True,
    'ro': False,
    'browsable': True,
    'guestok': False,
    'shadowcopy': True,
    'acl': True,
}
if share:
    print(f'SMB share exists: id={share["id"]} name={share["name"]}')
    update_payload = {k: v for k, v in share_payload.items() if k not in {'path', 'name'}}
    try:
        midclt('sharing.smb.update', share['id'], update_payload)
    except Exception as exc:  # TrueNAS versions differ on mutable SMB fields.
        print(f'warning: SMB share update failed: {exc!r}')
else:
    created = midclt('sharing.smb.create', share_payload)
    print(f'created SMB share: {created.get("id") if isinstance(created, dict) else created}')

try:
    run(['midclt', 'call', 'service.reload', 'cifs'], check=False)
except Exception as exc:
    print(f'warning: CIFS reload failed or unsupported; share may still be active: {exc!r}')

ops_dir = MOUNTPOINT / '_ops'
ops_dir.mkdir(parents=True, exist_ok=True)
forever_script = ops_dir / 'create-forever-snapshot.sh'
forever_script.write_text(f'''#!/bin/sh
set -eu
DATASET={DATASET!r}
kind=${{1:?usage: create-forever-snapshot.sh weekly|monthly}}
case "$kind" in
  weekly) name="workflow-weekly-$(date +%G-W%V)" ;;
  monthly) name="workflow-monthly-$(date +%Y-%m)" ;;
  *) echo "unsupported snapshot kind: $kind" >&2; exit 64 ;;
esac
snapshot="$DATASET@$name"
if zfs list -H -t snapshot "$snapshot" >/dev/null 2>&1; then
  exit 0
fi
exec zfs snapshot -r "$snapshot"
''')
forever_script.chmod(0o755)

tasks = midclt('pool.snapshottask.query')
hourly_task = ensure_snapshot_task(tasks, HOURLY_SCHEMA, {
    'dataset': DATASET,
    'recursive': True,
    'lifetime_value': 1,
    'lifetime_unit': 'WEEK',
    'enabled': True,
    'exclude': [],
    'naming_schema': HOURLY_SCHEMA,
    'allow_empty': False,
    'schedule': {
        'minute': '0',
        'hour': '*',
        'dom': '*',
        'month': '*',
        'dow': '*',
        'begin': '00:00',
        'end': '23:59',
    },
})
daily_task = ensure_snapshot_task(tasks, DAILY_SCHEMA, {
    'dataset': DATASET,
    'recursive': True,
    'lifetime_value': 2,
    'lifetime_unit': 'MONTH',
    'enabled': True,
    'exclude': [],
    'naming_schema': DAILY_SCHEMA,
    'allow_empty': True,
    'schedule': {
        'minute': '10',
        'hour': '0',
        'dom': '*',
        'month': '*',
        'dow': '*',
        'begin': '00:00',
        'end': '23:59',
    },
})

ensure_cron_job(
    WEEKLY_CRON_DESCRIPTION,
    f'{forever_script} weekly',
    {'minute': '20', 'hour': '0', 'dom': '*', 'month': '*', 'dow': '7'},
)
ensure_cron_job(
    MONTHLY_CRON_DESCRIPTION,
    f'{forever_script} monthly',
    {'minute': '30', 'hour': '0', 'dom': '1', 'month': '*', 'dow': '*'},
)

# Keep the legacy hourly task out of the way after migrating to the explicit
# workflow-hourly naming schema. Existing snapshots are preserved.
for task in tasks:
    if task.get('dataset') == DATASET and task.get('naming_schema') == 'workflow-%Y-%m-%d_%H-%M':
        print(f'disabling legacy hourly task id={task["id"]} schema={task["naming_schema"]}')
        midclt('pool.snapshottask.update', task['id'], {'enabled': False})

for task in (hourly_task, daily_task):
    task_id = task.get('id') if isinstance(task, dict) else None
    if task_id:
        try:
            print(f'running snapshot task id={task_id} once for immediate coverage')
            midclt('pool.snapshottask.run', task_id)
        except Exception as exc:
            print(f'warning: immediate snapshot run failed for task {task_id}: {exc!r}')

for kind in ('weekly', 'monthly'):
    run([str(forever_script), kind], check=False)

print('--- dataset ---')
print(capture(['zfs', 'list', '-o', 'name,mountpoint,used,avail', DATASET]).strip())
print('--- recent snapshots ---')
print(capture(['sh', '-c', f'zfs list -t snapshot -o name,creation -r {DATASET} | tail -10']).strip())
print('--- snapshot tasks ---')
for task in midclt('pool.snapshottask.query'):
    if task.get('dataset') == DATASET:
        print(json.dumps(task, indent=2, sort_keys=True))
PY
