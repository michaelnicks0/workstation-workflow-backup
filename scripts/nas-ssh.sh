#!/usr/bin/env bash
# Shared SSH helpers for the WORKSTATION1 workflow backup scripts.
# Expects config/backup.env to have been sourced by the caller.

nas__require() {
  local name=$1
  if [[ -z "${!name:-}" ]]; then
    echo "Required configuration is missing: $name" >&2
    return 2
  fi
}

nas__build_ssh_options() {
  local key=$1
  local -n out=$2
  out=(-i "$key" -o BatchMode=yes -o "StrictHostKeyChecking=${NAS_STRICT_HOST_KEY_CHECKING:-yes}")
  if [[ -n "${NAS_KNOWN_HOSTS:-}" ]]; then
    out+=(-o "UserKnownHostsFile=$NAS_KNOWN_HOSTS")
  fi
  if [[ -n "${NAS_HOST_KEY_ALIAS:-}" ]]; then
    out+=(-o "HostKeyAlias=$NAS_HOST_KEY_ALIAS")
  fi
}

nas__validate_pinned_host_key() {
  if [[ "${NAS_STRICT_HOST_KEY_CHECKING:-yes}" == "yes" && -n "${NAS_KNOWN_HOSTS:-}" && ! -r "$NAS_KNOWN_HOSTS" ]]; then
    echo "Pinned NAS known_hosts file is not readable: $NAS_KNOWN_HOSTS" >&2
    return 2
  fi
}

nas_runtime_ssh_options() {
  nas__require NAS_HOST
  nas__require NAS_USER
  nas__require NAS_SSH_KEY
  nas__validate_pinned_host_key
  nas__build_ssh_options "$NAS_SSH_KEY" NAS_SSH_OPTS
}

nas_admin_ssh_options() {
  nas__require NAS_HOST
  local admin_key=${NAS_ADMIN_SSH_KEY:-${NAS_SSH_KEY:-}}
  if [[ -z "$admin_key" ]]; then
    echo "Required configuration is missing: NAS_ADMIN_SSH_KEY or NAS_SSH_KEY" >&2
    return 2
  fi
  nas__validate_pinned_host_key
  nas__build_ssh_options "$admin_key" NAS_ADMIN_SSH_OPTS
}

ssh_nas() {
  nas_runtime_ssh_options
  ssh "${NAS_SSH_OPTS[@]}" "$NAS_USER@$NAS_HOST" "$@"
}

ssh_nas_admin() {
  nas_admin_ssh_options
  ssh "${NAS_ADMIN_SSH_OPTS[@]}" "${NAS_ADMIN_USER:-root}@$NAS_HOST" "$@"
}

nas_rsync_rsh() {
  nas_runtime_ssh_options
  local -a cmd=(ssh "${NAS_SSH_OPTS[@]}")
  printf '%q ' "${cmd[@]}"
}
