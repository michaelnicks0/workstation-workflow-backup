# Hourly Preflight Snapshot Flow

> Generated Markdown wrapper for C4 view `HourlyPreflightSnapshotFlow`. Canonical model: [`workspace.dsl`](../../workspace.dsl).

<!-- Generated from Structurizr exports; refresh from docs/architecture/workspace.dsl. -->

## Diagram

![Hourly Preflight Snapshot Flow](../dot-rendered/structurizr-HourlyPreflightSnapshotFlow.svg)

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

## Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-HourlyPreflightSnapshotFlow.mmd`](../structurizr-HourlyPreflightSnapshotFlow.mmd) |
| Mermaid SVG | [`structurizr-HourlyPreflightSnapshotFlow.svg`](../structurizr-HourlyPreflightSnapshotFlow.svg) |
| Mermaid PNG | [`structurizr-HourlyPreflightSnapshotFlow.png`](../structurizr-HourlyPreflightSnapshotFlow.png) |
| DOT source | [`structurizr-HourlyPreflightSnapshotFlow.dot`](../dot/structurizr-HourlyPreflightSnapshotFlow.dot) |
| Graphviz SVG | [`structurizr-HourlyPreflightSnapshotFlow.svg`](../dot-rendered/structurizr-HourlyPreflightSnapshotFlow.svg) |
| Graphviz PNG | [`structurizr-HourlyPreflightSnapshotFlow.png`](../dot-rendered/structurizr-HourlyPreflightSnapshotFlow.png) |
