#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
USER_SYSTEMD_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user

mkdir -p "$USER_SYSTEMD_DIR"
install -m 0644 "$REPO_ROOT/systemd/workstation-workflow-backup.service" "$USER_SYSTEMD_DIR/workstation-workflow-backup.service"
install -m 0644 "$REPO_ROOT/systemd/workstation-workflow-backup.timer" "$USER_SYSTEMD_DIR/workstation-workflow-backup.timer"
install -m 0644 "$REPO_ROOT/systemd/workstation-workflow-backup-failure-notify@.service" "$USER_SYSTEMD_DIR/workstation-workflow-backup-failure-notify@.service"

if [[ "$(ps -p 1 -o comm=)" != "systemd" ]]; then
  echo "systemd is not PID 1; cannot install user timer" >&2
  exit 1
fi

linger=$(loginctl show-user "$USER" -p Linger --value 2>/dev/null || true)
if [[ "$linger" != "yes" ]]; then
  echo "User linger is not enabled; enabling it so the timer survives WSL restarts..." >&2
  sudo loginctl enable-linger "$USER"
fi

systemctl --user daemon-reload
systemctl --user enable --now workstation-workflow-backup.timer
systemctl --user status workstation-workflow-backup.timer --no-pager -l
systemctl --user list-timers workstation-workflow-backup.timer --no-pager
