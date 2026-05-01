# Presentation Pipeline

This folder contains a small pipeline for turning the benchmark executable output
into elapsed-time charts

## Files

- `scripts/run_benchmarks.py`: runs `benchmarking/benchmark.exe`, captures the
  raw log, and stores parsed CSV/JSON results.
- `scripts/plot_benchmarks.py`: reads the CSV results and generates chart PNGs.
- `scripts/build_all.py`: convenience wrapper that runs the whole pipeline.

## Typical usage

```bash
python3 -m venv presentation/.venv
presentation/.venv/bin/python presentation/scripts/build_all.py
```

## Outputs

- Parsed benchmark data: `presentation/data/`
- Chart images: `presentation/assets/`