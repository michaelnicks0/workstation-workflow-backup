# Ops Provisioning Containers

> Generated Markdown wrapper for C4 view `OpsProvisioningContainers`. Canonical model: [`workspace.dsl`](../../workspace.dsl).

<!-- Generated from Structurizr exports; refresh from docs/architecture/workspace.dsl. -->

## Diagram

![Ops Provisioning Containers](../dot-rendered/structurizr-OpsProvisioningContainers.svg)

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
    24[("<div style='font-weight: bold'>TrueNAS Backup Dataset</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Encrypted TrueNAS dataset<br />v1/ws1/wf with current mirror<br />tree, manifests, SMB share<br />ws1-wf, and ZFS snapshot<br />history.</div>")]
    style 24 fill:#fef3c7,stroke:#d97706,color:#111827
    25["<div style='font-weight: bold'>TrueNAS Middleware and ZFS Control Plane</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>root@10.99.98.221 management<br />surface used for ZFS<br />properties, snapshot tasks,<br />SMB share configuration, and<br />verification.</div>"]
    style 25 fill:#f3e8ff,stroke:#9333ea,color:#111827
    28["<div style='font-weight: bold'>Operator Shell and Restore Tools</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Local shell, rsync, SSH,<br />Windows Previous Versions,<br />and README/runbook commands<br />used for verification and<br />targeted restores.</div>"]
    style 28 fill:#f3e8ff,stroke:#9333ea,color:#111827

    subgraph 2 ["WORKSTATION1 Workflow Backup"]
      style 2 fill:#ffffff,stroke:#16a34a,color:#16a34a

      17["<div style='font-weight: bold'>NAS Growth Guard</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + remote Python + zfs CLI]</div><div style='font-size: 80%; margin-top:10px'>Read-only ZFS budget check<br />that enforces dataset-used,<br />snapshot-held, free-space,<br />and snapshot-count limits<br />before/after writes.</div>"]
      style 17 fill:#ecfeff,stroke:#0891b2,color:#111827
      18["<div style='font-weight: bold'>NAS Provisioner</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + remote Python + midclt/zfs]</div><div style='font-size: 80%; margin-top:10px'>Idempotent provisioning<br />script for the TrueNAS<br />dataset, SMB share, periodic<br />snapshot tasks, and retired<br />legacy snapshot cron jobs.</div>"]
      style 18 fill:#ecfeff,stroke:#0891b2,color:#111827
      19["<div style='font-weight: bold'>Backup Verifier</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + systemctl + SSH]</div><div style='font-size: 80%; margin-top:10px'>Operational verification<br />script that checks the local<br />timer, last status, run<br />ledger, growth guard, NAS<br />dataset, snapshots,<br />manifests, snapshot tasks,<br />and retired cron jobs.</div>"]
      style 19 fill:#ecfeff,stroke:#0891b2,color:#111827
      21[("<div style='font-weight: bold'>Run Ledger and Local State</div><div style='font-size: 70%; margin-top: 0px'>[Container: SQLite + JSON + logs on WSL filesystem]</div><div style='font-size: 80%; margin-top:10px'>Local status, logs, SQLite<br />run ledger, exported<br />run-history JSON, SQLite<br />snapshot cache, and Windows<br />manifest cache under<br />~/.local/state/workstation-workflow-backup.</div>")]
      style 21 fill:#fef3c7,stroke:#d97706,color:#111827
    end

    1-. "<div>Runs backup, verification,<br />provisioning, and restore<br />commands from</div><div style='font-size: 70%'></div>" .->28
    28-. "<div>Runs backup health checks<br />through</div><div style='font-size: 70%'>[shell]</div>" .->19
    28-. "<div>Lists snapshots and inspects<br />NAS state through</div><div style='font-size: 70%'>[SSH + zfs/midclt]</div>" .->25
    28-. "<div>Restores selected files from<br />.zfs/snapshot/current paths</div><div style='font-size: 70%'>[SSH rsync or SMB Previous Versions]</div>" .->24
    17-. "<div>Reads ZFS used, available,<br />usedbysnapshots, and snapshot<br />count from</div><div style='font-size: 70%'>[SSH + zfs]</div>" .->25
    18-. "<div>Creates/updates dataset, SMB<br />share, snapshot tasks, and<br />disabled retired cron jobs<br />through</div><div style='font-size: 70%'>[SSH + zfs + midclt]</div>" .->25
    18-. "<div>Configures mountpoint, SMB<br />share, and snapshot<br />naming/retention for</div><div style='font-size: 70%'></div>" .->24
    19-. "<div>Reads local last status and<br />recent run ledger from</div><div style='font-size: 70%'>[filesystem + sqlite3]</div>" .->21
    19-. "<div>Runs read-only guard<br />verification through</div><div style='font-size: 70%'>[subprocess]</div>" .->17
    19-. "<div>Reads dataset, snapshot<br />tasks, and retired cron job<br />state from</div><div style='font-size: 70%'>[SSH + midclt + zfs]</div>" .->25
    19-. "<div>Checks required backup paths<br />and manifests in</div><div style='font-size: 70%'></div>" .->24

  end
```

</details>

## Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-OpsProvisioningContainers.mmd`](../structurizr-OpsProvisioningContainers.mmd) |
| Mermaid SVG | [`structurizr-OpsProvisioningContainers.svg`](../structurizr-OpsProvisioningContainers.svg) |
| Mermaid PNG | [`structurizr-OpsProvisioningContainers.png`](../structurizr-OpsProvisioningContainers.png) |
| DOT source | [`structurizr-OpsProvisioningContainers.dot`](../dot/structurizr-OpsProvisioningContainers.dot) |
| Graphviz SVG | [`structurizr-OpsProvisioningContainers.svg`](../dot-rendered/structurizr-OpsProvisioningContainers.svg) |
| Graphviz PNG | [`structurizr-OpsProvisioningContainers.png`](../dot-rendered/structurizr-OpsProvisioningContainers.png) |
