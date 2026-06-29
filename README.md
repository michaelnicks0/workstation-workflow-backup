# WORKSTATION1 Workflow Backup

High-frequency, ZFS-backed backup for local workflow state that would hurt if WORKSTATION1/WSL damaged or deleted it.

## Mission

Keep Michael's WSL/Hermes/workflow state recoverable on the configured TrueNAS dataset with a practical recovery point objective of **≤ 1 hour for the last day** plus bounded daily/weekly/monthly rollback points. Local sync runs hourly; ZFS snapshots protect against accidental local deletes or corruptions that are mirrored into the current backup. A fail-closed growth guard and dataset `refquota` stop backup writes before this dataset can silently run away.

## Operating concept

```text
WORKSTATION1 WSL + selected Windows artifacts
  ├─ hourly at :45: rsync / robocopy to NAS current tree
  ├─ runtime SSH: dedicated restricted NAS user/key, pinned host key, no root automation
  ├─ before/after sync: fail-closed NAS dataset growth guard
  ├─ restore checksums: NAS-side integrity manifest for critical restore artifacts
  ├─ hourly: TrueNAS periodic ZFS snapshot retained 2 days
  ├─ daily: TrueNAS periodic ZFS snapshot retained 2 weeks
  ├─ weekly: TrueNAS periodic ZFS snapshot retained 8 weeks
  ├─ monthly: TrueNAS periodic ZFS snapshot retained 1 year
  └─ on backup failure only: Telegram alert through existing Hermes bot env
```

Local machine/NAS values live in ignored `config/backup.env`; the public template is [`config/backup.env.example`](config/backup.env.example).

Key configured surfaces:

- NAS dataset: `$NAS_DATASET`
- NAS mountpoint: `$NAS_PATH`
- SMB share: `$NAS_UNC`
- Runtime SSH user: `$NAS_USER` (dedicated backup user, not root)
- Admin SSH user: `$NAS_ADMIN_USER` (manual provisioning/restore only)
- Pinned host key file: `$NAS_KNOWN_HOSTS` with `$NAS_HOST_KEY_ALIAS`
- Systemd timer: `workstation-workflow-backup.timer`
- Hourly snapshots: `wf-h-%Y%m%d-%H%M`, retained `2 DAYS`
- Daily snapshots: `wf-d-%Y%m%d-%H%M`, retained `2 WEEKS`
- Weekly snapshots: `wf-w-%Y%m%d-%H%M`, retained `8 WEEKS`
- Monthly snapshots: `wf-m-%Y%m%d-%H%M`, retained `1 YEAR`
- Growth guard: fails backup when dataset exceeds 2 TiB used, 1 TiB snapshot-held blocks, 5000 snapshots, or leaves less than 2 TiB free on the configured availability dataset
- Live current-tree hard cap: ZFS `refquota` from `$NAS_DATASET_REFQUOTA_BYTES`

## Security model

The hourly path does **not** SSH to the NAS as root. Runtime NAS access is installed by [`scripts/install-nas-runtime-hardening.sh`](scripts/install-nas-runtime-hardening.sh):

- creates/updates a dedicated runtime user (default `ws1backup`);
- installs a dedicated runtime SSH public key;
- pins the NAS host key through `StrictHostKeyChecking=yes`, `UserKnownHostsFile`, and `HostKeyAlias`;
- forces the runtime key through `scripts/nas-runtime-ssh-dispatch.py` on the NAS;
- permits only restricted `rsync --server` writes under `$NAS_PATH/current`, `mkdir -p` under that tree, and sudo execution of the NAS-side guard/integrity helpers;
- rejects interactive shell, arbitrary commands, port forwarding, agent forwarding, X11 forwarding, PTY, and rsync sender mode;
- applies a ZFS `refquota` so direct SMB/robocopy growth is interrupted by ZFS rather than only detected after the run.

Root/admin SSH remains necessary for explicit provisioning, snapshot inspection, and restore operations. It is not used by the hourly systemd timer.

## NAS encryption/key state

The workflow backup dataset lives under encrypted pool root `v1` on the live WORKSTATION1 NAS. This repo must never store TrueNAS encryption keys, config DB exports, SMB credentials, private SSH keys, or backed-up payload contents. Live unlock/import status should be checked with `scripts/verify-backup.sh`; this does not replace a separate cold reboot/import/unlock drill.

## Snapshot schedule / pruning

| Layer | Scheduler | Enabled | Schedule | Snapshot name | Pruning / retention |
|---|---|---:|---|---|---|
| Current mirror sync | WSL systemd user timer | Yes | `OnCalendar=*:45`, `OnBootSec=3min`, `AccuracySec=1min`, `RandomizedDelaySec=30s`, `Persistent=true` | Not a ZFS snapshot; writes `current/...` | No mirror history; delete/corruption recovery depends on ZFS snapshots below |
| Hourly ZFS snapshots | TrueNAS periodic snapshot task | Yes | every hour at minute `0`, all day | `wf-h-%Y%m%d-%H%M` | TrueNAS lifetime `2 DAYS`; `allow_empty=false`; recursive |
| Daily ZFS snapshots | TrueNAS periodic snapshot task | Yes | every day at `00:10` | `wf-d-%Y%m%d-%H%M` | TrueNAS lifetime `2 WEEKS`; `allow_empty=true`; recursive |
| Weekly ZFS snapshots | TrueNAS periodic snapshot task | Yes | Sunday at `00:20` | `wf-w-%Y%m%d-%H%M` | TrueNAS lifetime `8 WEEKS`; `allow_empty=true`; recursive |
| Monthly ZFS snapshots | TrueNAS periodic snapshot task | Yes | day `1` at `00:30` | `wf-m-%Y%m%d-%H%M` | TrueNAS lifetime `1 YEAR`; `allow_empty=true`; recursive |
| Retired retained-snapshot cron jobs | TrueNAS root cron jobs | No | formerly Sunday `00:20` / day `1` at `00:30` | `wf-w-*` / `wf-m-*` | Disabled by `nas-provision.sh`; legacy helper is renamed to `.retired`; retention is managed by TrueNAS periodic snapshot tasks, not repo-owned `zfs destroy` helpers |
| Legacy hourly task | TrueNAS periodic snapshot task | No | formerly every hour at minute `0` | `wf-%Y%m%d-%H%M` | Disabled by `nas-provision.sh`; existing snapshots are preserved if any remain |

Manual snapshots, such as `post-cleanup-*`, are outside configured pruning and must be reviewed/deleted explicitly.

## Documentation

| Doc | Purpose |
|---|---|
| **[High-level doc](workstation-workflow-backup-high-level-doc.html)** | Front door: what it does, how it works, commands, mental model, safety boundary |
| [Docs Index](docs/README.md) | Reading path, ownership matrix, validation gate, update triggers |
| [User Guide](docs/USER_GUIDE.md) | First-run journey, I want to… routing table, failure alert response, safety rules |
| [Executive Brief](docs/EXECUTIVE_BRIEF.md) | Risk posture, retention schedule, maturity summary |
| [Restore Runbook](docs/restore-runbook.md) | Step-by-step restore for files, DBs, Windows artifacts |
| [Architecture README](docs/architecture/README.md) | C4 views, ADR overview, architecture sources |
| [C4 Diagrams](docs/architecture/c4-diagrams.md) | Generated 10-view diagram atlas |
| [ADR Index](docs/architecture/adr/README.md) | 6 decisions with rationale |
| [Test Inventory](docs/TESTS.md) | 14 static contract tests, coverage map |

## Architecture / ADRs

- C4 model source: [`docs/architecture/workspace.dsl`](docs/architecture/workspace.dsl)
- Generated C4 diagram atlas: [`docs/architecture/c4-diagrams.md`](docs/architecture/c4-diagrams.md)
- Architecture guide: [`docs/architecture/README.md`](docs/architecture/README.md)
- Architecture Decision Records: [`docs/architecture/adr/README.md`](docs/architecture/adr/README.md)

## Requirements / traceability

| Requirement | Implementation | Verification |
|---|---|---|
| REQ-001: Back up `~/repos/` frequently. | `scripts/workflow-backup.sh` rsyncs `/home/mnicks/repos/`. | `scripts/verify-backup.sh`; NAS `current/wsl/home/mnicks/repos/`. |
| REQ-002: Back up Hermes DB/config/session/profile state. | `~/.hermes/` rsync plus consistent SQLite snapshots. | `current/wsl-sqlite-snapshots/home/mnicks/.hermes/state.db`. |
| REQ-003: Back up relevant local WSL DBs. | SQLite backup API snapshots for Hermes, lifelog, and browser-memory DBs. | SQLite snapshot manifest on NAS. |
| REQ-004: Back up critical Windows workflow artifacts. | Windows PowerShell helper uses `robocopy.exe` to SMB and leaves a local manifest copy for the WSL ledger. | `current/windows/...` plus Windows manifest. |
| REQ-005: Recover accidental deletes within 2 days with ≤1h loss. | TrueNAS hourly periodic snapshot task, 2-day retention. | `zfs list -t snapshot -r "$NAS_DATASET"`. |
| REQ-006: Run silently hourly. | User systemd timer `OnCalendar=*:45`; logs to local state with local retention. | `systemctl --user list-timers workstation-workflow-backup.timer`. |
| REQ-007: Telegram only on failure. | `OnFailure=...failure-notify@%n.service`; notifier reads `~/.hermes/.env`. | No success message; failure unit logs / Telegram Bot API on nonzero backup. |
| REQ-008: Keep daily snapshots for 2 weeks. | TrueNAS daily periodic snapshot task with `lifetime_value=2`, `lifetime_unit=WEEK`. | `scripts/verify-backup.sh` snapshot task dump. |
| REQ-009: Keep weekly/monthly rollback points without repo-owned pruning helpers. | TrueNAS weekly/monthly periodic snapshot tasks retain 8 weeks and 1 year respectively; retired cron helpers are disabled. | `scripts/verify-backup.sh` snapshot task and retired cron dump. |
| REQ-010: Keep queryable backup-run history. | `scripts/workflow-backup.sh` records start/completion/failure events in `~/.local/state/workstation-workflow-backup/runs.sqlite3`; final ledger write is strict. | `scripts/record-run-ledger.py status`; `scripts/verify-backup.sh`. |
| REQ-011: Prevent silent infinite dataset growth. | NAS-side helper checks ZFS `used`, availability dataset free space, `usedbysnapshots`, and snapshot count before/after writes; `refquota` caps live current-tree growth. | `scripts/check-nas-growth-guard.sh --stage verify`; `scripts/verify-backup.sh`. |
| REQ-012: Preserve restore integrity evidence. | NAS-side helper writes `_manifests/integrity-manifest.json` with SHA-256 checksums for critical restore artifacts every successful live run. | `scripts/verify-backup.sh` integrity summary; restore runbook checksum commands. |

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

The WSL rsync phase runs through `sudo -n rsync` locally so root-owned files inside local artifact/quarantine trees are included instead of silently skipped. The remote receiving side is the restricted NAS runtime user, not root; owner/group preservation is disabled by default because the restore source of truth is file content plus ZFS snapshots/checksums.

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
cp config/backup.env.example config/backup.env
$EDITOR config/backup.env

# Create a dedicated runtime key if config points to a new key path.
ssh-keygen -t ed25519 -N '' -C 'workstation-workflow-backup runtime' -f "$NAS_SSH_KEY"
ssh-keyscan -t ed25519 "$NAS_HOST" | sed "s/^$NAS_HOST /$NAS_HOST_KEY_ALIAS /" > "$NAS_KNOWN_HOSTS"
chmod 600 "$NAS_SSH_KEY" "$NAS_KNOWN_HOSTS"

./scripts/run-tests.sh
./scripts/nas-provision.sh
./scripts/install-nas-runtime-hardening.sh
./scripts/install-systemd-user.sh
./scripts/workflow-backup.sh --verbose   # first live run / smoke
./scripts/verify-backup.sh
```

Successful timer runs are quiet. Logs and state live under:

```text
~/.local/state/workstation-workflow-backup/
├── last-run.json               # compatibility latest-run status
├── runs.sqlite3                # append-only run event ledger
├── nas-export/run-history.json # exported recent run summaries before NAS sync
└── logs/workflow-backup-*.log  # one log per run, pruned by LOCAL_LOG_RETENTION_DAYS
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

Default fail-closed budget in `config/backup.env.example`:

| Guard | Limit |
|---|---:|
| Total dataset used | 2 TiB |
| Snapshot-held blocks | 1 TiB |
| Minimum free space on configured availability dataset | 2 TiB |
| Snapshot count | 5000 |
| Current-tree `refquota` | 2 TiB |

The guard is intentionally non-destructive. It stops the backup and lets the normal failure alert fire; it does not destroy snapshots or payload files.

The current NAS mirror keeps the latest status/integrity artifacts at:

```text
$NAS_PATH/current/_manifests/last-run.json
$NAS_PATH/current/_manifests/runs.sqlite3
$NAS_PATH/current/_manifests/run-history.json
$NAS_PATH/current/_manifests/integrity-manifest.json
```

## Restore quick reference

Use the admin SSH identity for restore/snapshot inspection, not the restricted runtime key:

```bash
source config/backup.env
source scripts/nas-ssh.sh
ssh_nas_admin "zfs list -t snapshot -r '$NAS_DATASET'"
```

Snapshot prefixes:

- `wf-h-*` — hourly, retained for 2 days
- `wf-d-*` — daily, retained for 2 weeks
- `wf-w-*` — weekly, retained for 8 weeks
- `wf-m-*` — monthly, retained for 1 year

### Restore a missing repo file

```bash
source config/backup.env
SNAP=wf-h-YYYYMMDD-HHMM
REMOTE=$NAS_PATH/.zfs/snapshot/$SNAP/current/wsl/home/mnicks/repos/path/to/file
rsync -a "$NAS_ADMIN_USER@$NAS_HOST:$REMOTE" /home/mnicks/repos/path/to/file
```

### Restore Hermes `state.db` from a consistent snapshot

Stop active Hermes processes first if replacing the live DB.

```bash
source config/backup.env
SNAP=wf-h-YYYYMMDD-HHMM
REMOTE=$NAS_PATH/.zfs/snapshot/$SNAP/current/wsl-sqlite-snapshots/home/mnicks/.hermes/state.db

# Copy to a staging file first; inspect before replacing live state.
rsync -a "$NAS_ADMIN_USER@$NAS_HOST:$REMOTE" /home/mnicks/.hermes/state.db.restore-candidate
```

### Verify a staged restore against the integrity manifest

```bash
source config/backup.env
SNAP=wf-h-YYYYMMDD-HHMM
MANIFEST=$NAS_PATH/.zfs/snapshot/$SNAP/current/_manifests/integrity-manifest.json
ssh "$NAS_ADMIN_USER@$NAS_HOST" "python3 -m json.tool '$MANIFEST' | head"
```

For a restored file whose path is present in `integrity-manifest.json`, compare the local SHA-256 with the manifest entry before replacing live state.

### Restore Windows artifacts

Browse `$NAS_UNC\current\windows` or use the NAS snapshot path:

```text
$NAS_PATH/.zfs/snapshot/<snapshot>/current/windows/Users/<windows-user>/...
```

The SMB share has shadow-copy support enabled, so Windows Previous Versions may also surface snapshots.

## Important caveats

- This is not a substitute for the existing full WSL distro export / Windows profile dump. It is the high-frequency workflow safety net.
- The NAS dataset contains secrets and credentials. Treat NAS admin, SMB, and runtime SSH access accordingly.
- Local corruption that exists for more than 2 weeks ages out of daily rollback; weekly/monthly rollback coverage is bounded by the configured TrueNAS lifetimes.
- Hourly snapshots mean the protected historical restore point can be up to one hour behind current local state. The current mirror usually trails by ≤1 hour but is not delete-proof by itself.
- A growth-guard failure means the dataset needs manual review before more payload writes; do not disable the guard just to silence the alert.
- `config/backup.env` is intentionally ignored going forward; older public history may still mention local LAN topology and should only be rewritten with explicit history-rewrite approval.
