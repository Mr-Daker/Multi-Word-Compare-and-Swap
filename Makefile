# Programming Assignment 5: Multi-Word Compare-and-Swap (MCAS)
# Student Makefile

.PHONY: all build test clean help test-lin-mcas test-lin-snapshot benchmark

# Default target
all: build

# Build the project
build:
	dune build

# Run all verification tests (excluding benchmarks)
test: test-lin-mcas test-lin-snapshot

# Run QCheck-Lin linearizability test for the isolated MCAS algorithm
test-lin-mcas:
	@echo "=== Running QCheck-Lin Linearizability Test (MCAS) ==="
	dune exec ./qcheck_lin_mcas.exe

# Run QCheck-Lin linearizability test for the MCAS-based Snapshot
test-lin-snapshot:
	@echo ""
	@echo "=== Running QCheck-Lin Linearizability Test (Snapshot) ==="
	dune exec ./qcheck_lin_snapshot.exe

# Run the performance benchmarks (Update/Scan throughput across 2-8 threads)
benchmark:
	@echo ""
	@echo "=== Running MCAS vs Double-Collect Benchmarks ==="
	dune exec ./benchmark.exe

# Clean build artifacts
clean:
	dune clean

# Help
help:
	@echo "Available targets:"
	@echo "  make build             - Build the project"
	@echo "  make test              - Run all linearizability tests"
	@echo "  make test-lin-mcas     - Run QCheck-Lin test for the core MCAS module"
	@echo "  make test-lin-snapshot - Run QCheck-Lin test for the new Snapshot"
	@echo "  make benchmark         - Run throughput benchmarks (2-8 threads)"
	@echo "  make clean             - Remove build artifacts"