# Common Language Standards

Section: Code Quality & Maintainability
Req: Robust Configuration: Ensure code is easily configurable and maintainable.
- Rule: Magic Numbers Avoidance: Hard-coded values MUST be strictly avoided in algorithmic implementations, thresholds, and dimensions.
  - Rule: Parameterize all such values via configuration structures, function arguments, or explicit named constants.
  - Rule: Provide sensible default values in parameterized configurations to preserve out-of-the-box usability while allowing programmatic overrides.

Req: Balanced Code Quality: Enforce SOLID principles and prioritize code readability without degrading system performance.
- Rule: SOLID Design Principles: Algorithmic implementations and modular architectures MUST adhere to SOLID principles across all programming languages to ensure high maintainability and testability.
  - Rule: Apply SOLID principles pragmatically to keep code modular and readable, explicitly avoiding speculative future-proofing, bloated design abstractions, or over-engineered structures that are not required for the immediate task (Simplicity First).
- Rule: Readability Priority: Emphasize code readability, explicit naming, and clear logical structure unless it actively harms execution performance.

Req: Component Isolation & Testability: Ensure components are decoupled and strictly verifiable.
- Rule: Dependency Injection: Strictly avoid global states, hardcoded connections, or deeply nested instantiations. Explicitly inject dependencies (e.g., configurations, clients, or services) via initializers, function parameters, or context objects to enable robust mocking and isolated testing.

Req: Scoped Resource & State Management: Ensure safe and guaranteed cleanup of resources and states upon scope exit.
- Rule: Scoped Return Pattern: Eagerly prefer scoped return and automatic cleanup mechanisms to guarantee the safe release of resources (file descriptors, memory, locks, sockets) and the restoration of state (working directories, environment changes) under any circumstances, including normal exit, early returns, errors, or panics.
  - Rule: Strictly prevent resource leaks and dangling state mutations by abandoning manual cleanup calls at the end of functions (which are easily bypassed by errors); instead, always leverage language-native resource lifetime management structures for deterministic cleanup.

Req: Zero-Copy Data Transfer: Minimize memory bandwidth and CPU overhead by eliminating redundant copying.
- Rule: Reference Views over Deep Copying: Always prefer views, slices, or references over allocating and deep-copying data.
- Rule: Move Semantics & Ownership: Prefer transferring ownership or moving structures when passing large datasets between contexts.
- Rule: Memory Mapping & OS Splice: For file I/O and large network streaming, use memory mapping or kernel-level splicing to bypass user-space buffer copying.

Section: Concurrency & Parallelism
Req: Data-Flow Parallelism: Prefer message passing and pipeline architectures over shared-state synchronization.
- Rule: Avoid Shared State: Do not communicate by sharing memory; instead, share memory by communicating. Avoid raw threads synchronized by manual locks (mutexes, semaphores) to eliminate data races and deadlocks.
- Rule: Pipeline Architecture: Structure parallel operations as unidirectional data-flow pipelines where data is passed between processing nodes via channels or pipes.
