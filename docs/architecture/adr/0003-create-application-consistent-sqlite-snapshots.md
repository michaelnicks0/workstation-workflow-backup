---
id: ADR-0003
status: accepted
date: 2026-06-28
decider: Michael
scope: repo
supersedes: []
superseded_by: []
related: [ADR-0001]
verification:
  - ./scripts/run-tests.sh
  - scripts/snapshot-sqlite-dbs.py --output <state-dir>
  - ./scripts/verify-backup.sh
---

# ADR-0003: Create application-consistent SQLite snapshots

## Context

Several high-value workflow systems store state in SQLite: Hermes, Kanban/profile DBs, ai-usage, lifelog, and browser-memory. Copying live SQLite files through a broad rsync mirror risks inconsistent DB/WAL/SHM combinations and can create restore candidates that look present but fail integrity checks.

## Decision

Before mirroring the broad WSL trees, run `scripts/snapshot-sqlite-dbs.py` to discover relevant SQLite databases and create consistent backup copies with SQLite's backup API. Store those copies under the local state snapshot tree and mirror them to `current/wsl-sqlite-snapshots/...` on the NAS. Exclude live SQLite files from broad mirrors where consistent copies are the authoritative restore source.

## Decision drivers

- Restore DBs from transactionally consistent snapshots, not file-race artifacts.
- Keep broad WSL mirrors useful without trusting live SQLite sidecars.
- Preserve a manifest of database counts, failures, durations, and output paths for the run ledger.
- Allow optional `PRAGMA quick_check` during explicit verification/smoke runs.

## Options considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| SQLite backup API snapshots | Consistent online copies; per-DB manifest; optional quick_check | Requires Python discovery/backup script | Chosen |
| Raw rsync/cp of DB/WAL/SHM files | Simple | Race-prone and harder to validate during active writes | Rejected |
| Stop every app before backup | Strong consistency | Operationally disruptive and brittle for hourly timer | Rejected |
| Rely only on app-native exports | App-specific semantics | Incomplete and inconsistent across local tools | Rejected |

## Consequences

- Positive: DB restore docs can point to `wsl-sqlite-snapshots` as the canonical DB restore tree.
- Positive: run history captures SQLite database/failure counts.
- Negative: discovery rules must stay current as new local DB locations become important.
- Operational: snapshot failure fails the backup run and triggers the normal failure alert path.

## Verification / validation

- `./scripts/run-tests.sh` compiles `scripts/snapshot-sqlite-dbs.py` and exercises ledger handling of SQLite manifest summaries.
- `scripts/workflow-backup.sh --quick-check-sqlite` can request `PRAGMA quick_check` on generated copies.
- `scripts/verify-backup.sh` checks the expected NAS SQLite snapshot path for Hermes `state.db`.
- `docs/restore-runbook.md` directs SQLite restores through `wsl-sqlite-snapshots`.

## Revisit triggers

- A high-value local SQLite database is not discovered by the script.
- Database count or failure count in manifests becomes unreliable.
- A backed-up application moves away from SQLite or requires a stronger application-native export.

## References

- `scripts/snapshot-sqlite-dbs.py`
- `scripts/workflow-backup.sh`
- `scripts/record-run-ledger.py`
- `README.md` backup scope and restore sections.
- `docs/restore-runbook.md`
