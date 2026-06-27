# Restore Runbook

Use this when a file, repo, Hermes session DB, lifelog DB, browser-memory DB, or Windows workflow artifact disappears or is corrupted locally.

## 1. Stop making the damage worse

- Do not run manual `rsync --delete` commands.
- If the backup timer is still running and you suspect mass deletion/corruption, pause it while investigating:

```bash
systemctl --user stop workstation-workflow-backup.timer
```

Do **not** destroy NAS snapshots.

## 2. Pick a snapshot

```bash
ssh root@10.99.98.221 'zfs list -t snapshot -r v1/ws1/wf -o name,creation,used,refer | tail -80'
```

Snapshot classes:

- `wf-h-*` — retained for 1 day; use for ≤1 hour RPO.
- `wf-d-*` — retained for 1 week.
- `wf-w-*` — latest 8 weekly snapshots retained by NAS cron.
- `wf-m-*` — latest 12 monthly snapshots retained by NAS cron.

Pick the newest snapshot before the loss/corruption.

## 3. Locate the artifact

```bash
SNAP=wf-h-YYYYMMDD-HHMM
BASE=/mnt/v1/ws1/wf/.zfs/snapshot/$SNAP/current
ssh root@10.99.98.221 "find $BASE -maxdepth 5 -name 'target-name' 2>/dev/null | head"
```

Prefer targeted paths over recursive searches on huge trees.

## 4. Restore to staging first

Never overwrite the live copy blindly. Copy to a restore candidate, inspect, then replace.

```bash
rsync -a root@10.99.98.221:/mnt/v1/ws1/wf/.zfs/snapshot/$SNAP/current/wsl/home/mnicks/repos/example \
  /home/mnicks/restore-candidate-example
```

## 5. SQLite DB restore pattern

Use the `wsl-sqlite-snapshots` tree for Hermes/lifelog/browser-memory DBs. Those files are produced with SQLite's backup API and are the canonical restore copies.

```bash
SNAP=wf-h-YYYYMMDD-HHMM
REMOTE=/mnt/v1/ws1/wf/.zfs/snapshot/$SNAP/current/wsl-sqlite-snapshots/home/mnicks/.hermes/state.db
rsync -a root@10.99.98.221:"$REMOTE" /home/mnicks/.hermes/state.db.restore-candidate
```

Before replacing live Hermes DBs, stop active Hermes processes/gateways that may write to them.

## 6. Resume timer

```bash
systemctl --user start workstation-workflow-backup.timer
./scripts/verify-backup.sh
```
