#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
source "$REPO_ROOT/config/backup.env"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/nas-ssh.sh"

ssh_nas_admin python3 - "$NAS_DATASET" "$SMB_SHARE_NAME" \
  "$NAS_HOURLY_SNAPSHOT_LIFETIME_DAYS" \
  "$NAS_DAILY_SNAPSHOT_LIFETIME_WEEKS" \
  "$NAS_WEEKLY_SNAPSHOT_LIFETIME_WEEKS" \
  "$NAS_MONTHLY_SNAPSHOT_LIFETIME_YEARS" \
  "${NAS_DATASET_REFQUOTA_BYTES:-0}" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

DATASET = sys.argv[1]
SHARE_NAME = sys.argv[2]
HOURLY_LIFETIME_DAYS = int(sys.argv[3])
DAILY_LIFETIME_WEEKS = int(sys.argv[4])
WEEKLY_LIFETIME_WEEKS = int(sys.argv[5])
MONTHLY_LIFETIME_YEARS = int(sys.argv[6])
REFQUOTA_BYTES = int(sys.argv[7] or 0)
MOUNTPOINT = Path('/mnt') / DATASET
HOURLY_SCHEMA = 'wf-h-%Y%m%d-%H%M'
DAILY_SCHEMA = 'wf-d-%Y%m%d-%H%M'
WEEKLY_SCHEMA = 'wf-w-%Y%m%d-%H%M'
MONTHLY_SCHEMA = 'wf-m-%Y%m%d-%H%M'
RETIRED_CRON_DESCRIPTIONS = (
    'WORKSTATION1 workflow backup weekly ZFS snapshot retained',
    'WORKSTATION1 workflow backup monthly ZFS snapshot retained',
    'WORKSTATION1 workflow backup weekly ZFS snapshot forever',
    'WORKSTATION1 workflow backup monthly ZFS snapshot forever',
)


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


def disable_retired_cron_jobs() -> None:
    jobs = midclt('cronjob.query')
    for job in jobs:
        description = str(job.get('description', ''))
        command = str(job.get('command', ''))
        if description in RETIRED_CRON_DESCRIPTIONS or 'create-retained-snapshot.py' in command:
            if job.get('enabled'):
                print(f'disabling retired snapshot cron job id={job["id"]} description={description!r}')
                midclt('cronjob.update', job['id'], {'enabled': False})
            else:
                print(f'retired snapshot cron job already disabled id={job["id"]} description={description!r}')


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
if REFQUOTA_BYTES:
    zfs_set('refquota', str(REFQUOTA_BYTES), DATASET)

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

# Weekly/monthly retention is managed by TrueNAS periodic snapshot tasks below.
# Do not create or run repo-owned zfs-destroy cron helpers here.
legacy_retained_script = MOUNTPOINT / '_ops' / 'create-retained-snapshot.py'
retired_retained_script = legacy_retained_script.with_name(legacy_retained_script.name + '.retired')
if legacy_retained_script.exists():
    if retired_retained_script.exists():
        duplicate_retained_script = legacy_retained_script.with_name(legacy_retained_script.name + '.retired-duplicate')
        legacy_retained_script.rename(duplicate_retained_script)
        print(f'retired duplicate legacy retained snapshot helper: {duplicate_retained_script}')
    else:
        legacy_retained_script.rename(retired_retained_script)
        print(f'retired legacy retained snapshot helper: {retired_retained_script}')
elif retired_retained_script.exists():
    print(f'legacy retained snapshot helper already retired: {retired_retained_script}')

tasks = midclt('pool.snapshottask.query')
hourly_task = ensure_snapshot_task(tasks, HOURLY_SCHEMA, {
    'dataset': DATASET,
    'recursive': True,
    'lifetime_value': HOURLY_LIFETIME_DAYS,
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
    'lifetime_value': DAILY_LIFETIME_WEEKS,
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
weekly_task = ensure_snapshot_task(tasks, WEEKLY_SCHEMA, {
    'dataset': DATASET,
    'recursive': True,
    'lifetime_value': WEEKLY_LIFETIME_WEEKS,
    'lifetime_unit': 'WEEK',
    'enabled': True,
    'exclude': [],
    'naming_schema': WEEKLY_SCHEMA,
    'allow_empty': True,
    'schedule': {
        'minute': '20',
        'hour': '0',
        'dom': '*',
        'month': '*',
        'dow': '7',
        'begin': '00:00',
        'end': '23:59',
    },
})
monthly_task = ensure_snapshot_task(tasks, MONTHLY_SCHEMA, {
    'dataset': DATASET,
    'recursive': True,
    'lifetime_value': MONTHLY_LIFETIME_YEARS,
    'lifetime_unit': 'YEAR',
    'enabled': True,
    'exclude': [],
    'naming_schema': MONTHLY_SCHEMA,
    'allow_empty': True,
    'schedule': {
        'minute': '30',
        'hour': '0',
        'dom': '1',
        'month': '*',
        'dow': '*',
        'begin': '00:00',
        'end': '23:59',
    },
})
disable_retired_cron_jobs()

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


print('--- dataset ---')
print(capture(['zfs', 'list', '-o', 'name,mountpoint,used,avail,refquota', DATASET]).strip())
print('--- recent snapshots ---')
print(capture(['sh', '-c', f'zfs list -t snapshot -o name,creation -r {DATASET} | tail -10']).strip())
print('--- snapshot tasks ---')
for task in midclt('pool.snapshottask.query'):
    if task.get('dataset') == DATASET:
        print(json.dumps(task, indent=2, sort_keys=True))
PY
