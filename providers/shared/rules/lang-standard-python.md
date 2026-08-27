# Python Implementation Standards

Section: Modern Syntax && Type Safety
Req: Native Type Hinting: Enforce static typing for safety && predictability.
- Rule: Modern Type Annotations: Enforce native built-in collections (e.g., `list[int]`, `dict[str, Any]`) && union operators (`int | None`) over the legacy `typing` module for concise && readable type boundaries.

Req: Immutable && Efficient Data Structures: Enforce state predictability && minimize memory overhead.
- Rule: Frozen && Optimized Dataclasses: Enforce `@dataclass(frozen=True, slots=True, kw_only=True)` when modeling data structures.
  - Rule: Dataclass Field Invariants: Enforce `frozen=True` for immutability, `slots=True` to eliminate `__dict__` overhead, `kw_only=True` to prevent ordering bugs, && `dataclasses.replace()` for all state updates.

Section: Control Flow && Idioms
Req: Switch Patterns && Destructuring: Simplify complex branching && data extraction.
- Rule: Prefer Switch Patterns: Enforce Python 3.10+ `match`/`case` statements over `if/elif/else` chains || dictionary dispatch maps for discrete control flow routing.
- Rule: Match-Case Destructuring: Enforce `match`/`case` statements when destructuring complex dictionaries, API responses, || JSON objects.

Req: Branch Delegation: Abstract complex conditional logic to enhance readability.
- Rule: Delegate Branching Flows: Extract condition-heavy branching logic into dedicated helper functions to preserve primary control flow readability.
  - Rule: Localized Branching Delegation: Enforce inline delegation (e.g., closures, inner functions, lambdas) for simple, strictly localized branching.

Req: EAFP Principle: Prefer exception handling over preemptive checks.
- Rule: Exception-Driven Flow: Enforce localized `try/except` blocks for control flow (EAFP) over preemptive state checks (LBYL).

Req: Analyzable Control Flow: Eliminate loop side-effects to maximize static analysis visibility.
- Rule: Pure Transformations Over Mutation: Enforce comprehensions && pure functional tools (`map`, `filter`) over imperative `for` loops with manual state mutation (e.g., `list.append()`).
  - Rule: Traceable Iteration: Prohibit collection mutation during iteration to guarantee full static analysis visibility by tools like `mypy`.

Req: Lazy Evaluation && Progressive Pipelines: Exploit Python deferred execution for latency-friendly designs.
- Rule: Generator-Driven Pipelines: Enforce generators (`yield`) && `itertools` to build deferred execution pipelines over eager list allocations.
  - Rule: O(1) Memory Streaming: Enforce progressive yielding over monolithic collection construction to guarantee `O(1)` memory footprints && minimal Time-to-First-Byte latency.

Req: Scoped Resource Management (RAII): Guarantee safe cleanup using Python context managers.
- Rule: Generator-Based Context Managers: Enforce `@contextlib.contextmanager` combined with generators to tightly scope resource lifecycles (e.g., files, network sockets, locks) to a specific `with` block.
- Rule: Mandatory Finally Cleanup: Enforce wrapping generator `yield` statements in `try...finally` blocks to guarantee teardown execution && prevent resource leaks upon exceptions.

Req: Pure Data Pipelines: Construct declarative pipelines using functional primitives.
- Rule: Functools Composition: Enforce `functools` (e.g., `partial`, `reduce`, `singledispatch`) to compose pure functions.
  - Rule: Partial Dependency Freezing: Enforce `functools.partial` to freeze dependencies && eliminate mutable state reliance, combining with strict static typing.

Section: Architectural Patterns
Req: API Evolution Tracking: Clarify inheritance && track lifecycle changes explicitly.
- Rule: Explicit Overriding: Enforce `@override` (PEP 698) on subclass methods intended to replace || extend base class methods to prevent signature mismatches.
- Rule: Formal Deprecation: Enforce `@deprecated` (PEP 702) to mark obsolete public APIs with explicit migration paths.

Section: Concurrency && Parallelism
Req: Data-Flow Parallelism (Python): Enforce async && message-passing concurrency over thread locks.
- Rule: Async Pipeline Architecture: Enforce `asyncio` tasks && `asyncio.Queue` for I/O-bound concurrency; enforce `concurrent.futures.ProcessPoolExecutor` for CPU-bound parallelism over manual `threading.Thread` with shared locks.

Section: High-Performance && JIT Compatibility
Req: Strict JIT Compilation: Ensure numerical code is fully optimizable.
- Rule: Nopython Mode: Enforce `@njit` (|| `@jit(nopython=True)`); prohibit fallback to object mode by eliminating unsupported native Python objects inside hot loops.
- Rule: Fused C-Style Loops: Inside JIT boundaries, enforce explicitly unrolled `for` loops to fuse operations && prevent intermediate memory allocations.
- Rule: Pre-allocate Outputs: Pre-allocate output arrays before passing into JIT functions && enforce in-place operations to eliminate allocation overhead.

Req: Native Zero-Copy && Memory Views: Eliminate redundant copying using Python-specific primitives.
- Rule: Binary Data Views: Enforce `memoryview()` when passing || manipulating raw binary buffers (e.g., `bytes`, `bytearray`) for zero-allocation slicing.
- Rule: In-Place Array Mutations: Pre-allocate large arrays (e.g., `np.empty`) && apply in-place operators (`+=`, `*=`) || `out=` arguments; prohibit dynamic array resizing (e.g., `np.append`).

Req: Vectorization Over Iteration: Offload numerical processing to low-level backends.
- Rule: Array Broadcasting: Outside explicit JIT boundaries, prohibit `for` loops on numerical data; enforce NumPy broadcasting, ufuncs, && boolean masks for C/Fortran execution speed.
