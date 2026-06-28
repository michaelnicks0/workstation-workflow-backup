# Failure Alert Flow

> Generated Markdown wrapper for C4 view `FailureAlertFlow`. Canonical model: [`workspace.dsl`](../../workspace.dsl).

<!-- Generated from Structurizr exports; refresh from docs/architecture/workspace.dsl. -->

## Diagram

![Failure Alert Flow](../dot-rendered/structurizr-FailureAlertFlow.svg)

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

## Derived artifacts

| Artifact | Link |
|---|---|
| Mermaid source | [`structurizr-FailureAlertFlow.mmd`](../structurizr-FailureAlertFlow.mmd) |
| Mermaid SVG | [`structurizr-FailureAlertFlow.svg`](../structurizr-FailureAlertFlow.svg) |
| Mermaid PNG | [`structurizr-FailureAlertFlow.png`](../structurizr-FailureAlertFlow.png) |
| DOT source | [`structurizr-FailureAlertFlow.dot`](../dot/structurizr-FailureAlertFlow.dot) |
| Graphviz SVG | [`structurizr-FailureAlertFlow.svg`](../dot-rendered/structurizr-FailureAlertFlow.svg) |
| Graphviz PNG | [`structurizr-FailureAlertFlow.png`](../dot-rendered/structurizr-FailureAlertFlow.png) |
