# WORKSTATION1 Backup SMB Name-Mangling Fix — Saved Session Context

> Purpose: Preserve the operator context for the June 27, 2026 workflow-backup failure, SMB fix, snapshot purge, and fresh baseline.

| Field | Value |
|---|---|
| Date | 2026-06-27 |
| Destination | `/home/mnicks/repos/workstation/workstation-workflow-backup` |
| Status | saved context; operational fix completed before this capture |
| Sensitivity | public-safe summary; no credentials, payload contents, or live topology required |

---

## Executive Snapshot

- The `17.7 GiB/hour` apparent `Documents` churn was an SMB/Robocopy name-mangling loop, not real source-file churn.
- The configured NAS SMB share now has `mangled names = no`, and a non-mutating Robocopy dry-run reports `0 copied / 0 extras`.
- All stale snapshots under the configured backup dataset were explicitly approved as cruft and purged; a successful backup run and fresh baseline snapshot were created.

---

## Punchlist

1. ✅ Diagnosed guard failures as `usedbysnapshots` exceeding the 512 GiB fail-closed budget.
2. ✅ Isolated `Documents` Robocopy churn to Samba 8.3/name-mangling alias exposure.
3. ✅ Disabled SMB name mangling on the configured SMB share and made the setting durable in `scripts/nas-provision.sh`.
4. ✅ Purged approved stale snapshots under the configured backup dataset only.
5. ✅ Ran a live workflow backup, created a fresh baseline snapshot, and verified the guard is green.
6. ▶️ Let the next scheduled timer run normally and verify it remains green.

We are here: item 6.

Next: after the next `*:45` timer run, check `./scripts/verify-backup.sh` and confirm the run ledger stays `ok` without new large `Documents` copies.

---

## Context Captured

Michael reported that workstation backups were failing by hitting guards. Investigation showed:

- Backup guard failure was policy-based, not pool exhaustion.
- The backup dataset had about `515.59 GiB` snapshot-held data against a `512 GiB` snapshot budget.
- Recent Robocopy summaries for the Windows `Documents` leg repeatedly showed `520 copied`, `520 extras`, and about `17.734 GiB` on both sides.
- A direct WSL/NAS file comparison showed the source and mirror were already identical: `528` files, equal total bytes, no source-only/destination-only files, and no size mismatches.
- A non-mutating Windows `robocopy /L` still reported the 520-file copy/delete loop, proving the mismatch existed through the Windows SMB view.
- The differing path component was an 8.3/mangled alias: the source component was longer, while the SMB-visible component was 8 characters and contained `~`.
- TrueNAS/Samba effective config originally exposed name mangling behavior; setting `mangled names = no` for the configured SMB share removed the loop.

No backed-up file names, payload contents, credentials, or secret material were written to this note.

---

## Durable Notes

### Root cause

| Layer | Finding | Evidence |
|---|---|---|
| Robocopy summaries | Repeated `Documents` copy/delete loop | `520 copied`, `520 extras`, `17.734 GiB` copied/extras every run |
| Source vs mirror scan | Mirror already matched source | `528` files on both sides; no size mismatch |
| Windows SMB view | Same tree appeared through a short alias | `robocopy /L` still saw new files and extras |
| Samba behavior | 8.3/name-mangled path component exposed over SMB | short component contained `~` |
| Fix | Disable name mangling for backup share | `mangled names = no` under the configured share |

### Live SMB change

The live TrueNAS SMB share was updated via middleware for the configured backup share:

```text
auxsmbconf: mangled names = no
```

SMB reload succeeded:

```text
midclt call service.reload cifs -> True
```

Effective Samba config after reload:

```text
[configured-backup-share]
    mangled names = no
    path = $NAS_PATH
```

### Durable repo change

Commit created before this save:

```text
f851469 backup: disable SMB name mangling for workflow share
```

Changed files:

- `scripts/nas-provision.sh` — adds `auxsmbconf = mangled names = no` to the SMB share payload.
- `tests/test_static.py` — adds a static regression check for the setting.

Ad-hoc targeted verification also checked the live Samba config and non-mutating Robocopy dry-run.

### Churn fix verification

Non-mutating Windows Robocopy dry-run after the SMB change:

```text
Files : 528 total, 0 copied, 528 skipped, 0 extras
Bytes : 19052453576 total, 0 copied, 19052453576 skipped, 0 extras
ROBOCOPY_EXIT_CODE=0
```

That confirms the `17.7 GiB/hour` loop was fixed for future runs.

### Snapshot reset

Michael explicitly approved purging the workflow-backup snapshots as accumulated cruft and starting fresh.

Destructive scope executed:

```text
$NAS_DATASET@%
```

Only snapshots under the configured backup dataset were destroyed; the mutable `current/...` mirror was not deleted.

Before purge:

```text
$NAS_DATASET used:       635G
used by snapshots:    516G
snapshot count:        38
pool allocation:      5.32T
```

After purge:

```text
$NAS_DATASET used:       120G
used by snapshots:     0B
snapshot count:         0
pool allocation:      4.82T
```

Fresh baseline created after a successful backup run:

```text
$NAS_DATASET@post-snapshot-reset-20260628-012002
USED 0B
REFER 120G
```

### Backup health after reset

Manual workflow backup run after purge:

```text
Result=success
ExecMainStatus=0
duration_seconds=54
status=ok
```

Growth guard verification:

```text
growth_guard stage=verify status=ok
used=119.95 GiB
snapshot_used=0.00 B
max_snapshot_used=512.00 GiB
snapshots=1
```

`./scripts/verify-backup.sh` passed after the reset and showed required NAS paths and manifests present.

---

## Source / Provenance Notes

| Source class | What was used | Notes |
|---|---|---|
| Current Hermes session | Visible context, tool outputs, and task state | Summarized; no raw transcript dump. |
| Local repo instructions | `AGENTS.md` | Confirmed no payloads in Git, explicit approval required for snapshot destruction, and `verify-backup.sh` as health check. |
| Local repo files | `scripts/nas-provision.sh`, `tests/test_static.py`, `README.md` | Used for durable fix and documentation context. |
| Live NAS ZFS | `zfs list`, `zfs destroy -nv`, `zfs destroy`, `zpool list`, `zpool status` | Read-only preflight before destruction; destruction only after Michael's explicit approval. |
| Live TrueNAS/Samba | `midclt`, `testparm` | Verified `mangled names = no` is effective for the configured share. |
| Windows Robocopy | non-mutating `robocopy.exe /L` | Verified `0 copied / 0 extras`; no filenames retained. |
| Local systemd | `systemctl --user` | Verified service result success and timer remains active. |

---

## Open Questions / Next Actions

- [ ] After the next scheduled timer run, rerun `./scripts/verify-backup.sh` and confirm the ledger records another `ok` run.
- [ ] If snapshot usage grows normally, leave the 512 GiB snapshot guard unchanged.
- [ ] If future large churn appears, inspect Robocopy phase summaries before raising guard limits.
