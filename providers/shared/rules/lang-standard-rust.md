# Rust Implementation Standards

Section: Rust Safety && Idioms
Req: Safe Arithmetic && Panic Prevention: Prevent runtime panics in hot execution loops.
- Rule: Overflow/Underflow Prevention: Enforce `saturating_sub`, `saturating_add`, || safe casting on unsigned integer mathematical operations (e.g., coordinates, sizes) to prevent silent underflows || runtime panics.

Req: Idiomatic Collections: Prefer zero-cost iterators over imperative loops.
- Rule: Zero-Cost Iterator Pipelines: Enforce zero-cost iterator pipelines (e.g., `iter().copied().fold(f32::MAX, f32::min)`) over imperative `for` loops when transforming collections || computing min/max extremes.

Req: Zero-Copy Performance (Rust): Leverage borrow checker && smart pointers to avoid allocations.
- Rule: Compiler-Checked Borrowing: Enforce references (`&[u8]`, `&str`) && explicit lifetimes; prohibit calling `.clone()`, `.to_owned()`, || `to_string()` without strict necessity.
- Rule: Smart Pointers && Cow: Enforce thread-safe shared pointers (`Arc<[u8]>`) for read-only data || clone-on-write (`Cow<'a, T>`) for lazy mutation.
- Rule: Memory Mapping: Enforce memory mapping crates (e.g., `memmap2`) for direct zero-copy file-to-memory parsing.

Req: Data-Flow Parallelism (Rust): Prefer message passing && parallel iterators over manual thread locks.
- Rule: Message Passing: Enforce safe channels (`mpsc` || `crossbeam`) && zero-overhead parallel iterators (`rayon`) for concurrency over manual mutex locking.

Req: Scoped Cleanup (Rust): Leverage compiler lifetime management.
- Rule: RAII && Drop Trait: Enforce RAII guards (e.g., `MutexGuard`) && types implementing `Drop` to automatically release resources && restore states; prohibit manual cleanup blocks.
