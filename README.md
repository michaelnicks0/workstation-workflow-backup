# WORKSTATION1 Workflow Backup

High-frequency, ZFS-backed backup for the local workflow state that would hurt if WORKSTATION1/WSL damaged or deleted it.

## Mission

Keep Michael's WSL/Hermes/workflow state recoverable from the TrueNAS host at `root@10.99.98.221`, with a practical recovery point objective of **≤ 1 hour for the last 7 days** plus longer daily/weekly/monthly rollback points. Local sync runs every 15 minutes; ZFS snapshots protect against accidental local deletes or corruptions that are mirrored into the current backup.

## Operating concept

```text
WORKSTATION1 WSL + selected Windows artifacts
  ├─ every 15 min: rsync / robocopy to NAS current tree
  ├─ hourly: TrueNAS periodic ZFS snapshot retained 1 week
  ├─ daily: TrueNAS periodic ZFS snapshot retained 2 months
  ├─ weekly/monthly: TrueNAS cron-created ZFS snapshots retained forever
  └─ on backup failure only: Telegram alert through existing Hermes bot env
```

- NAS dataset: `volume1/workstation1-workflow-backup`
- NAS mountpoint: `/mnt/volume1/workstation1-workflow-backup`
- SMB share: `\\10.99.98.221\workstation1-workflow-backup`
- Systemd timer: `workstation-workflow-backup.timer`
- Hourly snapshots: `workflow-hourly-%Y-%m-%d_%H-%M`, retained `1 WEEK`
- Daily snapshots: `workflow-daily-%Y-%m-%d_%H-%M`, retained `2 MONTH`
- Weekly snapshots: `workflow-weekly-YYYY-Www`, kept until manually destroyed
- Monthly snapshots: `workflow-monthly-YYYY-MM`, kept until manually destroyed

## Requirements / traceability

| Requirement | Implementation | Verification |
|---|---|---|
| REQ-001: Back up `~/repos/` frequently. | `scripts/workflow-backup.sh` rsyncs `/home/mnicks/repos/`. | `scripts/verify-backup.sh`; NAS `current/wsl/home/mnicks/repos/`. |
| REQ-002: Back up Hermes DB/config/session/profile state. | `~/.hermes/` rsync plus consistent SQLite snapshots. | `current/wsl-sqlite-snapshots/home/mnicks/.hermes/state.db`. |
| REQ-003: Back up relevant local WSL DBs. | SQLite backup API snapshots for Hermes, lifelog, and browser-memory DBs. | SQLite snapshot manifest on NAS. |
| REQ-004: Back up critical Windows workflow artifacts. | Windows PowerShell helper uses `robocopy.exe` to SMB. | `current/windows/...` plus Windows manifest. |
| REQ-005: Recover accidental deletes within 7 days with ≤1h loss. | TrueNAS hourly periodic snapshot task, 1-week retention. | `zfs list -t snapshot -r volume1/workstation1-workflow-backup`. |
| REQ-006: Run silently every 15 minutes. | User systemd timer `OnCalendar=*:0/15`; logs to local state. | `systemctl --user list-timers workstation-workflow-backup.timer`. |
| REQ-007: Telegram only on failure. | `OnFailure=...failure-notify@%n.service`; notifier reads `~/.hermes/.env`. | No success message; failure unit logs / Telegram Bot API on nonzero backup. |
| REQ-008: Keep daily snapshots for 2 months. | TrueNAS daily periodic snapshot task with `lifetime_value=2`, `lifetime_unit=MONTH`. | `scripts/verify-backup.sh` snapshot task dump. |
| REQ-009: Keep weekly and monthly snapshots forever. | TrueNAS root cron jobs create `workflow-weekly-*` and `workflow-monthly-*` snapshots with no retention/deletion job. | `scripts/verify-backup.sh` cron job dump and snapshot list. |
| REQ-010: Keep queryable backup-run history. | `scripts/workflow-backup.sh` records start/completion/failure events in `~/.local/state/workstation-workflow-backup/runs.sqlite3` and mirrors a DB snapshot plus JSON export to NAS manifests. | `scripts/record-run-ledger.py status`; `scripts/verify-backup.sh`. |

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

The current NAS mirror keeps the latest status artifacts at:

```text
/mnt/volume1/workstation1-workflow-backup/current/_manifests/last-run.json
/mnt/volume1/workstation1-workflow-backup/current/_manifests/runs.sqlite3
/mnt/volume1/workstation1-workflow-backup/current/_manifests/run-history.json
```

## Restore quick reference

### List snapshots

```bash
ssh root@10.99.98.221 'zfs list -t snapshot -r volume1/workstation1-workflow-backup'
```

Snapshot prefixes:

- `workflow-hourly-*` — hourly, retained for 1 week
- `workflow-daily-*` — daily, retained for 2 months
- `workflow-weekly-*` — weekly, retained forever
- `workflow-monthly-*` — monthly, retained forever

### Restore a missing repo file

```bash
SNAP=workflow-hourly-YYYY-MM-DD_HH-MM
REMOTE=/mnt/volume1/workstation1-workflow-backup/.zfs/snapshot/$SNAP/current/wsl/home/mnicks/repos/path/to/file
rsync -a root@10.99.98.221:"$REMOTE" /home/mnicks/repos/path/to/file
```

### Restore Hermes `state.db` from a consistent snapshot

Stop active Hermes processes first if replacing the live DB.

```bash
SNAP=workflow-hourly-YYYY-MM-DD_HH-MM
ssh root@10.99.98.221 \
  'ls -lh /mnt/volume1/workstation1-workflow-backup/.zfs/snapshot/'"$SNAP"'/current/wsl-sqlite-snapshots/home/mnicks/.hermes/state.db'

# Copy to a staging file first; inspect before replacing live state.
rsync -a root@10.99.98.221:/mnt/volume1/workstation1-workflow-backup/.zfs/snapshot/"$SNAP"/current/wsl-sqlite-snapshots/home/mnicks/.hermes/state.db \
  /home/mnicks/.hermes/state.db.restore-candidate
```

### Restore Windows artifacts

Browse `\\10.99.98.221\workstation1-workflow-backup\current\windows` or use the NAS snapshot path:

```text
/mnt/volume1/workstation1-workflow-backup/.zfs/snapshot/<snapshot>/current/windows/Users/mnicks/...
```

The SMB share has shadow-copy support enabled, so Windows Previous Versions may also surface snapshots.

## Important caveats

- This is not a substitute for the existing full WSL distro export / Windows profile dump. It is the high-frequency workflow safety net.
- The NAS dataset contains secrets and credentials. Treat NAS root and SMB access accordingly.
- Local corruption that exists for more than 2 months ages out of daily rollback but weekly/monthly snapshots remain until manually destroyed.
- Hourly snapshots mean the protected historical restore point can be up to one hour behind current local state. The current mirror usually trails by ≤15 minutes but is not delete-proof by itself.
