from __future__ import annotations

import configparser
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class StaticBackupRepoTests(unittest.TestCase):
    def test_timer_runs_every_15_minutes(self) -> None:
        timer = (ROOT / "systemd/workstation-workflow-backup.timer").read_text()
        self.assertIn("OnCalendar=*:0/15", timer)
        self.assertIn("Persistent=true", timer)

    def test_service_has_failure_notifier(self) -> None:
        service = (ROOT / "systemd/workstation-workflow-backup.service").read_text()
        self.assertIn("OnFailure=workstation-workflow-backup-failure-notify@%n.service", service)
        self.assertIn("ExecStart=/home/mnicks/repos/workstation/workstation-workflow-backup/scripts/workflow-backup.sh", service)

    def test_no_payload_patterns_allowed(self) -> None:
        gitignore = (ROOT / ".gitignore").read_text()
        for pattern in ("*.tar", "*.vhdx", "*.wim", "*.db-backup"):
            self.assertIn(pattern, gitignore)

    def test_config_points_to_expected_dataset(self) -> None:
        config = (ROOT / "config/backup.env").read_text()
        self.assertIn("NAS_HOST=10.99.98.221", config)
        self.assertIn("NAS_DATASET=volume1/workstation1-workflow-backup", config)
        self.assertIn("SMB_SHARE_NAME=workstation1-workflow-backup", config)

    def test_restore_docs_reference_zfs_snapshots(self) -> None:
        readme = (ROOT / "README.md").read_text()
        restore = (ROOT / "docs/restore-runbook.md").read_text()
        self.assertRegex(readme, re.compile(r"hourly snapshots", re.I))
        self.assertIn(".zfs/snapshot", restore)


if __name__ == "__main__":
    unittest.main()
