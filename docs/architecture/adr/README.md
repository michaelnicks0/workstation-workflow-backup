# Architecture Decision Records

> Purpose: durable decision log for the WORKSTATION1 workflow backup architecture.

| Field | Value |
|---|---|
| Owner | Michael |
| Status | Active |
| Last updated | 2026-06-28 |

## ADR index

| ADR | Status | Decision |
|---|---|---|
| [ADR-0001](0001-use-truenas-zfs-snapshots-for-rollback-history.md) | accepted | Use TrueNAS-managed ZFS snapshots for rollback history while keeping the current mirror simple. |
| [ADR-0002](0002-run-hourly-with-systemd-user-and-failure-only-alerts.md) | accepted | Run the backup from a WSL systemd user timer and send Telegram only on failure. |
| [ADR-0003](0003-create-application-consistent-sqlite-snapshots.md) | accepted | Snapshot live workflow SQLite databases with the SQLite backup API before mirroring. |
| [ADR-0004](0004-fail-closed-with-non-destructive-nas-growth-guard.md) | accepted | Enforce read-only growth budgets before and after writes; never delete data automatically. |
| [ADR-0005](0005-sync-windows-artifacts-through-smb-robocopy-with-name-mangling-disabled.md) | accepted | Sync Windows workflow artifacts through robocopy over the TrueNAS SMB share with Samba name mangling disabled. |
| [ADR-0006](0006-use-restricted-nas-runtime-identity-with-pinned-host-keys-and-restore-checksums.md) | accepted | Use a restricted NAS runtime user/key, pinned host-key verification, ZFS refquota, and restore-critical checksum manifests. |

## Workflow

- Add a new ADR for future changes that alter backup boundaries, retention, alerting, restore semantics, NAS control-plane behavior, or destructive-safety rules.
- Supersede accepted ADRs with a new ADR instead of rewriting history.
- Keep verification evidence real: commands, tests, scripts, or live verification paths.
