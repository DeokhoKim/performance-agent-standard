# Native Language Standards

Section: Native Language Performance
Req: High-Performance Data Processing: Optimize CPU cycles and memory allocations in native environments.
- Rule: Pre-allocate Collection Capacity: Avoid allocating new collection structures (like `Vec` or strings) inside tight loops (like pixel iteration) unless necessary. Pre-allocate capacity if size is known (e.g., `Vec::with_capacity`).

Req: Zero-Copy Performance (C++): Apply zero-copy optimizations for memory efficiency.
- Rule: Reference Views: Use C++17 `std::string_view` or C++20 `std::span` to reference existing buffers instead of allocating copies.
- Rule: Move Semantics: Use move semantics (`std::move`) and smart pointers (`std::unique_ptr`) to transfer resource ownership.
- Rule: Low-Level I/O: Use memory mapping (`mmap`) or system calls (`sendfile`, `splice` on pipes) for file/network streaming.

Req: Data-Flow Parallelism (C++): Structure concurrent code using pipelines or task queues.
- Rule: Concurrent Structures: Prefer concurrent queues, task-based designs, or pipeline libraries (such as Intel TBB or `std::future`/`std::promise`) instead of manual mutex locking.
