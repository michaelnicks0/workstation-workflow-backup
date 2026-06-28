#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
source "$REPO_ROOT/config/backup.env"

ssh_nas() {
  ssh -i "$NAS_SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$NAS_USER@$NAS_HOST" "$@"
}

ssh_nas python3 - "$NAS_DATASET" "$SMB_SHARE_NAME" "$NAS_WEEKLY_SNAPSHOT_RETAIN" "$NAS_MONTHLY_SNAPSHOT_RETAIN" <<'PY'
import json
import os
import subprocess
import sys
from pathlib import Path

DATASET = sys.argv[1]
SHARE_NAME = sys.argv[2]
WEEKLY_RETAIN = int(sys.argv[3])
MONTHLY_RETAIN = int(sys.argv[4])
MOUNTPOINT = Path('/mnt') / DATASET
HOURLY_SCHEMA = 'wf-h-%Y%m%d-%H%M'
DAILY_SCHEMA = 'wf-d-%Y%m%d-%H%M'
WEEKLY_CRON_DESCRIPTION = 'WORKSTATION1 workflow backup weekly ZFS snapshot retained'
MONTHLY_CRON_DESCRIPTION = 'WORKSTATION1 workflow backup monthly ZFS snapshot retained'
OLD_WEEKLY_CRON_DESCRIPTIONS = ('WORKSTATION1 workflow backup weekly ZFS snapshot forever',)
OLD_MONTHLY_CRON_DESCRIPTIONS = ('WORKSTATION1 workflow backup monthly ZFS snapshot forever',)


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


def ensure_cron_job(description: str, command: str, schedule: dict, old_descriptions=()) -> dict:
    jobs = midclt('cronjob.query')
    descriptions = {description, *old_descriptions}
    matching = [job for job in jobs if job.get('description') in descriptions]
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
    'comment': 'WORKSTATION1 hourly workflow backup target',
    'enabled': True,
    'ro': False,
    'browsable': True,
    'guestok': False,
    'shadowcopy': True,
    'acl': True,
    # Robocopy over SMB can repeatedly copy/delete large trees when Samba exposes
    # an 8.3/mangled alias for a long directory name. Keep backup paths literal.
    'auxsmbconf': 'mangled names = no',
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
retained_script = ops_dir / 'create-retained-snapshot.py'
retained_script.write_text(f'''#!/usr/bin/env python3
import re
import subprocess
import sys

DATASET = {DATASET!r}


def capture(cmd):
    return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)


def run(cmd):
    print('+ ' + ' '.join(cmd))
    subprocess.run(cmd, check=True)


def snapshot_exists(name):
    return subprocess.run(['zfs', 'list', '-H', '-t', 'snapshot', name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def main():
    if len(sys.argv) != 3:
        print('usage: create-retained-snapshot.py weekly|monthly RETAIN_COUNT', file=sys.stderr)
        return 64
    kind = sys.argv[1]
    try:
        retain = int(sys.argv[2])
    except ValueError:
        print('retain count must be an integer', file=sys.stderr)
        return 64
    if retain < 1:
        print('retain count must be >= 1', file=sys.stderr)
        return 64

    if kind == 'weekly':
        suffix = capture(['date', '+%G-W%V']).strip()
        prefix = 'wf-w-'
        pattern = re.compile(r'^' + re.escape(DATASET) + r'@wf-w-\d{{4}}-W\d{{2}}$')
    elif kind == 'monthly':
        suffix = capture(['date', '+%Y-%m']).strip()
        prefix = 'wf-m-'
        pattern = re.compile(r'^' + re.escape(DATASET) + r'@wf-m-\d{{4}}-\d{{2}}$')
    else:
        print(f'unsupported snapshot kind: {{kind}}', file=sys.stderr)
        return 64

    snapshot = f'{{DATASET}}@{{prefix}}{{suffix}}'
    if not snapshot_exists(snapshot):
        run(['zfs', 'snapshot', '-r', snapshot])

    snapshots = [
        line.strip()
        for line in capture(['zfs', 'list', '-H', '-t', 'snapshot', '-o', 'name', '-s', 'name', '-r', DATASET]).splitlines()
        if pattern.match(line.strip())
    ]
    delete_count = max(0, len(snapshots) - retain)
    for old_snapshot in snapshots[:delete_count]:
        if not pattern.match(old_snapshot):
            print(f'refusing to destroy unexpected snapshot name: {{old_snapshot}}', file=sys.stderr)
            return 65
        run(['zfs', 'destroy', old_snapshot])
    print(f'{{kind}} retained snapshot count={{len(snapshots) - delete_count}} retain={{retain}} deleted={{delete_count}}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
''')
retained_script.chmod(0o755)

tasks = midclt('pool.snapshottask.query')
hourly_task = ensure_snapshot_task(tasks, HOURLY_SCHEMA, {
    'dataset': DATASET,
    'recursive': True,
    'lifetime_value': 1,
    'lifetime_unit': 'DAY',
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
    'lifetime_value': 1,
    'lifetime_unit': 'WEEK',
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
    f'{retained_script} weekly {WEEKLY_RETAIN}',
    {'minute': '20', 'hour': '0', 'dom': '*', 'month': '*', 'dow': '7'},
    OLD_WEEKLY_CRON_DESCRIPTIONS,
)
ensure_cron_job(
    MONTHLY_CRON_DESCRIPTION,
    f'{retained_script} monthly {MONTHLY_RETAIN}',
    {'minute': '30', 'hour': '0', 'dom': '1', 'month': '*', 'dow': '*'},
    OLD_MONTHLY_CRON_DESCRIPTIONS,
)

# Keep the legacy hourly task out of the way after migrating to the explicit
# wf-h naming schema. Existing snapshots are preserved.
for task in tasks:
    if task.get('dataset') == DATASET and task.get('naming_schema') == 'wf-%Y%m%d-%H%M':
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

for kind, retain in (('weekly', WEEKLY_RETAIN), ('monthly', MONTHLY_RETAIN)):
    run([str(retained_script), kind, str(retain)], check=False)

print('--- dataset ---')
print(capture(['zfs', 'list', '-o', 'name,mountpoint,used,avail', DATASET]).strip())
print('--- recent snapshots ---')
print(capture(['sh', '-c', f'zfs list -t snapshot -o name,creation -r {DATASET} | tail -10']).strip())
print('--- snapshot tasks ---')
for task in midclt('pool.snapshottask.query'):
    if task.get('dataset') == DATASET:
        print(json.dumps(task, indent=2, sort_keys=True))
PY
