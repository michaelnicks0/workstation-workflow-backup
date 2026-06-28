# Local Deployment

> Generated Markdown wrapper for C4 view `LocalDeployment`. Canonical model: [`workspace.dsl`](../../workspace.dsl).

<!-- Generated from Structurizr exports; refresh from docs/architecture/workspace.dsl. -->

## Diagram

![Local Deployment](../dot-rendered/structurizr-LocalDeployment.svg)

_Preferred Markdown display: Graphviz SVG. Mermaid source is retained below for text review._

<details>
<summary>Mermaid source</summary>

```mermaid
graph TB
  linkStyle default fill:#ffffff

  subgraph diagram ["Deployment View: WORKSTATION1 Workflow Backup - WORKSTATION1 local plus TrueNAS"]
    style diagram fill:#ffffff,stroke:#ffffff

    subgraph 114 ["TrueNAS 10.99.98.221"]
      style 114 fill:#ffffff,stroke:#444444,color:#444444

      115["<div style='font-weight: bold'>Encrypted ZFS dataset v1/ws1/wf</div><div style='font-size: 70%; margin-top: 0px'>[Infrastructure Node: ZFS dataset]</div><div style='font-size: 80%; margin-top:10px'>Backup current tree,<br />manifests, and snapshot<br />history under /mnt/v1/ws1/wf.</div>"]
      style 115 fill:#f8fafc,stroke:#64748b,color:#111827
      116["<div style='font-weight: bold'>SMB share ws1-wf</div><div style='font-size: 70%; margin-top: 0px'>[Infrastructure Node: Samba SMB]</div><div style='font-size: 80%; margin-top:10px'>Windows helper destination<br />with shadow-copy support and<br />mangled names disabled.</div>"]
      style 116 fill:#f8fafc,stroke:#64748b,color:#111827
      117["<div style='font-weight: bold'>TrueNAS periodic snapshot tasks</div><div style='font-size: 70%; margin-top: 0px'>[Infrastructure Node: TrueNAS middleware]</div><div style='font-size: 80%; margin-top:10px'>wf-h/wf-d/wf-w/wf-m snapshot<br />tasks with 2d/2w/8w/1y<br />lifetimes.</div>"]
      style 117 fill:#f8fafc,stroke:#64748b,color:#111827
    end

    subgraph 118 ["Telegram"]
      style 118 fill:#ffffff,stroke:#444444,color:#444444

      119["<div style='font-weight: bold'>Telegram Bot API</div><div style='font-size: 70%; margin-top: 0px'>[Infrastructure Node: HTTPS]</div><div style='font-size: 80%; margin-top:10px'>HTTPS sendMessage endpoint<br />reached by the failure<br />notifier.</div>"]
      style 119 fill:#f8fafc,stroke:#64748b,color:#111827
    end

    subgraph 85 ["WORKSTATION1"]
      style 85 fill:#ffffff,stroke:#444444,color:#444444

      subgraph 109 ["Windows user profile"]
        style 109 fill:#ffffff,stroke:#444444,color:#444444

        110["<div style='font-weight: bold'>Windows Critical Sync Helper</div><div style='font-size: 70%; margin-top: 0px'>[Container: PowerShell + robocopy.exe]</div><div style='font-size: 80%; margin-top:10px'>PowerShell script launched<br />from WSL that uses<br />robocopy.exe to mirror<br />selected Windows profile<br />directories/files to the SMB<br />share and writes a Windows<br />sync manifest.</div>"]
        style 110 fill:#ecfeff,stroke:#0891b2,color:#111827
        113["<div style='font-weight: bold'>Selected Windows source artifacts</div><div style='font-size: 70%; margin-top: 0px'>[Infrastructure Node: NTFS]</div><div style='font-size: 80%; margin-top:10px'>Desktop, Documents,<br />Downloads, .ssh, .wslconfig,<br />Windows Terminal, VS Code,<br />PowerShell, Chrome profile<br />metadata, and Startup<br />entries.</div>"]
        style 113 fill:#f8fafc,stroke:#64748b,color:#111827
      end

      subgraph 86 ["WSL2 Ubuntu-22.04"]
        style 86 fill:#ffffff,stroke:#444444,color:#444444

        subgraph 103 ["Local backup state"]
          style 103 fill:#ffffff,stroke:#444444,color:#444444

          104[("<div style='font-weight: bold'>Run Ledger and Local State</div><div style='font-size: 70%; margin-top: 0px'>[Container: SQLite + JSON + logs on WSL filesystem]</div><div style='font-size: 80%; margin-top:10px'>Local status, logs, SQLite<br />run ledger, exported<br />run-history JSON, SQLite<br />snapshot cache, and Windows<br />manifest cache under<br />~/.local/state/workstation-workflow-backup.</div>")]
          style 104 fill:#fef3c7,stroke:#d97706,color:#111827
        end

        subgraph 87 ["systemd --user"]
          style 87 fill:#ffffff,stroke:#444444,color:#444444

          88("<div style='font-weight: bold'>systemd User Timer and Service</div><div style='font-size: 70%; margin-top: 0px'>[Container: systemd --user units]</div><div style='font-size: 80%; margin-top:10px'>Hourly user-level scheduler<br />and oneshot service that run<br />the backup at minute 45 and<br />route failures to the<br />notifier.</div>")
          style 88 fill:#e0e7ff,stroke:#4f46e5,color:#111827
          89["<div style='font-weight: bold'>Backup Orchestrator</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash]</div><div style='font-size: 80%; margin-top:10px'>scripts/workflow-backup.sh<br />coordinates one backup run:<br />locking, logging, pre/post<br />guard checks, WSL rsync,<br />SQLite snapshots, Windows<br />sync, run-ledger updates, and<br />NAS manifest publication.</div>"]
          style 89 fill:#e0f2fe,stroke:#0284c7,color:#111827
          91["<div style='font-weight: bold'>Failure Notifier</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + Python urllib]</div><div style='font-size: 80%; margin-top:10px'>Best-effort Telegram failure<br />alert unit that reads last<br />status/log tail and Hermes<br />bot environment variables;<br />success runs stay silent.</div>"]
          style 91 fill:#ecfeff,stroke:#0891b2,color:#111827
        end

        subgraph 94 ["Repo scripts"]
          style 94 fill:#ffffff,stroke:#444444,color:#444444

          100["<div style='font-weight: bold'>Backup Verifier</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + systemctl + SSH]</div><div style='font-size: 80%; margin-top:10px'>Operational verification<br />script that checks the local<br />timer, last status, run<br />ledger, growth guard, NAS<br />dataset, snapshots,<br />manifests, snapshot tasks,<br />and retired cron jobs.</div>"]
          style 100 fill:#ecfeff,stroke:#0891b2,color:#111827
          95["<div style='font-weight: bold'>SQLite Snapshotter</div><div style='font-size: 70%; margin-top: 0px'>[Container: Python 3, sqlite3]</div><div style='font-size: 80%; margin-top:10px'>Creates<br />application-consistent copies<br />of Hermes, lifelog,<br />browser-memory, and related<br />SQLite databases using<br />sqlite3 backup API; can<br />quick_check copies.</div>"]
          style 95 fill:#ecfeff,stroke:#0891b2,color:#111827
          97["<div style='font-weight: bold'>NAS Growth Guard</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + remote Python + zfs CLI]</div><div style='font-size: 80%; margin-top:10px'>Read-only ZFS budget check<br />that enforces dataset-used,<br />snapshot-held, free-space,<br />and snapshot-count limits<br />before/after writes.</div>"]
          style 97 fill:#ecfeff,stroke:#0891b2,color:#111827
          99["<div style='font-weight: bold'>NAS Provisioner</div><div style='font-size: 70%; margin-top: 0px'>[Container: Bash + remote Python + midclt/zfs]</div><div style='font-size: 80%; margin-top:10px'>Idempotent provisioning<br />script for the TrueNAS<br />dataset, SMB share, periodic<br />snapshot tasks, and retired<br />legacy snapshot cron jobs.</div>"]
          style 99 fill:#ecfeff,stroke:#0891b2,color:#111827
        end

      end

    end

    100-. "<div>Checks enabled/active timer<br />state through</div><div style='font-size: 70%'>[systemctl --user]</div>" .->88
    100-. "<div>Runs read-only guard<br />verification through</div><div style='font-size: 70%'>[subprocess]</div>" .->97
    89-. "<div>Writes logs, last-run.json,<br />run events, and exported<br />history in</div><div style='font-size: 70%'>[filesystem + sqlite3]</div>" .->104
    91-. "<div>Reads last status and log<br />tail from</div><div style='font-size: 70%'>[filesystem]</div>" .->104
    95-. "<div>Writes local SQLite snapshot<br />cache and manifest under</div><div style='font-size: 70%'>[filesystem]</div>" .->104
    100-. "<div>Reads local last status and<br />recent run ledger from</div><div style='font-size: 70%'>[filesystem + sqlite3]</div>" .->104
    89-. "<div>Launches Windows sync through</div><div style='font-size: 70%'>[PowerShell via WSL interop]</div>" .->110
    110-. "<div>Leaves manifest cache for<br />ledger summaries</div><div style='font-size: 70%'></div>" .->104
    88-. "<div>Starts hourly at :45 and<br />tracks service exit</div><div style='font-size: 70%'>[systemd --user]</div>" .->89
    88-. "<div>Triggers on nonzero service<br />result</div><div style='font-size: 70%'>[OnFailure]</div>" .->91
    89-. "<div>Exits nonzero so systemd can<br />alert through</div><div style='font-size: 70%'></div>" .->91
    89-. "<div>Creates consistent SQLite<br />backup copies with</div><div style='font-size: 70%'>[subprocess]</div>" .->95
    89-. "<div>Runs pre/post budget checks<br />through</div><div style='font-size: 70%'>[subprocess]</div>" .->97

  end
```

</details>

## Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-LocalDeployment.mmd`](../structurizr-LocalDeployment.mmd) |
| Mermaid SVG | [`structurizr-LocalDeployment.svg`](../structurizr-LocalDeployment.svg) |
| Mermaid PNG | [`structurizr-LocalDeployment.png`](../structurizr-LocalDeployment.png) |
| DOT source | [`structurizr-LocalDeployment.dot`](../dot/structurizr-LocalDeployment.dot) |
| Graphviz SVG | [`structurizr-LocalDeployment.svg`](../dot-rendered/structurizr-LocalDeployment.svg) |
| Graphviz PNG | [`structurizr-LocalDeployment.png`](../dot-rendered/structurizr-LocalDeployment.png) |
