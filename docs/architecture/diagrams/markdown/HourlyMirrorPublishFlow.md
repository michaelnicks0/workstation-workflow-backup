# Hourly Mirror Publish Flow

> Generated Markdown wrapper for C4 view `HourlyMirrorPublishFlow`. Canonical model: [`workspace.dsl`](../../workspace.dsl).

<!-- Generated from Structurizr exports; refresh from docs/architecture/workspace.dsl. -->

## Diagram

![Hourly Mirror Publish Flow](../dot-rendered/structurizr-HourlyMirrorPublishFlow.svg)

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

## Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-HourlyMirrorPublishFlow.mmd`](../structurizr-HourlyMirrorPublishFlow.mmd) |
| Mermaid SVG | [`structurizr-HourlyMirrorPublishFlow.svg`](../structurizr-HourlyMirrorPublishFlow.svg) |
| Mermaid PNG | [`structurizr-HourlyMirrorPublishFlow.png`](../structurizr-HourlyMirrorPublishFlow.png) |
| DOT source | [`structurizr-HourlyMirrorPublishFlow.dot`](../dot/structurizr-HourlyMirrorPublishFlow.dot) |
| Graphviz SVG | [`structurizr-HourlyMirrorPublishFlow.svg`](../dot-rendered/structurizr-HourlyMirrorPublishFlow.svg) |
| Graphviz PNG | [`structurizr-HourlyMirrorPublishFlow.png`](../dot-rendered/structurizr-HourlyMirrorPublishFlow.png) |
