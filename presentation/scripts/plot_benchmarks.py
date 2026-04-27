#!/usr/bin/env python3

from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter


SCENARIO_LABELS = {
    "updates_100": "100% updates",
    "balanced_50_50": "50% updates / 50% scans",
    "scans_90": "10% updates / 90% scans",
    "scans_100": "100% scans",
}

IMPL_LABELS = {
    "snapshot_baseline": "Baseline snapshot",
    "mcas_volatile": "MCAS snapshot (volatile)",
}

IMPL_COLORS = {
    "snapshot_baseline": "#38bdf8",
    "mcas_volatile": "#a78bfa",
}


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate benchmark visualizations.")
    parser.add_argument(
        "--input-csv",
        default=str(repo_root() / "presentation" / "data" / "benchmark_results_latest.csv"),
        help="CSV file produced by run_benchmarks.py.",
    )
    parser.add_argument(
        "--output-dir",
        default=str(repo_root() / "presentation" / "assets"),
        help="Directory for generated charts.",
    )
    parser.add_argument(
        "--min-domains",
        type=int,
        default=2,
        help="Minimum domain count to include in charts. Default keeps the slides aligned with the 2-8 thread deliverable.",
    )
    return parser.parse_args()


def read_rows(path: Path) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    with path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            rows.append(
                {
                    "impl_name": row["impl_name"],
                    "scenario_name": row["scenario_name"],
                    "domains": int(row["domains"]),
                    "total_ops": int(row["total_ops"]),
                    "seconds": float(row["seconds"]),
                    "avg_us_per_op": float(row["avg_us_per_op"]),
                }
            )
    return rows


def human_ms(value: float, _pos: object) -> str:
    return f"{value * 1000:.0f} ms"


def point_ms_label(value: float) -> str:
    return f"{value * 1000:.1f} ms"


def group_rows(rows: list[dict[str, object]], min_domains: int) -> dict[str, dict[str, list[dict[str, object]]]]:
    grouped: dict[str, dict[str, list[dict[str, object]]]] = defaultdict(lambda: defaultdict(list))
    for row in rows:
        if int(row["domains"]) < min_domains:
            continue
        grouped[str(row["scenario_name"])][str(row["impl_name"])].append(row)
    for scenario_rows in grouped.values():
        for impl_rows in scenario_rows.values():
            impl_rows.sort(key=lambda item: int(item["domains"]))
    return grouped


def style_axes(ax: plt.Axes) -> None:
    ax.set_facecolor("#ffffff")
    ax.grid(True, axis="y", color="#d7dee9", linewidth=0.8)
    ax.grid(False, axis="x")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color("#cbd5e1")
    ax.spines["bottom"].set_color("#cbd5e1")
    ax.tick_params(colors="#334155", labelsize=10)
    ax.yaxis.set_major_formatter(FuncFormatter(human_ms))


def plot_scenario(
    scenario: str,
    scenario_rows: dict[str, list[dict[str, object]]],
    output_dir: Path,
) -> Path:
    fig, ax = plt.subplots(figsize=(10, 5.6), dpi=200)
    fig.patch.set_facecolor("#f8fafc")
    style_axes(ax)

    for impl_name, rows in scenario_rows.items():
        xs = [int(row["domains"]) for row in rows]
        ys = [float(row["seconds"]) for row in rows]
        ax.plot(
            xs,
            ys,
            marker="o",
            linewidth=2.6,
            markersize=7,
            color=IMPL_COLORS[impl_name],
            label=IMPL_LABELS[impl_name],
        )
        if xs and ys:
            ax.annotate(
                point_ms_label(ys[-1]),
                (xs[-1], ys[-1]),
                textcoords="offset points",
                xytext=(8, 4),
                fontsize=9,
                color=IMPL_COLORS[impl_name],
                weight="bold",
            )

    ax.set_title(
        f"Elapsed Time vs. Threads: {SCENARIO_LABELS[scenario]}",
        fontsize=18,
        weight="bold",
        color="#0f172a",
        pad=14,
    )
    ax.set_xlabel("Threads / domains", fontsize=12, color="#334155")
    ax.set_ylabel("Elapsed time", fontsize=12, color="#334155")
    ax.set_xticks(sorted({int(row["domains"]) for rows in scenario_rows.values() for row in rows}))
    ax.legend(frameon=False, ncol=1, fontsize=10, loc="upper right")

    output_path = output_dir / f"{scenario}.png"
    fig.tight_layout()
    fig.savefig(output_path, bbox_inches="tight")
    plt.close(fig)
    return output_path


def plot_overview(
    grouped: dict[str, dict[str, list[dict[str, object]]]],
    output_dir: Path,
) -> Path:
    scenarios = list(SCENARIO_LABELS.keys())
    fig, axes = plt.subplots(2, 2, figsize=(14, 9), dpi=200)
    fig.patch.set_facecolor("#f8fafc")

    for ax, scenario in zip(axes.flat, scenarios):
        style_axes(ax)
        scenario_rows = grouped[scenario]
        for impl_name, rows in scenario_rows.items():
            ax.plot(
                [int(row["domains"]) for row in rows],
                [float(row["seconds"]) for row in rows],
                marker="o",
                linewidth=2.2,
                markersize=5,
                color=IMPL_COLORS[impl_name],
                label=IMPL_LABELS[impl_name],
            )
        ax.set_title(SCENARIO_LABELS[scenario], fontsize=14, weight="bold", color="#0f172a")
        ax.set_xlabel("Threads / domains", fontsize=10, color="#334155")
        ax.set_ylabel("Elapsed time", fontsize=10, color="#334155")
        ax.set_xticks(sorted({int(row["domains"]) for rows in scenario_rows.values() for row in rows}))

    handles, labels = axes.flat[0].get_legend_handles_labels()
    fig.legend(handles, labels, loc="upper center", ncol=3, frameon=False, bbox_to_anchor=(0.5, 0.98))
    fig.suptitle("MCAS Snapshot Elapsed-Time Overview", fontsize=24, weight="bold", color="#0f172a", y=0.995)
    fig.tight_layout(rect=(0, 0, 1, 0.95))

    output_path = output_dir / "benchmark_overview.png"
    fig.savefig(output_path, bbox_inches="tight")
    plt.close(fig)
    return output_path


def plot_relative_to_baseline(
    grouped: dict[str, dict[str, list[dict[str, object]]]],
    output_dir: Path,
) -> Path:
    fig, ax = plt.subplots(figsize=(10.5, 5.8), dpi=200)
    fig.patch.set_facecolor("#f8fafc")
    ax.set_facecolor("#ffffff")
    ax.grid(True, axis="y", color="#d7dee9", linewidth=0.8)
    ax.grid(False, axis="x")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color("#cbd5e1")
    ax.spines["bottom"].set_color("#cbd5e1")
    ax.tick_params(colors="#334155", labelsize=10)

    scenarios = list(SCENARIO_LABELS.keys())
    xs = list(range(len(scenarios)))
    for impl_name in ("mcas_volatile",):
        ratios = []
        for scenario in scenarios:
            baseline_rows = grouped[scenario]["snapshot_baseline"]
            impl_rows = grouped[scenario][impl_name]
            baseline = float(baseline_rows[-1]["seconds"])
            impl = float(impl_rows[-1]["seconds"])
            ratios.append(impl / baseline)
        ax.plot(
            xs,
            ratios,
            marker="o",
            linewidth=2.6,
            markersize=7,
            color=IMPL_COLORS[impl_name],
            label=IMPL_LABELS[impl_name],
        )
        for i, ratio in enumerate(ratios):
            ax.annotate(
                f"{ratio:.1f}x",
                (xs[i], ratio),
                textcoords="offset points",
                xytext=(0, 8),
                ha="center",
                fontsize=9,
                color=IMPL_COLORS[impl_name],
                weight="bold",
            )

    ax.set_title(
        "MCAS Elapsed-Time Slowdown at 8 Threads",
        fontsize=18,
        weight="bold",
        color="#0f172a",
        pad=14,
    )
    ax.set_xlabel("Workload mix", fontsize=12, color="#334155")
    ax.set_ylabel("Time relative to baseline (x)", fontsize=12, color="#334155")
    ax.set_xticks(xs, [SCENARIO_LABELS[scenario] for scenario in scenarios], rotation=0)
    ax.legend(frameon=False, fontsize=10, loc="upper right")

    output_path = output_dir / "relative_to_baseline.png"
    fig.tight_layout()
    fig.savefig(output_path, bbox_inches="tight")
    plt.close(fig)
    return output_path


def main() -> int:
    args = parse_args()
    input_csv = Path(args.input_csv)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    rows = read_rows(input_csv)
    grouped = group_rows(rows, args.min_domains)

    generated = []
    for scenario, scenario_rows in grouped.items():
        generated.append(plot_scenario(scenario, scenario_rows, output_dir))
    generated.append(plot_overview(grouped, output_dir))
    generated.append(plot_relative_to_baseline(grouped, output_dir))

    for path in generated:
        print(f"Generated {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
