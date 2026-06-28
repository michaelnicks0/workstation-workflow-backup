from __future__ import annotations

import json
import pathlib
import re
import sqlite3
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class StaticBackupRepoTests(unittest.TestCase):
    def test_timer_runs_hourly(self) -> None:
        timer = (ROOT / "systemd/workstation-workflow-backup.timer").read_text()
        self.assertIn("OnCalendar=*:45", timer)
        self.assertIn("Persistent=true", timer)

    def test_service_has_failure_notifier(self) -> None:
        service = (ROOT / "systemd/workstation-workflow-backup.service").read_text()
        self.assertIn("OnFailure=workstation-workflow-backup-failure-notify@%n.service", service)
        self.assertIn("ExecStart=/home/mnicks/repos/workstation/workstation-workflow-backup/scripts/workflow-backup.sh", service)

    def test_no_payload_patterns_allowed(self) -> None:
        gitignore = (ROOT / ".gitignore").read_text()
        for pattern in ("*.tar", "*.vhdx", "*.wim", "*.db-backup", "*.sqlite3", "*.db"):
            self.assertIn(pattern, gitignore)

    def test_config_template_has_runtime_hardening_shape(self) -> None:
        config = (ROOT / "config/backup.env.example").read_text()
        gitignore = (ROOT / ".gitignore").read_text()
        self.assertIn("config/backup.env", gitignore)
        self.assertIn("NAS_USER=ws1backup", config)
        self.assertIn("NAS_ADMIN_USER=root", config)
        self.assertIn("NAS_STRICT_HOST_KEY_CHECKING=yes", config)
        self.assertIn("NAS_KNOWN_HOSTS=", config)
        self.assertIn("NAS_HOST_KEY_ALIAS=", config)
        self.assertIn("NAS_DATASET=pool/workstation/workflow", config)
        self.assertIn("SMB_SHARE_NAME=workflow-backup", config)

    def test_snapshot_policy_is_managed_by_truenas_tasks(self) -> None:
        provision = (ROOT / "scripts/nas-provision.sh").read_text()
        config = (ROOT / "config/backup.env.example").read_text()
        self.assertIn("HOURLY_SCHEMA = 'wf-h-%Y%m%d-%H%M'", provision)
        self.assertIn("DAILY_SCHEMA = 'wf-d-%Y%m%d-%H%M'", provision)
        self.assertIn("WEEKLY_SCHEMA = 'wf-w-%Y%m%d-%H%M'", provision)
        self.assertIn("MONTHLY_SCHEMA = 'wf-m-%Y%m%d-%H%M'", provision)
        self.assertIn("'lifetime_value': HOURLY_LIFETIME_DAYS", provision)
        self.assertIn("'lifetime_value': DAILY_LIFETIME_WEEKS", provision)
        self.assertIn("'lifetime_value': WEEKLY_LIFETIME_WEEKS", provision)
        self.assertIn("'lifetime_value': MONTHLY_LIFETIME_YEARS", provision)
        self.assertIn("disable_retired_cron_jobs()", provision)
        self.assertIn(".retired", provision)
        self.assertNotIn("cronjob.create", provision)
        self.assertNotIn("create-retained-snapshot.py weekly", provision)
        self.assertNotIn("['zfs', 'destroy'", provision)
        self.assertIn("NAS_HOURLY_SNAPSHOT_LIFETIME_DAYS=2", config)
        self.assertIn("NAS_DAILY_SNAPSHOT_LIFETIME_WEEKS=2", config)
        self.assertIn("NAS_WEEKLY_SNAPSHOT_LIFETIME_WEEKS=8", config)
        self.assertIn("NAS_MONTHLY_SNAPSHOT_LIFETIME_YEARS=1", config)
        self.assertIn("refquota", provision)
        self.assertIn("NAS_DATASET_REFQUOTA_BYTES=2199023255552", config)

    def test_growth_guard_is_configured_and_wired(self) -> None:
        config = (ROOT / "config/backup.env.example").read_text()
        workflow = (ROOT / "scripts/workflow-backup.sh").read_text()
        verify = (ROOT / "scripts/verify-backup.sh").read_text()
        guard = (ROOT / "scripts/check-nas-growth-guard.sh").read_text()
        helper = (ROOT / "scripts/nas-growth-guard-helper.py").read_text()
        self.assertIn("NAS_GROWTH_GUARD_ENABLED=1", config)
        self.assertIn("NAS_DATASET_MAX_USED_BYTES=2199023255552", config)
        self.assertIn("NAS_DATASET_MAX_SNAPSHOT_BYTES=1099511627776", config)
        self.assertIn("NAS_DATASET_MIN_AVAILABLE_BYTES=2199023255552", config)
        self.assertIn("run_growth_guard pre", workflow)
        self.assertIn("run_growth_guard post", workflow)
        self.assertIn("check-nas-growth-guard.sh", verify)
        self.assertIn("NAS_GROWTH_GUARD_REMOTE_HELPER", guard)
        self.assertIn("usedbysnapshots", helper)
        self.assertIn("snapshot count", helper)
        self.assertIn("NAS_DATASET_MAX_SNAPSHOT_COUNT=5000", config)

    def test_runtime_ssh_uses_pinned_host_key_and_restricted_dispatch(self) -> None:
        config = (ROOT / "config/backup.env.example").read_text()
        nas_ssh = (ROOT / "scripts/nas-ssh.sh").read_text()
        installer = (ROOT / "scripts/install-nas-runtime-hardening.sh").read_text()
        dispatch = (ROOT / "scripts/nas-runtime-ssh-dispatch.py").read_text()
        combined_scripts = "\n".join(path.read_text() for path in (ROOT / "scripts").glob("*.sh"))
        self.assertIn("NAS_STRICT_HOST_KEY_CHECKING=yes", config)
        self.assertIn("UserKnownHostsFile=$NAS_KNOWN_HOSTS", nas_ssh)
        self.assertIn("HostKeyAlias=$NAS_HOST_KEY_ALIAS", nas_ssh)
        self.assertNotIn("StrictHostKeyChecking=accept-new", combined_scripts)
        self.assertIn("restrict,command=", installer)
        self.assertIn("--sender", dispatch)
        self.assertIn("command not allowed", dispatch)

    def test_smb_share_disables_name_mangling(self) -> None:
        provision = (ROOT / "scripts/nas-provision.sh").read_text()
        self.assertIn("'auxsmbconf': 'mangled names = no'", provision)
        self.assertIn("8.3/mangled alias", provision)

    def test_windows_sync_excludes_vcs_metadata(self) -> None:
        ps1 = (ROOT / "scripts/sync-windows-critical.ps1").read_text()
        self.assertIn("'.git'", ps1)
        self.assertIn("'.hg'", ps1)
        self.assertIn("'.svn'", ps1)

    def test_restore_docs_reference_zfs_snapshots(self) -> None:
        readme = (ROOT / "README.md").read_text()
        restore = (ROOT / "docs/restore-runbook.md").read_text()
        self.assertRegex(readme, re.compile(r"hourly snapshots", re.I))
        self.assertIn(".zfs/snapshot", restore)

    def test_workflow_records_and_syncs_run_ledger(self) -> None:
        workflow = (ROOT / "scripts/workflow-backup.sh").read_text()
        verify = (ROOT / "scripts/verify-backup.sh").read_text()
        config = (ROOT / "config/backup.env.example").read_text()
        self.assertIn("record-run-ledger.py", workflow)
        self.assertIn("runs.sqlite3", workflow)
        self.assertIn("run-history.json", workflow)
        self.assertIn("runs.sqlite3", verify)
        self.assertIn("LEDGER_STRICT_FINAL_EVENTS=1", config)
        self.assertIn("event_type\" == \"completed", workflow)

    def test_integrity_manifest_and_log_retention_are_wired(self) -> None:
        config = (ROOT / "config/backup.env.example").read_text()
        workflow = (ROOT / "scripts/workflow-backup.sh").read_text()
        verify = (ROOT / "scripts/verify-backup.sh").read_text()
        helper = (ROOT / "scripts/nas-integrity-manifest-helper.py").read_text()
        self.assertIn("NAS_INTEGRITY_MANIFEST_ENABLED=1", config)
        self.assertIn("NAS_INTEGRITY_SCOPE=critical", config)
        self.assertIn("LOCAL_LOG_RETENTION_DAYS=90", config)
        self.assertIn("run_integrity_manifest", workflow)
        self.assertIn("prune_old_logs", workflow)
        self.assertIn("integrity-manifest.json", verify)
        self.assertIn("sha256", helper)

    def test_workflow_uses_windows_interop_fallback(self) -> None:
        workflow = (ROOT / "scripts/workflow-backup.sh").read_text()
        runner = (ROOT / "scripts/run-tests.sh").read_text()
        helper = (ROOT / "scripts/windows-interop.sh").read_text()
        self.assertIn("windows-interop.sh", workflow)
        self.assertIn("resolve_windows_launcher", workflow)
        self.assertIn("windows-interop.sh", runner)
        self.assertIn("resolve_windows_launcher", runner)
        self.assertIn("/init", helper)
        self.assertIn("/run/WSL/*_interop", helper)

    def test_run_ledger_records_latest_run_and_exports(self) -> None:
        script = ROOT / "scripts/record-run-ledger.py"
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = pathlib.Path(tmpdir)
            db = tmp / "runs.sqlite3"
            log = tmp / "run.log"
            sqlite_manifest = tmp / "sqlite-manifest.json"
            windows_manifest = tmp / "windows-manifest.json"
            sqlite_manifest.write_text(
                json.dumps({"database_count": 3, "failure_count": 0, "duration_seconds": 1.25}),
                encoding="utf-8",
            )
            windows_manifest.write_bytes(
                ("\ufeff" + json.dumps({"duration_seconds": 2.5, "results": [{"status": "ok"}, {"status": "failed"}]})).encode(
                    "utf-8"
                )
            )

            subprocess.run(
                [
                    "python3",
                    str(script),
                    "event",
                    "--db",
                    str(db),
                    "--run-id",
                    "run-1",
                    "--event-type",
                    "started",
                    "--status",
                    "running",
                    "--dry-run",
                    "0",
                    "--log-file",
                    str(log),
                ],
                check=True,
            )
            subprocess.run(
                [
                    "python3",
                    str(script),
                    "event",
                    "--db",
                    str(db),
                    "--run-id",
                    "run-1",
                    "--event-type",
                    "completed",
                    "--status",
                    "ok",
                    "--dry-run",
                    "0",
                    "--log-file",
                    str(log),
                    "--duration-seconds",
                    "7",
                    "--sqlite-manifest",
                    str(sqlite_manifest),
                    "--windows-manifest",
                    str(windows_manifest),
                ],
                check=True,
            )

            conn = sqlite3.connect(db)
            try:
                row = conn.execute(
                    """
                    SELECT status, duration_seconds, sqlite_database_count,
                           sqlite_failure_count, windows_result_count, windows_failure_count
                    FROM latest_runs
                    WHERE run_id = 'run-1'
                    """
                ).fetchone()
            finally:
                conn.close()
            self.assertEqual(row, ("ok", 7, 3, 0, 2, 1))

            status = subprocess.run(
                ["python3", str(script), "status", "--db", str(db), "--limit", "1"],
                check=True,
                text=True,
                capture_output=True,
            )
            self.assertIn("run-1", status.stdout)
            self.assertIn("ok", status.stdout)

            exported = tmp / "run-history.json"
            snapshot = tmp / "runs.snapshot.sqlite3"
            subprocess.run(
                ["python3", str(script), "export-json", "--db", str(db), "--output-json", str(exported), "--limit", "5"],
                check=True,
            )
            subprocess.run(
                ["python3", str(script), "snapshot-db", "--db", str(db), "--output", str(snapshot)],
                check=True,
            )
            exported_payload = json.loads(exported.read_text(encoding="utf-8"))
            self.assertEqual(exported_payload["runs"][0]["run_id"], "run-1")
            snap_conn = sqlite3.connect(snapshot)
            try:
                snap_count = snap_conn.execute("SELECT count(*) FROM run_events").fetchone()[0]
            finally:
                snap_conn.close()
            self.assertEqual(snap_count, 2)


if __name__ == "__main__":
    unittest.main()
