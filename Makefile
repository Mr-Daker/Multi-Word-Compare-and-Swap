# Programming Assignment 5: Multi-Word Compare-and-Swap (MCAS)
# Student Makefile

.PHONY: all build test clean help \
  test-lin-mcas test-lin-snapshot \
  test-lin-linked-list test-lin-mcas-linked-list \
  test-lin-stm-volatile test-lin-stm-snapshot \
  test-stm-volatile test-stm-snapshot \
  benchmark benchmark-linked-list benchmark-doubly-linked-list \
  tsan tsan-volatile tsan-snapshot

OPAM_SWITCH ?= $(or $(shell opam switch show 2>/dev/null),default)
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
	-$(MAKE) test-lin-linked-list
	-$(MAKE) test-lin-mcas-linked-list
	-$(MAKE) test-lin-stm-snapshot
	-$(MAKE) test-stm-volatile
	-$(MAKE) test-stm-snapshot
	-$(MAKE) benchmark
	-$(MAKE) benchmark-linked-list
	-$(MAKE) benchmark-doubly-linked-list
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

# Run QCheck-Lin linearizability test for the CAS linked list
test-lin-linked-list:
	@echo ""
	@echo "=== Running QCheck-Lin Linearizability Test (CAS linked list) ==="
	$(OPAM_RUN) dune exec ./qlin/qcheck_lin_lockfree_linked_list.exe

# Run QCheck-Lin linearizability test for the MCAS linked list
test-lin-mcas-linked-list:
	@echo ""
	@echo "=== Running QCheck-Lin Linearizability Test (MCAS linked list) ==="
	$(OPAM_RUN) dune exec ./qlin/qcheck_lin_mcas_lockfree_linked_list.exe

# Run QCheck-Lin linearizability test for Stm_volatile
test-lin-stm-volatile:
	@echo ""
	@echo "=== Running QCheck-Lin Linearizability Test (stm_volatile) ==="
	$(OPAM_RUN) dune exec ./qlin/qcheck_lin_stm_volatile.exe

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

# Run QCheck-STM sequential+concurrent test for Stm_snapshot
test-stm-snapshot:
	@echo ""
	@echo "=== Running QCheck-STM Test (stm_snapshot, sequential) ==="
	$(OPAM_RUN) dune exec ./stm/qcheck_stm_snapshot.exe -- sequential
	@echo ""
	@echo "=== Running QCheck-STM Test (stm_snapshot, concurrent) ==="
	$(OPAM_RUN) dune exec ./stm/qcheck_stm_snapshot.exe -- concurrent

# Run the performance benchmarks (elapsed time across 2-8 threads)
benchmark:
	@echo ""
	@echo "=== Running MCAS vs Double-Collect Time Benchmarks ==="
	$(OPAM_RUN) dune exec ./benchmarking/benchmark.exe

# Run the linked-list benchmarks (CAS vs MCAS)
benchmark-linked-list:
	@echo ""
	@echo "=== Running CAS vs MCAS Linked-List Benchmarks ==="
	$(OPAM_RUN) dune exec ./benchmarking/benchmark_linked_list.exe

# Run the doubly-linked-list benchmarks (Mutex vs MCAS)
benchmark-doubly-linked-list:
	@echo ""
	@echo "=== Running Mutex vs MCAS Doubly-Linked-List Benchmarks ==="
	$(OPAM_RUN) dune exec ./benchmarking/benchmark_doubly_linked_list.exe

# Run all ThreadSanitizer stress tests
tsan: tsan-volatile tsan-snapshot

# TSan stress test for Stm_volatile
tsan-volatile:
	@echo ""
	@echo "=== Running TSan stress test (stm_volatile) ==="
	$(OPAM_RUN) dune exec ./tsan/tsan_volatile.exe

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
	@echo "  make test-lin-linked-list  - QCheck-Lin: CAS linked list"
	@echo "  make test-lin-mcas-linked-list - QCheck-Lin: MCAS linked list"
	@echo "  make test-lin-stm-volatile - QCheck-Lin: stm_volatile"
	@echo "  make test-lin-stm-snapshot - QCheck-Lin: stm_snapshot"
	@echo "  make test-stm-volatile     - QCheck-STM: stm_volatile (seq + conc)"
	@echo "  make test-stm-snapshot     - QCheck-STM: stm_snapshot (seq + conc)"
	@echo "  make benchmark             - Run elapsed-time benchmarks (2-8 threads)"
	@echo "  make benchmark-linked-list - Run linked-list elapsed-time benchmarks"
	@echo "  make benchmark-doubly-linked-list - Run doubly-linked-list elapsed-time benchmarks"
	@echo "  make tsan                  - Run all TSan stress tests"
	@echo "  make tsan-volatile         - TSan stress test for stm_volatile"
	@echo "  make tsan-snapshot         - TSan stress test for stm_snapshot"
	@echo "  make clean                 - Remove build artifacts"
