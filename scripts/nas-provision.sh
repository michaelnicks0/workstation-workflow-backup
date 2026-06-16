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
import time
from pathlib import Path

DATASET = sys.argv[1]
SHARE_NAME = sys.argv[2]
MOUNTPOINT = Path('/mnt') / DATASET
SNAPSHOT_SCHEMA = 'workflow-%Y-%m-%d_%H-%M'


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

tasks = midclt('pool.snapshottask.query')
matching = [task for task in tasks if task.get('dataset') == DATASET and task.get('naming_schema') == SNAPSHOT_SCHEMA]
snapshot_payload = {
    'dataset': DATASET,
    'recursive': True,
    'lifetime_value': 1,
    'lifetime_unit': 'WEEK',
    'enabled': True,
    'exclude': [],
    'naming_schema': SNAPSHOT_SCHEMA,
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
}
if matching:
    task = matching[0]
    print(f'snapshot task exists: id={task["id"]}')
    try:
        midclt('pool.snapshottask.update', task['id'], snapshot_payload)
    except Exception as exc:
        print(f'warning: snapshot task update failed: {exc!r}')
else:
    created = midclt('pool.snapshottask.create', snapshot_payload)
    print(f'created snapshot task: {created.get("id") if isinstance(created, dict) else created}')

manual_snapshot = f'{DATASET}@manual-bootstrap-{time.strftime("%Y%m%d-%H%M%S")}'
if subprocess.run(['zfs', 'list', '-H', '-t', 'snapshot', manual_snapshot], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
    run(['zfs', 'snapshot', '-r', manual_snapshot])

print('--- dataset ---')
print(capture(['zfs', 'list', '-o', 'name,mountpoint,used,avail', DATASET]).strip())
print('--- recent snapshots ---')
print(capture(['sh', '-c', f'zfs list -t snapshot -o name,creation -r {DATASET} | tail -10']).strip())
print('--- snapshot tasks ---')
for task in midclt('pool.snapshottask.query'):
    if task.get('dataset') == DATASET:
        print(json.dumps(task, indent=2, sort_keys=True))
PY
