---
id: ADR-0001
status: accepted
date: 2026-06-28
decider: Michael
scope: repo
supersedes: []
superseded_by: []
related: [ADR-0004]
verification:
  - ./scripts/run-tests.sh
  - ./scripts/verify-backup.sh
  - Structurizr validate/export for docs/architecture/workspace.dsl
---

# ADR-0001: Use TrueNAS ZFS snapshots for rollback history

## Context

The workflow backup must keep Michael's WSL/Hermes/workflow state recoverable with a practical last-day RPO of ≤1 hour plus bounded daily, weekly, and monthly rollback points. The mutable mirror under `v1/ws1/wf/current` protects against workstation loss but does not protect against accidental local deletes or corruption that are mirrored into `current`.

The repo previously had legacy retained-snapshot cron-helper behavior. The current operating model in `README.md`, `AGENTS.md`, `config/backup.env`, and `scripts/nas-provision.sh` places retention under TrueNAS periodic snapshot tasks.

## Decision

Use TrueNAS-managed recursive periodic ZFS snapshot tasks on `v1/ws1/wf` for rollback history:

| Class | Naming schema | Schedule | Lifetime |
|---|---|---:|---|
| Hourly | `wf-h-%Y%m%d-%H%M` | hourly at minute `0` | `2 DAYS` |
| Daily | `wf-d-%Y%m%d-%H%M` | `00:10` daily | `2 WEEKS` |
| Weekly | `wf-w-%Y%m%d-%H%M` | Sunday `00:20` | `8 WEEKS` |
| Monthly | `wf-m-%Y%m%d-%H%M` | day `1` `00:30` | `1 YEAR` |

The local backup job writes only the latest `current/...` mirror and manifests. Retention is a NAS/ZFS concern. Repo-owned ZFS destroy helpers are retired, and manual snapshots stay outside automatic pruning.

## Decision drivers

- ≤1 hour practical restore point for recent local damage.
- Bounded long-tail rollback without making the hourly sync script destructive.
- TrueNAS middleware should own snapshot lifecycle and lifetimes.
- Restore source of truth should be an explicit `.zfs/snapshot/<snapshot>/current/...` path.

## Options considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| TrueNAS periodic ZFS snapshots | Native retention, cheap snapshots, clear restore paths, no repo-owned deletion loop | Requires NAS task state to stay correct | Chosen |
| Keep history in dated mirror directories | Simple to browse | Expensive, slow, duplicate-heavy, delete semantics are harder | Rejected |
| Repo-owned cron scripts that create/destroy snapshots | Fully scriptable from repo | More destructive authority in custom scripts; drift from TrueNAS scheduler | Rejected |
| Current mirror only | Smallest automation | Mirrors deletes/corruption; no rollback | Rejected |

## Consequences

- Positive: rollback history is separated from the mutable current mirror.
- Positive: retention windows are visible through TrueNAS snapshot tasks and `verify-backup.sh`.
- Negative: live backup health depends on the NAS scheduler/control plane, not just local scripts.
- Operational: manual snapshots require explicit review/deletion and must not be destroyed without approval.

## Verification / validation

- Static repo verification: `./scripts/run-tests.sh` checks snapshot naming schemas, lifetimes, retired cron behavior, and restore-doc snapshot references.
- Live health verification: `./scripts/verify-backup.sh` checks dataset, recent snapshots, periodic snapshot tasks, and retired snapshot cron jobs.
- Architecture verification: Structurizr validation/export confirms the model includes the TrueNAS dataset/control-plane boundary and targeted restore flow.

## Revisit triggers

- RPO/RTO requirements change materially.
- TrueNAS periodic tasks fail repeatedly or are replaced by a different retention controller.
- Dataset growth exceeds bounded budgets under normal churn.
- Backup scope grows enough that a current mirror plus snapshots is no longer sufficient.

## References

- `README.md` — mission, snapshot schedule, restore quick reference.
- `config/backup.env` — snapshot lifetime values.
- `scripts/nas-provision.sh` — periodic snapshot task creation/update and retired cron handling.
- `scripts/verify-backup.sh` — live verification surface.
- `docs/restore-runbook.md` — restore procedure.
