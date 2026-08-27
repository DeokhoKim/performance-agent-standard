# Comprehensive Analysis Report: Modern C++ Standards, Hardware DMA, Bit-Twiddling & Standard Layering

## 1. Executive Summary & Objective

This report establishes the complete engineering foundation for high-performance, secure, and cross-platform C++ development. The standards are specifically tailored for **Unix-like systems (Linux, macOS, BSD) and Android NDK (API 29+ / Clang / Bionic / libc++)**, with minimal, isolated accommodation for Windows.

The architecture strictly enforces:
- **Default Baseline**: **C++17** as the assumed universal standard, with layered standard extensions for **C++20** and **C++23**.
- **Android Baseline**: **API 29+ (Android 10+)** targeting modern production systems, with **16 KB page size alignment** (mandated for Android 15+).
- **Runtime Performance & Hardware DMA**: Direct hardware-accelerated memory sharing via Linux `dma-buf` / `io_uring` and Android `AHardwareBuffer` across CPU, GPU (Vulkan), **NPU (Neural Accelerators / NNAPI / QNN / FastRPC)**, Camera, and IPC with explicit CPU cache invalidation.
- **Deep-Dive `std::invoke` & Delegation**: Replacing raw `void*` function pointers with concept-constrained templates (`std::invocable`), move-only delegates (`std::move_only_function`), and non-owning views (`std::function_ref`), executed exclusively via `std::invoke` with automatic dereferencing of raw pointers, `std::unique_ptr`, `std::shared_ptr`, and `std::reference_wrapper`.
- **In-Place Placement `new` with `std::unique_ptr`**: Encapsulating pre-allocated stack/arena storage inside `std::unique_ptr<T, InPlaceDeleter>` using stateless functor deleters (EBO `sizeof == 8`), `alignas(alignof(T))` storage, and `std::launder` provenance guarantees.
- **Member Visibility & `final` Specifier**: Pragmatic member visibility (`protected` for low-friction extensible hierarchies; `private` for strict invariants); universal `final` specifier on concrete classes and standalone structs to trigger compiler **static devirtualization** and eliminate indirect vtable dispatches.
- **Static Storage Safety & SDOF Elimination**: Strict prohibition of static/global variables with non-trivial destructors to eliminate Static Destruction Order Fiascos (SDOF) and post-`main()` worker thread race crashes; enforcing `NoDestructor<T>`, `constinit`, and explicit `main()` lifecycle management.
- **Hardware Bit-Twiddling & `<stdint.h>`**: Exact bit-width guarantees via `<stdint.h>`, branchless bitmask operations, memory page alignment arithmetic, and Stanford Bit Hacks (Sean Eron Anderson) coupled with C++20 `<bit>` hardware intrinsics (POPCNT, CLZ/CTZ, BSWAP).
- **Separation of State and Behavior**: Clear architectural separation between **Literal Value Structs** (passive data containers with public fields, standard layout, trivial copy/move) and **Stateless Operation Processors** (pure function engines without internal mutable state) to eliminate wide-surface multi-threaded data races.
- **Const-by-Default & Parameter Passing**: Rust-like single-assignment local `const` by default; plain value passing for scalar primitives (`int`) without signature clutter or pointer indirection; `const T&` or non-owning views for non-scalars.
- **`constexpr` Chaining & `consteval` Guarding**: Deep compile-time evaluation cascades for pure functions, FNV-1a string hashing, and lookup tables; enforcing `consteval` (C++20) or `constexpr auto` (C++17) to prevent silent runtime execution fallback.
- **Page Locality & TLB Optimization**: Page boundary alignment (4KB, 16KB for Android 15, 2MB Huge Pages via `mmap` / `madvise(MADV_HUGEPAGE)`), dynamic page discovery (`sysconf(_SC_PAGESIZE)`), and avoiding cross-page boundary memory splits.
- **Branch Hinting**: Happy path optimization via `[[likely]]` / `[[unlikely]]` and `__builtin_expect` for compact L1 instruction cache (I-cache) layout.
- **Symbol Visibility & Security**: Default hidden binary symbol visibility (`-fvisibility=hidden`, `-fvisibility-inlines-hidden`), explicit C-ABI export boundaries (`MYLIB_API`), strictly private class members with zero raw pointer leakage, and translation-unit anonymous namespaces (`namespace { ... }`).
- **Minimalist Implementations**: Prohibiting over-engineered template metaprogramming and bloated abstractions; prioritizing clean, readable code with mechanical sympathy.

---

## 2. Rule Hierarchy & "Baseline + 1" Layering Architecture

The rule system uses a **"Baseline + 1" modular loading model**: an agent loads `lang-standard-cpp.md` (Universal Baseline) plus exactly one dialect file corresponding to the project's C++ standard version:

```
+-----------------------------------------------------------------------------------+
|                            Common Language Standards                              |
|  - Robust Configuration & Dependency Injection                                    |
|  - Balanced SOLID & Readability Priority                                          |
|  - Scoped Resource Release (RAII) & Zero-Copy Pipelines                           |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------+-----------------------------------------+
|                            Native Language Standards                              |
|  - In-Place Linear-Time Selection (std::nth_element)                              |
|  - Zero-Copy Buffer Management (mmap, views) & Capacity Pre-Allocation            |
|  - RAII Guard Destruction & Pipeline Concurrency                                  |
+-----------------------------------------+-----------------------------------------+
                                          |
                                          v
+-----------------------------------------+-----------------------------------------+
|                      C++ Universal Baseline Standards                             |
|                           (lang-standard-cpp.md)                                  |
|  - Rule of Zero/Five & Deleted Copy (= delete) for Handles/Mutexes                |
|  - std::unique_ptr Supremacy & Stateless Custom Deleters (EBO sizeof == 8)        |
|  - Placement new inside std::unique_ptr for Pre-Allocated/Arena Storage           |
|  - Prohibit Non-Trivial Static Destructors (SDOF Elimination via NoDestructor<T>) |
|  - Separation of Data (Literal Structs) vs Behavior (Stateless Processors)        |
|  - Member Visibility (protected in hierarchies, private for invariants)          |
|  - Final Keyword on class and struct for Static Devirtualization                 |
|  - Modern Delegation Patterns & std::invoke for Universal Member/Function Calls   |
|  - Const-by-Default Locals & Register-Optimal Scalar Value Parameter Passing     |
|  - Pure constexpr Function Chaining & Compile-Time Evaluation Guarding            |
|  - Translation Unit Scoping (using namespace std in .cpp; anonymous namespace)    |
|  - Using Type Aliases (using Alias = ...) & Minimalist Implementation Restraint   |
|  - Pre-allocated C-Arrays for Compile-Time Sizes; Prohibit VLAs                   |
|  - Hardware Bit-Twiddling, <stdint.h> Widths & Stanford Bit Hacks                 |
|  - Page Locality (4KB/16KB/2MB Huge Pages) & Dynamic sysconf(_SC_PAGESIZE)        |
|  - Happy-Path Branch Hints ([[likely]] / [[unlikely]], __builtin_expect)          |
|  - Symbol Visibility & Security (-fvisibility=hidden, public C-ABI, no ptr leak)  |
|  - De-facto Directives (#pragma once, __restrict__, prefetch, hot/cold)           |
|  - Lock-Free Concurrency, Atomic Bitmasks, alignas(64) & Acquire-Release         |
|  - DMA & Hardware Buffers across CPU, GPU, NPU (AHardwareBuffer, dma-buf)         |
|  - Android API 29+ & Unix Primacy (16KB page alignment; zero Boost/locale/regex)  |
|  - Dynamic Shared Boundary ABI Isolation (extern "C", PImpl Handles)              |
+--------------------+--------------------+--------------------+--------------------+
                     |                    |                    |
        (Target: 17) v       (Target: 20) v       (Target: 23) v
+--------------------+   +--------------------+   +--------------------+
| lang-std-cpp-17.md |   | lang-std-cpp-20.md |   | lang-std-cpp-23.md |
| - SFINAE / traits  |   | - Concepts/requires|   | - std::expected    |
| - string_view value|   | - std::span view   |   | - std::flat_map    |
| - structured bind  |   | - <=> spaceship    |   | - std::mdspan      |
| - if constexpr     |   | - std::jthread     |   | - Deducing this    |
| - variant/optional |   | - std::ranges/views|   | - std::print       |
| - PMR arena stack  |   | - consteval/init   |   | - std::unreachable |
| - Explicit C++17   |   | - Explicit C++20   |   | - Explicit C++23   |
|   Prohibitions     |   |   Prohibitions     |   |   Prohibitions     |
+--------------------+   +--------------------+   +--------------------+
```

---

## 3. Placement `new` with `std::unique_ptr` for Pre-Allocated Storage

### 3.1 Mechanics: Safe In-Place Construction inside Smart Pointers
When working with pre-allocated memory (stack buffers, static arena slabs, or monotonic bump pools), objects can be constructed in-place via placement `new` and wrapped in `std::unique_ptr` with a custom stateless deleter:

```cpp
#include <stdint.h>
#include <memory>
#include <new>
#include <utility>

struct InPlaceDeleter {
    template <typename T>
    void operator()(T* ptr) const noexcept {
        if (ptr) {
            ptr->~T(); // Explicit destructor call only, NO memory free()
        }
    }
};

template <typename T>
using in_place_unique_ptr = std::unique_ptr<T, InPlaceDeleter>;

template <typename T>
struct alignas(alignof(T)) InPlaceStorage {
    uint8_t bytes[sizeof(T)];

    [[nodiscard]] void* address() noexcept { return static_cast<void*>(bytes); }
    [[nodiscard]] const void* address() const noexcept { return static_cast<const void*>(bytes); }
};

template <typename T, typename... Args>
[[nodiscard]] in_place_unique_ptr<T> make_in_place(void* storage, Args&&... args) {
    return in_place_unique_ptr<T>(::new (storage) T(std::forward<Args>(args)...));
}

// Zero-Cost Abstraction Guarantee via Empty Base Optimization (EBO)
static_assert(sizeof(in_place_unique_ptr<int>) == sizeof(int*), "EBO violation: Deleter added size overhead!");
```

### 3.2 Critical Safety Invariants
1. **Alignment & Sizing**: Storage MUST satisfy `alignas(alignof(T))` and `sizeof(T)` using raw byte arrays (`uint8_t` or `std::byte`). Prohibit deprecated `std::aligned_storage`.
2. **Buffer Lifetime Invariant**: The backing memory buffer MUST strictly outlive the `in_place_unique_ptr`. The storage MUST be declared **before** the `unique_ptr` in stack frames.
3. **Prohibit Escaping Stack Pointers**: `in_place_unique_ptr` tied to stack storage must never escape the enclosing stack frame.
4. **Pointer Provenance & `std::launder`**: Always initialize the `unique_ptr` with the exact pointer returned by `::new (...)`. When reading back through storage pointers containing `const` or reference members, apply `std::launder`.

---

## 4. Modern Delegation Patterns vs. Raw Function Pointers & Deep Dive on `std::invoke`

### 4.1 Vulnerabilities of Raw C Function Pointers (`void (*)(void*)`)
1. **Lack of Move-Only State Support**: Cannot encapsulate move-only types (`std::unique_ptr`, file descriptors, GPU handles) without manual, error-prone C-style destructor callback boilerplate.
2. **Type-Unsafe Contexts (`void*`)**: Bypasses compile-time type checking, alignment verification, and const-correctness.
3. **Decoupled Lifetimes**: No static guarantee that the context outlives the pointer invocation, creating use-after-free vectors across threads.

### 4.2 Modern Delegation Spectrum for Concurrent Pipelines
1. **Static Zero-Cost Delegation (Concept-Constrained Templates)**:
   - For compile-time topologies: `template <typename F> requires std::invocable<F, In>`. Direct devirtualization and compiler inlining.
2. **Thread-Confined Move-Only Delegates (`std::move_only_function` / SBO `MoveOnlyDelegate`)**:
   - For tasks traversing MPMC/SPSC lock-free queues across thread boundaries:
   - Encapsulates move-only resources (`std::unique_ptr<Data>`).
   - SBO eliminates heap allocations.
   - Enforces single-use execution via `&&` qualifier (`std::move_only_function<void() &&>`).
3. **Transient Borrowing (`std::function_ref`)**:
   - Non-owning 2-word view (`context_ptr + thunk`) for synchronous stack-scoped algorithms without dynamic allocation.
4. **Dynamic Hot-Swapping (`std::atomic<std::shared_ptr<const Delegate>>`)**:
   - Allows control threads to update processing strategies atomically while worker threads execute concurrently with zero lock contention.

### 4.3 Deep Dive: Uniform Invocation via `std::invoke` for Member Methods, Functions & Objects

#### The Syntax Fragmentation Problem in C++
In standard C++, direct call syntax `f(args...)` works only for free functions, static methods, and function objects. It **fails** when delegating to member function pointers or member data pointers:
- Object / Reference: `(obj.*method_ptr)(args...)`
- Raw Pointer: `(ptr->*method_ptr)(args...)`
- Smart Pointer (`std::unique_ptr`, `std::shared_ptr`): `((*smart_ptr).*method_ptr)(args...)`
- Pointer to Member Data: `obj.*data_ptr` or `ptr->*data_ptr`

`std::invoke` (defined in `<functional>` since C++17) resolves all syntax fragmentation into a single, uniform invocation interface with **zero runtime overhead** (pure compile-time template intrinsic).

#### Universal Invocation Matrix across Types

| Callable Target | Syntax with `std::invoke` | Standard C++ Direct Equivalent |
| :--- | :--- | :--- |
| **Free Function** | `std::invoke(func, a, b)` | `func(a, b)` |
| **Lambda / Functor** | `std::invoke(lambda, a, b)` | `lambda(a, b)` |
| **Member Method (Value/Ref)** | `std::invoke(&Class::method, obj, a, b)` | `(obj.*&Class::method)(a, b)` |
| **Member Method (Raw Pointer)** | `std::invoke(&Class::method, &obj, a, b)` | `((&obj)->*&Class::method)(a, b)` |
| **Member Method (`unique_ptr`)** | `std::invoke(&Class::method, uptr, a, b)` | `((*uptr).*&Class::method)(a, b)` |
| **Member Method (`shared_ptr`)** | `std::invoke(&Class::method, sptr, a, b)` | `((*sptr).*&Class::method)(a, b)` |
| **Member Method (`ref_wrapper`)**| `std::invoke(&Class::method, std::ref(obj), a, b)` | `(ref.get().*&Class::method)(a, b)` |
| **Member Data Pointer** | `std::invoke(&Class::field, obj)` | `obj.*&Class::field` (Returns field value/ref) |

#### Concrete Reference Code Pattern

```cpp
#include <functional>
#include <memory>
#include <stdint.h>
#include <utility>

struct AudioEngine {
    int32_t sample_rate = 48000;

    int32_t process_frame(int32_t channel, int32_t gain) const noexcept {
        return channel * gain;
    }
};

// Generic Zero-Cost Delegation Dispatcher
template <typename Callable, typename... Args>
constexpr decltype(auto) dispatch_delegate(Callable&& callable, Args&&... args) {
    return std::invoke(std::forward<Callable>(callable), std::forward<Args>(args)...);
}

void demo_invoke_semantics() {
    AudioEngine engine;
    auto engine_uptr = std::make_unique<AudioEngine>();
    auto engine_sptr = std::make_shared<AudioEngine>();

    // 1. Invoking Member Method on Object Instance (lvalue/rvalue)
    int32_t r1 = dispatch_delegate(&AudioEngine::process_frame, engine, 1, 10);

    // 2. Invoking Member Method through Raw Pointer
    int32_t r2 = dispatch_delegate(&AudioEngine::process_frame, &engine, 1, 10);

    // 3. Invoking Member Method through std::unique_ptr (Automatic Smart Pointer Dereferencing!)
    int32_t r3 = dispatch_delegate(&AudioEngine::process_frame, engine_uptr, 1, 10);

    // 4. Invoking Member Method through std::shared_ptr
    int32_t r4 = dispatch_delegate(&AudioEngine::process_frame, engine_sptr, 1, 10);

    // 5. Invoking Member Method through std::reference_wrapper
    int32_t r5 = dispatch_delegate(&AudioEngine::process_frame, std::ref(engine), 1, 10);

    // 6. Accessing Member Data Variable via Pointer-to-Member
    int32_t sr = dispatch_delegate(&AudioEngine::sample_rate, engine); // Returns 48000
}
```

---

## 5. Member Visibility & The `final` Specifier (Devirtualization)

### 5.1 Pragmatic Member Visibility (`protected` vs `private`)
- **`protected` Variables in Extensible Hierarchies**: Permitted in base classes specifically designed for subclass specialization (e.g. rendering backends, parsing nodes, pipeline stages) to give derived subclasses direct access to core buffers, eliminating trivial getter/setter boilerplate.
- **`private` Variables for Strict Invariants**: Enforced for state governing synchronization primitives (`std::mutex`, `std::atomic`), resource allocation lifetimes, or invariants that must never be bypassed by subclasses.
- **Non-Virtual Interface (NVI) Pattern**: Base classes provide non-virtual public entrypoints with pre/post-condition checks, delegating to `protected`/`private` virtual hooks.

### 5.2 Universal `final` Specifier on `class` and `struct`
- **Standard Compatibility**: The `final` contextual keyword is fully valid and standard across C++11, C++14, C++17, C++20, and C++23 on both `class` and `struct`.
- **Static Devirtualization**: Marking concrete leaf classes as `final` (`class VulkanRenderer final : public IRenderer`) or structs (`struct PacketHeader final { ... }`) informs the compiler that no further derivation exists.
  - Converts indirect vtable jumps (`call *%rax`) into **direct static calls** or **fully inlined instructions**.
  - Prevents accidental object slicing and eliminates redundant constructor/destructor vptr stores.

---

## 6. Static Storage Safety: Eliminating Initialization & Destruction Order Fiascos (SIOF & SDOF)

### 6.1 The Destruction Order Hazard (SDOF Post-`main()`)
- **Indeterminate Order**: Static/global objects across different translation units have an indeterminate destruction order (strict LIFO based on dynamic registration).
- **Post-`main()` Background Thread Race**: Active worker threads executing during `exit()` or after `main()` returns will crash when calling loggers, thread pools, or memory allocators whose destructors have already run.

### 6.2 Standards & Solutions
1. **Prohibit Global Non-Trivial Destructors**:
   - Namespace-scope static/global variables MUST have trivial destructors (e.g., `std::string_view`, numeric types, POD structs).
   - Prohibit global `std::string`, `std::vector`, `std::unique_ptr`, and `std::mutex`.
2. **`NoDestructor<T>` Pattern (Abseil / Chromium / LLVM)**:
   - For global singleton services (logging, metrics, registries), wrap storage in an aligned memory buffer whose destructor is never invoked. The OS reclaims memory at process exit.
3. **Explicit Lifecycle Management**:
   - Construct subsystems locally within `main()`. Explicitly stop and join all worker threads (`std::jthread`) before destroying dependencies.
4. **C++20 `constinit`**:
   - Enforce `constinit` on static storage duration variables to guarantee constant compile-time initialization, completely eliminating SIOF.

---

## 7. Immutability Discipline, Parameter Passing & `constexpr` Chaining

### 7.1 Parameter Passing: Scalar Values vs. Non-Scalar References
- **Scalar Primitives (Pass by Value)**:
  - Pass scalar types (`int8_t`–`int64_t`, `uint8_t`–`uint64_t`, `float`, `double`, `enum`, non-owning pointers `T*`) by **plain value** (`int x`, `uint32_t id`) in function signatures.
  - Prohibit `const int&` on scalars (forces memory pointer indirection, degrading CPU register passing).
  - Prohibit `const int x` in public header declarations (adds visual signature clutter with zero ABI benefit).
- **Non-Scalar Types (Pass by `const T&` or View)**:
  - Pass composite types (`std::vector`, large structs) by `const T&`.
  - Pass contiguous string and array buffers by non-owning views (`std::string_view`, `std::span<const T>`) **by value** (passed in 2 CPU registers).

### 7.2 Local Variable Immutability (Rust-like Const by Default)
- Enforce `const auto` / `const auto&` / `const T` on local variables inside function bodies.
- Enforce Immediately Invoked Function Expressions (IIFE: `[&]() { ... }()`) to initialize `const` variables requiring multi-branch decision trees.

### 7.3 Pure `constexpr` Chaining & `consteval` Guarding
- **Optimization Cascades**: Chaining pure `constexpr` functions folds complex mathematical transforms, lookup tables, and FNV-1a string hashing directly into `.rodata` or immediate instructions.
- **Runtime Execution Guarding**:
  - Functions marked `constexpr` drop silently to runtime if arguments are dynamic.
  - In **C++20**, enforce `consteval` (immediate functions) for algorithms that MUST execute during compilation.
  - In **C++17**, force compile-time evaluation via `constexpr auto var = fn(...)` or Non-Type Template Parameter (NTTP) wrappers.

---

## 8. Hardware Bit-Twiddling, Stanford Bit Hacks & `<stdint.h>` Widths

### 8.1 C-Compatible Exact Widths: `<stdint.h>` Primacy
- Enforce `#include <stdint.h>` (and `<stddef.h>`) to ensure universal portability across embedded, POSIX, C-compatible, and exotic toolchains without requiring `std::` qualification for fundamental integer types (`uint8_t`, `uint16_t`, `uint32_t`, `uint64_t`, `int32_t`, `int64_t`, `size_t`, `uintptr_t`).
- Prohibit ambiguous primitive integer types (`long`, `short`) whose bit-widths vary across LP64 and LLP64 platforms.

### 8.2 Stanford Bit Twiddling Hacks Reference
*Reference: Sean Eron Anderson, Stanford University Graphics Lab (`https://graphics.stanford.edu/~seander/bithacks.html`)*

| Operation | Stanford Bit Hack Expression | Modern ISA Instruction | Modern C++ Equivalent |
| :--- | :--- | :--- | :--- |
| **Power-of-2 Test** | `(v != 0) && ((v & (v - 1)) == 0)` | `BLSR` + `TEST` | `std::has_single_bit(v)` |
| **Clear Lowest Set Bit** | `v & (v - 1)` | `BLSR` (BMI1) | Compiler optimized `v & (v - 1)` |
| **Isolate Lowest Set Bit** | `v & -v` | `BLSI` (BMI1) | `v & -v` |
| **Mask to Lowest Set Bit** | `v ^ (v - 1)` | `BLSMSK` (BMI1) | `v ^ (v - 1)` |
| **Power-of-2 Alignment** | `(x + (A - 1)) & ~(A - 1)` | Direct arithmetic | `align_up(x, A)` |
| **Branchless Select** | `b ^ ((a ^ b) & -cond)` | `CMOV` (x86) / `CSEL` (ARM) | `cond ? a : b` / `CMOV` |
| **Population Count** | SWAR mask addition tree | `POPCNT` / `CNT` (ARM) | `std::popcount(v)` |
| **Count Trailing Zeros** | De Bruijn table lookup | `TZCNT` / `CLZ+RBIT` | `std::countr_zero(v)` |
| **Count Leading Zeros** | Bit-smearing + Popcount | `LZCNT` / `CLZ` (ARM) | `std::countl_zero(v)` |
| **Byte Swapping** | Shift-and-mask cascade | `BSWAP` / `REV` (ARM) | `std::byteswap(v)` (C++23) |

---

## 9. Page Locality, Page Size Architecture & Branch Hinting

### 9.1 Page Locality & TLB Reach (4KB, 16KB, 2MB Huge Pages)
- **TLB Reach**: A 512-entry L1 dTLB covers only 2 MB with 4 KB pages, but covers **8 MB with 16 KB pages** and **1 GB with 2 MB huge pages**.
- **Split-Page Access Penalty**: Data structures crossing page boundaries trigger two separate page table lookups and potential split-bus locks. Ensure memory buffers, DMA descriptors, and arena blocks align to page boundaries.
- **Android 15 Mandate (16 KB Pages)**:
  - Link all native shared libraries with `-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384`.
  - Prohibit hardcoded `#define PAGE_SIZE 4096`; always query page size dynamically via `sysconf(_SC_PAGESIZE)`.
  - All `mmap` offsets must be multiples of 16 KB.
- **Huge Pages (2 MB)**:
  - Advise the Linux kernel via `madvise(ptr, size, MADV_HUGEPAGE)` or allocate physical 2 MB huge pages via `mmap(..., MAP_HUGETLB | (21 << MAP_HUGE_SHIFT))` for large working sets ($>16\text{ MB}$), reducing TLB miss penalties by 512x.

### 9.2 Branch Hinting for Happy Paths (`[[likely]]` / `[[unlikely]]`)
- **Mechanical Sympathy**: Compilers layout basic blocks to keep the predicted hot path sequentially packed inside L1 instruction cache lines (L1i), moving cold error handlers out-of-line into distant `.text.unlikely` sections.
- **Guidelines**:
  - Mark validation and fatal error branches with `[[unlikely]]` (C++20) or `__builtin_expect(!!(cond), 0)`.
  - Mark primary fast paths with `[[likely]]` or `__builtin_expect(!!(cond), 1)`.
  - Restrict usage to extreme asymmetries ($>99\%$ or $<1\%$).

---

## 10. Symbol Visibility, Security & Encapsulation Conventions

### 10.1 Binary Symbol Visibility & Security Hardening
- **Default Hidden Symbols**: Build all shared targets with `-fvisibility=hidden -fvisibility-inlines-hidden`.
  - Prevents symbol interposition and hijacking attacks (e.g. `LD_PRELOAD` exploitation).
  - Eliminates symbol table bloat in `.dynsym` and reduces dynamic linking startup latency.
  - Hides internal implementation structures from binary reverse-engineering.
- **Explicit Export Annotations**: Public C-ABI interface functions must be explicitly annotated with export macros (`MYLIB_API` $\to$ `__attribute__((visibility("default")))`).

### 10.2 Minimalist Implementation (Simplicity First)
- Prohibit over-engineered template metaprogramming, deeply nested SFINAE traits, or multi-layer abstraction wrappers that create hundreds of lines of boilerplate for minor gains.
- Strive for concise, readable, and mechanically sympathetic implementations that achieve near-peak hardware performance with minimal code complexity.

---

## 11. Hardware DMA & Zero-Copy Transfers across CPU, GPU & NPU

```
Linux DMA Architecture                      Android DMA Architecture (API 29+)
======================                      ==================================
[User Buffer / DMA-BUF]                     [AHardwareBuffer (Gralloc 4 / AIDL)]
        │                                                 │
        ├─► io_uring (Registered Buffers)                 ├─► Vulkan (VkDeviceMemory Import)
        ├─► NPU / Accelerators (/dev/dma_heap)            ├─► NPU / AI Cores (NNAPI / QNN / FastRPC)
        ├─► splice / vmsplice                             ├─► Camera NDK (AImageReader)
        └─► DMA_BUF_IOCTL_SYNC (CPU Cache Flush)          └─► AHardwareBuffer_lock (CPU Sync)
```

1. **Android Hardware Buffer (`AHardwareBuffer`)**:
   - Universal zero-copy currency between CPU, GPU (Vulkan external memory import via `VK_ANDROID_external_memory_android_hardware_buffer`), **NPU / AI Accelerators** (Android NNAPI `ANeuralNetworksMemory_createFromAHardwareBuffer`, Qualcomm QNN / Hexagon FastRPC, MediaTek NeuroPilot, LiteRT delegates), Camera NDK (`AImageReader`), and IPC (`AHardwareBuffer_sendHandleToUnixSocket`).
   - `AHardwareBuffer_getId()` (API 29+) provides a unique 64-bit ID for $O(1)$ GPU texture & NPU tensor caching without staging copies.
2. **Linux DMA-BUF & Cache Synchronization**:
   - Direct memory sharing with Linux NPU drivers (ARM Ethos, Intel NPU, Rockchip RKNPU, Hailo, Tenstorrent) via `/dev/dma_heap`.
   - Accessing DMA-BUF via CPU requires explicit `DMA_BUF_IOCTL_SYNC` (`DMA_BUF_SYNC_START`/`DMA_BUF_SYNC_END`) to maintain coherency across non-coherent ARM64/NPU caches (`DC CIVAC` cache line writeback/invalidation).
3. **Linux `io_uring` Zero-Copy**:
   - `IORING_REGISTER_BUFFERS`: Pre-pins memory, eliminating per-I/O page table walks.
   - `IORING_OP_SEND_ZC`: Transmits network packet pages directly to the NIC DMA ring without copying.

---

## 12. Summary of Distilled Rules & Layering

1. **`lang-standard-cpp.md` (Universal Baseline $\ge$ C++17)**:
   - Rule of Zero/Five, deleted copy operations (`= delete`) on handles/mutexes, `noexcept` moves.
   - `std::unique_ptr` supremacy with stateless functor deleters (EBO `sizeof == 8`).
   - Placement `new` encapsulation in `std::unique_ptr` with custom in-place deleters for pre-allocated buffers.
   - Prohibit Non-Trivial Static Destructors (`NoDestructor<T>` pattern; SDOF elimination).
   - Separation of Data (Literal Structs) vs Behavior (Stateless Processors).
   - Member Visibility (`protected` for extensible hierarchies; `private` for invariants).
   - Universal `final` on concrete classes and structs for static devirtualization.
   - Modern Delegation Patterns & `std::invoke` universal member/free function dispatch.
   - Const-by-Default Locals & Register-Optimal Scalar Value Parameter Passing.
   - Pure `constexpr` Function Chaining & Compile-Time Evaluation Guarding.
   - `.cpp` translation unit scoping (`using namespace std;` strictly after `#include`; anonymous `namespace { ... }`).
   - `using` type aliasing, template restraint, and pre-allocated C arrays (`T arr[N] = {}`) for compile-time bounded buffers (prohibiting VLAs).
   - Exact bit-width `<stdint.h>` types, branchless bit-twiddling, Stanford Bit Hacks, and page alignment arithmetic.
   - Page locality (4KB/16KB/2MB Huge Pages) and dynamic `sysconf(_SC_PAGESIZE)` queries.
   - Happy-path branch hints (`[[likely]]` / `[[unlikely]]`, `__builtin_expect`).
   - Symbol visibility and security (`-fvisibility=hidden`, explicit C-ABI exports, prohibiting raw pointer leakage).
   - De-facto compiler directives (`#pragma once`, `__restrict__`, `__builtin_prefetch`, `hot`/`cold`).
   - Lock-free atomics, atomic bitmasks, acquire-release semantics, and `alignas(64)` false-sharing isolation.
   - Hardware DMA & zero-copy across CPU, GPU, NPU, Camera, and IPC (`AHardwareBuffer`, `dma-buf`).
   - Android API 29+ & Unix primacy (16 KB page alignment; zero Boost/locale/regex).
   - Dynamic boundary ABI isolation (`extern "C"`, PImpl opaque handles).

2. **`lang-standard-cpp-17.md` (C++17 Dialect - Default)**:
   - Permitted: `std::string_view` by value, structured bindings, `if constexpr`, fold expressions, `std::variant`/`std::optional` sum types, fallback span shims, and `std::pmr::monotonic_buffer_resource` stack arenas.
   - Dialect Prohibitions: Concepts, `std::span`, `<=>`, `std::jthread`, designated initializers, `std::expected`, `consteval`.

3. **`lang-standard-cpp-20.md` (C++20 Dialect)**:
   - Permitted: Concepts over SFINAE, `std::span<const T>`, spaceship operator (`<=>`), designated initializers, `std::jthread` + `std::stop_token`, `std::ranges`/`std::views`, `consteval`/`constinit`, and atomic `.wait()`.
   - Dialect Prohibitions: `std::expected`, `std::flat_map`, `std::mdspan`, deducing `this`, `std::print`, and C++20 modules in cross-platform builds.

4. **`lang-standard-cpp-23.md` (C++23 Dialect)**:
   - Permitted: `std::expected<T, E>` monadic chains, `std::flat_map`/`std::flat_set` contiguous lookups, `std::mdspan`, explicit object parameter ("Deducing this"), `std::print`/`std::println`, and `std::unreachable()`.
   - Dialect Prohibitions: Legacy out-params, node-based maps for small lookups, CRTP boilerplate, and experimental C++26 features.
