# Project 5: Multi-Word Compare-and-Swap (MCAS) in OCaml 5

## Project Agenda and Overview

This project explores the implementation and application of a software-based Multi-Word Compare-and-Swap (MCAS) primitive in OCaml 5. Standard hardware and the OCaml 5 `Atomic` module only provide single-word CAS operations. However, many lock-free data structures require atomically updating multiple independent memory locations simultaneously.

To bridge this gap, this project implements a software MCAS built on top of single-word CAS using descriptor-based helping mechanisms, specifically following the Harris-Fraser-Pratt algorithm.

The primary research question this project seeks to answer is:
**Does MCAS provide enough expressive power to meaningfully simplify the implementation of an atomic snapshot object, and what is the performance cost of the software MCAS layer?**

### Core Objectives

1. **Implement MCAS:** Develop the Harris-Fraser-Pratt MCAS algorithm in OCaml 5, properly handling descriptor objects and concurrent thread helping.
2. **Apply to Data Structures:** Utilize the MCAS primitive to construct a lock-free atomic snapshot object.
3. **Verify Linearizability:** Rigorously test the core MCAS implementation and the new atomic snapshot using `QCheck-Lin` to ensure correct linearizable behavior under concurrent execution.
4. **Benchmark Performance:** Compare the throughput of the MCAS-based snapshot against the double-collect implementation from Assignment 2 across varying thread counts (2-8) and update/scan ratios.

---

## Repository Structure

The project is organized into distinct modules separating the core synchronization primitives, the data structure implementations, and the verification suites.

### Core Algorithms

- **`mcas.mli` / `mcas.ml`**: The core multi-word compare-and-swap implementation. This contains the internal state machine, descriptor types, the RDCSS (Restricted Double-Compare Single-Swap) logic, and the recursive helping mechanisms required by the Harris-Fraser-Pratt algorithm.
- **`mcas_snapshot.mli` / `mcas_snapshot.ml`**: The new atomic snapshot implementation. This module leverages `mcas.ml` to achieve atomic scans and updates without relying on traditional double-collect loops or dirty bits.
- **`snapshot.mli` / `snapshot.ml`**: The baseline double-collect atomic snapshot algorithm from Assignment 2. Retained here to serve as the control group for performance benchmarking.

### Testing and Verification

- **`qcheck_lin_mcas.ml`**: Linearizability testing suite targeting the isolated `Mcas` module. Ensures that the descriptor installation and helping phases function correctly under high contention.
- **`qcheck_lin_snapshot.ml`**: Linearizability testing suite for the `Mcas_snapshot` implementation. Ensures that concurrent updates and scans yield consistent, linearizable array states.

### Benchmarking

- **`benchmark.ml`**: The performance evaluation harness. It spins up 2 to 8 OCaml 5 Domains, applying varying ratios of update and scan operations to both snapshot implementations, and measures operations per second (throughput).

### Build System

- **`Makefile`**: Exposes standard commands for building, testing, and benchmarking the project.
- **`dune` / `dune-project`**: Standard OCaml Dune build system configurations defining library dependencies and executable targets.

---

## Build and Execution Instructions

Ensure you have OCaml 5.x and Dune installed, along with the necessary `qcheck-lin` packages.

### Compilation

To compile the entire project (libraries, tests, and benchmarks):

```bash
make build
```
