---
id: ADR-0004
status: accepted
date: 2026-06-28
decider: Michael
scope: repo
supersedes: []
superseded_by: []
related: [ADR-0001, ADR-0005]
verification:
  - ./scripts/run-tests.sh
  - ./scripts/check-nas-growth-guard.sh --stage verify
  - ./scripts/verify-backup.sh
---

# ADR-0004: Fail closed with a non-destructive NAS growth guard

## Context

The backup target can grow from both current mirror churn and snapshot-held historical blocks. Silent growth can consume NAS capacity or mask a repeated sync loop. The safety response must stop writes and alert Michael, not destroy snapshots or payloads automatically.

## Decision

Run `scripts/check-nas-growth-guard.sh` before and after backup writes. The guard delegates to a NAS-side read-only helper over the restricted runtime SSH identity. The helper reads ZFS budget signals and exits nonzero when configured limits are violated:

| Guard | Default limit |
|---|---:|
| Backup dataset used | 2 TiB |
| Snapshot-held blocks | 1 TiB |
| Minimum free space on configured availability dataset | 2 TiB |
| Snapshot count | 5000 |

The guard is read-only and non-destructive. ADR-0006 adds a ZFS `refquota` hard cap to interrupt direct SMB/robocopy growth in addition to these pre/post checks. Backup failure triggers the existing systemd OnFailure notifier. Operators must investigate and explicitly approve any destructive cleanup.

## Decision drivers

- Detect runaway backup growth before the next write phase makes it worse.
- Keep destructive authority out of the hourly success path.
- Use ZFS source-of-truth counters rather than log heuristics alone.
- Integrate with existing failure-only alerting.

## Options considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| Read-only fail-closed guard pre/post writes | Prevents silent runaway; no automatic deletion | Requires manual investigation to resume | Chosen |
| Warn-only growth report | Lower risk of false stop | Allows runaway writes to continue | Rejected |
| Automatic snapshot/payload deletion | Frees space quickly | Destructive and can erase needed restore points | Rejected |
| No guard | Simple | Capacity failures and churn loops can accumulate silently | Rejected |

## Consequences

- Positive: abnormal growth becomes a visible backup failure.
- Positive: cleanup remains an explicit operator decision.
- Negative: a false-positive budget can pause backups until reviewed.
- Operational: do not disable the guard just to silence alerts; adjust budgets only after evidence shows normal growth.

## Verification / validation

- Static tests assert guard config values, workflow pre/post wiring, verify-script guard call, remote helper use, `usedbysnapshots`, and snapshot-count checks.
- `./scripts/check-nas-growth-guard.sh --stage verify` performs the live read-only guard check.
- `./scripts/verify-backup.sh` includes the guard result before reporting dataset/snapshot/manifests.

## Revisit triggers

- Normal workload size grows beyond budget with understood cause.
- ZFS property semantics change on TrueNAS.
- Repeated guard failures point to a recurring source churn issue that should be fixed upstream.

## References

- `config/backup.env.example` plus ignored local `config/backup.env`
- `scripts/nas-growth-guard-helper.py`
- `scripts/check-nas-growth-guard.sh`
- `scripts/workflow-backup.sh`
- `scripts/verify-backup.sh`
- `docs/notes/2026-06-27-smb-name-mangling-snapshot-reset.md`
