# Restore Runbook

Use this when a file, repo, Hermes session DB, lifelog DB, browser-memory DB, or Windows workflow artifact disappears or is corrupted locally.

All commands assume:

```bash
cd ~/repos/workstation/workstation-workflow-backup
source config/backup.env
source scripts/nas-ssh.sh
```

Use the admin SSH path for restore and snapshot inspection. The runtime backup key is deliberately restricted to writes under `current/...` plus NAS-side guard/integrity helpers.

## 1. Stop making the damage worse

- Do not run manual `rsync --delete` commands.
- If the backup timer is still running and you suspect mass deletion/corruption, pause it while investigating:

```bash
systemctl --user stop workstation-workflow-backup.timer
```

Do **not** destroy NAS snapshots.

## NAS pool/unlock preflight

Before using `.zfs/snapshot` paths, verify the encrypted pool root is imported, unlocked, and mounted. Do not create fallback directories under `/mnt/<pool>` if the ZFS dataset is missing; that can create a fake tree on the base filesystem.

```bash
ssh_nas_admin "zfs get -H -o name,property,value encryption,encryptionroot,keystatus,mounted '${NAS_AVAILABLE_DATASET:-$NAS_DATASET}'; midclt call zfs.dataset.locked_datasets"
```

Expected live state for ordinary restores:

- the encrypted pool/root has `keystatus=available` and `mounted=yes`;
- `zfs.dataset.locked_datasets` returns `[]`.

Do not print, copy, or commit raw encryption keys while doing restore work.

## 2. Pick a snapshot

```bash
ssh_nas_admin "zfs list -t snapshot -r '$NAS_DATASET' -o name,creation,used,refer | tail -80"
```

Snapshot classes:

- `wf-h-*` — retained for 2 days; use for ≤1 hour RPO.
- `wf-d-*` — retained for 2 weeks.
- `wf-w-*` — retained for 8 weeks by TrueNAS periodic snapshot task.
- `wf-m-*` — retained for 1 year by TrueNAS periodic snapshot task.

Pick the newest snapshot before the loss/corruption.

## 3. Locate the artifact

```bash
SNAP=wf-h-YYYYMMDD-HHMM
BASE=$NAS_PATH/.zfs/snapshot/$SNAP/current
ssh_nas_admin "find '$BASE' -maxdepth 5 -name 'target-name' 2>/dev/null | head"
```

Prefer targeted paths over recursive searches on huge trees.

## 4. Restore to staging first

Never overwrite the live copy blindly. Copy to a restore candidate, inspect, and verify checksums when available before replacing.

```bash
SNAP=wf-h-YYYYMMDD-HHMM
REMOTE=$NAS_PATH/.zfs/snapshot/$SNAP/current/wsl/home/mnicks/repos/example
rsync -a "$NAS_ADMIN_USER@$NAS_HOST:$REMOTE" /home/mnicks/restore-candidate-example
```

## 5. SQLite DB restore pattern

Use the `wsl-sqlite-snapshots` tree for Hermes/lifelog/browser-memory DBs. Those files are produced with SQLite's backup API and are the canonical restore copies.

```bash
SNAP=wf-h-YYYYMMDD-HHMM
REMOTE=$NAS_PATH/.zfs/snapshot/$SNAP/current/wsl-sqlite-snapshots/home/mnicks/.hermes/state.db
rsync -a "$NAS_ADMIN_USER@$NAS_HOST:$REMOTE" /home/mnicks/.hermes/state.db.restore-candidate
```

Before replacing live Hermes DBs, stop active Hermes processes/gateways that may write to them.

## 6. Verify integrity when the path is in the manifest

Each successful non-dry-run backup writes a NAS-side checksum manifest at:

```text
$NAS_PATH/current/_manifests/integrity-manifest.json
```

Snapshots preserve the matching manifest:

```bash
SNAP=wf-h-YYYYMMDD-HHMM
MANIFEST=$NAS_PATH/.zfs/snapshot/$SNAP/current/_manifests/integrity-manifest.json
ssh_nas_admin "python3 - <<'PY' '$MANIFEST'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    data = json.load(handle)
print(data['kind'], data['scope'], data['entry_count'], 'entries')
PY"
```

For a restored candidate, compare its `sha256sum` with the manifest entry for the corresponding `current/...` path. The default hourly scope is `critical`, which covers status manifests, Windows manifests, and SQLite snapshot artifacts. Use `NAS_INTEGRITY_SCOPE=full` only for deliberate full-tree verification windows because it hashes the whole current tree.

## 7. Resume timer

```bash
systemctl --user start workstation-workflow-backup.timer
./scripts/verify-backup.sh
```
