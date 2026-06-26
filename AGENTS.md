# AGENTS.md — WORKSTATION1 Workflow Backup

This repo contains the high-frequency WORKSTATION1 → TrueNAS workflow backup system.

## Safety

- Backup payloads live only on the NAS dataset `volume1/workstation1-workflow-backup`; never store payloads in this Git repo.
- The NAS dataset contains secrets (`~/.hermes/.env`, OAuth/auth stores, SSH keys, browser/workflow configs). Do not print payload contents into chat or logs.
- Do not destroy snapshots or datasets without explicit Michael approval.
- Use `scripts/verify-backup.sh` before declaring backup health.

## Key commands

```bash
./scripts/run-tests.sh
./scripts/nas-provision.sh
./scripts/install-systemd-user.sh
./scripts/workflow-backup.sh --verbose
./scripts/verify-backup.sh
```

## Operating model

- Local sync cadence: systemd user timer hourly at minute 45.
- NAS retention: hourly snapshots retained 1 day, daily snapshots retained 1 week, weekly snapshots retained latest 8, monthly snapshots retained latest 12.
- Growth guard: `scripts/check-nas-growth-guard.sh` fails backup runs before/after writes when dataset/snapshot/free-space budgets are exceeded; it does not delete data.
- Alert policy: successful runs are silent; Telegram is sent only from the systemd `OnFailure` notifier.
- Restore source of truth: `/mnt/volume1/workstation1-workflow-backup/.zfs/snapshot/<snapshot>/current/...` on the NAS.
