#!/usr/bin/env python3
"""Record and query WORKSTATION1 workflow backup run events."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import socket
import sqlite3
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

VALID_EVENT_TYPES = {"started", "completed", "failed", "skipped_lock"}
VALID_STATUSES = {"running", "ok", "failed", "skipped"}
SCHEMA_VERSION = 1

SCHEMA_SQL = f"""
CREATE TABLE IF NOT EXISTS run_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id TEXT NOT NULL,
    event_type TEXT NOT NULL CHECK (event_type IN ('started', 'completed', 'failed', 'skipped_lock')),
    status TEXT NOT NULL CHECK (status IN ('running', 'ok', 'failed', 'skipped')),
    occurred_at TEXT NOT NULL,
    host TEXT NOT NULL,
    dry_run INTEGER NOT NULL CHECK (dry_run IN (0, 1)),
    log_file TEXT,
    duration_seconds INTEGER,
    error TEXT NOT NULL DEFAULT '',
    sqlite_database_count INTEGER,
    sqlite_failure_count INTEGER,
    windows_result_count INTEGER,
    windows_failure_count INTEGER,
    details_json TEXT NOT NULL DEFAULT '{{}}'
);
CREATE INDEX IF NOT EXISTS idx_run_events_run_id_id ON run_events(run_id, id);
CREATE INDEX IF NOT EXISTS idx_run_events_occurred_at ON run_events(occurred_at);
CREATE INDEX IF NOT EXISTS idx_run_events_status ON run_events(status);
CREATE VIEW IF NOT EXISTS latest_runs AS
SELECT e.*
FROM run_events AS e
JOIN (
    SELECT run_id, max(id) AS latest_event_id
    FROM run_events
    GROUP BY run_id
) AS latest ON latest.latest_event_id = e.id;
PRAGMA user_version = {SCHEMA_VERSION};
"""


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_bool(value: str | bool | int) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, int):
        return bool(value)
    normalized = value.strip().lower()
    if normalized in {"1", "true", "yes", "y"}:
        return True
    if normalized in {"0", "false", "no", "n"}:
        return False
    raise argparse.ArgumentTypeError(f"expected boolean-like value, got {value!r}")


def connect(db_path: Path) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path), timeout=30.0)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA busy_timeout = 30000")
    return conn


def ensure_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(SCHEMA_SQL)
    conn.commit()


def load_json(path: Path) -> dict[str, Any] | None:
    if not path or not path.exists():
        return None
    with path.open("r", encoding="utf-8-sig") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"expected JSON object in {path}")
    return data


def int_or_none(value: Any) -> int | None:
    if value is None:
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def collect_sqlite_manifest(path: Path | None) -> tuple[int | None, int | None, dict[str, Any]]:
    if path is None:
        return None, None, {}
    data = load_json(path)
    if data is None:
        return None, None, {"sqlite_manifest_missing": str(path)}
    details: dict[str, Any] = {
        "sqlite_manifest": str(path),
        "sqlite_manifest_generated_at_epoch": data.get("generated_at_epoch"),
        "sqlite_manifest_duration_seconds": data.get("duration_seconds"),
    }
    return int_or_none(data.get("database_count")), int_or_none(data.get("failure_count")), details


def collect_windows_manifest(path: Path | None) -> tuple[int | None, int | None, dict[str, Any]]:
    if path is None:
        return None, None, {}
    data = load_json(path)
    if data is None:
        return None, None, {"windows_manifest_missing": str(path)}
    results = data.get("results")
    if not isinstance(results, list):
        results = []
    failure_count = 0
    for item in results:
        if not isinstance(item, dict):
            continue
        status = str(item.get("status", "")).lower()
        exit_code = int_or_none(item.get("robocopy_exit_code"))
        if status == "failed" or (exit_code is not None and exit_code >= 8):
            failure_count += 1
    details: dict[str, Any] = {
        "windows_manifest": str(path),
        "windows_manifest_started_at": data.get("started_at"),
        "windows_manifest_finished_at": data.get("finished_at"),
        "windows_manifest_duration_seconds": data.get("duration_seconds"),
    }
    return len(results), failure_count, details


def insert_event(args: argparse.Namespace) -> None:
    event_type = args.event_type
    status = args.status
    if event_type not in VALID_EVENT_TYPES:
        raise ValueError(f"invalid event type: {event_type}")
    if status not in VALID_STATUSES:
        raise ValueError(f"invalid status: {status}")

    sqlite_count, sqlite_failures, sqlite_details = collect_sqlite_manifest(args.sqlite_manifest)
    windows_count, windows_failures, windows_details = collect_windows_manifest(args.windows_manifest)
    details = {**sqlite_details, **windows_details}
    if args.details_json:
        extra = json.loads(args.details_json)
        if not isinstance(extra, dict):
            raise ValueError("--details-json must be a JSON object")
        details.update(extra)

    db_path = args.db.expanduser().resolve()
    conn = connect(db_path)
    try:
        ensure_schema(conn)
        conn.execute(
            """
            INSERT INTO run_events (
                run_id, event_type, status, occurred_at, host, dry_run, log_file,
                duration_seconds, error, sqlite_database_count, sqlite_failure_count,
                windows_result_count, windows_failure_count, details_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                args.run_id,
                event_type,
                status,
                utc_now(),
                socket.gethostname(),
                1 if parse_bool(args.dry_run) else 0,
                str(args.log_file) if args.log_file else None,
                args.duration_seconds,
                args.error or "",
                sqlite_count,
                sqlite_failures,
                windows_count,
                windows_failures,
                json.dumps(details, sort_keys=True),
            ),
        )
        conn.commit()
    finally:
        conn.close()


def row_to_dict(row: sqlite3.Row) -> dict[str, Any]:
    data = dict(row)
    data["dry_run"] = bool(data.get("dry_run"))
    try:
        data["details"] = json.loads(data.pop("details_json") or "{}")
    except json.JSONDecodeError:
        data["details"] = {}
    return data


def latest_rows(db_path: Path, limit: int) -> list[dict[str, Any]]:
    resolved = db_path.expanduser().resolve()
    if not resolved.exists():
        return []
    conn = connect(resolved)
    try:
        ensure_schema(conn)
        rows = conn.execute(
            """
            SELECT *
            FROM latest_runs
            ORDER BY id DESC
            LIMIT ?
            """,
            (limit,),
        ).fetchall()
        return [row_to_dict(row) for row in rows]
    finally:
        conn.close()


def print_status(args: argparse.Namespace) -> None:
    rows = latest_rows(args.db, args.limit)
    if args.json:
        print(json.dumps({"kind": "workflow-backup-run-ledger-status", "runs": rows}, indent=2, sort_keys=True))
        return
    if not rows:
        print("No run ledger events recorded yet.")
        return
    print("occurred_at            status   dur  dry  sqlite  win  run_id")
    for row in rows:
        duration = "-" if row["duration_seconds"] is None else str(row["duration_seconds"])
        sqlite_summary = "-"
        if row["sqlite_database_count"] is not None:
            sqlite_summary = f"{row['sqlite_database_count']}/{row['sqlite_failure_count'] or 0}"
        windows_summary = "-"
        if row["windows_result_count"] is not None:
            windows_summary = f"{row['windows_result_count']}/{row['windows_failure_count'] or 0}"
        dry = "Y" if row["dry_run"] else "N"
        print(
            f"{row['occurred_at']:<22} {row['status']:<7} {duration:<4} {dry:<4} "
            f"{sqlite_summary:<7} {windows_summary:<4} {row['run_id']}"
        )


def export_json(args: argparse.Namespace) -> None:
    rows = latest_rows(args.db, args.limit)
    output = args.output_json.expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "kind": "workflow-backup-run-history",
        "generated_at": utc_now(),
        "limit": args.limit,
        "runs": rows,
    }
    tmp = output.with_name(f".{output.name}.tmp-{os.getpid()}")
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, output)


def snapshot_db(args: argparse.Namespace) -> None:
    source = args.db.expanduser().resolve()
    output = args.output.expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    tmp = output.with_name(f".{output.name}.tmp-{os.getpid()}")
    if tmp.exists():
        tmp.unlink()
    src = connect(source)
    try:
        ensure_schema(src)
        dst = sqlite3.connect(str(tmp), timeout=30.0)
        try:
            src.backup(dst)
            dst.commit()
        finally:
            dst.close()
    finally:
        src.close()
    shutil.copymode(source, tmp) if source.exists() else None
    os.replace(tmp, output)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    event = subparsers.add_parser("event", help="append a run event")
    event.add_argument("--db", type=Path, required=True)
    event.add_argument("--run-id", required=True)
    event.add_argument("--event-type", required=True, choices=sorted(VALID_EVENT_TYPES))
    event.add_argument("--status", required=True, choices=sorted(VALID_STATUSES))
    event.add_argument("--dry-run", required=True)
    event.add_argument("--log-file", type=Path)
    event.add_argument("--duration-seconds", type=int)
    event.add_argument("--error", default="")
    event.add_argument("--sqlite-manifest", type=Path)
    event.add_argument("--windows-manifest", type=Path)
    event.add_argument("--details-json")
    event.set_defaults(func=insert_event)

    status = subparsers.add_parser("status", help="print recent latest run statuses")
    status.add_argument("--db", type=Path, required=True)
    status.add_argument("--limit", type=int, default=12)
    status.add_argument("--json", action="store_true")
    status.set_defaults(func=print_status)

    export = subparsers.add_parser("export-json", help="export recent latest run statuses to JSON")
    export.add_argument("--db", type=Path, required=True)
    export.add_argument("--output-json", type=Path, required=True)
    export.add_argument("--limit", type=int, default=100)
    export.set_defaults(func=export_json)

    snapshot = subparsers.add_parser("snapshot-db", help="write a consistent SQLite copy")
    snapshot.add_argument("--db", type=Path, required=True)
    snapshot.add_argument("--output", type=Path, required=True)
    snapshot.set_defaults(func=snapshot_db)

    return parser


def main(argv: Iterable[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        args.func(args)
    except Exception as exc:  # noqa: BLE001 - operator tooling should print concise failures.
        print(f"record-run-ledger.py: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
