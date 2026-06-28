# Targeted Restore Flow

> Generated Markdown wrapper for C4 view `TargetedRestoreFlow`. Canonical model: [`workspace.dsl`](../../workspace.dsl).

<!-- Generated from Structurizr exports; refresh from docs/architecture/workspace.dsl. -->

## Diagram

![Targeted Restore Flow](../dot-rendered/structurizr-TargetedRestoreFlow.svg)

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

      19["<div style='font-weight: bold'>Backup Verifier</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + systemctl + SSH]</div><div style='font-size: 80%; margin-top:10px'>Operational verification<br />script that checks the local<br />timer, last status, run<br />ledger, growth guard, NAS<br />dataset, snapshots,<br />manifests, snapshot tasks,<br />and retired cron jobs.</div>"]
      style 19 fill:#ecfeff,stroke:#0891b2,color:#111827
    end

    1["<div style='font-weight: bold'>Michael</div><div style='font-size: 70%; margin-top: 0px'>[Person]</div><div style='font-size: 80%; margin-top:10px'>Sole operator who installs,<br />verifies, and restores<br />WORKSTATION1 workflow<br />backups.</div>"]
    style 1 fill:#dbeafe,stroke:#2563eb,color:#111827
    24[("<div style='font-weight: bold'>TrueNAS Backup Dataset</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Encrypted TrueNAS dataset<br />v1/ws1/wf with current mirror<br />tree, manifests, SMB share<br />ws1-wf, and ZFS snapshot<br />history.</div>")]
    style 24 fill:#fef3c7,stroke:#d97706,color:#111827
    25["<div style='font-weight: bold'>TrueNAS Middleware and ZFS Control Plane</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>root@10.99.98.221 management<br />surface used for ZFS<br />properties, snapshot tasks,<br />SMB share configuration, and<br />verification.</div>"]
    style 25 fill:#f3e8ff,stroke:#9333ea,color:#111827
    28["<div style='font-weight: bold'>Operator Shell and Restore Tools</div><div style='font-size: 70%; margin-top: 0px'>[Software System]</div><div style='font-size: 80%; margin-top:10px'>Local shell, rsync, SSH,<br />Windows Previous Versions,<br />and README/runbook commands<br />used for verification and<br />targeted restores.</div>"]
    style 28 fill:#f3e8ff,stroke:#9333ea,color:#111827

    1-. "<div>1. Select snapshot before<br />loss/corruption</div><div style='font-size: 70%'></div>" .->28
    28-. "<div>2. List snapshots under<br />v1/ws1/wf</div><div style='font-size: 70%'>[SSH + zfs/midclt]</div>" .->25
    28-. "<div>3. Copy selected<br />.zfs/snapshot/.../current<br />path to restore candidate</div><div style='font-size: 70%'>[SSH rsync or SMB Previous Versions]</div>" .->24
    28-. "<div>4. Run verify-backup.sh after<br />timer resumes</div><div style='font-size: 70%'>[shell]</div>" .->19

  end
```

</details>

## Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-TargetedRestoreFlow.mmd`](../structurizr-TargetedRestoreFlow.mmd) |
| Mermaid SVG | [`structurizr-TargetedRestoreFlow.svg`](../structurizr-TargetedRestoreFlow.svg) |
| Mermaid PNG | [`structurizr-TargetedRestoreFlow.png`](../structurizr-TargetedRestoreFlow.png) |
| DOT source | [`structurizr-TargetedRestoreFlow.dot`](../dot/structurizr-TargetedRestoreFlow.dot) |
| Graphviz SVG | [`structurizr-TargetedRestoreFlow.svg`](../dot-rendered/structurizr-TargetedRestoreFlow.svg) |
| Graphviz PNG | [`structurizr-TargetedRestoreFlow.png`](../dot-rendered/structurizr-TargetedRestoreFlow.png) |
