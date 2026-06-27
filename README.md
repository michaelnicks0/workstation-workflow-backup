# WORKSTATION1 Workflow Backup

High-frequency, ZFS-backed backup for the local workflow state that would hurt if WORKSTATION1/WSL damaged or deleted it.

## Mission

Keep Michael's WSL/Hermes/workflow state recoverable from the TrueNAS host at `root@10.99.98.221`, with a practical recovery point objective of **≤ 1 hour for the last day** plus bounded daily/weekly/monthly rollback points. Local sync runs hourly; ZFS snapshots protect against accidental local deletes or corruptions that are mirrored into the current backup. A fail-closed growth guard stops backup writes before this dataset can silently run away.

## Operating concept

```text
WORKSTATION1 WSL + selected Windows artifacts
  ├─ hourly at :45: rsync / robocopy to NAS current tree
  ├─ before/after sync: fail-closed NAS dataset growth guard
  ├─ hourly: TrueNAS periodic ZFS snapshot retained 1 day
  ├─ daily: TrueNAS periodic ZFS snapshot retained 1 week
  ├─ weekly: NAS cron snapshot retained for latest 8 weekly points
  ├─ monthly: NAS cron snapshot retained for latest 12 monthly points
  └─ on backup failure only: Telegram alert through existing Hermes bot env
```

- NAS dataset: `v1/ws1/wf`
- NAS mountpoint: `/mnt/v1/ws1/wf`
- SMB share: `\\10.99.98.221\ws1-wf`
- Systemd timer: `workstation-workflow-backup.timer`
- Hourly snapshots: `wf-h-%Y%m%d-%H%M`, retained `1 DAY`
- Daily snapshots: `wf-d-%Y%m%d-%H%M`, retained `1 WEEK`
- Weekly snapshots: `wf-w-YYYY-Www`, retained latest 8
- Monthly snapshots: `wf-m-YYYY-MM`, retained latest 12
- Growth guard: fails backup when dataset exceeds 2 TiB used, 512 GiB snapshot-held blocks, 500 snapshots, or leaves less than 2 TiB free on `v1`

## Snapshot schedule / pruning

| Layer | Scheduler | Enabled | Schedule | Snapshot name | Pruning / retention |
|---|---|---:|---|---|---|
| Current mirror sync | WSL systemd user timer | Yes | `OnCalendar=*:45`, `OnBootSec=3min`, `AccuracySec=1min`, `RandomizedDelaySec=30s`, `Persistent=true` | Not a ZFS snapshot; writes `current/...` | No mirror history; delete/corruption recovery depends on ZFS snapshots below |
| Hourly ZFS snapshots | TrueNAS periodic snapshot task | Yes | every hour at minute `0`, all day | `wf-h-%Y%m%d-%H%M` | TrueNAS lifetime `1 DAY`; `allow_empty=false`; recursive |
| Daily ZFS snapshots | TrueNAS periodic snapshot task | Yes | every day at `00:10` | `wf-d-%Y%m%d-%H%M` | TrueNAS lifetime `1 WEEK`; `allow_empty=true`; recursive |
| Weekly ZFS snapshots | TrueNAS root cron job | Yes | Sunday at `00:20` (`dow=7`) | `wf-w-YYYY-Www` from ISO `%G-W%V` | `_ops/create-retained-snapshot.py weekly 8`; exact-pattern oldest-first prune, latest 8 retained |
| Monthly ZFS snapshots | TrueNAS root cron job | Yes | day `1` at `00:30` | `wf-m-YYYY-MM` | `_ops/create-retained-snapshot.py monthly 12`; exact-pattern oldest-first prune, latest 12 retained |
| Legacy hourly task | TrueNAS periodic snapshot task | No | formerly every hour at minute `0` | `wf-%Y%m%d-%H%M` | Disabled by `nas-provision.sh`; existing snapshots are preserved if any remain |

Manual snapshots, such as `post-cleanup-*`, are outside configured pruning and must be reviewed/deleted explicitly.

## Requirements / traceability

| Requirement | Implementation | Verification |
|---|---|---|
| REQ-001: Back up `~/repos/` frequently. | `scripts/workflow-backup.sh` rsyncs `/home/mnicks/repos/`. | `scripts/verify-backup.sh`; NAS `current/wsl/home/mnicks/repos/`. |
| REQ-002: Back up Hermes DB/config/session/profile state. | `~/.hermes/` rsync plus consistent SQLite snapshots. | `current/wsl-sqlite-snapshots/home/mnicks/.hermes/state.db`. |
| REQ-003: Back up relevant local WSL DBs. | SQLite backup API snapshots for Hermes, lifelog, and browser-memory DBs. | SQLite snapshot manifest on NAS. |
| REQ-004: Back up critical Windows workflow artifacts. | Windows PowerShell helper uses `robocopy.exe` to SMB. | `current/windows/...` plus Windows manifest. |
| REQ-005: Recover accidental deletes within 1 day with ≤1h loss. | TrueNAS hourly periodic snapshot task, 1-day retention. | `zfs list -t snapshot -r v1/ws1/wf`. |
| REQ-006: Run silently hourly. | User systemd timer `OnCalendar=*:45`; logs to local state. | `systemctl --user list-timers workstation-workflow-backup.timer`. |
| REQ-007: Telegram only on failure. | `OnFailure=...failure-notify@%n.service`; notifier reads `~/.hermes/.env`. | No success message; failure unit logs / Telegram Bot API on nonzero backup. |
| REQ-008: Keep daily snapshots for 1 week. | TrueNAS daily periodic snapshot task with `lifetime_value=1`, `lifetime_unit=WEEK`. | `scripts/verify-backup.sh` snapshot task dump. |
| REQ-009: Keep weekly/monthly rollback points without unbounded retention. | NAS cron jobs run `_ops/create-retained-snapshot.py`, retaining latest 8 weekly and 12 monthly snapshots by exact name pattern. | `scripts/verify-backup.sh` cron job dump and snapshot list. |
| REQ-010: Keep queryable backup-run history. | `scripts/workflow-backup.sh` records start/completion/failure events in `~/.local/state/workstation-workflow-backup/runs.sqlite3` and mirrors a DB snapshot plus JSON export to NAS manifests. | `scripts/record-run-ledger.py status`; `scripts/verify-backup.sh`. |
| REQ-011: Prevent silent infinite dataset growth. | `scripts/check-nas-growth-guard.sh` checks ZFS `used`, `available`, `usedbysnapshots`, and snapshot count before and after backup writes; violations fail the backup and trigger the existing failure alert path. | `scripts/check-nas-growth-guard.sh --stage verify`; `scripts/verify-backup.sh`. |

## Backup scope

### WSL

Primary mirrors:

- `/home/mnicks/repos/`
- `/home/mnicks/.hermes/` (excluding live SQLite files; consistent copies are under `wsl-sqlite-snapshots`)
- `/home/mnicks/.ssh/`
- `/home/mnicks/.config/systemd/user/`
- `/home/mnicks/.local/share/lifelog/` (SQLite excluded from mirror, backed consistently)
- `/home/mnicks/.local/share/browser-memory-daemon/` (SQLite excluded from mirror, backed consistently)
- `/home/mnicks/brain-code/` when present

The WSL rsync phase runs through `sudo -n rsync` so root-owned files inside local artifact/quarantine trees are included instead of silently skipped. It uses `/home/mnicks/.ssh/id_ed25519` for NAS SSH.

Consistent SQLite snapshots include:

- `~/.hermes/state.db`
- `~/.hermes/kanban.db`, `~/.hermes/ai-usage.db`, board/profile DBs
- `~/.local/share/lifelog/lifelog.sqlite3`
- `~/.local/share/browser-memory-daemon/browser-memory.sqlite3`

### Windows host

The Windows phase intentionally targets workflow-critical user artifacts, not a full bare-metal image:

- `Desktop`, `Documents`, `Downloads`
- `%USERPROFILE%\.ssh`
- `%USERPROFILE%\.wslconfig`
- Windows Terminal `LocalState`
- VS Code `User` settings/snippets
- PowerShell profile directories
- Chrome Default `Bookmarks`, `Preferences`, and `Secure Preferences`
- Startup folder shortcuts/scripts

For a full profile or WSL distro export, use the older disaster-recovery repo: `~/repos/workstation/freenas-windows-backup`.

## Install / operate

```bash
cd ~/repos/workstation/workstation-workflow-backup
./scripts/run-tests.sh
./scripts/nas-provision.sh
./scripts/install-systemd-user.sh
./scripts/workflow-backup.sh --verbose   # first live run / smoke
./scripts/verify-backup.sh
```

Successful timer runs are quiet. Logs and state live under:

```text
~/.local/state/workstation-workflow-backup/
├── last-run.json              # compatibility latest-run status
├── runs.sqlite3               # append-only run event ledger
├── nas-export/run-history.json # exported recent run summaries before NAS sync
└── logs/workflow-backup-*.log # one log per run
```

Query recent runs:

```bash
python3 scripts/record-run-ledger.py status \
  --db ~/.local/state/workstation-workflow-backup/runs.sqlite3 \
  --limit 12
```

Check the live ZFS growth budget without mutating the NAS:

```bash
./scripts/check-nas-growth-guard.sh --stage manual
```

Default fail-closed budget in `config/backup.env`:

| Guard | Limit |
|---|---:|
| Total dataset used | 2 TiB |
| Snapshot-held blocks | 512 GiB |
| Minimum free space on `v1` | 2 TiB |
| Snapshot count | 500 |

The guard is intentionally non-destructive. It stops the backup and lets the normal failure alert fire; it does not destroy snapshots or payload files.

The current NAS mirror keeps the latest status artifacts at:

```text
/mnt/v1/ws1/wf/current/_manifests/last-run.json
/mnt/v1/ws1/wf/current/_manifests/runs.sqlite3
/mnt/v1/ws1/wf/current/_manifests/run-history.json
```

## Restore quick reference

### List snapshots

```bash
ssh root@10.99.98.221 'zfs list -t snapshot -r v1/ws1/wf'
```

Snapshot prefixes:

- `wf-h-*` — hourly, retained for 1 day
- `wf-d-*` — daily, retained for 1 week
- `wf-w-*` — latest 8 weekly snapshots retained by NAS cron
- `wf-m-*` — latest 12 monthly snapshots retained by NAS cron

### Restore a missing repo file

```bash
SNAP=wf-h-YYYYMMDD-HHMM
REMOTE=/mnt/v1/ws1/wf/.zfs/snapshot/$SNAP/current/wsl/home/mnicks/repos/path/to/file
rsync -a root@10.99.98.221:"$REMOTE" /home/mnicks/repos/path/to/file
```

### Restore Hermes `state.db` from a consistent snapshot

Stop active Hermes processes first if replacing the live DB.

```bash
SNAP=wf-h-YYYYMMDD-HHMM
ssh root@10.99.98.221 \
  'ls -lh /mnt/v1/ws1/wf/.zfs/snapshot/'"$SNAP"'/current/wsl-sqlite-snapshots/home/mnicks/.hermes/state.db'

# Copy to a staging file first; inspect before replacing live state.
rsync -a root@10.99.98.221:/mnt/v1/ws1/wf/.zfs/snapshot/"$SNAP"/current/wsl-sqlite-snapshots/home/mnicks/.hermes/state.db \
  /home/mnicks/.hermes/state.db.restore-candidate
```

### Restore Windows artifacts

Browse `\\10.99.98.221\ws1-wf\current\windows` or use the NAS snapshot path:

```text
/mnt/v1/ws1/wf/.zfs/snapshot/<snapshot>/current/windows/Users/mnicks/...
```

The SMB share has shadow-copy support enabled, so Windows Previous Versions may also surface snapshots.

## Important caveats

- This is not a substitute for the existing full WSL distro export / Windows profile dump. It is the high-frequency workflow safety net.
- The NAS dataset contains secrets and credentials. Treat NAS root and SMB access accordingly.
- Local corruption that exists for more than 1 week ages out of daily rollback; weekly/monthly rollback coverage is bounded by the configured retained counts.
- Hourly snapshots mean the protected historical restore point can be up to one hour behind current local state. The current mirror usually trails by ≤1 hour but is not delete-proof by itself.
- A growth-guard failure means the dataset needs manual review before more payload writes; do not disable the guard just to silence the alert.
