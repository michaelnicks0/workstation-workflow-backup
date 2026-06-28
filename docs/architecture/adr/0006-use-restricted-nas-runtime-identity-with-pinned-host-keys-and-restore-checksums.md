---
id: ADR-0006
title: Use a restricted NAS runtime identity with pinned host keys and restore checksums
status: accepted
date: 2026-06-28
supersedes: []
superseded_by: []
---

# ADR-0006: Use a restricted NAS runtime identity with pinned host keys and restore checksums

## Context

The first working implementation used the same root SSH identity for hourly automation, provisioning, ZFS growth checks, status publication, and restore inspection. It also used `StrictHostKeyChecking=accept-new`, stored local NAS topology in the tracked config file, and verified backup health primarily by checking required paths and snapshots.

That was operationally simple, but it made the hourly path too powerful: compromise of the workstation runtime key could become root access to the NAS. It also left host-key trust as TOFU, made the public repo overly local, and did not preserve checksum evidence for restore-critical artifacts.

## Decision

Use two NAS access paths:

1. **Runtime path** — hourly automation uses a dedicated NAS user/key, pinned host key, and forced-command dispatcher.
2. **Admin path** — explicit provisioning/restore uses the configured admin SSH identity.

The runtime key is restricted to:

- `rsync --server` receiver mode under `$NAS_PATH/current` only;
- `mkdir -p` under `$NAS_PATH/current` only;
- NAS-side growth guard helper through passwordless sudo;
- NAS-side integrity manifest helper through passwordless sudo.

Additional hardening:

- `StrictHostKeyChecking=yes` with `UserKnownHostsFile` and `HostKeyAlias` is used for all repo SSH helpers.
- `config/backup.env` is ignored; `config/backup.env.example` is the public template.
- TrueNAS `refquota` caps the live current-tree referenced size so SMB/robocopy growth can be interrupted mid-run.
- Successful non-dry-run backups write `_manifests/integrity-manifest.json` with SHA-256 checksums for critical restore artifacts.
- Local workflow logs are pruned by `LOCAL_LOG_RETENTION_DAYS`.
- Final completed-run ledger writes are strict; start/skipped-lock writes remain non-disruptive.

## Decision drivers

- Reduce blast radius of a compromised workstation runtime key.
- Keep root/admin authority out of the hourly timer path.
- Remove TOFU from normal SSH operations after initial key pinning.
- Keep public repo configuration template-safe without breaking local operation.
- Add restore-time byte-integrity evidence for critical artifacts without hashing the full tree every hour.
- Preserve existing failure-only alerting and non-destructive growth-guard semantics.

## Considered options

| Option | Outcome | Rationale |
|---|---|---|
| Keep root SSH for everything | Rejected | Operationally simple but too much privilege for hourly automation. |
| Use one forced-command key for all behavior, including restore | Rejected | Restore needs broad read/admin workflows; mixing restore with runtime would weaken restrictions. |
| Dedicated runtime user with forced-command dispatcher | Accepted | Gives the timer the minimum command surface needed for rsync writes, guard checks, and integrity manifests. |
| Hash the entire backup tree every hour | Rejected for default | Better byte coverage, but too expensive for the high-frequency path. Full-tree hashing remains available by changing `NAS_INTEGRITY_SCOPE=full` for deliberate verification windows. |

## Consequences

Positive:

- Runtime key compromise no longer grants NAS root shell.
- Runtime key cannot run arbitrary shell commands or pull data with rsync sender mode.
- Host-key verification is pinned and consistent across runtime/provisioning/verification helpers.
- Public repo no longer tracks local `backup.env` values going forward.
- Restore-critical artifacts carry SHA-256 evidence in snapshots.
- SMB/robocopy runaway writes hit ZFS `refquota` instead of relying only on post-run detection.

Tradeoffs:

- Initial setup now has an extra runtime-hardening install step.
- Existing Git history may still contain old LAN topology; rewriting public history is a separate explicit decision.
- Runtime writes no longer preserve remote owner/group metadata by default. Restore is content/snapshot/checksum oriented.
- Default integrity scope is critical, not full-tree, to keep hourly runs practical.

## Verification / validation

Expected verification gates:

- `./scripts/run-tests.sh` passes static/script/parser tests.
- `./scripts/install-nas-runtime-hardening.sh` installs/updates runtime user, forced-command dispatcher, helpers, sudo allowlist, and `refquota`.
- Runtime SSH smoke rejects arbitrary commands and allows the growth guard plus restricted rsync writes under `_manifests`.
- `./scripts/check-nas-growth-guard.sh --stage verify` reports `status=ok` with pinned host-key runtime SSH.
- A live `./scripts/workflow-backup.sh --verbose` writes status, ledger, Windows manifest cache, and integrity manifest through the restricted runtime path.
- `./scripts/verify-backup.sh` reports required paths and integrity manifest summary.

## References

- [`../../../scripts/nas-ssh.sh`](../../../scripts/nas-ssh.sh)
- [`../../../scripts/install-nas-runtime-hardening.sh`](../../../scripts/install-nas-runtime-hardening.sh)
- [`../../../scripts/nas-runtime-ssh-dispatch.py`](../../../scripts/nas-runtime-ssh-dispatch.py)
- [`../../../scripts/nas-growth-guard-helper.py`](../../../scripts/nas-growth-guard-helper.py)
- [`../../../scripts/nas-integrity-manifest-helper.py`](../../../scripts/nas-integrity-manifest-helper.py)
- [`../../../config/backup.env.example`](../../../config/backup.env.example)
