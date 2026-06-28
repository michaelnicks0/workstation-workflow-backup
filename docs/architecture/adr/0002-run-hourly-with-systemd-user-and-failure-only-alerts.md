---
id: ADR-0002
status: accepted
date: 2026-06-28
decider: Michael
scope: repo
supersedes: []
superseded_by: []
related: [ADR-0001, ADR-0004]
verification:
  - ./scripts/run-tests.sh
  - systemctl --user list-timers workstation-workflow-backup.timer
  - ./scripts/verify-backup.sh
---

# ADR-0002: Run hourly with systemd user scheduling and failure-only alerts

## Context

The workflow backup is intended to be a quiet high-frequency safety net, not a noisy operations feed. It must run under the WSL user environment, survive WSL restarts with linger, and alert Michael when action is required. Successful runs should be inspectable through local status/logs and NAS manifests without posting messages.

## Decision

Run `scripts/workflow-backup.sh` from a WSL systemd user timer:

- `workstation-workflow-backup.timer` uses `OnCalendar=*:45`, `OnBootSec=3min`, `Persistent=true`, `AccuracySec=1min`, and a small randomized delay.
- `workstation-workflow-backup.service` is a `Type=oneshot` unit with a 25-minute timeout.
- `OnFailure=workstation-workflow-backup-failure-notify@%n.service` invokes the Telegram notifier only for nonzero backup exits.
- Success state is recorded locally and mirrored as manifests; success does not send Telegram.

## Decision drivers

- Hourly cadence supports the ≤1 hour recent RPO target.
- User-level systemd fits WSL user-owned repo paths and local state.
- Failure-only alerting avoids habituation and keeps normal operation silent.
- OnFailure isolates alerting from backup success-path logic.

## Options considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| WSL systemd user timer + OnFailure notifier | Native scheduling, persistent catch-up, clear failure path, local logs | Requires systemd/linger to be available | Chosen |
| Cron inside WSL | Simple | Weaker WSL restart semantics and less direct unit failure wiring | Rejected |
| Long-running custom daemon loop | Full control | More code and watchdog burden for a simple hourly task | Rejected |
| Telegram on every run | Maximum visibility | Alert fatigue; noisy success path | Rejected |

## Consequences

- Positive: backup cadence is declarative and inspectable with `systemctl --user`.
- Positive: the alert path is activated by service failure, not by ad hoc script branches.
- Negative: timer installation depends on WSL systemd and user linger.
- Operational: lack of Telegram messages is expected on success; use `verify-backup.sh` or run-ledger status for health checks.

## Verification / validation

- Static tests assert timer cadence, persistence, OnFailure wiring, and service `ExecStart` path.
- `scripts/install-systemd-user.sh` installs units, enables linger if needed, reloads user systemd, enables/starts the timer, and prints timer status.
- `scripts/verify-backup.sh` reports timer enabled/active/list-timer state and last local status.

## Revisit triggers

- WSL systemd becomes unavailable or unreliable.
- Backup duration regularly exceeds the service timeout or overlaps next runs.
- Michael wants success-heartbeat reporting rather than silent success.
- The backup becomes multi-host and needs centralized scheduling.

## References

- `systemd/workstation-workflow-backup.timer`
- `systemd/workstation-workflow-backup.service`
- `systemd/workstation-workflow-backup-failure-notify@.service`
- `scripts/install-systemd-user.sh`
- `scripts/notify-telegram-failure.sh`
- `scripts/verify-backup.sh`
