# User Guide — WORKSTATION1 Workflow Backup

> **Audience:** the operator using or restoring the workflow backup system.
> **Altitude:** task-first. Start here when you want to configure, verify, respond to a failure alert, or restore.
> **Companion docs:** risk posture in [`EXECUTIVE_BRIEF.md`](EXECUTIVE_BRIEF.md) · exact restore procedures in [`restore-runbook.md`](restore-runbook.md) · design rationale in [`architecture/README.md`](architecture/README.md).

---

## Mental model in one sentence

Every hour, this system **silently rsyncs your workflow state to TrueNAS,
lands it on a ZFS-snapshotted dataset, and shouts only if something breaks.**

```
WORKSTATION1 (:45 each hour)
  │
  ├─ pre-flight: growth guard (fail-closed)
  ├─ SQLite snapshots (consistent copies of live DBs)
  ├─ WSL rsync → NAS current/wsl/...
  ├─ Windows robocopy → NAS current/windows/...
  ├─ post-flight: growth guard (fail-closed)
  ├─ run ledger + integrity manifest → NAS current/_manifests/
  └─ silent on success / Telegram on failure
        │
        └─ TrueNAS ZFS snapshot ladder
             wf-h-*  2 days      ←── ≤1h RPO window
             wf-d-*  2 weeks
             wf-w-*  8 weeks
             wf-m-*  1 year
```

Once installed and configured, you never interact with this system unless something breaks or you need to restore.

---

## First-run journey

### 1. Configure

```bash
cd ~/repos/workstation/workstation-workflow-backup
cp config/backup.env.example config/backup.env
$EDITOR config/backup.env          # fill in NAS_HOST, NAS_USER, paths, keys
```

Key values to set:

| Variable | What it controls |
|---|---|
| `NAS_HOST` | TrueNAS hostname or IP |
| `NAS_USER` / `NAS_RUNTIME_USER` | Dedicated restricted backup user (default: `ws1backup`) |
| `NAS_ADMIN_USER` | Admin SSH user for restore/provisioning only |
| `NAS_SSH_KEY` | Path to dedicated runtime SSH private key |
| `NAS_KNOWN_HOSTS` | Path to pinned-host-key file |
| `NAS_HOST_KEY_ALIAS` | Logical alias for the pinned host key |
| `NAS_DATASET` | TrueNAS ZFS dataset path (e.g. `pool/workstation/workflow`) |
| `NAS_PATH` | Mountpoint of the dataset (e.g. `/mnt/pool/workstation/workflow`) |
| `NAS_UNC` | SMB share UNC path for Windows robocopy phase |

### 2. Generate a runtime SSH key (if needed)

```bash
source config/backup.env
ssh-keygen -t ed25519 -N '' -C 'workstation-workflow-backup runtime' -f "$NAS_SSH_KEY"
ssh-keyscan -t ed25519 "$NAS_HOST" | sed "s/^$NAS_HOST /$NAS_HOST_KEY_ALIAS /" > "$NAS_KNOWN_HOSTS"
chmod 600 "$NAS_SSH_KEY" "$NAS_KNOWN_HOSTS"
```

### 3. Verify and provision

```bash
./scripts/run-tests.sh
./scripts/nas-provision.sh         # create dataset/share/snapshot tasks on TrueNAS
./scripts/install-nas-runtime-hardening.sh   # install restricted user/key/forced-command on NAS
./scripts/install-systemd-user.sh  # install and enable the systemd user timer
```

### 4. Smoke-test (optional manual run)

```bash
./scripts/workflow-backup.sh --verbose   # runs a full backup cycle, verbose output
./scripts/verify-backup.sh               # health check against live NAS state
```

### 5. Confirm the timer is running

```bash
systemctl --user list-timers workstation-workflow-backup.timer
```

You should see the timer scheduled for the next `:45` mark. Successful runs are silent.

---

## I want to… → start here

| Goal | Command / doc |
|---|---|
| **Check if the backup ran recently** | `python3 scripts/record-run-ledger.py status --db ~/.local/state/workstation-workflow-backup/runs.sqlite3 --limit 12` |
| **Check NAS dataset growth budget** | `./scripts/check-nas-growth-guard.sh --stage manual` |
| **Restore a missing repo file** | [Restore Runbook](restore-runbook.md) → "Restore a missing repo file" |
| **Restore Hermes state.db** | [Restore Runbook](restore-runbook.md) → "Restore Hermes state.db from a consistent snapshot" |
| **Restore Windows artifacts** | [Restore Runbook](restore-runbook.md) → "Restore Windows artifacts" |
| **Pick a snapshot** | `ssh_nas_admin "zfs list -t snapshot -r '$NAS_DATASET' -o name,creation,used,refer \| tail -80"` |
| **Verify a staged restore file** | [Restore Runbook](restore-runbook.md) → "Verify a staged restore against the integrity manifest" |
| **Investigate a failure alert** | Check `~/.local/state/workstation-workflow-backup/logs/` for the latest log; also run `systemctl --user status workstation-workflow-backup.service` |
| **Temporarily pause the timer** | `systemctl --user stop workstation-workflow-backup.timer` (then start when ready) |
| **Re-provision NAS snapshot tasks** | `./scripts/nas-provision.sh` (idempotent) |
| **Read architecture docs** | [Architecture README](architecture/README.md) |
| **Read decision history** | [ADR Index](architecture/adr/README.md) |

---

## The one safety rule that matters

**Never run `./scripts/verify-backup.sh` or `./scripts/workflow-backup.sh` to "test" — instead use `./scripts/check-nas-growth-guard.sh --stage manual` for a read-only NAS budget check, and `python3 scripts/record-run-ledger.py status` for run history.**

Specifically:

- Do **not** manually `rsync --delete` to NAS paths; a wrong target can silently wipe backup history.
- Do **not** bump `zfs destroy` snapshots to "clean up" — let TrueNAS manage retention; manual destroys bypass the budgets.
- Do **not** disable the growth guard to silence an alert — a guard failure means the dataset needs review, not suppression.
- Do **not** commit or print `config/backup.env`, SSH private keys, TrueNAS encryption keys, or the contents of backed-up payload files.

---

## Local state layout

```text
~/.local/state/workstation-workflow-backup/
├── last-run.json               # compatibility latest-run status
├── runs.sqlite3                # append-only run event ledger
├── nas-export/run-history.json # exported recent run summaries before NAS sync
└── logs/workflow-backup-*.log  # one log per run, pruned after 90 days
```

---

## Failure alert behavior

Successful runs are completely silent. A Telegram message via your Hermes
bot is sent **only** when the systemd service exits nonzero (via
`OnFailure=workstation-workflow-backup-failure-notify@%n.service`).

When you receive a failure alert:

1. Read the log: `ls -lt ~/.local/state/workstation-workflow-backup/logs/ | head -3` then `cat` the newest file.
2. Check the run ledger: `python3 scripts/record-run-ledger.py status --db ~/.local/state/workstation-workflow-backup/runs.sqlite3 --limit 5`.
3. If the growth guard fired, run `./scripts/check-nas-growth-guard.sh --stage manual` to inspect each budget dimension.
4. Fix the root cause (disk space, NAS connectivity, growth budget) before re-enabling the timer.

---

## What this backup does NOT cover

- Full WSL distro export or bare-metal recovery: see `~/repos/workstation/freenas-windows-backup`.
- Windows full-profile or OS images.
- TrueNAS encryption-key custody and cold reboot/import/unlock drills.
- Artifacts that have aged out of the retention window (> 1 year for monthly snapshots).

---

## Further reading

- [README](../README.md) — full configuration reference, snapshot schedule table, restore quick reference
- [Restore Runbook](restore-runbook.md) — step-by-step restore procedures
- [Architecture README](architecture/README.md) — C4 views and ADR overview
- [ADR Index](architecture/adr/README.md) — six design decisions with rationale
- [C4 Diagrams](architecture/c4-diagrams.md) — generated diagram atlas
- [Test Inventory](TESTS.md) — 14 static contract tests and coverage map
- [Executive Brief](EXECUTIVE_BRIEF.md) — risk posture and maturity summary
