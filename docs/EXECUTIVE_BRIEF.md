# Executive Brief — WORKSTATION1 Workflow Backup

| Field | Value |
|---|---|
| System | `workstation-workflow-backup` |
| Owner | Michael |
| Status | Active / Production |
| Recovery Point Objective | ≤ 1 hour (last 2 days); up to 1 year bounded rollback |
| Last updated | 2026-06-28 |

## What it is

An automated, ZFS-backed high-frequency backup for WORKSTATION1 WSL and
Windows workflow state — repos, Hermes AI session data, SSH keys, browser
profiles, dev tool configs, and critical Windows desktop artifacts — to a
configured TrueNAS dataset.

This is the **workflow safety net**, not a bare-metal image. It protects
against accidental deletion, local corruption, or disk failure with a
recovery point of at most one hour for any artifact within the last 48
hours, and progressively sparser rollback coverage out to one year.

## Why it matters

Hermes agent state, code repos, local AI configs, lifelog databases, and
browser session data are high-entropy artifacts that cannot be easily
reconstructed. Loss of `~/.hermes/` or `~/repos/` during a WSL disk event
or accidental delete would cost hours to days of irreversible work. A
silent, fail-closed, hourly backup with a ZFS snapshot ladder eliminates
that risk for less than five minutes of daily I/O overhead.

## How it works (one sentence)

Every hour at :45, a WSL `systemd` user timer rsyncs selected local paths
to a restricted NAS identity over pinned-host-key SSH, takes consistent
SQLite snapshots, mirrors Windows artifacts over SMB via robocopy, checks
dataset growth budgets before and after writes, writes a run ledger and
integrity manifest to the NAS, and sends a Telegram alert only if the run
fails.

## Risk posture

| Risk | Mitigation | Status |
|---|---|---|
| Silent runaway dataset growth | Fail-closed growth guard (non-destructive) + ZFS `refquota` hard cap | Active |
| Accidental delete replicated to NAS | ZFS snapshot ladder; hourly, daily, weekly, monthly retention | Active |
| NAS root access during hourly path | Dedicated restricted runtime user `ws1backup`; forced-command SSH dispatch | Active |
| Wrong host connect / MITM | Pinned host key, `StrictHostKeyChecking=yes`, `HostKeyAlias` | Active |
| Restore artifact corruption | Per-run SHA-256 integrity manifest for critical restore artifacts | Active |
| Live SQLite file inconsistency | SQLite backup API snapshots before mirror phase | Active |
| Secrets committed to this repo | Gitignore enforces exclusion; static tests assert the exclusion patterns | Active |
| Silent backup failure | `OnFailure` Telegram notifier on every nonzero systemd service exit | Active |

## Retention schedule

| Layer | Retention |
|---|---|
| Hourly ZFS snapshots (`wf-h-*`) | 2 days |
| Daily ZFS snapshots (`wf-d-*`) | 2 weeks |
| Weekly ZFS snapshots (`wf-w-*`) | 8 weeks |
| Monthly ZFS snapshots (`wf-m-*`) | 1 year |

Snapshots are managed exclusively by TrueNAS periodic snapshot tasks. No
repo-owned `zfs destroy` helper is used; the failure path stops writes, it
does not delete history.

## Maturity

| Dimension | State |
|---|---|
| Tests | 14 static contract tests; all passing |
| Architecture | C4 model, 10 views, 6 ADRs |
| Security decisions | ADR-0006: restricted runtime identity, pinned keys, restore checksums |
| Growth guard | Fail-closed; budgets: 2 TiB used / 1 TiB snapshots / 2 TiB free / 5 000 snapshots |
| Restore path | Documented runbook with staged restore, integrity-manifest checksum verification |

## Key personnel

Michael is the sole operator. All automated functions (backup, guard checks,
Telegram alerts) execute without human interaction. Michael controls
provisioning, restore operations, stop authority, and retention policy
changes.

## Reading path

| Audience | Start here |
|---|---|
| Understand the system architecture | [Architecture README](architecture/README.md) · [C4 Diagrams](architecture/c4-diagrams.md) |
| Operate / restore | [README](../README.md) · [Restore Runbook](restore-runbook.md) |
| Decision history | [ADR Index](architecture/adr/README.md) |
| Test coverage | [Test Inventory](TESTS.md) |
| User on-ramp | [User Guide](USER_GUIDE.md) |
