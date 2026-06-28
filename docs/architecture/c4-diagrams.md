# WORKSTATION1 Workflow Backup Architecture C4 Diagrams

> Single-file generated C4 diagram atlas. Canonical model: [`workspace.dsl`](workspace.dsl).

<!-- Generated from Structurizr exports; refresh from docs/architecture/workspace.dsl. -->

## Reading notes

- This file intentionally includes every generated C4 view in one Markdown document.
- Diagrams prefer clean rendered artifacts first, usually Graphviz SVG with white-backed relationship labels.
- Mermaid source is retained under each diagram for text review and diffability.
- Generated per-view wrappers remain available at [`diagrams/markdown/`](diagrams/markdown); generated artifact index: [`diagrams/README.md`](diagrams/README.md).

## Diagram index

| View | Section | Preferred render | Per-view page |
|---|---|---|---|
| `BackupRuntimeContainers` | [`BackupRuntimeContainers`](#backup-runtime-containers) | [`Graphviz SVG`](diagrams/dot-rendered/structurizr-BackupRuntimeContainers.svg) | [`BackupRuntimeContainers.md`](diagrams/markdown/BackupRuntimeContainers.md) |
| `FailureAlertFlow` | [`FailureAlertFlow`](#failure-alert-flow) | [`Graphviz SVG`](diagrams/dot-rendered/structurizr-FailureAlertFlow.svg) | [`FailureAlertFlow.md`](diagrams/markdown/FailureAlertFlow.md) |
| `HourlyMirrorPublishFlow` | [`HourlyMirrorPublishFlow`](#hourly-mirror-publish-flow) | [`Graphviz SVG`](diagrams/dot-rendered/structurizr-HourlyMirrorPublishFlow.svg) | [`HourlyMirrorPublishFlow.md`](diagrams/markdown/HourlyMirrorPublishFlow.md) |
| `HourlyPreflightSnapshotFlow` | [`HourlyPreflightSnapshotFlow`](#hourly-preflight-snapshot-flow) | [`Graphviz SVG`](diagrams/dot-rendered/structurizr-HourlyPreflightSnapshotFlow.svg) | [`HourlyPreflightSnapshotFlow.md`](diagrams/markdown/HourlyPreflightSnapshotFlow.md) |
| `LocalDeployment` | [`LocalDeployment`](#local-deployment) | [`Graphviz SVG`](diagrams/dot-rendered/structurizr-LocalDeployment.svg) | [`LocalDeployment.md`](diagrams/markdown/LocalDeployment.md) |
| `OpsProvisioningContainers` | [`OpsProvisioningContainers`](#ops-provisioning-containers) | [`Graphviz SVG`](diagrams/dot-rendered/structurizr-OpsProvisioningContainers.svg) | [`OpsProvisioningContainers.md`](diagrams/markdown/OpsProvisioningContainers.md) |
| `OrchestratorControlComponents` | [`OrchestratorControlComponents`](#orchestrator-control-components) | [`Graphviz SVG`](diagrams/dot-rendered/structurizr-OrchestratorControlComponents.svg) | [`OrchestratorControlComponents.md`](diagrams/markdown/OrchestratorControlComponents.md) |
| `OrchestratorSyncComponents` | [`OrchestratorSyncComponents`](#orchestrator-sync-components) | [`Graphviz SVG`](diagrams/dot-rendered/structurizr-OrchestratorSyncComponents.svg) | [`OrchestratorSyncComponents.md`](diagrams/markdown/OrchestratorSyncComponents.md) |
| `SystemContext` | [`SystemContext`](#system-context) | [`Graphviz SVG`](diagrams/dot-rendered/structurizr-SystemContext.svg) | [`SystemContext.md`](diagrams/markdown/SystemContext.md) |
| `TargetedRestoreFlow` | [`TargetedRestoreFlow`](#targeted-restore-flow) | [`Graphviz SVG`](diagrams/dot-rendered/structurizr-TargetedRestoreFlow.svg) | [`TargetedRestoreFlow.md`](diagrams/markdown/TargetedRestoreFlow.md) |

---

## Backup Runtime Containers

> C4 view `BackupRuntimeContainers`.

### Diagram

![Backup Runtime Containers](diagrams/dot-rendered/structurizr-BackupRuntimeContainers.svg)

_Preferred Markdown display: Graphviz SVG. Mermaid source is retained below for text review._

<details>
<summary>Mermaid source</summary>

```mermaid
graph LR
  linkStyle default fill:#ffffff

  subgraph diagram ["Container View: WORKSTATION1 Workflow Backup"]
    style diagram fill:#ffffff,stroke:#ffffff

    26[("<div style='font-weight: bold'>WSL Workflow Sources</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Workflow-critical WSL paths:<br />~/repos, ~/.hermes, ~/.ssh,<br />systemd user config,<br />lifelog/browser-memory data,<br />and optional brain-code tree.</div>")]
    style 26 fill:#fef3c7,stroke:#d97706,color:#111827
    27[("<div style='font-weight: bold'>Windows Workflow Sources</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Selected Windows user-profile<br />artifacts: Desktop,<br />Documents, Downloads, Windows<br />.ssh/.wslconfig, Terminal/VS<br />Code/PowerShell config,<br />Chrome profile metadata, and<br />Startup entries.</div>")]
    style 27 fill:#fef3c7,stroke:#d97706,color:#111827
    28[("<div style='font-weight: bold'>TrueNAS Backup Dataset</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured encrypted TrueNAS<br />dataset with current mirror<br />tree, manifests, SMB share,<br />restore checksum manifest,<br />refquota, and ZFS snapshot<br />history.</div>")]
    style 28 fill:#fef3c7,stroke:#d97706,color:#111827
    29["<div style='font-weight: bold'>TrueNAS Middleware and ZFS Control Plane</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured admin SSH and<br />middleware surface used for<br />ZFS properties, runtime-user<br />setup, snapshot tasks, SMB<br />share configuration, and<br />verification.</div>"]
    style 29 fill:#f3e8ff,stroke:#9333ea,color:#111827
    30[("<div style='font-weight: bold'>Hermes Bot Environment File</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Local ~/.hermes/.env values<br />that supply Telegram bot<br />token/chat settings to the<br />failure notifier; contents<br />are not stored in this repo.</div>")]
    style 30 fill:#fef3c7,stroke:#d97706,color:#111827
    31["<div style='font-weight: bold'>Telegram Bot API</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>External API used only for<br />backup failure notifications.</div>"]
    style 31 fill:#f3e8ff,stroke:#9333ea,color:#111827

    subgraph 2 ["WORKSTATION1 Workflow Backup"]
      style 2 fill:#ffffff,stroke:#16a34a,color:#16a34a

      16["<div style='font-weight: bold'>SQLite Snapshotter</div><div style='font-size: 70%; margin-top: 0px'>[Container: Python 3, sqlite3]</div><div style='font-size: 80%; margin-top:10px'>Creates<br />application-consistent copies<br />of Hermes, lifelog,<br />browser-memory, and related<br />SQLite databases using<br />sqlite3 backup API; can<br />quick_check copies.</div>"]
      style 16 fill:#ecfeff,stroke:#0891b2,color:#111827
      17["<div style='font-weight: bold'>Windows Critical Sync Helper</div><div style='font-size: 70%; margin-top: 0px'>[Container: PowerShell + robocopy.exe]</div><div style='font-size: 80%; margin-top:10px'>PowerShell script launched<br />from WSL that uses<br />robocopy.exe to mirror<br />selected Windows profile<br />directories/files to the SMB<br />share and writes a Windows<br />sync manifest.</div>"]
      style 17 fill:#ecfeff,stroke:#0891b2,color:#111827
      18["<div style='font-weight: bold'>NAS Growth Guard</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + NAS sudo helper + zfs CLI]</div><div style='font-size: 80%; margin-top:10px'>Read-only NAS-side ZFS budget<br />check that enforces<br />dataset-used, snapshot-held,<br />availability-dataset<br />free-space, and<br />snapshot-count limits<br />before/after writes.</div>"]
      style 18 fill:#ecfeff,stroke:#0891b2,color:#111827
      19["<div style='font-weight: bold'>NAS Integrity Manifest Builder</div><div style='font-size: 70%; margin-top: 0px'>[Container: Python + SHA-256]</div><div style='font-size: 80%; margin-top:10px'>NAS-side helper that hashes<br />restore-critical current-tree<br />artifacts and writes<br />_manifests/integrity-manifest.json<br />for snapshot-preserved<br />restore verification.</div>"]
      style 19 fill:#ecfeff,stroke:#0891b2,color:#111827
      20["<div style='font-weight: bold'>Restricted NAS Runtime SSH Boundary</div><div style='font-size: 70%; margin-top: 0px'>[Container: OpenSSH forced command + sudoers + ZFS refquota]</div><div style='font-size: 80%; margin-top:10px'>Dedicated runtime NAS<br />user/key, pinned host-key<br />verification, forced-command<br />dispatcher, sudo allowlist,<br />and refquota-backed<br />current-tree write boundary.</div>"]
      style 20 fill:#ecfeff,stroke:#0891b2,color:#111827
      24["<div style='font-weight: bold'>Failure Notifier</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + Python urllib]</div><div style='font-size: 80%; margin-top:10px'>Best-effort Telegram failure<br />alert unit that reads last<br />status/log tail and Hermes<br />bot environment variables;<br />success runs stay silent.</div>"]
      style 24 fill:#ecfeff,stroke:#0891b2,color:#111827
      25[("<div style='font-weight: bold'>Run Ledger and Local State</div><div style='font-size: 70%; margin-top: 0px'>[Container: SQLite + JSON + logs on WSL filesystem]</div><div style='font-size: 80%; margin-top:10px'>Local status, pruned logs,<br />SQLite run ledger, exported<br />run-history JSON, SQLite<br />snapshot cache, and Windows<br />manifest cache under<br />~/.local/state/workstation-workflow-backup.</div>")]
      style 25 fill:#fef3c7,stroke:#d97706,color:#111827
      3("<div style='font-weight: bold'>systemd User Timer and Service</div><div style='font-size: 70%; margin-top: 0px'>[Container: systemd --user units]</div><div style='font-size: 80%; margin-top:10px'>Hourly user-level scheduler<br />and oneshot service that run<br />the backup at minute 45 and<br />route failures to the<br />notifier.</div>")
      style 3 fill:#e0e7ff,stroke:#4f46e5,color:#111827
      4["<div style='font-weight: bold'>Backup Orchestrator</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash]</div><div style='font-size: 80%; margin-top:10px'>scripts/workflow-backup.sh<br />coordinates one backup run:<br />locking, log pruning,<br />pre/post guard checks, WSL<br />rsync, SQLite snapshots,<br />Windows sync, strict final<br />ledger updates, NAS manifest<br />publication, and<br />restore-checksum generation.</div>"]
      style 4 fill:#e0f2fe,stroke:#0284c7,color:#111827
    end

    3-. "<div>Starts hourly at :45 and<br />tracks service exit</div><div style='font-size: 70%'>[systemd --user]</div>" .->4
    3-. "<div>Triggers on nonzero service<br />result</div><div style='font-size: 70%'>[OnFailure]</div>" .->24
    4-. "<div>Writes logs, last-run.json,<br />run events, and exported<br />history in</div><div style='font-size: 70%'>[filesystem + sqlite3]</div>" .->25
    4-. "<div>Runs pre/post budget checks<br />through</div><div style='font-size: 70%'>[subprocess]</div>" .->18
    18-. "<div>Reads ZFS used, availability,<br />usedbysnapshots, and snapshot<br />count from</div><div style='font-size: 70%'>[NAS-side helper + zfs]</div>" .->29
    4-. "<div>Creates consistent SQLite<br />backup copies with</div><div style='font-size: 70%'>[subprocess]</div>" .->16
    16-. "<div>Reads live SQLite databases<br />from</div><div style='font-size: 70%'>[sqlite3 backup API]</div>" .->26
    16-. "<div>Writes local SQLite snapshot<br />cache and manifest under</div><div style='font-size: 70%'>[filesystem]</div>" .->25
    4-. "<div>Mirrors configured WSL source<br />trees from</div><div style='font-size: 70%'>[sudo rsync]</div>" .->26
    4-. "<div>Connects with dedicated<br />runtime key and pinned<br />host-key verification through</div><div style='font-size: 70%'>[SSH]</div>" .->20
    20-. "<div>Allows receiver-mode rsync<br />and mkdir only under current<br />tree</div><div style='font-size: 70%'>[forced command + rsync]</div>" .->28
    20-. "<div>Allows sudo execution of<br />guard helper only</div><div style='font-size: 70%'>[forced command + sudo]</div>" .->18
    20-. "<div>Allows sudo execution of<br />integrity helper only</div><div style='font-size: 70%'>[forced command + sudo]</div>" .->19
    4-. "<div>Writes current/wsl,<br />wsl-sqlite-snapshots, and<br />_manifests to</div><div style='font-size: 70%'>[restricted SSH rsync]</div>" .->28
    4-. "<div>Launches Windows sync through</div><div style='font-size: 70%'>[PowerShell via WSL interop]</div>" .->17
    17-. "<div>Mirrors selected Windows<br />artifacts from</div><div style='font-size: 70%'>[robocopy.exe]</div>" .->27
    17-. "<div>Writes current/windows and<br />Windows manifests to</div><div style='font-size: 70%'>[SMB share]</div>" .->28
    17-. "<div>Leaves manifest cache for<br />ledger summaries</div><div style='font-size: 70%'></div>" .->25
    4-. "<div>Runs restore-critical<br />checksum manifest generation<br />through</div><div style='font-size: 70%'>[restricted SSH]</div>" .->19
    19-. "<div>Hashes NAS current-tree<br />critical artifacts and writes<br />integrity-manifest.json to</div><div style='font-size: 70%'>[SHA-256 + filesystem]</div>" .->28
    4-. "<div>Exits nonzero so systemd can<br />alert through</div><div style='font-size: 70%'></div>" .->24
    24-. "<div>Reads last status and log<br />tail from</div><div style='font-size: 70%'>[filesystem]</div>" .->25
    24-. "<div>Reads Telegram bot token/chat<br />values from</div><div style='font-size: 70%'>[filesystem]</div>" .->30
    24-. "<div>Sends failure-only<br />notification to</div><div style='font-size: 70%'>[HTTPS]</div>" .->31

  end
```

</details>

### Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-BackupRuntimeContainers.mmd`](diagrams/structurizr-BackupRuntimeContainers.mmd) |
| Mermaid SVG | [`structurizr-BackupRuntimeContainers.svg`](diagrams/structurizr-BackupRuntimeContainers.svg) |
| Mermaid PNG | [`structurizr-BackupRuntimeContainers.png`](diagrams/structurizr-BackupRuntimeContainers.png) |
| DOT source | [`structurizr-BackupRuntimeContainers.dot`](diagrams/dot/structurizr-BackupRuntimeContainers.dot) |
| Graphviz SVG | [`structurizr-BackupRuntimeContainers.svg`](diagrams/dot-rendered/structurizr-BackupRuntimeContainers.svg) |
| Graphviz PNG | [`structurizr-BackupRuntimeContainers.png`](diagrams/dot-rendered/structurizr-BackupRuntimeContainers.png) |


---

## Failure Alert Flow

> C4 view `FailureAlertFlow`.

### Diagram

![Failure Alert Flow](diagrams/dot-rendered/structurizr-FailureAlertFlow.svg)

_Preferred Markdown display: Graphviz SVG. Mermaid source is retained below for text review._

<details>
<summary>Mermaid source</summary>

```mermaid
graph LR
  linkStyle default fill:#ffffff

  subgraph diagram ["Dynamic View: WORKSTATION1 Workflow Backup"]
    style diagram fill:#ffffff,stroke:#ffffff

    subgraph 2 ["WORKSTATION1 Workflow Backup"]
      style 2 fill:#ffffff,stroke:#16a34a,color:#16a34a

      24["<div style='font-weight: bold'>Failure Notifier</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + Python urllib]</div><div style='font-size: 80%; margin-top:10px'>Best-effort Telegram failure<br />alert unit that reads last<br />status/log tail and Hermes<br />bot environment variables;<br />success runs stay silent.</div>"]
      style 24 fill:#ecfeff,stroke:#0891b2,color:#111827
      25[("<div style='font-weight: bold'>Run Ledger and Local State</div><div style='font-size: 70%; margin-top: 0px'>[Container: SQLite + JSON + logs on WSL filesystem]</div><div style='font-size: 80%; margin-top:10px'>Local status, pruned logs,<br />SQLite run ledger, exported<br />run-history JSON, SQLite<br />snapshot cache, and Windows<br />manifest cache under<br />~/.local/state/workstation-workflow-backup.</div>")]
      style 25 fill:#fef3c7,stroke:#d97706,color:#111827
      3("<div style='font-weight: bold'>systemd User Timer and Service</div><div style='font-size: 70%; margin-top: 0px'>[Container: systemd --user units]</div><div style='font-size: 80%; margin-top:10px'>Hourly user-level scheduler<br />and oneshot service that run<br />the backup at minute 45 and<br />route failures to the<br />notifier.</div>")
      style 3 fill:#e0e7ff,stroke:#4f46e5,color:#111827
      4["<div style='font-weight: bold'>Backup Orchestrator</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash]</div><div style='font-size: 80%; margin-top:10px'>scripts/workflow-backup.sh<br />coordinates one backup run:<br />locking, log pruning,<br />pre/post guard checks, WSL<br />rsync, SQLite snapshots,<br />Windows sync, strict final<br />ledger updates, NAS manifest<br />publication, and<br />restore-checksum generation.</div>"]
      style 4 fill:#e0f2fe,stroke:#0284c7,color:#111827
    end

    28[("<div style='font-weight: bold'>TrueNAS Backup Dataset</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured encrypted TrueNAS<br />dataset with current mirror<br />tree, manifests, SMB share,<br />restore checksum manifest,<br />refquota, and ZFS snapshot<br />history.</div>")]
    style 28 fill:#fef3c7,stroke:#d97706,color:#111827
    30[("<div style='font-weight: bold'>Hermes Bot Environment File</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Local ~/.hermes/.env values<br />that supply Telegram bot<br />token/chat settings to the<br />failure notifier; contents<br />are not stored in this repo.</div>")]
    style 30 fill:#fef3c7,stroke:#d97706,color:#111827
    31["<div style='font-weight: bold'>Telegram Bot API</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>External API used only for<br />backup failure notifications.</div>"]
    style 31 fill:#f3e8ff,stroke:#9333ea,color:#111827

    4-. "<div>1. Write failed<br />last-run/log/ledger event</div><div style='font-size: 70%'>[filesystem + sqlite3]</div>" .->25
    4-. "<div>2. Best-effort publish<br />failure manifests</div><div style='font-size: 70%'>[restricted SSH rsync]</div>" .->28
    4-. "<div>3. Exit nonzero</div><div style='font-size: 70%'>[systemd --user]</div>" .->3
    3-. "<div>4. Invoke OnFailure notifier</div><div style='font-size: 70%'>[OnFailure]</div>" .->24
    24-. "<div>5. Read last-run.json and log<br />tail</div><div style='font-size: 70%'>[filesystem]</div>" .->25
    24-. "<div>6. Load bot token/chat<br />settings</div><div style='font-size: 70%'>[filesystem]</div>" .->30
    24-. "<div>7. sendMessage backup failure<br />alert</div><div style='font-size: 70%'>[HTTPS]</div>" .->31

  end
```

</details>

### Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-FailureAlertFlow.mmd`](diagrams/structurizr-FailureAlertFlow.mmd) |
| Mermaid SVG | [`structurizr-FailureAlertFlow.svg`](diagrams/structurizr-FailureAlertFlow.svg) |
| Mermaid PNG | [`structurizr-FailureAlertFlow.png`](diagrams/structurizr-FailureAlertFlow.png) |
| DOT source | [`structurizr-FailureAlertFlow.dot`](diagrams/dot/structurizr-FailureAlertFlow.dot) |
| Graphviz SVG | [`structurizr-FailureAlertFlow.svg`](diagrams/dot-rendered/structurizr-FailureAlertFlow.svg) |
| Graphviz PNG | [`structurizr-FailureAlertFlow.png`](diagrams/dot-rendered/structurizr-FailureAlertFlow.png) |


---

## Hourly Mirror Publish Flow

> C4 view `HourlyMirrorPublishFlow`.

### Diagram

![Hourly Mirror Publish Flow](diagrams/dot-rendered/structurizr-HourlyMirrorPublishFlow.svg)

_Preferred Markdown display: Graphviz SVG. Mermaid source is retained below for text review._

<details>
<summary>Mermaid source</summary>

```mermaid
graph LR
  linkStyle default fill:#ffffff

  subgraph diagram ["Dynamic View: WORKSTATION1 Workflow Backup"]
    style diagram fill:#ffffff,stroke:#ffffff

    subgraph 2 ["WORKSTATION1 Workflow Backup"]
      style 2 fill:#ffffff,stroke:#16a34a,color:#16a34a

      17["<div style='font-weight: bold'>Windows Critical Sync Helper</div><div style='font-size: 70%; margin-top: 0px'>[Container: PowerShell + robocopy.exe]</div><div style='font-size: 80%; margin-top:10px'>PowerShell script launched<br />from WSL that uses<br />robocopy.exe to mirror<br />selected Windows profile<br />directories/files to the SMB<br />share and writes a Windows<br />sync manifest.</div>"]
      style 17 fill:#ecfeff,stroke:#0891b2,color:#111827
      18["<div style='font-weight: bold'>NAS Growth Guard</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + NAS sudo helper + zfs CLI]</div><div style='font-size: 80%; margin-top:10px'>Read-only NAS-side ZFS budget<br />check that enforces<br />dataset-used, snapshot-held,<br />availability-dataset<br />free-space, and<br />snapshot-count limits<br />before/after writes.</div>"]
      style 18 fill:#ecfeff,stroke:#0891b2,color:#111827
      19["<div style='font-weight: bold'>NAS Integrity Manifest Builder</div><div style='font-size: 70%; margin-top: 0px'>[Container: Python + SHA-256]</div><div style='font-size: 80%; margin-top:10px'>NAS-side helper that hashes<br />restore-critical current-tree<br />artifacts and writes<br />_manifests/integrity-manifest.json<br />for snapshot-preserved<br />restore verification.</div>"]
      style 19 fill:#ecfeff,stroke:#0891b2,color:#111827
      25[("<div style='font-weight: bold'>Run Ledger and Local State</div><div style='font-size: 70%; margin-top: 0px'>[Container: SQLite + JSON + logs on WSL filesystem]</div><div style='font-size: 80%; margin-top:10px'>Local status, pruned logs,<br />SQLite run ledger, exported<br />run-history JSON, SQLite<br />snapshot cache, and Windows<br />manifest cache under<br />~/.local/state/workstation-workflow-backup.</div>")]
      style 25 fill:#fef3c7,stroke:#d97706,color:#111827
      4["<div style='font-weight: bold'>Backup Orchestrator</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash]</div><div style='font-size: 80%; margin-top:10px'>scripts/workflow-backup.sh<br />coordinates one backup run:<br />locking, log pruning,<br />pre/post guard checks, WSL<br />rsync, SQLite snapshots,<br />Windows sync, strict final<br />ledger updates, NAS manifest<br />publication, and<br />restore-checksum generation.</div>"]
      style 4 fill:#e0f2fe,stroke:#0284c7,color:#111827
    end

    26[("<div style='font-weight: bold'>WSL Workflow Sources</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Workflow-critical WSL paths:<br />~/repos, ~/.hermes, ~/.ssh,<br />systemd user config,<br />lifelog/browser-memory data,<br />and optional brain-code tree.</div>")]
    style 26 fill:#fef3c7,stroke:#d97706,color:#111827
    27[("<div style='font-weight: bold'>Windows Workflow Sources</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Selected Windows user-profile<br />artifacts: Desktop,<br />Documents, Downloads, Windows<br />.ssh/.wslconfig, Terminal/VS<br />Code/PowerShell config,<br />Chrome profile metadata, and<br />Startup entries.</div>")]
    style 27 fill:#fef3c7,stroke:#d97706,color:#111827
    28[("<div style='font-weight: bold'>TrueNAS Backup Dataset</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured encrypted TrueNAS<br />dataset with current mirror<br />tree, manifests, SMB share,<br />restore checksum manifest,<br />refquota, and ZFS snapshot<br />history.</div>")]
    style 28 fill:#fef3c7,stroke:#d97706,color:#111827
    29["<div style='font-weight: bold'>TrueNAS Middleware and ZFS Control Plane</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured admin SSH and<br />middleware surface used for<br />ZFS properties, runtime-user<br />setup, snapshot tasks, SMB<br />share configuration, and<br />verification.</div>"]
    style 29 fill:#f3e8ff,stroke:#9333ea,color:#111827

    4-. "<div>1. Read WSL source trees</div><div style='font-size: 70%'>[sudo rsync]</div>" .->26
    4-. "<div>2. Mirror WSL current tree</div><div style='font-size: 70%'>[restricted SSH rsync]</div>" .->28
    4-. "<div>3. Launch PowerShell robocopy<br />helper</div><div style='font-size: 70%'>[PowerShell via WSL interop]</div>" .->17
    17-. "<div>4. Read selected Windows<br />artifacts</div><div style='font-size: 70%'>[robocopy.exe]</div>" .->27
    17-. "<div>5. Mirror Windows current<br />tree and manifest</div><div style='font-size: 70%'>[SMB share]</div>" .->28
    4-. "<div>6. Run post-write guard</div><div style='font-size: 70%'>[subprocess]</div>" .->18
    18-. "<div>7. Read ZFS budget values</div><div style='font-size: 70%'>[NAS-side helper + zfs]</div>" .->29
    4-. "<div>8. Record completed event and<br />export history</div><div style='font-size: 70%'>[filesystem + sqlite3]</div>" .->25
    4-. "<div>9. Publish _manifests status<br />files</div><div style='font-size: 70%'>[restricted SSH rsync]</div>" .->28
    4-. "<div>10. Build restore checksum<br />manifest</div><div style='font-size: 70%'>[restricted SSH]</div>" .->19
    19-. "<div>11. Write<br />integrity-manifest.json</div><div style='font-size: 70%'>[SHA-256 + filesystem]</div>" .->28

  end
```

</details>

### Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-HourlyMirrorPublishFlow.mmd`](diagrams/structurizr-HourlyMirrorPublishFlow.mmd) |
| Mermaid SVG | [`structurizr-HourlyMirrorPublishFlow.svg`](diagrams/structurizr-HourlyMirrorPublishFlow.svg) |
| Mermaid PNG | [`structurizr-HourlyMirrorPublishFlow.png`](diagrams/structurizr-HourlyMirrorPublishFlow.png) |
| DOT source | [`structurizr-HourlyMirrorPublishFlow.dot`](diagrams/dot/structurizr-HourlyMirrorPublishFlow.dot) |
| Graphviz SVG | [`structurizr-HourlyMirrorPublishFlow.svg`](diagrams/dot-rendered/structurizr-HourlyMirrorPublishFlow.svg) |
| Graphviz PNG | [`structurizr-HourlyMirrorPublishFlow.png`](diagrams/dot-rendered/structurizr-HourlyMirrorPublishFlow.png) |


---

## Hourly Preflight Snapshot Flow

> C4 view `HourlyPreflightSnapshotFlow`.

### Diagram

![Hourly Preflight Snapshot Flow](diagrams/dot-rendered/structurizr-HourlyPreflightSnapshotFlow.svg)

_Preferred Markdown display: Graphviz SVG. Mermaid source is retained below for text review._

<details>
<summary>Mermaid source</summary>

```mermaid
graph LR
  linkStyle default fill:#ffffff

  subgraph diagram ["Dynamic View: WORKSTATION1 Workflow Backup"]
    style diagram fill:#ffffff,stroke:#ffffff

    subgraph 2 ["WORKSTATION1 Workflow Backup"]
      style 2 fill:#ffffff,stroke:#16a34a,color:#16a34a

      16["<div style='font-weight: bold'>SQLite Snapshotter</div><div style='font-size: 70%; margin-top: 0px'>[Container: Python 3, sqlite3]</div><div style='font-size: 80%; margin-top:10px'>Creates<br />application-consistent copies<br />of Hermes, lifelog,<br />browser-memory, and related<br />SQLite databases using<br />sqlite3 backup API; can<br />quick_check copies.</div>"]
      style 16 fill:#ecfeff,stroke:#0891b2,color:#111827
      18["<div style='font-weight: bold'>NAS Growth Guard</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + NAS sudo helper + zfs CLI]</div><div style='font-size: 80%; margin-top:10px'>Read-only NAS-side ZFS budget<br />check that enforces<br />dataset-used, snapshot-held,<br />availability-dataset<br />free-space, and<br />snapshot-count limits<br />before/after writes.</div>"]
      style 18 fill:#ecfeff,stroke:#0891b2,color:#111827
      20["<div style='font-weight: bold'>Restricted NAS Runtime SSH Boundary</div><div style='font-size: 70%; margin-top: 0px'>[Container: OpenSSH forced command + sudoers + ZFS refquota]</div><div style='font-size: 80%; margin-top:10px'>Dedicated runtime NAS<br />user/key, pinned host-key<br />verification, forced-command<br />dispatcher, sudo allowlist,<br />and refquota-backed<br />current-tree write boundary.</div>"]
      style 20 fill:#ecfeff,stroke:#0891b2,color:#111827
      25[("<div style='font-weight: bold'>Run Ledger and Local State</div><div style='font-size: 70%; margin-top: 0px'>[Container: SQLite + JSON + logs on WSL filesystem]</div><div style='font-size: 80%; margin-top:10px'>Local status, pruned logs,<br />SQLite run ledger, exported<br />run-history JSON, SQLite<br />snapshot cache, and Windows<br />manifest cache under<br />~/.local/state/workstation-workflow-backup.</div>")]
      style 25 fill:#fef3c7,stroke:#d97706,color:#111827
      3("<div style='font-weight: bold'>systemd User Timer and Service</div><div style='font-size: 70%; margin-top: 0px'>[Container: systemd --user units]</div><div style='font-size: 80%; margin-top:10px'>Hourly user-level scheduler<br />and oneshot service that run<br />the backup at minute 45 and<br />route failures to the<br />notifier.</div>")
      style 3 fill:#e0e7ff,stroke:#4f46e5,color:#111827
      4["<div style='font-weight: bold'>Backup Orchestrator</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash]</div><div style='font-size: 80%; margin-top:10px'>scripts/workflow-backup.sh<br />coordinates one backup run:<br />locking, log pruning,<br />pre/post guard checks, WSL<br />rsync, SQLite snapshots,<br />Windows sync, strict final<br />ledger updates, NAS manifest<br />publication, and<br />restore-checksum generation.</div>"]
      style 4 fill:#e0f2fe,stroke:#0284c7,color:#111827
    end

    26[("<div style='font-weight: bold'>WSL Workflow Sources</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Workflow-critical WSL paths:<br />~/repos, ~/.hermes, ~/.ssh,<br />systemd user config,<br />lifelog/browser-memory data,<br />and optional brain-code tree.</div>")]
    style 26 fill:#fef3c7,stroke:#d97706,color:#111827
    28[("<div style='font-weight: bold'>TrueNAS Backup Dataset</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured encrypted TrueNAS<br />dataset with current mirror<br />tree, manifests, SMB share,<br />restore checksum manifest,<br />refquota, and ZFS snapshot<br />history.</div>")]
    style 28 fill:#fef3c7,stroke:#d97706,color:#111827
    29["<div style='font-weight: bold'>TrueNAS Middleware and ZFS Control Plane</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured admin SSH and<br />middleware surface used for<br />ZFS properties, runtime-user<br />setup, snapshot tasks, SMB<br />share configuration, and<br />verification.</div>"]
    style 29 fill:#f3e8ff,stroke:#9333ea,color:#111827

    3-. "<div>1. Start oneshot backup<br />service</div><div style='font-size: 70%'>[systemd --user]</div>" .->4
    4-. "<div>2. Record started event and<br />open log</div><div style='font-size: 70%'>[filesystem + sqlite3]</div>" .->25
    4-. "<div>3. Run pre-write guard</div><div style='font-size: 70%'>[subprocess]</div>" .->18
    18-. "<div>4. Read ZFS budget values</div><div style='font-size: 70%'>[NAS-side helper + zfs]</div>" .->29
    4-. "<div>5. Snapshot live SQLite DBs</div><div style='font-size: 70%'>[subprocess]</div>" .->16
    16-. "<div>6. Read live SQLite databases</div><div style='font-size: 70%'>[sqlite3 backup API]</div>" .->26
    16-. "<div>7. Write snapshot<br />manifest/cache</div><div style='font-size: 70%'>[filesystem]</div>" .->25
    4-. "<div>8. Open restricted runtime<br />SSH session</div><div style='font-size: 70%'>[SSH]</div>" .->20
    4-. "<div>9. Mirror SQLite snapshot<br />tree</div><div style='font-size: 70%'>[restricted SSH rsync]</div>" .->28

  end
```

</details>

### Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-HourlyPreflightSnapshotFlow.mmd`](diagrams/structurizr-HourlyPreflightSnapshotFlow.mmd) |
| Mermaid SVG | [`structurizr-HourlyPreflightSnapshotFlow.svg`](diagrams/structurizr-HourlyPreflightSnapshotFlow.svg) |
| Mermaid PNG | [`structurizr-HourlyPreflightSnapshotFlow.png`](diagrams/structurizr-HourlyPreflightSnapshotFlow.png) |
| DOT source | [`structurizr-HourlyPreflightSnapshotFlow.dot`](diagrams/dot/structurizr-HourlyPreflightSnapshotFlow.dot) |
| Graphviz SVG | [`structurizr-HourlyPreflightSnapshotFlow.svg`](diagrams/dot-rendered/structurizr-HourlyPreflightSnapshotFlow.svg) |
| Graphviz PNG | [`structurizr-HourlyPreflightSnapshotFlow.png`](diagrams/dot-rendered/structurizr-HourlyPreflightSnapshotFlow.png) |


---

## Local Deployment

> C4 view `LocalDeployment`.

### Diagram

![Local Deployment](diagrams/dot-rendered/structurizr-LocalDeployment.svg)

_Preferred Markdown display: Graphviz SVG. Mermaid source is retained below for text review._

<details>
<summary>Mermaid source</summary>

```mermaid
graph TB
  linkStyle default fill:#ffffff

  subgraph diagram ["Deployment View: WORKSTATION1 Workflow Backup - WORKSTATION1 local plus TrueNAS"]
    style diagram fill:#ffffff,stroke:#ffffff

    subgraph 134 ["Configured TrueNAS host"]
      style 134 fill:#ffffff,stroke:#444444,color:#444444

      135["<div style='font-weight: bold'>Encrypted ZFS backup dataset</div><div style='font-size: 70%; margin-top: 0px'>[Infrastructure Node: ZFS dataset]</div><div style='font-size: 80%; margin-top:10px'>Backup current tree,<br />manifests, integrity<br />manifest, refquota, and<br />snapshot history under the<br />configured NAS path.</div>"]
      style 135 fill:#f8fafc,stroke:#64748b,color:#111827
      136["<div style='font-weight: bold'>Restricted runtime SSH user/key</div><div style='font-size: 70%; margin-top: 0px'>[Infrastructure Node: OpenSSH authorized_keys]</div><div style='font-size: 80%; margin-top:10px'>Forced-command receiver for<br />rsync writes, guard helper,<br />and integrity helper; no<br />interactive shell path.</div>"]
      style 136 fill:#f8fafc,stroke:#64748b,color:#111827
      137["<div style='font-weight: bold'>SMB backup share</div><div style='font-size: 70%; margin-top: 0px'>[Infrastructure Node: Samba SMB]</div><div style='font-size: 80%; margin-top:10px'>Windows helper destination<br />with shadow-copy support and<br />mangled names disabled.</div>"]
      style 137 fill:#f8fafc,stroke:#64748b,color:#111827
      138["<div style='font-weight: bold'>TrueNAS periodic snapshot tasks</div><div style='font-size: 70%; margin-top: 0px'>[Infrastructure Node: TrueNAS middleware]</div><div style='font-size: 80%; margin-top:10px'>wf-h/wf-d/wf-w/wf-m snapshot<br />tasks with 2d/2w/8w/1y<br />lifetimes.</div>"]
      style 138 fill:#f8fafc,stroke:#64748b,color:#111827
    end

    subgraph 139 ["Telegram"]
      style 139 fill:#ffffff,stroke:#444444,color:#444444

      140["<div style='font-weight: bold'>Telegram Bot API</div><div style='font-size: 70%; margin-top: 0px'>[Infrastructure Node: HTTPS]</div><div style='font-size: 80%; margin-top:10px'>HTTPS sendMessage endpoint<br />reached by the failure<br />notifier.</div>"]
      style 140 fill:#f8fafc,stroke:#64748b,color:#111827
    end

    subgraph 98 ["WORKSTATION1"]
      style 98 fill:#ffffff,stroke:#444444,color:#444444

      subgraph 129 ["Windows user profile"]
        style 129 fill:#ffffff,stroke:#444444,color:#444444

        130["<div style='font-weight: bold'>Windows Critical Sync Helper</div><div style='font-size: 70%; margin-top: 0px'>[Container: PowerShell + robocopy.exe]</div><div style='font-size: 80%; margin-top:10px'>PowerShell script launched<br />from WSL that uses<br />robocopy.exe to mirror<br />selected Windows profile<br />directories/files to the SMB<br />share and writes a Windows<br />sync manifest.</div>"]
        style 130 fill:#ecfeff,stroke:#0891b2,color:#111827
        133["<div style='font-weight: bold'>Selected Windows source artifacts</div><div style='font-size: 70%; margin-top: 0px'>[Infrastructure Node: NTFS]</div><div style='font-size: 80%; margin-top:10px'>Desktop, Documents,<br />Downloads, .ssh, .wslconfig,<br />Windows Terminal, VS Code,<br />PowerShell, Chrome profile<br />metadata, and Startup<br />entries.</div>"]
        style 133 fill:#f8fafc,stroke:#64748b,color:#111827
      end

      subgraph 99 ["WSL2 Ubuntu-22.04"]
        style 99 fill:#ffffff,stroke:#444444,color:#444444

        subgraph 100 ["systemd --user"]
          style 100 fill:#ffffff,stroke:#444444,color:#444444

          101("<div style='font-weight: bold'>systemd User Timer and Service</div><div style='font-size: 70%; margin-top: 0px'>[Container: systemd --user units]</div><div style='font-size: 80%; margin-top:10px'>Hourly user-level scheduler<br />and oneshot service that run<br />the backup at minute 45 and<br />route failures to the<br />notifier.</div>")
          style 101 fill:#e0e7ff,stroke:#4f46e5,color:#111827
          102["<div style='font-weight: bold'>Backup Orchestrator</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash]</div><div style='font-size: 80%; margin-top:10px'>scripts/workflow-backup.sh<br />coordinates one backup run:<br />locking, log pruning,<br />pre/post guard checks, WSL<br />rsync, SQLite snapshots,<br />Windows sync, strict final<br />ledger updates, NAS manifest<br />publication, and<br />restore-checksum generation.</div>"]
          style 102 fill:#e0f2fe,stroke:#0284c7,color:#111827
          104["<div style='font-weight: bold'>Failure Notifier</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + Python urllib]</div><div style='font-size: 80%; margin-top:10px'>Best-effort Telegram failure<br />alert unit that reads last<br />status/log tail and Hermes<br />bot environment variables;<br />success runs stay silent.</div>"]
          style 104 fill:#ecfeff,stroke:#0891b2,color:#111827
        end

        subgraph 107 ["Repo scripts"]
          style 107 fill:#ffffff,stroke:#444444,color:#444444

          108["<div style='font-weight: bold'>SQLite Snapshotter</div><div style='font-size: 70%; margin-top: 0px'>[Container: Python 3, sqlite3]</div><div style='font-size: 80%; margin-top:10px'>Creates<br />application-consistent copies<br />of Hermes, lifelog,<br />browser-memory, and related<br />SQLite databases using<br />sqlite3 backup API; can<br />quick_check copies.</div>"]
          style 108 fill:#ecfeff,stroke:#0891b2,color:#111827
          110["<div style='font-weight: bold'>NAS Growth Guard</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + NAS sudo helper + zfs CLI]</div><div style='font-size: 80%; margin-top:10px'>Read-only NAS-side ZFS budget<br />check that enforces<br />dataset-used, snapshot-held,<br />availability-dataset<br />free-space, and<br />snapshot-count limits<br />before/after writes.</div>"]
          style 110 fill:#ecfeff,stroke:#0891b2,color:#111827
          112["<div style='font-weight: bold'>NAS Integrity Manifest Builder</div><div style='font-size: 70%; margin-top: 0px'>[Container: Python + SHA-256]</div><div style='font-size: 80%; margin-top:10px'>NAS-side helper that hashes<br />restore-critical current-tree<br />artifacts and writes<br />_manifests/integrity-manifest.json<br />for snapshot-preserved<br />restore verification.</div>"]
          style 112 fill:#ecfeff,stroke:#0891b2,color:#111827
          114["<div style='font-weight: bold'>Restricted NAS Runtime SSH Boundary</div><div style='font-size: 70%; margin-top: 0px'>[Container: OpenSSH forced command + sudoers + ZFS refquota]</div><div style='font-size: 80%; margin-top:10px'>Dedicated runtime NAS<br />user/key, pinned host-key<br />verification, forced-command<br />dispatcher, sudo allowlist,<br />and refquota-backed<br />current-tree write boundary.</div>"]
          style 114 fill:#ecfeff,stroke:#0891b2,color:#111827
          118["<div style='font-weight: bold'>NAS Provisioner</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + admin SSH + remote Python + midclt/zfs]</div><div style='font-size: 80%; margin-top:10px'>Idempotent provisioning<br />script for the TrueNAS<br />dataset, SMB share, periodic<br />snapshot tasks, refquota, and<br />retired legacy snapshot cron<br />jobs.</div>"]
          style 118 fill:#ecfeff,stroke:#0891b2,color:#111827
          119["<div style='font-weight: bold'>NAS Runtime Hardening Installer</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + admin SSH + TrueNAS middleware]</div><div style='font-size: 80%; margin-top:10px'>Installs or updates the<br />dedicated runtime user/key,<br />forced-command dispatcher,<br />NAS-side guard/integrity<br />helpers, sudo allowlist,<br />runtime-writable subtrees,<br />host-key pinning config, and<br />dataset refquota.</div>"]
          style 119 fill:#ecfeff,stroke:#0891b2,color:#111827
          120["<div style='font-weight: bold'>Backup Verifier</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + systemctl + SSH]</div><div style='font-size: 80%; margin-top:10px'>Operational verification<br />script that checks the local<br />timer, last status, run<br />ledger, growth guard, NAS<br />dataset, snapshots,<br />manifests, integrity summary,<br />snapshot tasks, and retired<br />cron jobs.</div>"]
          style 120 fill:#ecfeff,stroke:#0891b2,color:#111827
        end

        subgraph 123 ["Local backup state"]
          style 123 fill:#ffffff,stroke:#444444,color:#444444

          124[("<div style='font-weight: bold'>Run Ledger and Local State</div><div style='font-size: 70%; margin-top: 0px'>[Container: SQLite + JSON + logs on WSL filesystem]</div><div style='font-size: 80%; margin-top:10px'>Local status, pruned logs,<br />SQLite run ledger, exported<br />run-history JSON, SQLite<br />snapshot cache, and Windows<br />manifest cache under<br />~/.local/state/workstation-workflow-backup.</div>")]
          style 124 fill:#fef3c7,stroke:#d97706,color:#111827
        end

      end

    end

    101-. "<div>Starts hourly at :45 and<br />tracks service exit</div><div style='font-size: 70%'>[systemd --user]</div>" .->102
    101-. "<div>Triggers on nonzero service<br />result</div><div style='font-size: 70%'>[OnFailure]</div>" .->104
    102-. "<div>Exits nonzero so systemd can<br />alert through</div><div style='font-size: 70%'></div>" .->104
    102-. "<div>Creates consistent SQLite<br />backup copies with</div><div style='font-size: 70%'>[subprocess]</div>" .->108
    102-. "<div>Runs pre/post budget checks<br />through</div><div style='font-size: 70%'>[subprocess]</div>" .->110
    102-. "<div>Runs restore-critical<br />checksum manifest generation<br />through</div><div style='font-size: 70%'>[restricted SSH]</div>" .->112
    102-. "<div>Connects with dedicated<br />runtime key and pinned<br />host-key verification through</div><div style='font-size: 70%'>[SSH]</div>" .->114
    114-. "<div>Allows sudo execution of<br />guard helper only</div><div style='font-size: 70%'>[forced command + sudo]</div>" .->110
    114-. "<div>Allows sudo execution of<br />integrity helper only</div><div style='font-size: 70%'>[forced command + sudo]</div>" .->112
    120-. "<div>Checks enabled/active timer<br />state through</div><div style='font-size: 70%'>[systemctl --user]</div>" .->101
    120-. "<div>Runs read-only guard<br />verification through</div><div style='font-size: 70%'>[subprocess]</div>" .->110
    102-. "<div>Writes logs, last-run.json,<br />run events, and exported<br />history in</div><div style='font-size: 70%'>[filesystem + sqlite3]</div>" .->124
    104-. "<div>Reads last status and log<br />tail from</div><div style='font-size: 70%'>[filesystem]</div>" .->124
    108-. "<div>Writes local SQLite snapshot<br />cache and manifest under</div><div style='font-size: 70%'>[filesystem]</div>" .->124
    120-. "<div>Reads local last status and<br />recent run ledger from</div><div style='font-size: 70%'>[filesystem + sqlite3]</div>" .->124
    102-. "<div>Launches Windows sync through</div><div style='font-size: 70%'>[PowerShell via WSL interop]</div>" .->130
    130-. "<div>Leaves manifest cache for<br />ledger summaries</div><div style='font-size: 70%'></div>" .->124

  end
```

</details>

### Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-LocalDeployment.mmd`](diagrams/structurizr-LocalDeployment.mmd) |
| Mermaid SVG | [`structurizr-LocalDeployment.svg`](diagrams/structurizr-LocalDeployment.svg) |
| Mermaid PNG | [`structurizr-LocalDeployment.png`](diagrams/structurizr-LocalDeployment.png) |
| DOT source | [`structurizr-LocalDeployment.dot`](diagrams/dot/structurizr-LocalDeployment.dot) |
| Graphviz SVG | [`structurizr-LocalDeployment.svg`](diagrams/dot-rendered/structurizr-LocalDeployment.svg) |
| Graphviz PNG | [`structurizr-LocalDeployment.png`](diagrams/dot-rendered/structurizr-LocalDeployment.png) |


---

## Ops Provisioning Containers

> C4 view `OpsProvisioningContainers`.

### Diagram

![Ops Provisioning Containers](diagrams/dot-rendered/structurizr-OpsProvisioningContainers.svg)

_Preferred Markdown display: Graphviz SVG. Mermaid source is retained below for text review._

<details>
<summary>Mermaid source</summary>

```mermaid
graph LR
  linkStyle default fill:#ffffff

  subgraph diagram ["Container View: WORKSTATION1 Workflow Backup"]
    style diagram fill:#ffffff,stroke:#ffffff

    1["<div style='font-weight: bold'>Michael</div><div style='font-size: 70%; margin-top: 0px'>[Person]</div><div style='font-size: 80%; margin-top:10px'>Sole operator who installs,<br />verifies, and restores<br />WORKSTATION1 workflow<br />backups.</div>"]
    style 1 fill:#dbeafe,stroke:#2563eb,color:#111827
    28[("<div style='font-weight: bold'>TrueNAS Backup Dataset</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured encrypted TrueNAS<br />dataset with current mirror<br />tree, manifests, SMB share,<br />restore checksum manifest,<br />refquota, and ZFS snapshot<br />history.</div>")]
    style 28 fill:#fef3c7,stroke:#d97706,color:#111827
    29["<div style='font-weight: bold'>TrueNAS Middleware and ZFS Control Plane</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured admin SSH and<br />middleware surface used for<br />ZFS properties, runtime-user<br />setup, snapshot tasks, SMB<br />share configuration, and<br />verification.</div>"]
    style 29 fill:#f3e8ff,stroke:#9333ea,color:#111827
    32["<div style='font-weight: bold'>Operator Shell and Restore Tools</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Local shell, rsync, SSH,<br />Windows Previous Versions,<br />and README/runbook commands<br />used for verification and<br />targeted restores.</div>"]
    style 32 fill:#f3e8ff,stroke:#9333ea,color:#111827

    subgraph 2 ["WORKSTATION1 Workflow Backup"]
      style 2 fill:#ffffff,stroke:#16a34a,color:#16a34a

      18["<div style='font-weight: bold'>NAS Growth Guard</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + NAS sudo helper + zfs CLI]</div><div style='font-size: 80%; margin-top:10px'>Read-only NAS-side ZFS budget<br />check that enforces<br />dataset-used, snapshot-held,<br />availability-dataset<br />free-space, and<br />snapshot-count limits<br />before/after writes.</div>"]
      style 18 fill:#ecfeff,stroke:#0891b2,color:#111827
      19["<div style='font-weight: bold'>NAS Integrity Manifest Builder</div><div style='font-size: 70%; margin-top: 0px'>[Container: Python + SHA-256]</div><div style='font-size: 80%; margin-top:10px'>NAS-side helper that hashes<br />restore-critical current-tree<br />artifacts and writes<br />_manifests/integrity-manifest.json<br />for snapshot-preserved<br />restore verification.</div>"]
      style 19 fill:#ecfeff,stroke:#0891b2,color:#111827
      20["<div style='font-weight: bold'>Restricted NAS Runtime SSH Boundary</div><div style='font-size: 70%; margin-top: 0px'>[Container: OpenSSH forced command + sudoers + ZFS refquota]</div><div style='font-size: 80%; margin-top:10px'>Dedicated runtime NAS<br />user/key, pinned host-key<br />verification, forced-command<br />dispatcher, sudo allowlist,<br />and refquota-backed<br />current-tree write boundary.</div>"]
      style 20 fill:#ecfeff,stroke:#0891b2,color:#111827
      21["<div style='font-weight: bold'>NAS Provisioner</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + admin SSH + remote Python + midclt/zfs]</div><div style='font-size: 80%; margin-top:10px'>Idempotent provisioning<br />script for the TrueNAS<br />dataset, SMB share, periodic<br />snapshot tasks, refquota, and<br />retired legacy snapshot cron<br />jobs.</div>"]
      style 21 fill:#ecfeff,stroke:#0891b2,color:#111827
      22["<div style='font-weight: bold'>NAS Runtime Hardening Installer</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + admin SSH + TrueNAS middleware]</div><div style='font-size: 80%; margin-top:10px'>Installs or updates the<br />dedicated runtime user/key,<br />forced-command dispatcher,<br />NAS-side guard/integrity<br />helpers, sudo allowlist,<br />runtime-writable subtrees,<br />host-key pinning config, and<br />dataset refquota.</div>"]
      style 22 fill:#ecfeff,stroke:#0891b2,color:#111827
      23["<div style='font-weight: bold'>Backup Verifier</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + systemctl + SSH]</div><div style='font-size: 80%; margin-top:10px'>Operational verification<br />script that checks the local<br />timer, last status, run<br />ledger, growth guard, NAS<br />dataset, snapshots,<br />manifests, integrity summary,<br />snapshot tasks, and retired<br />cron jobs.</div>"]
      style 23 fill:#ecfeff,stroke:#0891b2,color:#111827
      25[("<div style='font-weight: bold'>Run Ledger and Local State</div><div style='font-size: 70%; margin-top: 0px'>[Container: SQLite + JSON + logs on WSL filesystem]</div><div style='font-size: 80%; margin-top:10px'>Local status, pruned logs,<br />SQLite run ledger, exported<br />run-history JSON, SQLite<br />snapshot cache, and Windows<br />manifest cache under<br />~/.local/state/workstation-workflow-backup.</div>")]
      style 25 fill:#fef3c7,stroke:#d97706,color:#111827
    end

    1-. "<div>Runs backup, verification,<br />provisioning, and restore<br />commands from</div><div style='font-size: 70%'></div>" .->32
    32-. "<div>Runs backup health checks<br />through</div><div style='font-size: 70%'>[shell]</div>" .->23
    32-. "<div>Lists snapshots and inspects<br />NAS state through</div><div style='font-size: 70%'>[admin SSH + zfs/midclt]</div>" .->29
    32-. "<div>Restores selected files from<br />.zfs/snapshot/current paths</div><div style='font-size: 70%'>[SSH rsync or SMB Previous Versions]</div>" .->28
    18-. "<div>Reads ZFS used, availability,<br />usedbysnapshots, and snapshot<br />count from</div><div style='font-size: 70%'>[NAS-side helper + zfs]</div>" .->29
    20-. "<div>Allows receiver-mode rsync<br />and mkdir only under current<br />tree</div><div style='font-size: 70%'>[forced command + rsync]</div>" .->28
    20-. "<div>Allows sudo execution of<br />guard helper only</div><div style='font-size: 70%'>[forced command + sudo]</div>" .->18
    20-. "<div>Allows sudo execution of<br />integrity helper only</div><div style='font-size: 70%'>[forced command + sudo]</div>" .->19
    19-. "<div>Hashes NAS current-tree<br />critical artifacts and writes<br />integrity-manifest.json to</div><div style='font-size: 70%'>[SHA-256 + filesystem]</div>" .->28
    21-. "<div>Creates/updates dataset, SMB<br />share, snapshot tasks,<br />refquota, and disabled<br />retired cron jobs through</div><div style='font-size: 70%'>[admin SSH + zfs + midclt]</div>" .->29
    21-. "<div>Configures mountpoint, SMB<br />share, refquota, and snapshot<br />naming/retention for</div><div style='font-size: 70%'></div>" .->28
    22-. "<div>Creates runtime user/key,<br />forced command, sudo<br />allowlist, helper scripts,<br />and pinned host-key boundary<br />through</div><div style='font-size: 70%'>[admin SSH + middleware]</div>" .->29
    22-. "<div>Owns runtime-writable current<br />subtrees and applies refquota<br />for</div><div style='font-size: 70%'></div>" .->28
    23-. "<div>Reads local last status and<br />recent run ledger from</div><div style='font-size: 70%'>[filesystem + sqlite3]</div>" .->25
    23-. "<div>Runs read-only guard<br />verification through</div><div style='font-size: 70%'>[subprocess]</div>" .->18
    23-. "<div>Reads dataset, snapshot<br />tasks, and retired cron job<br />state from</div><div style='font-size: 70%'>[SSH + midclt + zfs]</div>" .->29
    23-. "<div>Checks required backup paths,<br />status manifests, and<br />integrity manifest in</div><div style='font-size: 70%'></div>" .->28

  end
```

</details>

### Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-OpsProvisioningContainers.mmd`](diagrams/structurizr-OpsProvisioningContainers.mmd) |
| Mermaid SVG | [`structurizr-OpsProvisioningContainers.svg`](diagrams/structurizr-OpsProvisioningContainers.svg) |
| Mermaid PNG | [`structurizr-OpsProvisioningContainers.png`](diagrams/structurizr-OpsProvisioningContainers.png) |
| DOT source | [`structurizr-OpsProvisioningContainers.dot`](diagrams/dot/structurizr-OpsProvisioningContainers.dot) |
| Graphviz SVG | [`structurizr-OpsProvisioningContainers.svg`](diagrams/dot-rendered/structurizr-OpsProvisioningContainers.svg) |
| Graphviz PNG | [`structurizr-OpsProvisioningContainers.png`](diagrams/dot-rendered/structurizr-OpsProvisioningContainers.png) |


---

## Orchestrator Control Components

> C4 view `OrchestratorControlComponents`.

### Diagram

![Orchestrator Control Components](diagrams/dot-rendered/structurizr-OrchestratorControlComponents.svg)

_Preferred Markdown display: Graphviz SVG. Mermaid source is retained below for text review._

<details>
<summary>Mermaid source</summary>

```mermaid
graph LR
  linkStyle default fill:#ffffff

  subgraph diagram ["Component View: WORKSTATION1 Workflow Backup - Backup Orchestrator"]
    style diagram fill:#ffffff,stroke:#ffffff

    28[("<div style='font-weight: bold'>TrueNAS Backup Dataset</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured encrypted TrueNAS<br />dataset with current mirror<br />tree, manifests, SMB share,<br />restore checksum manifest,<br />refquota, and ZFS snapshot<br />history.</div>")]
    style 28 fill:#fef3c7,stroke:#d97706,color:#111827
    29["<div style='font-weight: bold'>TrueNAS Middleware and ZFS Control Plane</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured admin SSH and<br />middleware surface used for<br />ZFS properties, runtime-user<br />setup, snapshot tasks, SMB<br />share configuration, and<br />verification.</div>"]
    style 29 fill:#f3e8ff,stroke:#9333ea,color:#111827

    subgraph 2 ["WORKSTATION1 Workflow Backup"]
      style 2 fill:#ffffff,stroke:#16a34a,color:#16a34a

      subgraph 4 ["Backup Orchestrator"]
        style 4 fill:#ffffff,stroke:#0284c7,color:#0284c7

        13["<div style='font-weight: bold'>NAS Status Publisher</div><div style='font-size: 70%; margin-top: 0px'>[Component: Python + rsync over restricted SSH]</div><div style='font-size: 80%; margin-top:10px'>Exports the run ledger to<br />JSON/SQLite snapshots and<br />rsyncs last-run/run-history<br />manifests to NAS through the<br />restricted runtime SSH<br />boundary.</div>"]
        style 13 fill:#f0fdf4,stroke:#22c55e,color:#111827
        14["<div style='font-weight: bold'>Integrity Manifest Phase</div><div style='font-size: 70%; margin-top: 0px'>[Component: Bash + restricted SSH]</div><div style='font-size: 80%; margin-top:10px'>Runs the NAS-side checksum<br />helper after successful<br />status publication to write<br />restore-critical SHA-256<br />evidence.</div>"]
        style 14 fill:#f0fdf4,stroke:#22c55e,color:#111827
        15["<div style='font-weight: bold'>Error Trap</div><div style='font-size: 70%; margin-top: 0px'>[Component: Bash ERR trap]</div><div style='font-size: 80%; margin-top:10px'>Converts command failures<br />into failed status, ledger<br />event, best-effort NAS status<br />sync, and nonzero service<br />exit.</div>"]
        style 15 fill:#f0fdf4,stroke:#22c55e,color:#111827
        5["<div style='font-weight: bold'>Argument Parser</div><div style='font-size: 70%; margin-top: 0px'>[Component: Bash case parser]</div><div style='font-size: 80%; margin-top:10px'>Handles --dry-run, --verbose,<br />--skip-windows, --skip-wsl,<br />and --quick-check-sqlite<br />flags.</div>"]
        style 5 fill:#f0fdf4,stroke:#22c55e,color:#111827
        6["<div style='font-weight: bold'>Lock and Run Identity</div><div style='font-size: 70%; margin-top: 0px'>[Component: Bash + flock]</div><div style='font-size: 80%; margin-top:10px'>Creates the local state/log<br />directories, acquires a flock<br />lock, generates run_id, and<br />skips concurrent runs<br />silently.</div>"]
        style 6 fill:#f0fdf4,stroke:#22c55e,color:#111827
        7["<div style='font-weight: bold'>Log and Last-Status Writer</div><div style='font-size: 70%; margin-top: 0px'>[Component: Bash + Python JSON helper]</div><div style='font-size: 80%; margin-top:10px'>Prunes old local logs and<br />writes per-run logs plus<br />last-run.json with host,<br />status, duration, dry-run,<br />error, and log path.</div>"]
        style 7 fill:#f0fdf4,stroke:#22c55e,color:#111827
        8["<div style='font-weight: bold'>Run Ledger Adapter</div><div style='font-size: 70%; margin-top: 0px'>[Component: record-run-ledger.py CLI]</div><div style='font-size: 80%; margin-top:10px'>Appends<br />started/completed/failed/skipped<br />events with SQLite and<br />Windows manifest summaries.</div>"]
        style 8 fill:#f0fdf4,stroke:#22c55e,color:#111827
        9["<div style='font-weight: bold'>Growth Guard Runner</div><div style='font-size: 70%; margin-top: 0px'>[Component: Bash subprocess]</div><div style='font-size: 80%; margin-top:10px'>Invokes<br />check-nas-growth-guard.sh<br />before and after writes and<br />fails closed on budget<br />violations.</div>"]
        style 9 fill:#f0fdf4,stroke:#22c55e,color:#111827
      end

      18["<div style='font-weight: bold'>NAS Growth Guard</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + NAS sudo helper + zfs CLI]</div><div style='font-size: 80%; margin-top:10px'>Read-only NAS-side ZFS budget<br />check that enforces<br />dataset-used, snapshot-held,<br />availability-dataset<br />free-space, and<br />snapshot-count limits<br />before/after writes.</div>"]
      style 18 fill:#ecfeff,stroke:#0891b2,color:#111827
      19["<div style='font-weight: bold'>NAS Integrity Manifest Builder</div><div style='font-size: 70%; margin-top: 0px'>[Container: Python + SHA-256]</div><div style='font-size: 80%; margin-top:10px'>NAS-side helper that hashes<br />restore-critical current-tree<br />artifacts and writes<br />_manifests/integrity-manifest.json<br />for snapshot-preserved<br />restore verification.</div>"]
      style 19 fill:#ecfeff,stroke:#0891b2,color:#111827
      20["<div style='font-weight: bold'>Restricted NAS Runtime SSH Boundary</div><div style='font-size: 70%; margin-top: 0px'>[Container: OpenSSH forced command + sudoers + ZFS refquota]</div><div style='font-size: 80%; margin-top:10px'>Dedicated runtime NAS<br />user/key, pinned host-key<br />verification, forced-command<br />dispatcher, sudo allowlist,<br />and refquota-backed<br />current-tree write boundary.</div>"]
      style 20 fill:#ecfeff,stroke:#0891b2,color:#111827
      25[("<div style='font-weight: bold'>Run Ledger and Local State</div><div style='font-size: 70%; margin-top: 0px'>[Container: SQLite + JSON + logs on WSL filesystem]</div><div style='font-size: 80%; margin-top:10px'>Local status, pruned logs,<br />SQLite run ledger, exported<br />run-history JSON, SQLite<br />snapshot cache, and Windows<br />manifest cache under<br />~/.local/state/workstation-workflow-backup.</div>")]
      style 25 fill:#fef3c7,stroke:#d97706,color:#111827
    end

    18-. "<div>Reads ZFS used, availability,<br />usedbysnapshots, and snapshot<br />count from</div><div style='font-size: 70%'>[NAS-side helper + zfs]</div>" .->29
    20-. "<div>Allows receiver-mode rsync<br />and mkdir only under current<br />tree</div><div style='font-size: 70%'>[forced command + rsync]</div>" .->28
    20-. "<div>Allows sudo execution of<br />guard helper only</div><div style='font-size: 70%'>[forced command + sudo]</div>" .->18
    20-. "<div>Allows sudo execution of<br />integrity helper only</div><div style='font-size: 70%'>[forced command + sudo]</div>" .->19
    19-. "<div>Hashes NAS current-tree<br />critical artifacts and writes<br />integrity-manifest.json to</div><div style='font-size: 70%'>[SHA-256 + filesystem]</div>" .->28
    5-. "<div>Passes selected run mode to</div><div style='font-size: 70%'></div>" .->6
    6-. "<div>Initializes log and status<br />paths for</div><div style='font-size: 70%'></div>" .->7
    6-. "<div>Records skipped_lock when<br />another run is active</div><div style='font-size: 70%'></div>" .->8
    8-. "<div>Writes run events to</div><div style='font-size: 70%'>[sqlite3]</div>" .->25
    7-. "<div>Writes last-run.json and logs<br />to</div><div style='font-size: 70%'>[filesystem]</div>" .->25
    9-. "<div>Executes guard stages through</div><div style='font-size: 70%'></div>" .->18
    9-. "<div>Stores guard failure message<br />through</div><div style='font-size: 70%'></div>" .->7
    13-. "<div>Snapshots ledger DB and<br />exports run history from</div><div style='font-size: 70%'>[sqlite3]</div>" .->25
    13-. "<div>Publishes<br />_manifests/last-run.json,<br />runs.sqlite3, and<br />run-history.json to</div><div style='font-size: 70%'>[restricted SSH rsync]</div>" .->28
    14-. "<div>Requests restore checksum<br />manifest from</div><div style='font-size: 70%'></div>" .->19
    14-. "<div>Publishes<br />integrity-manifest.json<br />through</div><div style='font-size: 70%'>[NAS-side helper]</div>" .->28
    15-. "<div>Marks failed status through</div><div style='font-size: 70%'></div>" .->7
    15-. "<div>Records failed event through</div><div style='font-size: 70%'></div>" .->8
    15-. "<div>Best-effort syncs failure<br />status through</div><div style='font-size: 70%'></div>" .->13

  end
```

</details>

### Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-OrchestratorControlComponents.mmd`](diagrams/structurizr-OrchestratorControlComponents.mmd) |
| Mermaid SVG | [`structurizr-OrchestratorControlComponents.svg`](diagrams/structurizr-OrchestratorControlComponents.svg) |
| Mermaid PNG | [`structurizr-OrchestratorControlComponents.png`](diagrams/structurizr-OrchestratorControlComponents.png) |
| DOT source | [`structurizr-OrchestratorControlComponents.dot`](diagrams/dot/structurizr-OrchestratorControlComponents.dot) |
| Graphviz SVG | [`structurizr-OrchestratorControlComponents.svg`](diagrams/dot-rendered/structurizr-OrchestratorControlComponents.svg) |
| Graphviz PNG | [`structurizr-OrchestratorControlComponents.png`](diagrams/dot-rendered/structurizr-OrchestratorControlComponents.png) |


---

## Orchestrator Sync Components

> C4 view `OrchestratorSyncComponents`.

### Diagram

![Orchestrator Sync Components](diagrams/dot-rendered/structurizr-OrchestratorSyncComponents.svg)

_Preferred Markdown display: Graphviz SVG. Mermaid source is retained below for text review._

<details>
<summary>Mermaid source</summary>

```mermaid
graph LR
  linkStyle default fill:#ffffff

  subgraph diagram ["Component View: WORKSTATION1 Workflow Backup - Backup Orchestrator"]
    style diagram fill:#ffffff,stroke:#ffffff

    26[("<div style='font-weight: bold'>WSL Workflow Sources</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Workflow-critical WSL paths:<br />~/repos, ~/.hermes, ~/.ssh,<br />systemd user config,<br />lifelog/browser-memory data,<br />and optional brain-code tree.</div>")]
    style 26 fill:#fef3c7,stroke:#d97706,color:#111827
    27[("<div style='font-weight: bold'>Windows Workflow Sources</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Selected Windows user-profile<br />artifacts: Desktop,<br />Documents, Downloads, Windows<br />.ssh/.wslconfig, Terminal/VS<br />Code/PowerShell config,<br />Chrome profile metadata, and<br />Startup entries.</div>")]
    style 27 fill:#fef3c7,stroke:#d97706,color:#111827
    28[("<div style='font-weight: bold'>TrueNAS Backup Dataset</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured encrypted TrueNAS<br />dataset with current mirror<br />tree, manifests, SMB share,<br />restore checksum manifest,<br />refquota, and ZFS snapshot<br />history.</div>")]
    style 28 fill:#fef3c7,stroke:#d97706,color:#111827

    subgraph 2 ["WORKSTATION1 Workflow Backup"]
      style 2 fill:#ffffff,stroke:#16a34a,color:#16a34a

      subgraph 4 ["Backup Orchestrator"]
        style 4 fill:#ffffff,stroke:#0284c7,color:#0284c7

        10["<div style='font-weight: bold'>SQLite Snapshot Phase</div><div style='font-size: 70%; margin-top: 0px'>[Component: Python subprocess + rsync]</div><div style='font-size: 80%; margin-top:10px'>Runs the SQLite backup API<br />snapshotter and mirrors the<br />consistent DB snapshot tree<br />to NAS.</div>"]
        style 10 fill:#f0fdf4,stroke:#22c55e,color:#111827
        11["<div style='font-weight: bold'>WSL Rsync Phase</div><div style='font-size: 70%; margin-top: 0px'>[Component: rsync over SSH]</div><div style='font-size: 80%; margin-top:10px'>Mirrors configured WSL<br />directories to current/wsl<br />using sudo rsync over SSH<br />with payload exclusions.</div>"]
        style 11 fill:#f0fdf4,stroke:#22c55e,color:#111827
        12["<div style='font-weight: bold'>Windows Phase Launcher</div><div style='font-size: 70%; margin-top: 0px'>[Component: Bash + WSL interop]</div><div style='font-size: 80%; margin-top:10px'>Copies the PowerShell helper<br />to Windows temp and launches<br />it through direct WSL interop<br />or /init fallback.</div>"]
        style 12 fill:#f0fdf4,stroke:#22c55e,color:#111827
      end

      16["<div style='font-weight: bold'>SQLite Snapshotter</div><div style='font-size: 70%; margin-top: 0px'>[Container: Python 3, sqlite3]</div><div style='font-size: 80%; margin-top:10px'>Creates<br />application-consistent copies<br />of Hermes, lifelog,<br />browser-memory, and related<br />SQLite databases using<br />sqlite3 backup API; can<br />quick_check copies.</div>"]
      style 16 fill:#ecfeff,stroke:#0891b2,color:#111827
      17["<div style='font-weight: bold'>Windows Critical Sync Helper</div><div style='font-size: 70%; margin-top: 0px'>[Container: PowerShell + robocopy.exe]</div><div style='font-size: 80%; margin-top:10px'>PowerShell script launched<br />from WSL that uses<br />robocopy.exe to mirror<br />selected Windows profile<br />directories/files to the SMB<br />share and writes a Windows<br />sync manifest.</div>"]
      style 17 fill:#ecfeff,stroke:#0891b2,color:#111827
      20["<div style='font-weight: bold'>Restricted NAS Runtime SSH Boundary</div><div style='font-size: 70%; margin-top: 0px'>[Container: OpenSSH forced command + sudoers + ZFS refquota]</div><div style='font-size: 80%; margin-top:10px'>Dedicated runtime NAS<br />user/key, pinned host-key<br />verification, forced-command<br />dispatcher, sudo allowlist,<br />and refquota-backed<br />current-tree write boundary.</div>"]
      style 20 fill:#ecfeff,stroke:#0891b2,color:#111827
      25[("<div style='font-weight: bold'>Run Ledger and Local State</div><div style='font-size: 70%; margin-top: 0px'>[Container: SQLite + JSON + logs on WSL filesystem]</div><div style='font-size: 80%; margin-top:10px'>Local status, pruned logs,<br />SQLite run ledger, exported<br />run-history JSON, SQLite<br />snapshot cache, and Windows<br />manifest cache under<br />~/.local/state/workstation-workflow-backup.</div>")]
      style 25 fill:#fef3c7,stroke:#d97706,color:#111827
    end

    16-. "<div>Reads live SQLite databases<br />from</div><div style='font-size: 70%'>[sqlite3 backup API]</div>" .->26
    16-. "<div>Writes local SQLite snapshot<br />cache and manifest under</div><div style='font-size: 70%'>[filesystem]</div>" .->25
    20-. "<div>Allows receiver-mode rsync<br />and mkdir only under current<br />tree</div><div style='font-size: 70%'>[forced command + rsync]</div>" .->28
    17-. "<div>Mirrors selected Windows<br />artifacts from</div><div style='font-size: 70%'>[robocopy.exe]</div>" .->27
    17-. "<div>Writes current/windows and<br />Windows manifests to</div><div style='font-size: 70%'>[SMB share]</div>" .->28
    17-. "<div>Leaves manifest cache for<br />ledger summaries</div><div style='font-size: 70%'></div>" .->25
    10-. "<div>Creates consistent DB<br />snapshot tree through</div><div style='font-size: 70%'></div>" .->16
    10-. "<div>Mirrors DB snapshot tree to</div><div style='font-size: 70%'>[rsync]</div>" .->28
    11-. "<div>Reads configured WSL paths<br />from</div><div style='font-size: 70%'>[filesystem]</div>" .->26
    11-. "<div>Mirrors WSL trees to</div><div style='font-size: 70%'>[rsync over SSH]</div>" .->28
    12-. "<div>Launches and monitors</div><div style='font-size: 70%'>[PowerShell]</div>" .->17
    12-. "<div>Uses SMB root for Windows<br />helper destination</div><div style='font-size: 70%'></div>" .->28

  end
```

</details>

### Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-OrchestratorSyncComponents.mmd`](diagrams/structurizr-OrchestratorSyncComponents.mmd) |
| Mermaid SVG | [`structurizr-OrchestratorSyncComponents.svg`](diagrams/structurizr-OrchestratorSyncComponents.svg) |
| Mermaid PNG | [`structurizr-OrchestratorSyncComponents.png`](diagrams/structurizr-OrchestratorSyncComponents.png) |
| DOT source | [`structurizr-OrchestratorSyncComponents.dot`](diagrams/dot/structurizr-OrchestratorSyncComponents.dot) |
| Graphviz SVG | [`structurizr-OrchestratorSyncComponents.svg`](diagrams/dot-rendered/structurizr-OrchestratorSyncComponents.svg) |
| Graphviz PNG | [`structurizr-OrchestratorSyncComponents.png`](diagrams/dot-rendered/structurizr-OrchestratorSyncComponents.png) |


---

## System Context

> C4 view `SystemContext`.

### Diagram

![System Context](diagrams/dot-rendered/structurizr-SystemContext.svg)

_Preferred Markdown display: Graphviz SVG. Mermaid source is retained below for text review._

<details>
<summary>Mermaid source</summary>

```mermaid
graph LR
  linkStyle default fill:#ffffff

  subgraph diagram ["System Context View: WORKSTATION1 Workflow Backup"]
    style diagram fill:#ffffff,stroke:#ffffff

    1["<div style='font-weight: bold'>Michael</div><div style='font-size: 70%; margin-top: 0px'>[Person]</div><div style='font-size: 80%; margin-top:10px'>Sole operator who installs,<br />verifies, and restores<br />WORKSTATION1 workflow<br />backups.</div>"]
    style 1 fill:#dbeafe,stroke:#2563eb,color:#111827
    2["<div style='font-weight: bold'>WORKSTATION1 Workflow Backup</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Repo-owned backup automation<br />that mirrors<br />workflow-critical WSL and<br />Windows artifacts to TrueNAS<br />through a restricted runtime<br />identity, preserves rollback<br />points with ZFS snapshots,<br />records run history, writes<br />restore checksums, and alerts<br />only on failure.</div>"]
    style 2 fill:#dcfce7,stroke:#16a34a,color:#111827
    26[("<div style='font-weight: bold'>WSL Workflow Sources</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Workflow-critical WSL paths:<br />~/repos, ~/.hermes, ~/.ssh,<br />systemd user config,<br />lifelog/browser-memory data,<br />and optional brain-code tree.</div>")]
    style 26 fill:#fef3c7,stroke:#d97706,color:#111827
    27[("<div style='font-weight: bold'>Windows Workflow Sources</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Selected Windows user-profile<br />artifacts: Desktop,<br />Documents, Downloads, Windows<br />.ssh/.wslconfig, Terminal/VS<br />Code/PowerShell config,<br />Chrome profile metadata, and<br />Startup entries.</div>")]
    style 27 fill:#fef3c7,stroke:#d97706,color:#111827
    28[("<div style='font-weight: bold'>TrueNAS Backup Dataset</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured encrypted TrueNAS<br />dataset with current mirror<br />tree, manifests, SMB share,<br />restore checksum manifest,<br />refquota, and ZFS snapshot<br />history.</div>")]
    style 28 fill:#fef3c7,stroke:#d97706,color:#111827
    29["<div style='font-weight: bold'>TrueNAS Middleware and ZFS Control Plane</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured admin SSH and<br />middleware surface used for<br />ZFS properties, runtime-user<br />setup, snapshot tasks, SMB<br />share configuration, and<br />verification.</div>"]
    style 29 fill:#f3e8ff,stroke:#9333ea,color:#111827
    31["<div style='font-weight: bold'>Telegram Bot API</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>External API used only for<br />backup failure notifications.</div>"]
    style 31 fill:#f3e8ff,stroke:#9333ea,color:#111827
    32["<div style='font-weight: bold'>Operator Shell and Restore Tools</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Local shell, rsync, SSH,<br />Windows Previous Versions,<br />and README/runbook commands<br />used for verification and<br />targeted restores.</div>"]
    style 32 fill:#f3e8ff,stroke:#9333ea,color:#111827

    1-. "<div>Installs, verifies, and<br />restores through</div><div style='font-size: 70%'></div>" .->2
    1-. "<div>Runs backup, verification,<br />provisioning, and restore<br />commands from</div><div style='font-size: 70%'></div>" .->32
    32-. "<div>Executes scripts and reads<br />documentation in</div><div style='font-size: 70%'>[shell]</div>" .->2
    32-. "<div>Lists snapshots and inspects<br />NAS state through</div><div style='font-size: 70%'>[admin SSH + zfs/midclt]</div>" .->29
    32-. "<div>Restores selected files from<br />.zfs/snapshot/current paths</div><div style='font-size: 70%'>[SSH rsync or SMB Previous Versions]</div>" .->28
    2-. "<div>Reads ZFS used, availability,<br />usedbysnapshots, and snapshot<br />count from</div><div style='font-size: 70%'>[NAS-side helper + zfs]</div>" .->29
    2-. "<div>Reads live SQLite databases<br />from</div><div style='font-size: 70%'>[sqlite3 backup API]</div>" .->26
    2-. "<div>Allows receiver-mode rsync<br />and mkdir only under current<br />tree</div><div style='font-size: 70%'>[forced command + rsync]</div>" .->28
    2-. "<div>Mirrors selected Windows<br />artifacts from</div><div style='font-size: 70%'>[robocopy.exe]</div>" .->27
    2-. "<div>Sends failure-only<br />notification to</div><div style='font-size: 70%'>[HTTPS]</div>" .->31

  end
```

</details>

### Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-SystemContext.mmd`](diagrams/structurizr-SystemContext.mmd) |
| Mermaid SVG | [`structurizr-SystemContext.svg`](diagrams/structurizr-SystemContext.svg) |
| Mermaid PNG | [`structurizr-SystemContext.png`](diagrams/structurizr-SystemContext.png) |
| DOT source | [`structurizr-SystemContext.dot`](diagrams/dot/structurizr-SystemContext.dot) |
| Graphviz SVG | [`structurizr-SystemContext.svg`](diagrams/dot-rendered/structurizr-SystemContext.svg) |
| Graphviz PNG | [`structurizr-SystemContext.png`](diagrams/dot-rendered/structurizr-SystemContext.png) |


---

## Targeted Restore Flow

> C4 view `TargetedRestoreFlow`.

### Diagram

![Targeted Restore Flow](diagrams/dot-rendered/structurizr-TargetedRestoreFlow.svg)

_Preferred Markdown display: Graphviz SVG. Mermaid source is retained below for text review._

<details>
<summary>Mermaid source</summary>

```mermaid
graph LR
  linkStyle default fill:#ffffff

  subgraph diagram ["Dynamic View: WORKSTATION1 Workflow Backup"]
    style diagram fill:#ffffff,stroke:#ffffff

    subgraph 2 ["WORKSTATION1 Workflow Backup"]
      style 2 fill:#ffffff,stroke:#16a34a,color:#16a34a

      23["<div style='font-weight: bold'>Backup Verifier</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + systemctl + SSH]</div><div style='font-size: 80%; margin-top:10px'>Operational verification<br />script that checks the local<br />timer, last status, run<br />ledger, growth guard, NAS<br />dataset, snapshots,<br />manifests, integrity summary,<br />snapshot tasks, and retired<br />cron jobs.</div>"]
      style 23 fill:#ecfeff,stroke:#0891b2,color:#111827
    end

    1["<div style='font-weight: bold'>Michael</div><div style='font-size: 70%; margin-top: 0px'>[Person]</div><div style='font-size: 80%; margin-top:10px'>Sole operator who installs,<br />verifies, and restores<br />WORKSTATION1 workflow<br />backups.</div>"]
    style 1 fill:#dbeafe,stroke:#2563eb,color:#111827
    28[("<div style='font-weight: bold'>TrueNAS Backup Dataset</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured encrypted TrueNAS<br />dataset with current mirror<br />tree, manifests, SMB share,<br />restore checksum manifest,<br />refquota, and ZFS snapshot<br />history.</div>")]
    style 28 fill:#fef3c7,stroke:#d97706,color:#111827
    29["<div style='font-weight: bold'>TrueNAS Middleware and ZFS Control Plane</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Configured admin SSH and<br />middleware surface used for<br />ZFS properties, runtime-user<br />setup, snapshot tasks, SMB<br />share configuration, and<br />verification.</div>"]
    style 29 fill:#f3e8ff,stroke:#9333ea,color:#111827
    32["<div style='font-weight: bold'>Operator Shell and Restore Tools</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Local shell, rsync, SSH,<br />Windows Previous Versions,<br />and README/runbook commands<br />used for verification and<br />targeted restores.</div>"]
    style 32 fill:#f3e8ff,stroke:#9333ea,color:#111827

    1-. "<div>1. Select snapshot before<br />loss/corruption</div><div style='font-size: 70%'></div>" .->32
    32-. "<div>2. List snapshots under<br />configured backup dataset</div><div style='font-size: 70%'>[admin SSH + zfs/midclt]</div>" .->29
    32-. "<div>3. Copy selected<br />.zfs/snapshot/.../current<br />path to restore candidate</div><div style='font-size: 70%'>[SSH rsync or SMB Previous Versions]</div>" .->28
    32-. "<div>4. Read snapshot<br />integrity-manifest.json for<br />checksum comparison</div><div style='font-size: 70%'>[SSH rsync or SMB Previous Versions]</div>" .->28
    32-. "<div>5. Run verify-backup.sh after<br />timer resumes</div><div style='font-size: 70%'>[shell]</div>" .->23

  end
```

</details>

### Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-TargetedRestoreFlow.mmd`](diagrams/structurizr-TargetedRestoreFlow.mmd) |
| Mermaid SVG | [`structurizr-TargetedRestoreFlow.svg`](diagrams/structurizr-TargetedRestoreFlow.svg) |
| Mermaid PNG | [`structurizr-TargetedRestoreFlow.png`](diagrams/structurizr-TargetedRestoreFlow.png) |
| DOT source | [`structurizr-TargetedRestoreFlow.dot`](diagrams/dot/structurizr-TargetedRestoreFlow.dot) |
| Graphviz SVG | [`structurizr-TargetedRestoreFlow.svg`](diagrams/dot-rendered/structurizr-TargetedRestoreFlow.svg) |
| Graphviz PNG | [`structurizr-TargetedRestoreFlow.png`](diagrams/dot-rendered/structurizr-TargetedRestoreFlow.png) |
