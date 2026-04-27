## 1. Algorithmic Overhead
The double-collect algorithm simply:

This uses only atomic reads - very fast operations.

The MCAS-based scan:

This attempts a full multi-word CAS operation to validate that no values changed during the scan.

## 2. MCAS Implementation Complexity
The MCAS algorithm (following Harris-Fraser-Pratt) involves:

Creating descriptor objects for each word
Installing word descriptors atomically
Coordinating between multiple threads via helping mechanisms
RDCSS (Restricted Double-Compare Single-Swap) operations
Cleanup and retirement phases
For a 16-register snapshot, this means coordinating 16 separate memory locations atomically.

## 3. False Conflicts
Even when no real conflicts exist, MCAS may fail due to:

Descriptor installation races
Helping threads interfering
Memory layout and cache effects

## Trade-offs

### MCAS Advantages:
Stronger Correctness: Provides true linearizable atomicity
Composability: Can be used to build more complex atomic operations
Uniform Interface: Updates and scans use the same underlying primitive
No False Negatives: Won't restart unnecessarily due to timing
Double-Collect Advantages:
Performance: 2-50x faster depending on workload
Simplicity: Only uses hardware atomic reads
Scalability: Performance improves with thread count
Low Latency: Minimal overhead per operation

### The Trade-off Decision:
MCAS provides "expressive power" (as stated in your research question) by enabling complex atomic operations that would be difficult to implement with double-collect. However, this comes at a significant performance cost - especially for read-heavy workloads where the overhead of multi-word validation outweighs the benefits.

For atomic snapshots specifically, double-collect appears to be the better choice unless you need the stronger composability guarantees of MCAS for building more complex data structures.
