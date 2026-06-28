#!/usr/bin/env bash
# Helpers for launching Windows executables from WSL systemd services.
# shellcheck shell=bash
# shellcheck disable=SC2034 # WINDOWS_LAUNCHER_* variables are consumed by callers after sourcing.

windows_launcher_smoke() {
  local -a cmd=("$@")
  "${cmd[@]}" -NoProfile -Command 'exit 0' >/dev/null 2>&1
}

resolve_windows_launcher() {
  local exe=${1:?windows executable path required}
  WINDOWS_LAUNCHER=()
  WINDOWS_LAUNCHER_MODE=""

  if [[ ! -x "$exe" ]]; then
    echo "Windows executable not found: $exe" >&2
    return 1
  fi

  WINDOWS_LAUNCHER=("$exe")
  if windows_launcher_smoke "${WINDOWS_LAUNCHER[@]}"; then
    WINDOWS_LAUNCHER_MODE="direct"
    return 0
  fi

  if [[ ! -x /init ]]; then
    echo "WSL /init is not executable; cannot use Windows interop fallback" >&2
    return 1
  fi

  local sock
  for sock in "${WSL_INTEROP:-}" /run/WSL/*_interop; do
    [[ -S "$sock" ]] || continue
    WINDOWS_LAUNCHER=(env "WSL_INTEROP=$sock" /init "$exe")
    if windows_launcher_smoke "${WINDOWS_LAUNCHER[@]}"; then
      WINDOWS_LAUNCHER_MODE="/init via $sock"
      return 0
    fi
  done

  echo "Unable to execute Windows PowerShell from WSL; WSL interop is unavailable" >&2
  return 1
}
