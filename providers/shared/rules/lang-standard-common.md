# Common Language Standards

Section: Code Quality && Maintainability
Req: Robust Configuration: Ensure code is easily configurable && maintainable.
- Rule: Magic Numbers Avoidance: Prohibit hard-coded values in algorithmic implementations, thresholds, && dimensions.
  - Rule: Parameterized Configs: Parameterize all algorithmic values via configuration structures, function arguments, || explicit named constants.
  - Rule: Usable Defaults: Provide sensible default values in parameterized configurations to preserve out-of-the-box usability while allowing programmatic overrides.

Req: Balanced Code Quality: Enforce SOLID principles && prioritize code readability without degrading system performance.
- Rule: SOLID Design Principles: Enforce SOLID principles across modular architectures to guarantee maintainability && testability.
  - Rule: Pragmatic Application: Apply SOLID pragmatically to keep code modular && readable without unnecessary design overhead (Simplicity First).
- Rule: Readability Priority: Emphasize code readability, explicit naming, && clear logical structure unless it actively degrades execution performance.

Req: Component Isolation && Testability: Ensure components are decoupled && strictly verifiable.
- Rule: Dependency Injection: Prohibit global states, hardcoded connections, || deeply nested instantiations; explicitly inject dependencies (e.g., configurations, clients, services) via initializers, parameters, || context objects to enable isolated testing.

Req: Scoped Resource && State Management: Ensure safe && guaranteed cleanup of resources && states upon scope exit.
- Rule: Scoped Return Pattern: Enforce scoped return && automatic cleanup mechanisms to guarantee safe release of resources (file descriptors, memory, locks, sockets) && restoration of state (working directories, environment changes) across normal exits, early returns, errors, || panics.
  - Rule: Native Deterministic Cleanup: Prohibit manual cleanup calls at function endpoints; enforce language-native lifetime management structures for deterministic cleanup to eliminate leak vectors from unhandled errors.

Req: Zero-Copy Data Transfer: Minimize memory bandwidth && CPU overhead by eliminating redundant copying.
- Rule: Reference Views over Deep Copying: Enforce views, slices, || references over allocating && deep-copying data.
- Rule: Move Semantics && Ownership: Enforce ownership transfer || moving structures when passing large datasets between contexts.
- Rule: Memory Mapping && OS Splice: Enforce memory mapping || kernel-level splicing for file I/O && large network streaming to bypass user-space buffer copying.

Section: Concurrency && Parallelism
Req: Data-Flow Parallelism: Enforce message passing && pipeline architectures over shared-state synchronization.
- Rule: Memory Sharing via Communication: Prohibit raw threads synchronized by manual locks (mutexes, semaphores); enforce message passing && communication channels to eliminate data races && deadlocks.
- Rule: Pipeline Architecture: Enforce unidirectional data-flow pipelines where data is passed between processing nodes via channels || pipes.
