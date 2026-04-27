#!/usr/bin/env python3

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
from datetime import datetime
from pathlib import Path


LINE_RE = re.compile(
    r"^(?P<impl>\S+)\s+"
    r"(?P<scenario>\S+)\s+"
    r"domains=(?P<domains>\d+)\s+"
    r"ops=\s*(?P<total_ops>\d+)\s+"
    r"time=\s*(?P<seconds>[0-9.]+)s\s+"
    r"avg=\s*(?P<avg_us_per_op>[0-9.]+)us/op$"
)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run the benchmark executable and store parsed results."
    )
    parser.add_argument(
        "--command",
        default="opam exec -- dune exec ./benchmarking/benchmark.exe",
        help="Command used to run the benchmark executable.",
    )
    parser.add_argument(
        "--output-dir",
        default=str(repo_root() / "presentation" / "data"),
        help="Directory for raw and parsed benchmark outputs.",
    )
    return parser.parse_args()


def parse_results(output: str) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for line in output.splitlines():
        match = LINE_RE.match(line.strip())
        if not match:
            continue
        row = match.groupdict()
        rows.append(
            {
                "impl_name": row["impl"],
                "scenario_name": row["scenario"],
                "domains": int(row["domains"]),
                "total_ops": int(row["total_ops"]),
                "seconds": float(row["seconds"]),
                "avg_us_per_op": float(row["avg_us_per_op"]),
            }
        )
    return rows


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    fieldnames = [
        "impl_name",
        "scenario_name",
        "domains",
        "total_ops",
        "seconds",
        "avg_us_per_op",
    ]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    args = parse_args()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    command = args.command

    completed = subprocess.run(
        command,
        cwd=repo_root(),
        shell=True,
        text=True,
        capture_output=True,
        check=False,
    )

    raw_output = completed.stdout
    if completed.stderr:
        raw_output = raw_output + ("\n" if raw_output else "") + completed.stderr

    raw_latest = output_dir / "benchmark_raw_latest.txt"
    raw_timestamped = output_dir / f"benchmark_raw_{timestamp}.txt"
    raw_latest.write_text(raw_output, encoding="utf-8")
    raw_timestamped.write_text(raw_output, encoding="utf-8")

    if completed.returncode != 0:
        print(raw_output)
        raise SystemExit(
            f"Benchmark command failed with exit code {completed.returncode}."
        )

    rows = parse_results(completed.stdout)
    if not rows:
        raise SystemExit(
            "Benchmark command succeeded but no benchmark result lines were parsed."
        )

    csv_latest = output_dir / "benchmark_results_latest.csv"
    csv_timestamped = output_dir / f"benchmark_results_{timestamp}.csv"
    json_latest = output_dir / "benchmark_results_latest.json"
    json_timestamped = output_dir / f"benchmark_results_{timestamp}.json"
    meta_latest = output_dir / "benchmark_metadata_latest.json"

    write_csv(csv_latest, rows)
    write_csv(csv_timestamped, rows)

    payload = {
        "generated_at": timestamp,
        "command": command,
        "row_count": len(rows),
        "results": rows,
    }
    json_latest.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    json_timestamped.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    meta_latest.write_text(
        json.dumps(
            {
                "generated_at": timestamp,
                "command": command,
                "returncode": completed.returncode,
                "row_count": len(rows),
                "raw_log": str(raw_latest.relative_to(repo_root())),
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    print(f"Stored {len(rows)} parsed benchmark rows in {csv_latest}")
    print(f"Stored raw benchmark log in {raw_latest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
