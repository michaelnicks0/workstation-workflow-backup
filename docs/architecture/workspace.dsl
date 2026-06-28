workspace "WORKSTATION1 Workflow Backup" "C4 architecture model for the high-frequency WORKSTATION1 to TrueNAS workflow backup system." {
    model {
        michael = person "Michael" "Sole operator who installs, verifies, and restores WORKSTATION1 workflow backups."

        workflowBackup = softwareSystem "WORKSTATION1 Workflow Backup" "Repo-owned backup automation that mirrors workflow-critical WSL and Windows artifacts to TrueNAS through a restricted runtime identity, preserves rollback points with ZFS snapshots, records run history, writes restore checksums, and alerts only on failure." {
            systemdTimer = container "systemd User Timer and Service" "Hourly user-level scheduler and oneshot service that run the backup at minute 45 and route failures to the notifier." "systemd --user units" {
                tags "Scheduler"
            }

            backupOrchestrator = container "Backup Orchestrator" "scripts/workflow-backup.sh coordinates one backup run: locking, log pruning, pre/post guard checks, WSL rsync, SQLite snapshots, Windows sync, strict final ledger updates, NAS manifest publication, and restore-checksum generation." "Bash" {
                argumentParser = component "Argument Parser" "Handles --dry-run, --verbose, --skip-windows, --skip-wsl, and --quick-check-sqlite flags." "Bash case parser"
                lockAndRunIdentity = component "Lock and Run Identity" "Creates the local state/log directories, acquires a flock lock, generates run_id, and skips concurrent runs silently." "Bash + flock"
                logStatusWriter = component "Log and Last-Status Writer" "Prunes old local logs and writes per-run logs plus last-run.json with host, status, duration, dry-run, error, and log path." "Bash + Python JSON helper"
                ledgerAdapter = component "Run Ledger Adapter" "Appends started/completed/failed/skipped events with SQLite and Windows manifest summaries." "record-run-ledger.py CLI"
                guardRunner = component "Growth Guard Runner" "Invokes check-nas-growth-guard.sh before and after writes and fails closed on budget violations." "Bash subprocess"
                sqlitePhase = component "SQLite Snapshot Phase" "Runs the SQLite backup API snapshotter and mirrors the consistent DB snapshot tree to NAS." "Python subprocess + rsync"
                wslSyncPhase = component "WSL Rsync Phase" "Mirrors configured WSL directories to current/wsl using sudo rsync over SSH with payload exclusions." "rsync over SSH"
                windowsPhase = component "Windows Phase Launcher" "Copies the PowerShell helper to Windows temp and launches it through direct WSL interop or /init fallback." "Bash + WSL interop"
                statusPublisher = component "NAS Status Publisher" "Exports the run ledger to JSON/SQLite snapshots and rsyncs last-run/run-history manifests to NAS through the restricted runtime SSH boundary." "Python + rsync over restricted SSH"
                integrityPhase = component "Integrity Manifest Phase" "Runs the NAS-side checksum helper after successful status publication to write restore-critical SHA-256 evidence." "Bash + restricted SSH"
                errorTrap = component "Error Trap" "Converts command failures into failed status, ledger event, best-effort NAS status sync, and nonzero service exit." "Bash ERR trap"
            }

            sqliteSnapshotter = container "SQLite Snapshotter" "Creates application-consistent copies of Hermes, lifelog, browser-memory, and related SQLite databases using sqlite3 backup API; can quick_check copies." "Python 3, sqlite3" {
                tags "Script"
            }

            windowsSyncHelper = container "Windows Critical Sync Helper" "PowerShell script launched from WSL that uses robocopy.exe to mirror selected Windows profile directories/files to the SMB share and writes a Windows sync manifest." "PowerShell + robocopy.exe" {
                tags "Script"
            }

            growthGuard = container "NAS Growth Guard" "Read-only NAS-side ZFS budget check that enforces dataset-used, snapshot-held, availability-dataset free-space, and snapshot-count limits before/after writes." "Bash + NAS sudo helper + zfs CLI" {
                tags "Script"
            }

            integrityManifestBuilder = container "NAS Integrity Manifest Builder" "NAS-side helper that hashes restore-critical current-tree artifacts and writes _manifests/integrity-manifest.json for snapshot-preserved restore verification." "Python + SHA-256" {
                tags "Script"
            }

            runtimeSshBoundary = container "Restricted NAS Runtime SSH Boundary" "Dedicated runtime NAS user/key, pinned host-key verification, forced-command dispatcher, sudo allowlist, and refquota-backed current-tree write boundary." "OpenSSH forced command + sudoers + ZFS refquota" {
                tags "Script"
            }

            nasProvisioner = container "NAS Provisioner" "Idempotent provisioning script for the TrueNAS dataset, SMB share, periodic snapshot tasks, refquota, and retired legacy snapshot cron jobs." "Bash + admin SSH + remote Python + midclt/zfs" {
                tags "Script"
            }

            nasRuntimeHardener = container "NAS Runtime Hardening Installer" "Installs or updates the dedicated runtime user/key, forced-command dispatcher, NAS-side guard/integrity helpers, sudo allowlist, runtime-writable subtrees, host-key pinning config, and dataset refquota." "Bash + admin SSH + TrueNAS middleware" {
                tags "Script"
            }

            verifier = container "Backup Verifier" "Operational verification script that checks the local timer, last status, run ledger, growth guard, NAS dataset, snapshots, manifests, integrity summary, snapshot tasks, and retired cron jobs." "Bash + systemctl + SSH" {
                tags "Script"
            }

            failureNotifier = container "Failure Notifier" "Best-effort Telegram failure alert unit that reads last status/log tail and Hermes bot environment variables; success runs stay silent." "Bash + Python urllib" {
                tags "Script"
            }

            runLedger = container "Run Ledger and Local State" "Local status, pruned logs, SQLite run ledger, exported run-history JSON, SQLite snapshot cache, and Windows manifest cache under ~/.local/state/workstation-workflow-backup." "SQLite + JSON + logs on WSL filesystem" {
                tags "Data Store", "Database"
            }
        }

        wslSources = softwareSystem "WSL Workflow Sources" "Workflow-critical WSL paths: ~/repos, ~/.hermes, ~/.ssh, systemd user config, lifelog/browser-memory data, and optional brain-code tree." {
            tags "External", "Data Store"
        }
        windowsSources = softwareSystem "Windows Workflow Sources" "Selected Windows user-profile artifacts: Desktop, Documents, Downloads, Windows .ssh/.wslconfig, Terminal/VS Code/PowerShell config, Chrome profile metadata, and Startup entries." {
            tags "External", "Data Store"
        }
        trueNasDataset = softwareSystem "TrueNAS Backup Dataset" "Configured encrypted TrueNAS dataset with current mirror tree, manifests, SMB share, restore checksum manifest, refquota, and ZFS snapshot history." {
            tags "External", "Data Store", "Database"
        }
        trueNasControlPlane = softwareSystem "TrueNAS Middleware and ZFS Control Plane" "Configured admin SSH and middleware surface used for ZFS properties, runtime-user setup, snapshot tasks, SMB share configuration, and verification." {
            tags "External"
        }
        hermesBotEnv = softwareSystem "Hermes Bot Environment File" "Local ~/.hermes/.env values that supply Telegram bot token/chat settings to the failure notifier; contents are not stored in this repo." {
            tags "External", "Data Store"
        }
        telegramBotApi = softwareSystem "Telegram Bot API" "External API used only for backup failure notifications." {
            tags "External"
        }
        operatorShell = softwareSystem "Operator Shell and Restore Tools" "Local shell, rsync, SSH, Windows Previous Versions, and README/runbook commands used for verification and targeted restores." {
            tags "External"
        }

        michael -> workflowBackup "Installs, verifies, and restores through"
        michael -> operatorShell "Runs backup, verification, provisioning, and restore commands from"
        operatorShell -> workflowBackup "Executes scripts and reads documentation in" "shell"
        operatorShell -> verifier "Runs backup health checks through" "shell"
        operatorShell -> trueNasControlPlane "Lists snapshots and inspects NAS state through" "admin SSH + zfs/midclt"
        operatorShell -> trueNasDataset "Restores selected files from .zfs/snapshot/current paths" "SSH rsync or SMB Previous Versions"

        systemdTimer -> backupOrchestrator "Starts hourly at :45 and tracks service exit" "systemd --user"
        systemdTimer -> failureNotifier "Triggers on nonzero service result" "OnFailure"
        backupOrchestrator -> runLedger "Writes logs, last-run.json, run events, and exported history in" "filesystem + sqlite3"
        backupOrchestrator -> growthGuard "Runs pre/post budget checks through" "subprocess"
        growthGuard -> trueNasControlPlane "Reads ZFS used, availability, usedbysnapshots, and snapshot count from" "NAS-side helper + zfs"
        backupOrchestrator -> sqliteSnapshotter "Creates consistent SQLite backup copies with" "subprocess"
        sqliteSnapshotter -> wslSources "Reads live SQLite databases from" "sqlite3 backup API"
        sqliteSnapshotter -> runLedger "Writes local SQLite snapshot cache and manifest under" "filesystem"
        backupOrchestrator -> wslSources "Mirrors configured WSL source trees from" "sudo rsync"
        backupOrchestrator -> runtimeSshBoundary "Connects with dedicated runtime key and pinned host-key verification through" "SSH"
        runtimeSshBoundary -> trueNasDataset "Allows receiver-mode rsync and mkdir only under current tree" "forced command + rsync"
        runtimeSshBoundary -> growthGuard "Allows sudo execution of guard helper only" "forced command + sudo"
        runtimeSshBoundary -> integrityManifestBuilder "Allows sudo execution of integrity helper only" "forced command + sudo"
        backupOrchestrator -> trueNasDataset "Writes current/wsl, wsl-sqlite-snapshots, and _manifests to" "restricted SSH rsync"
        backupOrchestrator -> windowsSyncHelper "Launches Windows sync through" "PowerShell via WSL interop"
        windowsSyncHelper -> windowsSources "Mirrors selected Windows artifacts from" "robocopy.exe"
        windowsSyncHelper -> trueNasDataset "Writes current/windows and Windows manifests to" "SMB share"
        windowsSyncHelper -> runLedger "Leaves manifest cache for ledger summaries"
        backupOrchestrator -> integrityManifestBuilder "Runs restore-critical checksum manifest generation through" "restricted SSH"
        integrityManifestBuilder -> trueNasDataset "Hashes NAS current-tree critical artifacts and writes integrity-manifest.json to" "SHA-256 + filesystem"
        backupOrchestrator -> failureNotifier "Exits nonzero so systemd can alert through"

        failureNotifier -> runLedger "Reads last status and log tail from" "filesystem"
        failureNotifier -> hermesBotEnv "Reads Telegram bot token/chat values from" "filesystem"
        failureNotifier -> telegramBotApi "Sends failure-only notification to" "HTTPS"

        nasProvisioner -> trueNasControlPlane "Creates/updates dataset, SMB share, snapshot tasks, refquota, and disabled retired cron jobs through" "admin SSH + zfs + midclt"
        nasProvisioner -> trueNasDataset "Configures mountpoint, SMB share, refquota, and snapshot naming/retention for"
        nasRuntimeHardener -> trueNasControlPlane "Creates runtime user/key, forced command, sudo allowlist, helper scripts, and pinned host-key boundary through" "admin SSH + middleware"
        nasRuntimeHardener -> trueNasDataset "Owns runtime-writable current subtrees and applies refquota for"
        verifier -> systemdTimer "Checks enabled/active timer state through" "systemctl --user"
        verifier -> runLedger "Reads local last status and recent run ledger from" "filesystem + sqlite3"
        verifier -> growthGuard "Runs read-only guard verification through" "subprocess"
        verifier -> trueNasControlPlane "Reads dataset, snapshot tasks, and retired cron job state from" "SSH + midclt + zfs"
        verifier -> trueNasDataset "Checks required backup paths, status manifests, and integrity manifest in"

        argumentParser -> lockAndRunIdentity "Passes selected run mode to"
        lockAndRunIdentity -> logStatusWriter "Initializes log and status paths for"
        lockAndRunIdentity -> ledgerAdapter "Records skipped_lock when another run is active"
        ledgerAdapter -> runLedger "Writes run events to" "sqlite3"
        logStatusWriter -> runLedger "Writes last-run.json and logs to" "filesystem"
        guardRunner -> growthGuard "Executes guard stages through"
        guardRunner -> logStatusWriter "Stores guard failure message through"
        sqlitePhase -> sqliteSnapshotter "Creates consistent DB snapshot tree through"
        sqlitePhase -> trueNasDataset "Mirrors DB snapshot tree to" "rsync"
        wslSyncPhase -> wslSources "Reads configured WSL paths from" "filesystem"
        wslSyncPhase -> trueNasDataset "Mirrors WSL trees to" "rsync over SSH"
        windowsPhase -> windowsSyncHelper "Launches and monitors" "PowerShell"
        windowsPhase -> trueNasDataset "Uses SMB root for Windows helper destination"
        statusPublisher -> runLedger "Snapshots ledger DB and exports run history from" "sqlite3"
        statusPublisher -> trueNasDataset "Publishes _manifests/last-run.json, runs.sqlite3, and run-history.json to" "restricted SSH rsync"
        integrityPhase -> integrityManifestBuilder "Requests restore checksum manifest from"
        integrityPhase -> trueNasDataset "Publishes integrity-manifest.json through" "NAS-side helper"
        errorTrap -> logStatusWriter "Marks failed status through"
        errorTrap -> ledgerAdapter "Records failed event through"
        errorTrap -> statusPublisher "Best-effort syncs failure status through"

        localDeployment = deploymentEnvironment "WORKSTATION1 local plus TrueNAS" {
            workstation = deploymentNode "WORKSTATION1" "Michael's Windows workstation hosting WSL2 and Windows profile sources." "Windows + WSL2" {
                wsl = deploymentNode "WSL2 Ubuntu-22.04" "WSL environment that owns the repo, systemd user timer, local state, SSH client, rsync, and backup scripts." "Ubuntu + systemd --user" {
                    systemdUser = deploymentNode "systemd --user" "User timer and oneshot service installed by scripts/install-systemd-user.sh." "systemd" {
                        containerInstance systemdTimer
                        containerInstance backupOrchestrator
                        containerInstance failureNotifier
                    }
                    repoScripts = deploymentNode "Repo scripts" "Versioned scripts and config template in ~/repos/workstation/workstation-workflow-backup." "Bash/Python/PowerShell source" {
                        containerInstance sqliteSnapshotter
                        containerInstance growthGuard
                        containerInstance integrityManifestBuilder
                        containerInstance runtimeSshBoundary
                        containerInstance nasProvisioner
                        containerInstance nasRuntimeHardener
                        containerInstance verifier
                    }
                    localStateNode = deploymentNode "Local backup state" "~/.local/state/workstation-workflow-backup with last status, logs, ledger DB, exported JSON, and transient manifests." "WSL filesystem" {
                        containerInstance runLedger
                    }
                }
                windowsHost = deploymentNode "Windows user profile" "Windows-side artifacts mirrored by the PowerShell helper through robocopy.exe." "Windows profile + PowerShell" {
                    containerInstance windowsSyncHelper
                    windowsProfileData = infrastructureNode "Selected Windows source artifacts" "Desktop, Documents, Downloads, .ssh, .wslconfig, Windows Terminal, VS Code, PowerShell, Chrome profile metadata, and Startup entries." "NTFS"
                }
            }
            nasHost = deploymentNode "Configured TrueNAS host" "NAS host that receives current mirrors through a restricted runtime key and owns ZFS snapshot retention." "TrueNAS + ZFS + SMB + OpenSSH" {
                zfsDatasetNode = infrastructureNode "Encrypted ZFS backup dataset" "Backup current tree, manifests, integrity manifest, refquota, and snapshot history under the configured NAS path." "ZFS dataset"
                runtimeUserNode = infrastructureNode "Restricted runtime SSH user/key" "Forced-command receiver for rsync writes, guard helper, and integrity helper; no interactive shell path." "OpenSSH authorized_keys"
                smbShareNode = infrastructureNode "SMB backup share" "Windows helper destination with shadow-copy support and mangled names disabled." "Samba SMB"
                snapshotTasksNode = infrastructureNode "TrueNAS periodic snapshot tasks" "wf-h/wf-d/wf-w/wf-m snapshot tasks with 2d/2w/8w/1y lifetimes." "TrueNAS middleware"
            }
            telegramNode = deploymentNode "Telegram" "External notification service used only on backup failure." "SaaS API" {
                telegramApiNode = infrastructureNode "Telegram Bot API" "HTTPS sendMessage endpoint reached by the failure notifier." "HTTPS"
            }
        }
    }

    views {
        systemContext workflowBackup "SystemContext" {
            description "C1: WORKSTATION1 workflow backup system, local source surfaces, TrueNAS target/control plane, and failure-only Telegram notification."
            include michael
            include workflowBackup
            include wslSources
            include windowsSources
            include trueNasDataset
            include trueNasControlPlane
            include telegramBotApi
            include operatorShell
            autoLayout lr
        }

        container workflowBackup "BackupRuntimeContainers" {
            description "C2: hourly runtime path for guarded WSL/Windows sync, consistent SQLite snapshots, run history, and failure notification."
            include systemdTimer
            include backupOrchestrator
            include sqliteSnapshotter
            include windowsSyncHelper
            include growthGuard
            include integrityManifestBuilder
            include runtimeSshBoundary
            include runLedger
            include failureNotifier
            include wslSources
            include windowsSources
            include trueNasDataset
            include trueNasControlPlane
            include hermesBotEnv
            include telegramBotApi
            autoLayout lr
        }

        container workflowBackup "OpsProvisioningContainers" {
            description "C2: operator-facing provisioning, verification, restore, and NAS-control surfaces."
            include michael
            include operatorShell
            include nasProvisioner
            include nasRuntimeHardener
            include verifier
            include growthGuard
            include integrityManifestBuilder
            include runtimeSshBoundary
            include integrityManifestBuilder
            include runtimeSshBoundary
            include runLedger
            include trueNasDataset
            include trueNasControlPlane
            autoLayout lr
        }

        component backupOrchestrator "OrchestratorControlComponents" {
            description "C3: workflow-backup.sh control path for argument handling, locking, status, ledger, guard checks, publication, and error handling."
            include argumentParser
            include lockAndRunIdentity
            include logStatusWriter
            include ledgerAdapter
            include guardRunner
            include statusPublisher
            include integrityPhase
            include errorTrap
            include growthGuard
            include integrityManifestBuilder
            include runtimeSshBoundary
            include integrityManifestBuilder
            include runtimeSshBoundary
            include runLedger
            include trueNasDataset
            include trueNasControlPlane
            autoLayout lr
        }

        component backupOrchestrator "OrchestratorSyncComponents" {
            description "C3: workflow-backup.sh data-movement path for SQLite snapshots, WSL rsync, and Windows robocopy helper launch."
            include sqlitePhase
            include wslSyncPhase
            include windowsPhase
            include sqliteSnapshotter
            include windowsSyncHelper
            include runLedger
            include wslSources
            include windowsSources
            include trueNasDataset
            include runtimeSshBoundary
            autoLayout lr
        }

        dynamic workflowBackup "HourlyPreflightSnapshotFlow" {
            description "First half of a successful hourly run: service start, local status, pre-write guard, and consistent SQLite snapshot creation."
            systemdTimer -> backupOrchestrator "Start oneshot backup service"
            backupOrchestrator -> runLedger "Record started event and open log"
            backupOrchestrator -> growthGuard "Run pre-write guard"
            growthGuard -> trueNasControlPlane "Read ZFS budget values"
            backupOrchestrator -> sqliteSnapshotter "Snapshot live SQLite DBs"
            sqliteSnapshotter -> wslSources "Read live SQLite databases"
            sqliteSnapshotter -> runLedger "Write snapshot manifest/cache"
            backupOrchestrator -> runtimeSshBoundary "Open restricted runtime SSH session"
            backupOrchestrator -> trueNasDataset "Mirror SQLite snapshot tree"
            autoLayout lr
        }

        dynamic workflowBackup "HourlyMirrorPublishFlow" {
            description "Second half of a successful hourly run: WSL and Windows mirroring, post-write guard, ledger completion, NAS manifest publication, and restore checksum generation."
            backupOrchestrator -> wslSources "Read WSL source trees"
            backupOrchestrator -> trueNasDataset "Mirror WSL current tree"
            backupOrchestrator -> windowsSyncHelper "Launch PowerShell robocopy helper"
            windowsSyncHelper -> windowsSources "Read selected Windows artifacts"
            windowsSyncHelper -> trueNasDataset "Mirror Windows current tree and manifest"
            backupOrchestrator -> growthGuard "Run post-write guard"
            growthGuard -> trueNasControlPlane "Read ZFS budget values"
            backupOrchestrator -> runLedger "Record completed event and export history"
            backupOrchestrator -> trueNasDataset "Publish _manifests status files"
            backupOrchestrator -> integrityManifestBuilder "Build restore checksum manifest"
            integrityManifestBuilder -> trueNasDataset "Write integrity-manifest.json"
            autoLayout lr
        }

        dynamic workflowBackup "FailureAlertFlow" {
            description "Failure-only alert path; successful timer runs produce no Telegram message."
            backupOrchestrator -> runLedger "Write failed last-run/log/ledger event"
            backupOrchestrator -> trueNasDataset "Best-effort publish failure manifests"
            backupOrchestrator -> systemdTimer "Exit nonzero"
            systemdTimer -> failureNotifier "Invoke OnFailure notifier"
            failureNotifier -> runLedger "Read last-run.json and log tail"
            failureNotifier -> hermesBotEnv "Load bot token/chat settings"
            failureNotifier -> telegramBotApi "sendMessage backup failure alert"
            autoLayout lr
        }

        dynamic workflowBackup "TargetedRestoreFlow" {
            description "Targeted restore sequence from a ZFS snapshot; restores should stage first, then replace deliberately."
            michael -> operatorShell "Select snapshot before loss/corruption"
            operatorShell -> trueNasControlPlane "List snapshots under configured backup dataset"
            operatorShell -> trueNasDataset "Copy selected .zfs/snapshot/.../current path to restore candidate"
            operatorShell -> trueNasDataset "Read snapshot integrity-manifest.json for checksum comparison"
            operatorShell -> verifier "Run verify-backup.sh after timer resumes"
            autoLayout lr
        }

        deployment workflowBackup "WORKSTATION1 local plus TrueNAS" "LocalDeployment" {
            description "Deployment topology for the local WORKSTATION1 WSL/Windows backup automation and TrueNAS target."
            include *
            autoLayout tb
        }

        styles {
            element "Person" {
                shape Person
                background #dbeafe
                color #111827
                stroke #2563eb
            }
            element "Software System" {
                background #dcfce7
                color #111827
                stroke #16a34a
            }
            element "Container" {
                background #e0f2fe
                color #111827
                stroke #0284c7
            }
            element "Component" {
                background #f0fdf4
                color #111827
                stroke #22c55e
            }
            element "Database" {
                shape Cylinder
                background #fef3c7
                color #111827
                stroke #d97706
            }
            element "Data Store" {
                shape Cylinder
                background #fef3c7
                color #111827
                stroke #d97706
            }
            element "External" {
                background #f3e8ff
                color #111827
                stroke #9333ea
            }
            element "Scheduler" {
                shape RoundedBox
                background #e0e7ff
                color #111827
                stroke #4f46e5
            }
            element "Script" {
                shape Hexagon
                background #ecfeff
                color #111827
                stroke #0891b2
            }
            element "Infrastructure Node" {
                background #f8fafc
                color #111827
                stroke #64748b
            }
            relationship "Relationship" {
                color #475569
                thickness 2
            }
        }
    }
}
