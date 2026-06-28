#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
source "$REPO_ROOT/config/backup.env"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/nas-ssh.sh"

RUNTIME_USER=${NAS_RUNTIME_USER:-$NAS_USER}
RUNTIME_HOME=${NAS_RUNTIME_HOME:-"$NAS_PATH/.ops/${RUNTIME_USER}-home"}
RUNTIME_PUBLIC_KEY_FILE=${NAS_RUNTIME_PUBLIC_KEY_FILE:-"${NAS_SSH_KEY}.pub"}
DISPATCH_PATH=${NAS_RUNTIME_DISPATCH_PATH:-/usr/local/libexec/ws1-wf-ssh-dispatch}
GUARD_HELPER=${NAS_GROWTH_GUARD_REMOTE_HELPER:-/usr/local/sbin/ws1-wf-growth-guard}
INTEGRITY_HELPER=${NAS_INTEGRITY_REMOTE_HELPER:-/usr/local/sbin/ws1-wf-integrity-manifest}
RUNTIME_CONFIG=${NAS_RUNTIME_CONFIG_PATH:-/usr/local/etc/ws1-wf-runtime.json}
REMOTE_RSYNC=${NAS_REMOTE_RSYNC:-/usr/local/bin/rsync}
DATASET_REFQUOTA_BYTES=${NAS_DATASET_REFQUOTA_BYTES:-0}

if [[ ! -r "$RUNTIME_PUBLIC_KEY_FILE" ]]; then
  echo "Runtime public key not readable: $RUNTIME_PUBLIC_KEY_FILE" >&2
  exit 2
fi
PUBLIC_KEY=$(<"$RUNTIME_PUBLIC_KEY_FILE")
PUBLIC_KEY_B64=$(printf '%s' "$PUBLIC_KEY" | base64 -w 0)

remote_quote() {
  local s=${1//\'/\'\\\'\'}
  printf "'%s'" "$s"
}

install_remote_file() {
  local src=$1
  local dest=$2
  local mode=$3
  ssh_nas_admin "umask 077; mkdir -p $(remote_quote "$(dirname "$dest")"); cat > $(remote_quote "$dest"); chmod $mode $(remote_quote "$dest")" < "$src"
}

install_remote_file "$SCRIPT_DIR/nas-runtime-ssh-dispatch.py" "$DISPATCH_PATH" 0755
install_remote_file "$SCRIPT_DIR/nas-growth-guard-helper.py" "$GUARD_HELPER" 0755
install_remote_file "$SCRIPT_DIR/nas-integrity-manifest-helper.py" "$INTEGRITY_HELPER" 0755

runtime_json=$(python3 - <<'PY' "$NAS_DATASET" "${NAS_AVAILABLE_DATASET:-$NAS_DATASET}" "$NAS_PATH" "$NAS_PATH/current" "$REMOTE_RSYNC" "$GUARD_HELPER" "$INTEGRITY_HELPER"
import json, sys
keys = ["dataset", "availability_dataset", "dataset_path", "allowed_root", "rsync_path", "growth_guard_helper", "integrity_helper"]
print(json.dumps(dict(zip(keys, sys.argv[1:])), indent=2, sort_keys=True))
PY
)
printf '%s\n' "$runtime_json" | ssh_nas_admin "umask 077; cat > $(remote_quote "$RUNTIME_CONFIG"); chmod 0644 $(remote_quote "$RUNTIME_CONFIG")"

ssh_nas_admin python3 - "$RUNTIME_USER" "$PUBLIC_KEY_B64" "$RUNTIME_HOME" <<'PY'
import base64
import json
import subprocess
import sys

user, public_key_b64, home = sys.argv[1:]
public_key = base64.b64decode(public_key_b64.encode()).decode()


def midclt(method, *args):
    cmd = ["midclt", "call", method] + [json.dumps(arg) for arg in args]
    out = subprocess.check_output(cmd, text=True)
    return json.loads(out) if out.strip() else None


def query_user(username):
    users = midclt("user.query", [["username", "=", username]])
    return users[0] if users else None


def next_uid() -> int:
    users = midclt("user.query")
    used = {int(item["uid"]) for item in users if item.get("uid") is not None}
    candidate = 1000
    while candidate in used:
        candidate += 1
    return candidate

existing = query_user(user)
if existing:
    payload = {
        "sshpubkey": public_key,
        "home": home,
        "shell": "/bin/sh",
        "password_disabled": True,
        "locked": False,
        "smb": False,
        "sudo": True,
        "sudo_nopasswd": True,
        "sudo_commands": [
            "/usr/local/sbin/ws1-wf-growth-guard *",
            "/usr/local/sbin/ws1-wf-integrity-manifest *",
        ],
    }
    midclt("user.update", existing["id"], payload)
else:
    payload = {
        "uid": next_uid(),
        "username": user,
        "full_name": "WORKSTATION1 workflow backup runtime",
        "group_create": True,
        "home": home,
        "home_mode": "700",
        "shell": "/bin/sh",
        "sshpubkey": public_key,
        "password_disabled": True,
        "locked": False,
        "smb": False,
        "sudo": True,
        "sudo_nopasswd": True,
        "sudo_commands": [
            "/usr/local/sbin/ws1-wf-growth-guard *",
            "/usr/local/sbin/ws1-wf-integrity-manifest *",
        ],
    }
    midclt("user.create", payload)

subprocess.run(["install", "-d", "-m", "700", "-o", user, "-g", user, home], check=True)
subprocess.run(["install", "-d", "-m", "700", "-o", user, "-g", user, f"{home}/.ssh"], check=True)
PY

forced_key="restrict,command=\"$DISPATCH_PATH\",no-agent-forwarding,no-port-forwarding,no-X11-forwarding,no-pty $PUBLIC_KEY"
printf '%s\n' "$forced_key" | ssh_nas_admin "cat > $(remote_quote "$RUNTIME_HOME/.ssh/authorized_keys"); chown $RUNTIME_USER:$RUNTIME_USER $(remote_quote "$RUNTIME_HOME/.ssh/authorized_keys"); chmod 0600 $(remote_quote "$RUNTIME_HOME/.ssh/authorized_keys")"

sudoers_line="$RUNTIME_USER ALL=(root) NOPASSWD: $GUARD_HELPER *, $INTEGRITY_HELPER *"
printf '%s\n' "$sudoers_line" | ssh_nas_admin "cat > /usr/local/etc/sudoers.d/ws1-wf-runtime; chmod 0440 /usr/local/etc/sudoers.d/ws1-wf-runtime; /usr/local/sbin/visudo -cf /usr/local/etc/sudoers.d/ws1-wf-runtime >/dev/null"

ssh_nas_admin "set -e
zfs list -H $(remote_quote "$NAS_DATASET") >/dev/null
mkdir -p $(remote_quote "$NAS_PATH/current/wsl") $(remote_quote "$NAS_PATH/current/wsl-sqlite-snapshots") $(remote_quote "$NAS_PATH/current/_manifests") $(remote_quote "$NAS_PATH/.ops")
chown -R $RUNTIME_USER:$RUNTIME_USER $(remote_quote "$NAS_PATH/current/wsl") $(remote_quote "$NAS_PATH/current/wsl-sqlite-snapshots") $(remote_quote "$NAS_PATH/current/_manifests") $(remote_quote "$NAS_PATH/.ops")
if [ $(remote_quote "$DATASET_REFQUOTA_BYTES") != '0' ]; then
  zfs set refquota=$(remote_quote "$DATASET_REFQUOTA_BYTES") $(remote_quote "$NAS_DATASET")
fi
"

ssh_nas "$GUARD_HELPER" \
  --dataset "$NAS_DATASET" \
  --availability-dataset "${NAS_AVAILABLE_DATASET:-$NAS_DATASET}" \
  --stage runtime-hardening-smoke \
  --max-used "${NAS_DATASET_MAX_USED_BYTES:-0}" \
  --max-snapshot-used "${NAS_DATASET_MAX_SNAPSHOT_BYTES:-0}" \
  --min-available "${NAS_DATASET_MIN_AVAILABLE_BYTES:-0}" \
  --max-snapshot-count "${NAS_DATASET_MAX_SNAPSHOT_COUNT:-0}" \
  --enforce "${NAS_GROWTH_GUARD_ENFORCE:-1}"

echo "NAS runtime hardening installed for $RUNTIME_USER@$NAS_HOST"
