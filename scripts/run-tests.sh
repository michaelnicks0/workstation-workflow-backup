#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
cd "$REPO_ROOT"

for script in scripts/*.sh; do
  bash -n "$script"
done

python3 -m py_compile scripts/snapshot-sqlite-dbs.py
python3 -m unittest discover -s tests -v

PS_EXE=${PS_EXE:-/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe}
if [[ -x "$PS_EXE" ]]; then
  ps_script=$(wslpath -w scripts/sync-windows-critical.ps1)
  "$PS_EXE" -NoProfile -ExecutionPolicy Bypass -Command \
    "\$null = [scriptblock]::Create((Get-Content -Raw '$ps_script')); 'PowerShell parser OK'"
else
  echo "Skipping PowerShell parser check; not found: $PS_EXE" >&2
fi
