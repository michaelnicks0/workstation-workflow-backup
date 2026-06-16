#!/usr/bin/env bash
set -euo pipefail

UNIT_NAME=${1:-workstation-workflow-backup.service}
STATE_DIR=${LOCAL_STATE:-$HOME/.local/state/workstation-workflow-backup}
ENV_FILE=${HERMES_ENV_FILE:-$HOME/.hermes/.env}
LAST_STATUS="$STATE_DIR/last-run.json"

load_env_key() {
  local key=$1
  local line value
  [[ -r "$ENV_FILE" ]] || return 0
  line=$(grep -E "^${key}=" "$ENV_FILE" | tail -n 1 || true)
  [[ -n "$line" ]] || return 0
  value=${line#*=}
  value=${value%$'\r'}
  value=${value#\'}; value=${value%\'}
  value=${value#\"}; value=${value%\"}
  export "$key=$value"
}

load_env_key TELEGRAM_BOT_TOKEN
load_env_key TELEGRAM_HOME_CHANNEL
load_env_key TELEGRAM_HOME_CHANNEL_THREAD_ID
load_env_key BACKUP_TELEGRAM_CHAT_ID
load_env_key BACKUP_TELEGRAM_THREAD_ID

CHAT_ID=${BACKUP_TELEGRAM_CHAT_ID:-${TELEGRAM_HOME_CHANNEL:-}}
THREAD_ID=${BACKUP_TELEGRAM_THREAD_ID:-${TELEGRAM_HOME_CHANNEL_THREAD_ID:-}}
TOKEN=${TELEGRAM_BOT_TOKEN:-}

# Failure notification is best-effort. If Telegram is not configured, do not make
# the failure handler itself fail or spam stdout.
if [[ -z "$TOKEN" || -z "$CHAT_ID" ]]; then
  exit 0
fi

LAST_LOG=""
if [[ -r "$LAST_STATUS" ]]; then
  LAST_LOG=$(python3 - <<'PY' "$LAST_STATUS" 2>/dev/null || true
import json, sys
try:
    data=json.load(open(sys.argv[1], encoding='utf-8'))
    print(data.get('log_file',''))
except Exception:
    pass
PY
)
fi

TAIL=""
if [[ -n "$LAST_LOG" && -r "$LAST_LOG" ]]; then
  TAIL=$(tail -40 "$LAST_LOG" | sed -e 's/[[:cntrl:]]//g' | tail -c 2500)
fi

python3 - <<'PY' "$TOKEN" "$CHAT_ID" "$THREAD_ID" "$UNIT_NAME" "$LAST_STATUS" "$LAST_LOG" "$TAIL"
import json
import socket
import sys
import textwrap
import urllib.parse
import urllib.request
from datetime import datetime, timezone

token, chat_id, thread_id, unit_name, last_status, last_log, tail = sys.argv[1:]
when = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
host = socket.gethostname()
message = f"🚨 WORKSTATION1 backup failed\n\nUnit: {unit_name}\nHost: {host}\nUTC: {when}\nStatus: {last_status}\nLog: {last_log or 'unknown'}"
if tail:
    message += "\n\nLast log tail:\n```\n" + tail[-2500:] + "\n```"

payload = {"chat_id": chat_id, "text": message, "parse_mode": "Markdown"}
if thread_id:
    payload["message_thread_id"] = thread_id
body = urllib.parse.urlencode(payload).encode()
url = f"https://api.telegram.org/bot{token}/sendMessage"
request = urllib.request.Request(url, data=body, method="POST")
with urllib.request.urlopen(request, timeout=20) as response:
    response.read()
PY
