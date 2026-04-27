# Presentation Pipeline

This folder contains a small pipeline for turning the benchmark executable output
into elapsed-time charts and a PowerPoint presentation.

## Files

- `scripts/run_benchmarks.py`: runs `benchmarking/benchmark.exe`, captures the
  raw log, and stores parsed CSV/JSON results.
- `scripts/plot_benchmarks.py`: reads the CSV results and generates chart PNGs.
- `scripts/build_presentation.py`: builds a `.pptx` deck from the results and
  generated charts.
- `scripts/build_all.py`: convenience wrapper that runs the whole pipeline.

## Typical usage

```bash
python3 presentation/scripts/build_all.py
```

If `python-pptx` is not available in the system Python, create a local virtual
environment first:

```bash
python3 -m venv presentation/.venv
presentation/.venv/bin/pip install python-pptx
presentation/.venv/bin/python presentation/scripts/build_all.py
```

## Outputs

- Parsed benchmark data: `presentation/data/`
- Chart images: `presentation/assets/`
- Presentation deck: `presentation/mcas_snapshot_benchmark_presentation.pptx`
