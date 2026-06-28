#!/usr/bin/env python3
"""NAS-side read-only ZFS budget guard for WORKSTATION1 workflow backups."""

from __future__ import annotations

import argparse
import subprocess
import sys


def capture(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT)


def fmt(num: int) -> str:
    value = float(num)
    for unit in ("B", "KiB", "MiB", "GiB", "TiB", "PiB"):
        if abs(value) < 1024 or unit == "PiB":
            return f"{value:.2f} {unit}"
        value /= 1024
    raise AssertionError("unreachable")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dataset", required=True)
    parser.add_argument("--availability-dataset", default=None)
    parser.add_argument("--stage", required=True)
    parser.add_argument("--max-used", type=int, default=0)
    parser.add_argument("--max-snapshot-used", type=int, default=0)
    parser.add_argument("--min-available", type=int, default=0)
    parser.add_argument("--max-snapshot-count", type=int, default=0)
    parser.add_argument("--enforce", choices=("0", "1"), default="1")
    args = parser.parse_args()

    props: dict[str, int] = {}
    availability_dataset = args.availability_dataset or args.dataset
    raw_props = capture([
        "zfs",
        "get",
        "-H",
        "-p",
        "-o",
        "property,value",
        "used,usedbysnapshots",
        args.dataset,
    ])
    for line in raw_props.splitlines():
        key, value = line.split("\t", 1)
        props[key] = int(value)

    available = int(capture([
        "zfs",
        "get",
        "-H",
        "-p",
        "-o",
        "value",
        "available",
        availability_dataset,
    ]).strip())
    snapshot_lines = capture(["zfs", "list", "-H", "-t", "snapshot", "-o", "name", "-r", args.dataset]).splitlines()
    snapshot_count = len([line for line in snapshot_lines if line.strip()])

    used = props["used"]
    snapshot_used = props["usedbysnapshots"]
    enforce = args.enforce == "1"
    violations: list[str] = []

    if args.max_used and used > args.max_used:
        violations.append(f"dataset used {fmt(used)} exceeds max {fmt(args.max_used)}")
    if args.max_snapshot_used and snapshot_used > args.max_snapshot_used:
        violations.append(f"snapshot-held data {fmt(snapshot_used)} exceeds max {fmt(args.max_snapshot_used)}")
    if args.min_available and available < args.min_available:
        violations.append(f"available space {fmt(available)} is below reserve {fmt(args.min_available)}")
    if args.max_snapshot_count and snapshot_count > args.max_snapshot_count:
        violations.append(f"snapshot count {snapshot_count} exceeds max {args.max_snapshot_count}")

    status = "failed" if violations and enforce else "warning" if violations else "ok"
    print(
        "growth_guard "
        f"stage={args.stage} status={status} dataset={args.dataset} availability_dataset={availability_dataset} "
        f"used={fmt(used)} max_used={fmt(args.max_used) if args.max_used else 'disabled'} "
        f"snapshot_used={fmt(snapshot_used)} max_snapshot_used={fmt(args.max_snapshot_used) if args.max_snapshot_used else 'disabled'} "
        f"available={fmt(available)} min_available={fmt(args.min_available) if args.min_available else 'disabled'} "
        f"snapshots={snapshot_count} max_snapshots={args.max_snapshot_count if args.max_snapshot_count else 'disabled'}"
    )
    for violation in violations:
        print(f"growth_guard violation: {violation}")

    if violations and enforce:
        return 75
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
