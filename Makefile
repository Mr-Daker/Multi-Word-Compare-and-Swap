# Programming Assignment 5: Multi-Word Compare-and-Swap (MCAS)
# Student Makefile

.PHONY: all build test clean help \
  test-lin-mcas test-lin-snapshot \
  test-lin-stm-volatile test-lin-stm-persistent test-lin-stm-snapshot \
  test-stm-volatile test-stm-persistent test-stm-snapshot \
  benchmark \
  tsan tsan-volatile tsan-persistent tsan-snapshot

OPAM_SWITCH := 5.2.0
OPAM_RUN := opam exec --switch=$(OPAM_SWITCH) --

# Default target
all: build

# Build the project
build:
	$(OPAM_RUN) dune build

# Run all verification tests: qlin, STM, benchmarks, and tsan
test:
	$(OPAM_RUN) dune build
	-$(MAKE) test-lin-mcas
	-$(MAKE) test-lin-snapshot
	-$(MAKE) test-lin-stm-snapshot
	-$(MAKE) test-stm-volatile
	-$(MAKE) test-stm-persistent
	-$(MAKE) test-stm-snapshot
	-$(MAKE) benchmark
	-$(MAKE) tsan

# Run QCheck-Lin linearizability test for the isolated MCAS algorithm
test-lin-mcas:
	@echo "=== Running QCheck-Lin Linearizability Test (MCAS) ==="
	$(OPAM_RUN) dune exec ./qlin/qcheck_lin_mcas.exe

# Run QCheck-Lin linearizability test for the MCAS-based Snapshot
test-lin-snapshot:
	@echo ""
	@echo "=== Running QCheck-Lin Linearizability Test (Snapshot) ==="
	$(OPAM_RUN) dune exec ./qlin/qcheck_lin_snapshot.exe

# Run QCheck-Lin linearizability test for Stm_volatile
test-lin-stm-volatile:
	@echo ""
	@echo "=== Running QCheck-Lin Linearizability Test (stm_volatile) ==="
	$(OPAM_RUN) dune exec ./qlin/qcheck_lin_stm_volatile.exe

# Run QCheck-Lin linearizability test for Stm_persistent
test-lin-stm-persistent:
	@echo ""
	@echo "=== Running QCheck-Lin Linearizability Test (stm_persistent) ==="
	$(OPAM_RUN) dune exec ./qlin/qcheck_lin_stm_persistent.exe

# Run QCheck-Lin linearizability test for Stm_snapshot
test-lin-stm-snapshot:
	@echo ""
	@echo "=== Running QCheck-Lin Linearizability Test (stm_snapshot) ==="
	$(OPAM_RUN) dune exec ./qlin/qcheck_lin_stm_snapshot.exe

# Run QCheck-STM sequential+concurrent test for Stm_volatile
test-stm-volatile:
	@echo ""
	@echo "=== Running QCheck-STM Test (stm_volatile, sequential) ==="
	$(OPAM_RUN) dune exec ./stm/qcheck_stm_volatile.exe -- sequential
	@echo ""
	@echo "=== Running QCheck-STM Test (stm_volatile, concurrent) ==="
	$(OPAM_RUN) dune exec ./stm/qcheck_stm_volatile.exe -- concurrent

# Run QCheck-STM sequential+concurrent test for Stm_persistent
test-stm-persistent:
	@echo ""
	@echo "=== Running QCheck-STM Test (stm_persistent, sequential) ==="
	$(OPAM_RUN) dune exec ./stm/qcheck_stm_persistent.exe -- sequential
	@echo ""
	@echo "=== Running QCheck-STM Test (stm_persistent, concurrent) ==="
	$(OPAM_RUN) dune exec ./stm/qcheck_stm_persistent.exe -- concurrent

# Run QCheck-STM sequential+concurrent test for Stm_snapshot
test-stm-snapshot:
	@echo ""
	@echo "=== Running QCheck-STM Test (stm_snapshot, sequential) ==="
	$(OPAM_RUN) dune exec ./stm/qcheck_stm_snapshot.exe -- sequential
	@echo ""
	@echo "=== Running QCheck-STM Test (stm_snapshot, concurrent) ==="
	$(OPAM_RUN) dune exec ./stm/qcheck_stm_snapshot.exe -- concurrent

# Run the performance benchmarks (Update/Scan throughput across 2-8 threads)
benchmark:
	@echo ""
	@echo "=== Running MCAS vs Double-Collect Benchmarks ==="
	$(OPAM_RUN) dune exec ./benchmarking/benchmark.exe

# Run all ThreadSanitizer stress tests
tsan: tsan-volatile tsan-persistent tsan-snapshot

# TSan stress test for Stm_volatile
tsan-volatile:
	@echo ""
	@echo "=== Running TSan stress test (stm_volatile) ==="
	$(OPAM_RUN) dune exec ./tsan/tsan_volatile.exe

# TSan stress test for Stm_persistent
tsan-persistent:
	@echo ""
	@echo "=== Running TSan stress test (stm_persistent) ==="
	$(OPAM_RUN) dune exec ./tsan/tsan_persistent.exe

# TSan stress test for Stm_snapshot
tsan-snapshot:
	@echo ""
	@echo "=== Running TSan stress test (stm_snapshot) ==="
	$(OPAM_RUN) dune exec ./tsan/tsan_snapshot.exe

# Clean build artifacts
clean:
	$(OPAM_RUN) dune clean

# Help
help:
	@echo "Available targets:"
	@echo "  using OPAM switch      - $(OPAM_SWITCH)"
	@echo "  make build             - Build the project"
	@echo "  make test                  - Run ALL tests (qlin + STM + benchmarks + tsan)"
	@echo "  make test-lin-mcas         - QCheck-Lin: core MCAS module"
	@echo "  make test-lin-snapshot     - QCheck-Lin: MCAS snapshot"
	@echo "  make test-lin-stm-volatile - QCheck-Lin: stm_volatile"
	@echo "  make test-lin-stm-persistent - QCheck-Lin: stm_persistent"
	@echo "  make test-lin-stm-snapshot - QCheck-Lin: stm_snapshot"
	@echo "  make test-stm-volatile     - QCheck-STM: stm_volatile (seq + conc)"
	@echo "  make test-stm-persistent   - QCheck-STM: stm_persistent (seq + conc)"
	@echo "  make test-stm-snapshot     - QCheck-STM: stm_snapshot (seq + conc)"
	@echo "  make benchmark             - Run throughput benchmarks (2-8 threads)"
	@echo "  make tsan                  - Run all TSan stress tests"
	@echo "  make tsan-volatile         - TSan stress test for stm_volatile"
	@echo "  make tsan-persistent       - TSan stress test for stm_persistent"
	@echo "  make tsan-snapshot         - TSan stress test for stm_snapshot"
	@echo "  make clean                 - Remove build artifacts"
