# Python Implementation Standards

Section: Modern Syntax & Type Safety
Req: Native Type Hinting: Enforce static typing for safety and predictability.
- Rule: Modern Type Annotations: Use native built-in collections (e.g., `list[int]`, `dict[str, Any]`) and union operators (`int | None`) instead of the legacy `typing` module to ensure concise and readable type boundaries.

Req: Immutable & Efficient Data Structures: Enforce state predictability and minimize memory overhead.
- Rule: Frozen & Optimized Dataclasses: When modeling data structures, strictly prefer `@dataclass(frozen=True, slots=True, kw_only=True)`.
  - Rule: Enforce `frozen=True` to guarantee state immutability for static analyzers, `slots=True` to avoid `__dict__` creation for memory efficiency, and `kw_only=True` to prevent parameter ordering bugs. Mandate `dataclasses.replace()` for all state updates.

Section: Control Flow & Idioms
Req: Switch Patterns & Destructuring: Simplify complex branching and data extraction.
- Rule: Prefer Switch Patterns: Exclusively prefer Python 3.10+ `match`/`case` (switch) statements over a series of `if/elif/else` patterns or legacy dictionary-based dispatch maps for discrete control flow routing.
- Rule: Match-Case Destructuring: Utilize `match`/`case` statements when destructuring complex dictionaries, API responses, or JSON objects.

Req: Branch Delegation: Abstract complex conditional logic to enhance readability.
- Rule: Delegate Branching Flows: Extract condition-heavy branching logic into pre-created helper functions to preserve primary control flow readability.
  - Rule: Utilize inline delegation (e.g., closures, inner functions, or lambdas) for simple, strictly localized branching.

Req: EAFP Principle: Prefer exception handling over preemptive checks.
- Rule: Exception-Driven Flow: Adopt the "Easier to Ask Forgiveness than Permission" (EAFP) idiom. Rely on localized `try/except` blocks for control flow rather than excessive "Look Before You Leap" (LBYL) state checks.

Req: Analyzable Control Flow: Eliminate loop side-effects to maximize static analysis visibility.
- Rule: Pure Transformations Over Mutation: Favor list/dict comprehensions and pure functional tools (`map`, `filter`) over imperative `for` loops with manual state mutation (e.g., `list.append()`).
  - Rule: Ensure control flow remains traceable by static analyzers (like `mypy`) by strictly converting side-effecting `for` loops into pure expression comprehensions, preventing all collection modification during iteration.

Req: Lazy Evaluation & Progressive Pipelines: Exploit Python's deferred execution for latency-friendly designs.
- Rule: Generator-Driven Pipelines: Utilize generators (`yield`) and the `itertools` module to build deferred execution pipelines rather than eager evaluations (e.g., instantiating full lists).
  - Rule: Enforce O(1) memory footprint and minimal Time-to-First-Byte latency for streaming/large-scale data by strictly yielding progressive results instead of building and returning whole collections at once.

Req: Scoped Resource Management (RAII): Guarantee safe cleanup using Python context managers.
- Rule: Generator-Based Context Managers: Use `@contextlib.contextmanager` combined with generators to tightly scope resource lifecycles (e.g., files, network sockets, locks) to a specific `with` block, satisfying common scoped return constraints.
- Rule: Mandatory Finally Cleanup: Always wrap the generator's `yield` statement in a `try...finally` block to strictly guarantee that the teardown logic executes and prevents resource leaks even if an exception is raised within the `with` block.

Req: Pure Data Pipelines: Construct declarative pipelines using functional primitives.
- Rule: Functools Composition: Leverage `functools` (e.g., `partial`, `reduce`, `singledispatch`) to compose pure functions.
  - Rule: Freeze dependencies through `functools.partial` to eliminate global or instance state reliance, combining this with strict typing to guarantee that all functional data pipelines are fully verifiable at compile-time.

Section: Architectural Patterns
Req: API Evolution Tracking: Clarify inheritance and track lifecycle changes explicitly.
- Rule: Explicit Overriding: Use the `@override` decorator (PEP 698) on subclass methods intended to replace or extend a base class method to catch signature mismatches.
- Rule: Formal Deprecation: Use the `@deprecated` decorator (PEP 702) to mark obsolete public APIs with a clear migration path.

Section: High-Performance & JIT Compatibility
Req: Strict JIT Compilation: Ensure numerical code is fully optimizable.
- Rule: Nopython Mode: Exclusively use `@njit` (or `@jit(nopython=True)`). Prevent fallback to object mode by avoiding unsupported native Python objects inside hot loops.
- Rule: Fused C-Style Loops: Inside JIT boundaries, use explicitly unrolled `for` loops to fuse operations and prevent intermediate memory allocations.
- Rule: Pre-allocate Outputs: Pre-allocate output arrays before passing them into JIT functions and use in-place operations to minimize memory management overhead.

Req: Native Zero-Copy & Memory Views: Eliminate redundant copying using Python-specific primitives.
- Rule: Binary Data Views: Strictly use `memoryview()` when passing or manipulating raw binary buffers (e.g., `bytes`, `bytearray`) to enforce zero-allocation slicing.
- Rule: In-Place Array Mutations: Pre-allocate large arrays (e.g., `np.empty`) and apply in-place operators (`+=`, `*=`) or `out=` arguments, completely avoiding dynamic array resizing (like `np.append`).

Req: Vectorization Over Iteration: Offload numerical processing to low-level backends.
- Rule: Array Broadcasting: Outside of explicit JIT boundaries, completely avoid `for` loops on numerical data. Rely exclusively on NumPy broadcasting, ufuncs, and boolean masks to execute operations at C/Fortran speeds.
