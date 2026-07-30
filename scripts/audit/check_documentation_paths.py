#!/usr/bin/env python3
"""Fail when tracked documentation paths regress to ambiguous casing."""

from __future__ import annotations

from collections import defaultdict
from pathlib import Path
import subprocess
import sys


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
LOWERCASE_DOCUMENTATION_ROOT = "doc" + "s/"


def run_git(*arguments: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", *arguments],
        cwd=REPOSITORY_ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if check and result.returncode != 0:
        print(result.stderr, file=sys.stderr, end="")
        raise RuntimeError("git command failed: git " + " ".join(arguments))
    return result


def tracked_paths() -> list[str]:
    return [path for path in run_git("ls-files").stdout.splitlines() if path]


def main() -> int:
    failures: list[str] = []
    paths = tracked_paths()

    lowercase_paths = [
        path for path in paths if path.startswith(LOWERCASE_DOCUMENTATION_ROOT)
    ]
    if lowercase_paths:
        failures.append(
            "Tracked paths under the lowercase documentation root:\n"
            + "\n".join(f"  {path}" for path in lowercase_paths)
        )

    paths_by_casefolded_name: dict[str, list[str]] = defaultdict(list)
    for path in paths:
        paths_by_casefolded_name[path.casefold()].append(path)
    duplicate_groups = [
        sorted(group)
        for group in paths_by_casefolded_name.values()
        if len(group) > 1
    ]
    if duplicate_groups:
        failures.append(
            "Case-insensitive duplicate tracked paths:\n"
            + "\n".join(
                "  " + " | ".join(group) for group in sorted(duplicate_groups)
            )
        )

    stale_reference_result = run_git(
        "grep", "-n", "-I", "-e", LOWERCASE_DOCUMENTATION_ROOT, check=False
    )
    if stale_reference_result.returncode == 0:
        failures.append(
            "Stale lowercase documentation-root references:\n"
            + stale_reference_result.stdout.rstrip()
        )
    elif stale_reference_result.returncode != 1:
        print(stale_reference_result.stderr, file=sys.stderr, end="")
        failures.append("Unable to scan tracked files for stale documentation references.")

    if failures:
        print("\n\n".join(failures), file=sys.stderr)
        return 1

    canonical_count = sum(path.startswith("Docs/") for path in paths)
    print(
        "PASS: documentation path health "
        f"({canonical_count} tracked Docs files; no lowercase paths, "
        "case-insensitive duplicates, or stale references)"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(error, file=sys.stderr)
        raise SystemExit(1)
