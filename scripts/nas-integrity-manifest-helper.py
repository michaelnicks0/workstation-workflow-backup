#!/usr/bin/env python3
"""NAS-side checksum manifest builder for workflow backup restore verification."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import time
from pathlib import Path


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def iter_scope(dataset_path: Path, scope: str) -> list[Path]:
    current = dataset_path / "current"
    if scope == "full":
        return [current]
    return [
        current / "_manifests",
        current / "wsl-sqlite-snapshots",
        current / "windows" / "_manifests",
    ]


def should_skip(path: Path, output: Path) -> bool:
    if path == output or path.name.startswith(".integrity-manifest.tmp-"):
        return True
    parts = set(path.parts)
    return "_logs" in parts


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dataset-path", required=True)
    parser.add_argument("--scope", choices=("critical", "full"), default="critical")
    parser.add_argument("--output", required=True)
    parser.add_argument("--max-file-bytes", type=int, default=0, help="Skip regular files larger than this many bytes; 0 means no limit")
    args = parser.parse_args()

    dataset_path = Path(args.dataset_path).resolve()
    current = dataset_path / "current"
    output = Path(args.output).resolve()
    if not current.is_dir():
        raise SystemExit(f"missing backup current tree: {current}")
    if not str(output).startswith(str(current) + os.sep):
        raise SystemExit(f"output must be under {current}: {output}")

    started = time.time()
    entries: list[dict[str, object]] = []
    skipped: list[dict[str, str]] = []
    roots = iter_scope(dataset_path, args.scope)
    for root in roots:
        if not root.exists():
            skipped.append({"path": str(root.relative_to(dataset_path)), "reason": "missing"})
            continue
        if root.is_file():
            candidates = [root]
        else:
            candidates = [path for path in root.rglob("*") if path.is_file()]
        for path in sorted(candidates):
            try:
                resolved = path.resolve()
                if should_skip(resolved, output):
                    continue
                stat = resolved.stat()
                rel = resolved.relative_to(dataset_path).as_posix()
                if args.max_file_bytes and stat.st_size > args.max_file_bytes:
                    skipped.append({"path": rel, "reason": f"larger-than-{args.max_file_bytes}"})
                    continue
                entries.append(
                    {
                        "path": rel,
                        "size": stat.st_size,
                        "mtime_ns": stat.st_mtime_ns,
                        "sha256": sha256_file(resolved),
                    }
                )
            except Exception as exc:  # noqa: BLE001 - manifest records unreadable files instead of hiding them.
                try:
                    rel = path.relative_to(dataset_path).as_posix()
                except ValueError:
                    rel = str(path)
                skipped.append({"path": rel, "reason": repr(exc)})

    payload = {
        "kind": "workflow-backup-integrity-manifest",
        "generated_at_epoch": round(time.time(), 3),
        "duration_seconds": round(time.time() - started, 3),
        "dataset_path": str(dataset_path),
        "scope": args.scope,
        "entry_count": len(entries),
        "skipped_count": len(skipped),
        "entries": entries,
        "skipped": skipped,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    tmp = output.with_name(f".integrity-manifest.tmp-{os.getpid()}")
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, output)
    print(
        "integrity_manifest "
        f"status=ok scope={args.scope} entries={len(entries)} skipped={len(skipped)} output={output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
