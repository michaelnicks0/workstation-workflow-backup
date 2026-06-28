# WORKSTATION1 Workflow Backup Architecture

> Purpose: describe the architecture, generated C4 diagrams, ADR record, and verification gates for the high-frequency WORKSTATION1 → TrueNAS workflow backup system.

| Field | Value |
|---|---|
| Owner | Michael |
| Status | Active |
| Last updated | 2026-06-28 |
| Canonical C4 model | [`workspace.dsl`](workspace.dsl) |
| Generated C4 atlas | [`c4-diagrams.md`](c4-diagrams.md) |
| ADR index | [`adr/README.md`](adr/README.md) |

## Scope

The architecture covers the repo-owned automation for:

- hourly WSL systemd user timer execution;
- restricted, pinned-host-key NAS runtime SSH access;
- guarded WSL and Windows workflow artifact sync to TrueNAS;
- application-consistent SQLite backup snapshots;
- run ledger/status/manifest publication;
- restore-critical checksum manifest generation;
- failure-only Telegram notification;
- TrueNAS provisioning, runtime hardening, periodic snapshot retention, verification, and targeted restore.

It does **not** model full bare-metal recovery, full WSL distro exports, Windows profile imaging, or NAS encryption-key custody. Those are adjacent recovery concerns outside this repo's high-frequency workflow-backup boundary.

## Architecture sources

| Claim area | Primary source paths |
|---|---|
| Mission, RPO, snapshot schedule, backup scope, restore commands | [`../../README.md`](../../README.md) |
| Repo safety rules and operating model | [`../../AGENTS.md`](../../AGENTS.md) |
| Local config template | [`../../config/backup.env.example`](../../config/backup.env.example) |
| Shared SSH/pinned-host-key helpers | [`../../scripts/nas-ssh.sh`](../../scripts/nas-ssh.sh) |
| Runtime SSH hardening installer | [`../../scripts/install-nas-runtime-hardening.sh`](../../scripts/install-nas-runtime-hardening.sh) |
| Forced-command runtime dispatcher | [`../../scripts/nas-runtime-ssh-dispatch.py`](../../scripts/nas-runtime-ssh-dispatch.py) |
| Hourly orchestration, locking, ledger, guards, WSL/Windows phases | [`../../scripts/workflow-backup.sh`](../../scripts/workflow-backup.sh) |
| TrueNAS dataset/share/snapshot-task provisioning | [`../../scripts/nas-provision.sh`](../../scripts/nas-provision.sh) |
| Non-destructive growth guard | [`../../scripts/check-nas-growth-guard.sh`](../../scripts/check-nas-growth-guard.sh), [`../../scripts/nas-growth-guard-helper.py`](../../scripts/nas-growth-guard-helper.py) |
| Restore checksum manifest | [`../../scripts/nas-integrity-manifest-helper.py`](../../scripts/nas-integrity-manifest-helper.py) |
| Backup health verification | [`../../scripts/verify-backup.sh`](../../scripts/verify-backup.sh) |
| SQLite consistent snapshots | [`../../scripts/snapshot-sqlite-dbs.py`](../../scripts/snapshot-sqlite-dbs.py) |
| Run ledger schema/export behavior | [`../../scripts/record-run-ledger.py`](../../scripts/record-run-ledger.py) |
| Windows robocopy path | [`../../scripts/sync-windows-critical.ps1`](../../scripts/sync-windows-critical.ps1) |
| Timer/failure notifier wiring | [`../../systemd/`](../../systemd/) |
| Restore procedure | [`../restore-runbook.md`](../restore-runbook.md) |

## System boundary

**WORKSTATION1 Workflow Backup** is the owned software system. It includes the versioned scripts/config template/systemd units in this repo plus the local state they create under `~/.local/state/workstation-workflow-backup`.

External systems and stores:

- WSL workflow source paths (`~/repos`, `~/.hermes`, `~/.ssh`, systemd user config, lifelog/browser-memory data, optional `~/brain-code`).
- Windows workflow source paths (Desktop, Documents, Downloads, Windows SSH/WSL config, Terminal/VS Code/PowerShell config, Chrome profile metadata, Startup entries).
- Configured TrueNAS dataset/control plane, including the backup dataset, SMB share, periodic snapshot tasks, ZFS properties, middleware APIs, runtime user, and forced-command SSH boundary.
- Hermes bot environment file for Telegram notification configuration.
- Telegram Bot API for failure-only alerts.

## C4 views

| View key | C4 level | Purpose |
|---|---|---|
| `SystemContext` | C1 System Context | Operator, backup system boundary, WSL/Windows sources, TrueNAS target/control plane, restore shell, and Telegram alert API. |
| `BackupRuntimeContainers` | C2 Container | Hourly runtime path: scheduler, orchestrator, restricted SSH, SQLite snapshotter, Windows helper, growth guard, integrity manifest, run ledger, notifier, and external stores. |
| `OpsProvisioningContainers` | C2 Container | Operator-facing provisioning, runtime hardening, verification, guard, run-ledger, and restore/control-plane surfaces. |
| `OrchestratorControlComponents` | C3 Component | Control responsibilities inside `scripts/workflow-backup.sh`: arguments, locking, status, ledger, guards, publication, integrity, and errors. |
| `OrchestratorSyncComponents` | C3 Component | Data-movement responsibilities inside `scripts/workflow-backup.sh`: SQLite snapshots, WSL rsync, and Windows robocopy helper launch. |
| `HourlyPreflightSnapshotFlow` | Dynamic | First half of a successful hourly run: service start, status, pre-write guard, and SQLite snapshot creation. |
| `HourlyMirrorPublishFlow` | Dynamic | Second half of a successful hourly run: WSL/Windows mirroring, post-write guard, ledger completion, NAS manifest publication, and integrity manifest generation. |
| `FailureAlertFlow` | Dynamic | Nonzero backup service result to Telegram failure notification. |
| `TargetedRestoreFlow` | Dynamic | Snapshot selection, staged restore, deliberate replacement, checksum verification, and post-restore verification. |
| `LocalDeployment` | Deployment | WORKSTATION1 WSL/Windows runtime plus TrueNAS target and Telegram API. |

## Diagram ownership

- [`workspace.dsl`](workspace.dsl) is canonical.
- [`c4-diagrams.md`](c4-diagrams.md) and everything under [`diagrams/`](diagrams/) are generated from Structurizr exports.
- Do not hand-edit generated diagram artifacts. Change `workspace.dsl`, regenerate, and verify.
- ADRs live under [`adr/`](adr/) and explain durable decisions that future operators must preserve.

## Render and validate

```bash
STRUCTURIZR_CLI=${STRUCTURIZR_CLI:-/tmp/structurizr-cli/structurizr.sh}
C4_SKILL_DIR=${C4_SKILL_DIR:-$HOME/.hermes/skills/software-development/c4-structurizr-architecture}

"$STRUCTURIZR_CLI" validate -workspace docs/architecture/workspace.dsl

mkdir -p docs/architecture/diagrams
find docs/architecture/diagrams -maxdepth 1 -type f \( -name '*.mmd' -o -name '*.svg' -o -name '*.png' \) -delete
JAVA_TOOL_OPTIONS='-Djava.awt.headless=true' \
  "$STRUCTURIZR_CLI" export -workspace docs/architecture/workspace.dsl -format mermaid -output docs/architecture/diagrams

cat > /tmp/workstation-workflow-backup-mermaid-config.json <<'JSON'
{"securityLevel":"loose","htmlLabels":true}
JSON
# If Mermaid CLI cannot find Chrome, install Puppeteer's headless shell:
#   npx --yes puppeteer browsers install chrome-headless-shell
if [[ -z "${PUPPETEER_EXECUTABLE_PATH:-}" && -d "$HOME/.cache/puppeteer/chrome-headless-shell" ]]; then
  PUPPETEER_EXECUTABLE_PATH=$(find "$HOME/.cache/puppeteer/chrome-headless-shell" -type f -name chrome-headless-shell | sort | tail -1)
  export PUPPETEER_EXECUTABLE_PATH
fi
for f in docs/architecture/diagrams/*.mmd; do
  npx --yes @mermaid-js/mermaid-cli -c /tmp/workstation-workflow-backup-mermaid-config.json -i "$f" -o "${f%.mmd}.svg"
  npx --yes @mermaid-js/mermaid-cli -c /tmp/workstation-workflow-backup-mermaid-config.json -i "$f" -o "${f%.mmd}.png" -b transparent
done

rm -rf docs/architecture/diagrams/dot docs/architecture/diagrams/dot-rendered
mkdir -p docs/architecture/diagrams/dot docs/architecture/diagrams/dot-rendered
JAVA_TOOL_OPTIONS='-Djava.awt.headless=true' \
  "$STRUCTURIZR_CLI" export -workspace docs/architecture/workspace.dsl -format dot -output docs/architecture/diagrams/dot
python3 "$C4_SKILL_DIR/scripts/graphviz-edge-label-backgrounds.py" docs/architecture/diagrams/dot
for file in docs/architecture/diagrams/dot/*.dot; do
  base=$(basename "$file" .dot)
  dot -Tsvg "$file" -o "docs/architecture/diagrams/dot-rendered/$base.svg"
  dot -Tpng "$file" -o "docs/architecture/diagrams/dot-rendered/$base.png"
done

rm -rf docs/architecture/diagrams/markdown docs/architecture/diagrams/README.md docs/architecture/c4-diagrams.md
python3 "$C4_SKILL_DIR/scripts/structurizr-diagrams-to-markdown.py" \
  --diagrams-dir docs/architecture/diagrams \
  --workspace docs/architecture/workspace.dsl \
  --title "WORKSTATION1 Workflow Backup Architecture C4 Diagrams"
```

## Verification gates

| Gate | Command |
|---|---|
| Structurizr DSL parse | `STRUCTURIZR_CLI=/tmp/structurizr-cli/structurizr.sh "$STRUCTURIZR_CLI" validate -workspace docs/architecture/workspace.dsl` |
| Generated artifact completeness | Count `.mmd`, Mermaid SVG/PNG, DOT, Graphviz SVG/PNG, per-view Markdown, diagram README, and atlas after regeneration. |
| Repo static tests | `./scripts/run-tests.sh` |
| Live runtime smoke | `./scripts/install-nas-runtime-hardening.sh`; restricted-command rejection; runtime rsync smoke; `./scripts/check-nas-growth-guard.sh --stage verify` |
| Git whitespace | `git diff --check -- .` and `git diff --cached --check` before commit. |

Use `scripts/verify-backup.sh` before declaring **live backup health**. Architecture docs/tests can prove documentation consistency, but they do not replace live NAS health verification.

## Assumptions and TBDs

- Deployment view is the local WORKSTATION1 + TrueNAS topology only; no staging/production topology exists.
- This model records path classes and control/data flow, not backed-up payload contents.
- Hermes `.env` is modeled as an external local configuration source for failure notification only; its contents must not be committed or printed.
- TrueNAS encryption-key custody and cold reboot/import/unlock drills are outside this repo's current automation boundary.
- The default integrity scope is restore-critical artifacts, not a full-tree hourly checksum sweep.
