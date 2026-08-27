# Native Language Standards

Section: Native Language Performance
Req: High-Performance Data Processing: Optimize CPU cycles && memory allocations in native/compiled environments.
- Rule: In-Place Mutations: Enforce in-place linear-time selection algorithms over full sorting when finding percentiles/quantiles to eliminate unnecessary O(n log n) overhead.
- Rule: Pre-allocate Collection Capacity: Prohibit allocating new collection structures inside tight loops without necessity; pre-allocate capacity when size is known to prevent repeated heap allocations.

Req: Zero-Copy Buffer Management: Enforce zero-allocation data access patterns in compiled environments.
- Rule: Reference Views: Enforce read-only reference views over buffer copies for string && byte-slice operations.
- Rule: Move Semantics: Enforce ownership transfer over deep copying when passing large structures between scopes.
- Rule: Low-Level I/O: Enforce memory mapping (`mmap`) || kernel-level splice syscalls (`sendfile`, `splice`) for file/network streaming to bypass user-space buffer copying.

Req: Native Concurrency Patterns: Structure concurrent code using pipelines || task queues.
- Rule: Concurrent Data Structures: Enforce concurrent queues, task-based designs, || pipeline architectures over manual mutex locking.

Req: Scoped Cleanup (RAII): Enforce deterministic resource release via compiler-managed lifetimes.
- Rule: RAII Guard Pattern: Enforce RAII wrapper types to automatically release memory, file descriptors, && locks upon scope exit; prohibit manual cleanup calls.
