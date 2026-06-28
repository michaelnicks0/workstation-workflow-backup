# Test Inventory

<!-- BEGIN GENERATED:inventory-summary -->
> **Current inventory:** 14 test functions across 1 files (1 test classes)
<!-- END GENERATED:inventory-summary -->

## Coverage philosophy

These are **static contract tests** — they assert that critical config
values, script wiring, systemd unit references, and architectural
invariants are present in source files. They do not run a live backup.

| Area | Tests |
|---|---|
| Systemd timer / failure notifier | `test_timer_runs_hourly`, `test_service_has_failure_notifier` |
| Payload exclusion (gitignore safety) | `test_no_payload_patterns_allowed` |
| Runtime SSH hardening (pinned host key, restricted dispatch) | `test_runtime_ssh_uses_pinned_host_key_and_restricted_dispatch`, `test_config_template_has_runtime_hardening_shape` |
| TrueNAS snapshot task wiring | `test_snapshot_policy_is_managed_by_truenas_tasks` |
| NAS growth guard | `test_growth_guard_is_configured_and_wired` |
| SMB name mangling disabled | `test_smb_share_disables_name_mangling` |
| Windows sync VCS exclusion | `test_windows_sync_excludes_vcs_metadata` |
| Restore docs reference ZFS snapshots | `test_restore_docs_reference_zfs_snapshots` |
| Run ledger (record, export, snapshot) | `test_workflow_records_and_syncs_run_ledger`, `test_run_ledger_records_latest_run_and_exports` |
| Integrity manifest + log retention | `test_integrity_manifest_and_log_retention_are_wired` |
| Windows interop fallback | `test_workflow_uses_windows_interop_fallback` |

<!-- BEGIN GENERATED:per-file-counts -->
| Test file | Test functions |
|---|---:|
| `tests/test_static.py` | 14 |
| **Total** | **14** |
<!-- END GENERATED:per-file-counts -->

<!-- BEGIN GENERATED:test-case-inventory -->
| File | Class | Test function | Line | Coverage note |
|---|---|---|---:|---|
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_timer_runs_hourly` | 15 | Timer runs hourly. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_service_has_failure_notifier` | 20 | Service has failure notifier. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_no_payload_patterns_allowed` | 25 | No payload patterns allowed. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_config_template_has_runtime_hardening_shape` | 30 | Config template has runtime hardening shape. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_snapshot_policy_is_managed_by_truenas_tasks` | 42 | Snapshot policy is managed by truenas tasks. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_growth_guard_is_configured_and_wired` | 65 | Growth guard is configured and wired. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_runtime_ssh_uses_pinned_host_key_and_restricted_dispatch` | 83 | Runtime ssh uses pinned host key and restricted dispatch. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_smb_share_disables_name_mangling` | 97 | Smb share disables name mangling. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_windows_sync_excludes_vcs_metadata` | 102 | Windows sync excludes vcs metadata. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_restore_docs_reference_zfs_snapshots` | 108 | Restore docs reference zfs snapshots. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_workflow_records_and_syncs_run_ledger` | 114 | Workflow records and syncs run ledger. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_integrity_manifest_and_log_retention_are_wired` | 125 | Integrity manifest and log retention are wired. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_workflow_uses_windows_interop_fallback` | 138 | Workflow uses windows interop fallback. |
| `tests/test_static.py` | `StaticBackupRepoTests` | `test_run_ledger_records_latest_run_and_exports` | 149 | Run ledger records latest run and exports. |
<!-- END GENERATED:test-case-inventory -->

<!-- BEGIN GENERATED:audit-run -->
Latest inventory: **14 test functions** across **1 files** and **1 test classes** (AST of `test_*` / `*_test.py`). Regenerate with `python scripts/generate_test_inventory.py --write`; enforce with `--check`. Counts are static test functions, not parametrized-case expansions.
<!-- END GENERATED:audit-run -->

## Run the suite

```bash
./scripts/run-tests.sh
# or directly:
python3 -m unittest discover -s tests -v
```

Check inventory drift:

```bash
python3 scripts/generate_test_inventory.py --check
```
