#!/usr/bin/env python3
"""Forced-command dispatcher for the WORKSTATION1 workflow backup runtime SSH key."""

from __future__ import annotations

import json
import os
import posixpath
import shlex
import sys

CONFIG_PATH = "/usr/local/etc/ws1-wf-runtime.json"


def deny(message: str) -> int:
    print(f"restricted backup key: {message}", file=sys.stderr)
    return 126


def load_config() -> dict[str, str]:
    with open(CONFIG_PATH, "r", encoding="utf-8") as handle:
        return json.load(handle)


def under(path: str, root: str) -> bool:
    if not path.startswith("/"):
        return False
    norm_path = posixpath.normpath(path)
    norm_root = posixpath.normpath(root)
    return norm_path == norm_root or norm_path.startswith(norm_root + "/")


def validate_no_parent_escape(argv: list[str]) -> bool:
    return all(".." not in token.split("/") for token in argv)


def execv(path: str, argv: list[str]) -> None:
    os.execv(path, argv)


def allow_mkdir(argv: list[str], allowed_root: str) -> bool:
    return (
        len(argv) == 3
        and argv[0] in {"mkdir", "/bin/mkdir", "/usr/bin/mkdir"}
        and argv[1] == "-p"
        and under(argv[2], allowed_root)
    )


def allow_rsync(argv: list[str], allowed_root: str, rsync_path: str) -> bool:
    if len(argv) < 3:
        return False
    if posixpath.basename(argv[0]) != "rsync":
        return False
    if argv[1] != "--server":
        return False
    if "--sender" in argv:
        return False
    absolute_args = [token for token in argv[2:] if token.startswith("/")]
    return bool(absolute_args) and all(under(token, allowed_root) for token in absolute_args)


def allow_helper(
    argv: list[str],
    helper: str,
    dataset: str,
    availability_dataset: str,
    dataset_path: str,
    allowed_root: str,
) -> bool:
    if not argv:
        return False
    if argv[0] != helper:
        return False
    allowed_flags = {
        "--dataset",
        "--availability-dataset",
        "--stage",
        "--max-used",
        "--max-snapshot-used",
        "--min-available",
        "--max-snapshot-count",
        "--enforce",
        "--dataset-path",
        "--scope",
        "--output",
        "--max-file-bytes",
    }
    i = 1
    while i < len(argv):
        flag = argv[i]
        if flag not in allowed_flags or i + 1 >= len(argv):
            return False
        value = argv[i + 1]
        if flag == "--dataset" and value != dataset:
            return False
        if flag == "--availability-dataset" and value != availability_dataset:
            return False
        if flag == "--dataset-path" and posixpath.normpath(value) != posixpath.normpath(dataset_path):
            return False
        if flag == "--output" and not under(value, allowed_root):
            return False
        if flag == "--scope" and value not in {"critical", "full"}:
            return False
        if flag in {"--max-used", "--max-snapshot-used", "--min-available", "--max-snapshot-count", "--max-file-bytes"}:
            if not value.isdigit():
                return False
        if flag == "--enforce" and value not in {"0", "1"}:
            return False
        i += 2
    return True


def main() -> int:
    config = load_config()
    allowed_root = config["allowed_root"]
    dataset = config["dataset"]
    availability_dataset = config.get("availability_dataset", dataset)
    dataset_path = config["dataset_path"]
    rsync_path = config.get("rsync_path", "/usr/local/bin/rsync")
    guard_helper = config["growth_guard_helper"]
    integrity_helper = config["integrity_helper"]

    original = os.environ.get("SSH_ORIGINAL_COMMAND", "")
    if not original:
        return deny("interactive login disabled")
    try:
        argv = shlex.split(original)
    except ValueError as exc:
        return deny(f"could not parse command: {exc}")
    if not argv or not validate_no_parent_escape(argv):
        return deny("invalid command")

    if allow_mkdir(argv, allowed_root):
        execv("/bin/mkdir", ["mkdir", "-p", argv[2]])
    if allow_rsync(argv, allowed_root, rsync_path):
        execv(rsync_path, [rsync_path] + argv[1:])
    if allow_helper(argv, guard_helper, dataset, availability_dataset, dataset_path, allowed_root):
        execv("/usr/local/bin/sudo", ["sudo", "-n", guard_helper] + argv[1:])
    if allow_helper(argv, integrity_helper, dataset, availability_dataset, dataset_path, allowed_root):
        execv("/usr/local/bin/sudo", ["sudo", "-n", integrity_helper] + argv[1:])
    return deny("command not allowed")


if __name__ == "__main__":
    raise SystemExit(main())
