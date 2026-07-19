# Rust Implementation Standards

Section: Rust Safety & Idioms
Req: Safe Arithmetic & Panic Prevention: Prevent runtime panics in hot execution loops.
- Rule: Overflow/Underflow Prevention: Mathematical operations on unsigned integers (e.g., coordinates, sizes) MUST use `saturating_sub`, `saturating_add`, or safe casting to prevent silent underflows or runtime panics.

Req: Idiomatic Collections: Prefer zero-cost iterators over imperative loops.
- Rule: Zero-Cost Iterator Pipelines: Use idiomatic zero-cost iterator pipelines (such as `iter().copied().fold(f32::MAX, f32::min)`) instead of imperative `for` loops when transforming collections or finding extremes (min/max).

Req: Zero-Copy Performance (Rust): Leverage borrow checker and smart pointers to avoid allocations.
- Rule: Compiler-Checked Borrowing: Use references (`&[u8]`, `&str`) and lifetime parameters instead of calling `.clone()`, `.to_owned()`, or `to_string()` unnecessarily.
- Rule: Smart Pointers & Cow: Use thread-safe shared pointers (`Arc<[u8]>`) for read-only data, or clone-on-write (`Cow<'a, T>`) for lazy mutation.
- Rule: Memory Mapping: Use memory mapping crates (such as `memmap2`) for direct file-to-memory zero-copy parsing.

Req: Data-Flow Parallelism (Rust): Prefer message passing and parallel iterators over manual thread locks.
- Rule: Message Passing: Prefer safe channels (`mpsc` or `crossbeam`) and zero-overhead parallel iterators (`rayon`) for concurrency.

Req: Scoped Cleanup (Rust): Leverage compiler lifetime management.
- Rule: RAII and Drop Trait: Rely on RAII guards (e.g., `MutexGuard`) and structures implementing the `Drop` trait to automatically release resources and restore states. Avoid manual cleanup blocks.

