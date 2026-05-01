#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def run_step(script_name: str) -> None:
    script_path = repo_root() / "presentation" / "scripts" / script_name
    print(f"\n=== Running {script_name} ===")
    subprocess.run([sys.executable, str(script_path)], cwd=repo_root(), check=True)


def main() -> int:
    for script_name in (
        "run_benchmarks.py",
        "plot_benchmarks.py",
    ):
        run_step(script_name)
    print("\nbuild pipeline complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
