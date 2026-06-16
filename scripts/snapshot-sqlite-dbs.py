#!/usr/bin/env python3
"""Create application-consistent SQLite backup copies for workflow DBs."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sqlite3
import sys
import time
from pathlib import Path
from typing import Iterable
from urllib.parse import quote

SQLITE_HEADER = b"SQLite format 3\x00"
HOME = Path.home().resolve()


def has_sqlite_header(path: Path) -> bool:
    try:
        with path.open("rb") as handle:
            return handle.read(16) == SQLITE_HEADER
    except OSError:
        return False


def is_sidecar(path: Path) -> bool:
    name = path.name.lower()
    return name.endswith(("-wal", "-shm", "-journal")) or name.endswith((".db-wal", ".db-shm"))


def under(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def discover_databases() -> list[Path]:
    candidates: set[Path] = set()
    explicit = [
        HOME / ".hermes/state.db",
        HOME / ".hermes/kanban.db",
        HOME / ".hermes/ai-usage.db",
        HOME / ".local/share/lifelog/lifelog.sqlite3",
        HOME / ".local/share/browser-memory-daemon/browser-memory.sqlite3",
    ]
    candidates.update(path for path in explicit if path.exists())

    globs = [
        HOME / ".hermes/kanban/boards/*/*.db",
        HOME / ".hermes/profiles/*/state.db",
        HOME / ".local/share/lifelog/**/*.sqlite*",
        HOME / ".local/share/browser-memory-daemon/**/*.sqlite*",
    ]
    for pattern in globs:
        candidates.update(Path(p) for p in HOME.glob(str(pattern.relative_to(HOME))))

    skip_roots = [
        HOME / ".hermes/hermes-agent/venv",
        HOME / ".hermes/hermes-agent/.git",
        HOME / ".hermes/state-snapshots",
    ]
    discovered = []
    for path in sorted(candidates):
        try:
            resolved = path.resolve()
        except OSError:
            continue
        if not resolved.is_file() or is_sidecar(resolved):
            continue
        if any(under(resolved, root) for root in skip_roots if root.exists()):
            continue
        if not has_sqlite_header(resolved):
            continue
        discovered.append(resolved)
    return discovered


def relative_output_path(src: Path, output_root: Path) -> Path:
    if under(src, HOME):
        rel = Path("home") / HOME.name / src.relative_to(HOME)
    else:
        rel = Path("absolute") / Path(str(src).lstrip("/"))
    return output_root / rel


def backup_sqlite(src: Path, dest: Path, quick_check: bool) -> dict[str, object]:
    started = time.time()
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_name(f".{dest.name}.tmp-{os.getpid()}")
    if tmp.exists():
        tmp.unlink()

    uri = "file:" + quote(str(src)) + "?mode=ro"
    source = sqlite3.connect(uri, uri=True, timeout=30.0)
    try:
        target = sqlite3.connect(str(tmp), timeout=30.0)
        try:
            source.backup(target, pages=4096)
            target.commit()
        finally:
            target.close()
    finally:
        source.close()

    if quick_check:
        check_conn = sqlite3.connect(str(tmp), timeout=30.0)
        try:
            result = check_conn.execute("PRAGMA quick_check").fetchone()
            if not result or str(result[0]).lower() != "ok":
                raise RuntimeError(f"quick_check failed for {src}: {result!r}")
        finally:
            check_conn.close()

    os.replace(tmp, dest)
    src_stat = src.stat()
    dest_stat = dest.stat()
    return {
        "source": str(src),
        "dest": str(dest),
        "source_size": src_stat.st_size,
        "dest_size": dest_stat.st_size,
        "duration_seconds": round(time.time() - started, 3),
        "quick_check": quick_check,
    }


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, help="Output directory for SQLite backup tree")
    parser.add_argument("--manifest", default=None, help="Manifest path; defaults to <output>/_manifest.json")
    parser.add_argument("--quick-check", action="store_true", help="Run PRAGMA quick_check on each backup copy")
    args = parser.parse_args(argv)

    output_root = Path(args.output).expanduser().resolve()
    output_root.mkdir(parents=True, exist_ok=True)
    manifest_path = Path(args.manifest).expanduser().resolve() if args.manifest else output_root / "_manifest.json"

    records: list[dict[str, object]] = []
    failures: list[dict[str, str]] = []
    started = time.time()
    for src in discover_databases():
        dest = relative_output_path(src, output_root)
        try:
            records.append(backup_sqlite(src, dest, args.quick_check))
        except Exception as exc:  # noqa: BLE001 - manifest should record every failed DB path.
            failures.append({"source": str(src), "error": repr(exc)})

    manifest = {
        "kind": "workflow-sqlite-snapshot-manifest",
        "generated_at_epoch": round(time.time(), 3),
        "duration_seconds": round(time.time() - started, 3),
        "host": os.uname().nodename,
        "database_count": len(records),
        "failure_count": len(failures),
        "records": records,
        "failures": failures,
    }
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")

    print(json.dumps({"database_count": len(records), "failure_count": len(failures), "manifest": str(manifest_path)}, sort_keys=True))
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
