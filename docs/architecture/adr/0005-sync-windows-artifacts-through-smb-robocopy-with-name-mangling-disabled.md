---
id: ADR-0005
status: accepted
date: 2026-06-28
decider: Michael
scope: repo
supersedes: []
superseded_by: []
related: [ADR-0002, ADR-0004]
verification:
  - ./scripts/run-tests.sh
  - scripts/nas-provision.sh
  - scripts/sync-windows-critical.ps1 parser check through scripts/run-tests.sh
---

# ADR-0005: Sync Windows artifacts through SMB robocopy with name mangling disabled

## Context

The backup includes selected Windows workflow artifacts. Copying large Windows profile trees through WSL DrvFS is slow and unnecessary when Windows-native `robocopy.exe` can mirror NTFS paths directly to a NAS SMB share. A previous failure mode showed repeated apparent `Documents` churn caused by Samba 8.3/name-mangled alias exposure through the SMB view, which made robocopy see copy/delete loops despite matching source and destination content.

## Decision

Launch `scripts/sync-windows-critical.ps1` from WSL and use `robocopy.exe` to mirror selected Windows profile directories/files to `\\10.99.98.221\ws1-wf\current\windows`. Configure the TrueNAS SMB share `ws1-wf` with:

```text
mangled names = no
```

Persist that setting in `scripts/nas-provision.sh`. Treat the Windows sync manifest as the authoritative summary for the Windows phase and ingest it into the run ledger.

## Decision drivers

- Preserve selected Windows workflow artifacts without creating a full profile image.
- Use Windows-native filesystem semantics and robocopy behavior for Windows-owned paths.
- Avoid DrvFS throughput/metadata penalties for large Windows trees.
- Prevent Samba 8.3/name-mangling alias loops from causing recurring churn and guard failures.

## Options considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| PowerShell robocopy to TrueNAS SMB with name mangling disabled | Native Windows copy semantics; durable manifest; avoids known alias loop | Requires WSL-to-Windows interop and reachable SMB share | Chosen |
| WSL rsync from `/mnt/c/Users/...` | Single sync mechanism | Slow DrvFS path; poorer Windows metadata semantics | Rejected |
| Full Windows profile image/export | Broad coverage | Too large/noisy for hourly workflow backup | Rejected |
| Ignore Windows artifacts | Smaller scope | Misses workflow-critical Desktop/Documents/Downloads/config artifacts | Rejected |

## Consequences

- Positive: Windows profile artifacts are mirrored through the interface Windows uses natively.
- Positive: `mangled names = no` is a durable guard against the previously observed robocopy churn loop.
- Negative: Windows phase depends on WSL interop and SMB reachability.
- Operational: if large Windows churn reappears, inspect robocopy dry-run summaries and Samba name behavior before raising growth budgets.

## Verification / validation

- Static tests assert the SMB `auxsmbconf` setting and Windows VCS-directory exclusions.
- `scripts/run-tests.sh` parser-checks the PowerShell helper when Windows interop is available.
- `scripts/nas-provision.sh` applies the SMB setting through TrueNAS middleware.
- `scripts/verify-backup.sh` checks the Windows sync manifest path on the NAS.

## Revisit triggers

- The NAS SMB share no longer exposes stable Windows path semantics.
- WSL interop becomes unavailable for the systemd user timer.
- Windows backup scope expands from selected workflow artifacts to full profile/bare-metal recovery.

## References

- `scripts/sync-windows-critical.ps1`
- `scripts/windows-interop.sh`
- `scripts/nas-provision.sh`
- `tests/test_static.py`
- `docs/notes/2026-06-27-smb-name-mangling-snapshot-reset.md`
