# Native Language Standards

Section: Naming Conventions && Identifier Taxonomy
Req: Native Identifier Uniformity: Enforce deterministic lexical naming patterns across native compiled codebases (C, C++, Rust, Zig).
- Rule: TypeIdentifiersPascalCase: MUST enforce `PascalCase` for all type declarations (`struct`, `class`, `enum`, `union`, `concept`, `trait`, type aliases) to guarantee immediate type distinction; MUST NOT use `snake_case` or `camelCase` for type definitions.
- Rule: FunctionsAndModulesSnakeCase: MUST enforce `snake_case` for all function names, member methods, namespaces, and package/module identifiers to ensure uniform symbol discovery; MUST NOT use `camelCase` or `PascalCase` for function symbols.
- Rule: MemberVariablesSnakeCase: MUST enforce `snake_case` with a trailing underscore (`field_name_`) in C/C++ classes and structs to isolate member fields from local variables; MUST NOT declare field names with leading underscores (`_var`, `__var` are compiler-reserved).
- Rule: ConstantsAndMacrosTaxonomy: MUST enforce `kPascalCase` || `SCREAMING_SNAKE_CASE` for compile-time immutable constants; MUST enforce `SCREAMING_SNAKE_CASE` exclusively for preprocessor macros; MUST NOT define lowercase macros.
- Rule: GenericParametersPascalCase: MUST enforce `PascalCase` or single uppercase symbols for generic and template type parameters (`template <typename ItemType>`, `<Element>`, `T`); MUST NOT use `snake_case` for generic parameters.

Section: Memory Geometry, Page Locality && Cache Alignment
Req: Hardware Memory Alignment: Guarantee memory layout efficiency across diverse CPU and OS architectures.
- Rule: DynamicPageSizeQuery: MUST query runtime page geometry dynamically via `sysconf(_SC_PAGESIZE)` or platform runtime APIs; MUST NOT hardcode 4096-byte page size assumptions to prevent page mapping faults on variable-page kernels.
- Rule: AndroidSixteenKbPageAlignment: MUST enforce 16 KB max page alignment on all native ELF binaries by passing linker flags `-Wl,-z,max-page-size=16384` to guarantee Android 15+ execution readiness; MUST NOT link binaries with 4 KB segment limits.
- Rule: TransparentHugePages: MUST enforce 2 MB Transparent Huge Page backing via `madvise(addr, len, MADV_HUGEPAGE)` || `mmap(..., MAP_HUGETLB)` when contiguous working sets exceed 16 MB to minimize TLB misses.
- Rule: CacheLineFalseSharingIsolation: MUST enforce 64-byte boundary alignment (`alignas(64)` in C/C++, `#[repr(align(64))]` in Rust, `align(64)` in Zig) on independent concurrent atomics, ring-buffer read/write pointers, and lockless queue cursors to eliminate false sharing.

Section: Hardware DMA Zero-Copy && Kernel Acceleration
Req: Kernel Zero-Copy Pipelines: Stream hardware buffers across subsystem boundaries without user-space memcpy.
- Rule: HardwareDmaPipelines: MUST enforce Linux `dma-buf` / `io_uring` fixed buffers and Android `AHardwareBuffer` zero-copy memory pipelines across CPU, GPU (Vulkan), NPU (Neural Accelerators / QNN / FastRPC / modern vendor runtimes; note NNAPI is deprecated), Camera, and IPC; MUST NOT copy buffer payloads through user-space memory.
- Rule: ExplicitCacheSynchronization: MUST invoke explicit cache synchronization ioctls (`DMA_BUF_IOCTL_SYNC`, `AHardwareBuffer_lock`/`unlock`) before and after CPU memory operations on shared DMA buffers to guarantee coherency; MUST NOT access shared DMA memory without sync barriers.
- Rule: AsynchronousSyncFences: MUST enforce explicit sync fence file descriptors (`sync_fence_fd`) to synchronize cross-accelerator execution without blocking CPU worker threads.

Section: Exact-Width Types, Bit Manipulation && SIMD Data Locality
Req: Deterministic Bitwidth && Microarchitecture Saturation: Maximize single-cycle ALU execution and memory cache hit rates.
- Rule: ExactWidthIntegerTypes: MUST enforce `<stdint.h>` exact-width types (`uint8_t`..`uint64_t`, `int32_t`, `int64_t`, `size_t`, `uintptr_t`); MUST NOT use ambiguous `long` or `short` types in data structures, network protocols, or binary storage formats.
- Rule: SafeBitwiseTypePunning: MUST enforce typed bit-cast operations (`std::bit_cast`, `memcpy`, `@bitCast`, `bytemuck`/`transmute`) for bitwise reinterpretation; MUST NOT utilize undefined union punning or raw pointer casts.
- Rule: HardwareBitTwiddlingIntrinsics: MUST enforce single-cycle hardware intrinsics (`popcount`, `countl_zero`/`clz`, `byteswap`/`bswap`) and branchless bit-hacks (`v & (v - 1)` to clear lowest set bit, `v & -v` to isolate lowest set bit, `(x + M) & ~M` for power-of-2 alignment where `M = align - 1`, `v && !(v & (v - 1))` for power-of-2 validation); MUST NOT write manual looping algorithms for bit manipulation.
- Rule: ContiguousLookupContainers: MUST enforce cache-contiguous flat arrays (`std::vector`, slices, flat maps) over pointer-chasing node trees (`std::map`, linked lists) for small-to-medium datasets ($N < 5000$) to guarantee L1/L2 cache spatial locality.
- Rule: StructureOfArraysLayout: MUST enforce Structure of Arrays (SoA) layout over Array of Structures (AoS) for vectorized batch computation to guarantee contiguous SIMD vector streams (AVX2/NEON); MUST NOT interleave non-computational payload fields inside high-throughput compute structures.
- Rule: LinearTimeSelection: MUST enforce linear-time selection (`std::nth_element`, `select_nth_unstable`, $\mathcal{O}(N)$) over full sorting ($\mathcal{O}(N \log N)$) when extracting percentiles, medians, or top-$K$ subsets.

Section: Binary Symbol Hardening && C-ABI Isolation
Req: Dynamic Library Boundary Hardening: Guarantee stable ABI boundaries and minimize exported symbol tables.
- Rule: ContextualSymbolVisibility: If a repository || build configuration enforces default hidden visibility (`-fvisibility=hidden`), code MUST adhere to it && annotate public entry points with explicit export macros (`MYLIB_API`, `#[no_mangle]`, `export`); otherwise, MUST NOT unconditionally enforce global hidden visibility without vetting to prevent breaking downstream ABI consumers.
- Rule: StableCAbiBoundaries: MUST enforce `extern "C"` linkage, primitive types, and opaque pointer handles across dynamic library boundaries; MUST NOT leak language-specific standard library templates, classes, or runtime types across `.so`/`.dll` boundaries.

Section: Static Lifecycle && Destruction Safety (SDOF)
Req: Deterministic Initialization && Destruction Safety: Eliminate Static Destruction Order Fiascos across translation units.
- Rule: ProhibitNonTrivialStaticDestructors: MUST enforce trivial destructibility or immortal lifetimes for all global and non-local static variables to eliminate Static Destruction Order Fiascos (SDOF); MUST NOT define global objects with non-trivial destructors to prevent post-`main()` thread race crashes.
- Rule: DeterministicLifecycleStorage: MUST enforce `constinit`, immortal zero-destructor storage wrappers, or explicit application lifecycle orchestrators initialized and torn down inside `main()`.
