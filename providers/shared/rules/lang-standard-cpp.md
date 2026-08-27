# C++ Universal Implementation Standards

Section: Memory Safety, Lifecycle Macros && SDOF Elimination
Req: Deterministic RAII Lifetime: Eliminate manual memory management, circular leaks, and static destruction race hazards.
- Rule: NonCopyableMoveableMacros: MUST enforce `NON_COPYABLE(TypeName)` and `NON_MOVEABLE(TypeName)` macros with explicit `= delete` in `public:` sections for unique resource handles to guarantee compile-time lifecycle enforcement; MUST NOT rely on implicit compiler deletion or private dummy declarations.
- Rule: RuleOfZeroAndFive: Composite RAII types MUST enforce the Rule of Zero using self-managing members; raw resource handle wrappers MUST enforce the Rule of Five with explicit `noexcept` move operations; partial special member implementations MUST NOT be written.
- Rule: SmartPointerSupremacy: Dynamic memory allocations MUST use `std::unique_ptr` (via `std::make_unique`) as the default exclusive owner; `std::shared_ptr` MUST be strictly restricted to disjoint multi-owner lifetimes; non-owning back-references MUST use `std::weak_ptr`; owning raw pointers (`T*` via `new`) MUST NOT be used.
- Rule: StatelessCustomDeleters: Custom OS handle deleters in `std::unique_ptr<T, Deleter>` MUST be stateless functors (`operator() const noexcept`) to guarantee Empty Base Optimization (EBO → `sizeof(std::unique_ptr<T, Deleter>) == sizeof(void*)`); stateful lambda deleters or raw function pointers MUST NOT be used for single handles.
- Rule: InPlacePlacementNewUniquePtr: Pre-allocated buffer construction MUST encapsulate placement `new` inside `std::unique_ptr<T, InPlaceDeleter>` using `alignas(alignof(T))` storage buffers to guarantee automated RAII cleanup; raw unmanaged placement `new` MUST NOT be used, and recycled storage accesses MUST invoke `std::launder`.
- Rule: StaticDestructionSafety: Non-local static variables with non-trivial destructors MUST NOT be declared to prevent Static Destruction Order Fiascos (SDOF) and process exit race crashes; all static/global state MUST be wrapped in `NoDestructor<T>`.

```cpp
#define NON_COPYABLE(TypeName) \
    TypeName(const TypeName&) = delete; \
    TypeName& operator=(const TypeName&) = delete

#define NON_MOVEABLE(TypeName) \
    TypeName(TypeName&&) = delete; \
    TypeName& operator=(TypeName&&) = delete

// In-Place Placement new in std::unique_ptr & SDOF-Safe NoDestructor
struct InPlaceDeleter final {
    template <typename T> void operator()(T* p) const noexcept { if (p) p->~T(); }
};
template <typename T> using InPlaceUniquePtr = std::unique_ptr<T, InPlaceDeleter>;

template <typename T, typename... Args>
inline InPlaceUniquePtr<T> make_in_place(void* storage, Args&&... args) {
    return InPlaceUniquePtr<T>(::new (storage) T(std::forward<Args>(args)...));
}

template <typename T>
class NoDestructor final {
public:
    template <typename... Args>
    explicit constexpr NoDestructor(Args&&... args) noexcept {
        ::new (static_cast<void*>(storage_)) T(std::forward<Args>(args)...);
    }
    ~NoDestructor() = default;
    NON_COPYABLE(NoDestructor);
    NON_MOVEABLE(NoDestructor);
    [[nodiscard]] T* get() noexcept { return std::launder(reinterpret_cast<T*>(storage_)); }
    [[nodiscard]] const T* get() const noexcept { return std::launder(reinterpret_cast<const T*>(storage_)); }
    [[nodiscard]] T* operator->() noexcept { return get(); }
    [[nodiscard]] const T* operator->() const noexcept { return get(); }
    [[nodiscard]] T& operator*() noexcept { return *get(); }
    [[nodiscard]] const T& operator*() const noexcept { return *get(); }
private:
    alignas(alignof(T)) uint8_t storage_[sizeof(T)];
};
```

Section: Structural Architecture && Devirtualization
Req: Type Design && Static Dispatch: Separate passive data transfer from active processing.
- Rule: StructuralSeparation: Passive data transfer objects MUST be declared as `struct` literal POD aggregates with public fields, trivial copy, and no business logic methods; active stateful/stateless processors MUST be declared as `class` with private `_` state and `const` queries; mixing operational business methods inside data structs MUST NOT be permitted.
- Rule: UniversalFinalDevirtualization: All concrete classes, structs, and virtual method overrides MUST be marked `final` to guarantee static devirtualization and inline expansion; unsealed concrete inheritance hierarchies MUST NOT be permitted.

Section: Delegation, Immutability && Evaluation Purity
Req: Modern Invocation, Deduction && Evaluation Purity: Maximize uniform dispatch, automatic type deduction, parameter register passing, and compile-time evaluation.
- Rule: AutoTypeDeduction: MUST enforce `const auto`, `auto&`, `const auto&`, or `auto&&` for local variables, container bindings, and complex template types (AAA - Almost Always Auto) to eliminate redundant type spelling and accidental conversions; explicit types MUST be specified only when type casts or primitive literal disambiguations are required.
- Rule: RangeBasedForLoops: MUST enforce range-based `for` loops (`for (const auto& item : container)`, `for (auto&& item : container)`) over index-based indexing (`for (size_t i = 0; ...)`) or manual iterator loops; index loops MUST be restricted strictly to cases requiring explicit numeric indices or custom non-standard strides.
- Rule: ModernDelegationDispatch: Callable delegation interfaces MUST accept generic callable templates or invocables to guarantee zero allocation overhead; invocations MUST be dispatched via `std::invoke` to uniformly handle free functions, lambdas, raw pointers, `std::unique_ptr`, `std::shared_ptr`, and member pointers.
- Rule: ParameterPassingConventions: Primitive scalar types (`int`, `uint32_t`, `double`, `enum`) MUST be passed by value to guarantee register-optimal ABI calling conventions; `const T` or `const T&` MUST NOT be used for primitive scalars; non-scalar types MUST be passed via `const T&` or non-owning views (`std::string_view`, `std::span`).
- Rule: ConstByDefaultIIFE: Local variables MUST be declared `const` by default to guarantee single-assignment immutability; multi-branch initializations MUST use Immediately Invoked Functional Expressions (`[&]() { ... }()`); uninitialized or mutable temporary variables MUST NOT be declared where IIFE applies.
- Rule: PureConstexprFunctions: Pure deterministic functions MUST be declared `constexpr` to guarantee compile-time evaluation and zero runtime overhead; runtime-only computation MUST NOT be introduced for statically knowable constants.

```cpp
// Universal std::invoke Delegation Dispatcher (Free/Member/SmartPointer)
template <typename Callable, typename... Args>
constexpr decltype(auto) dispatch_task(Callable&& c, Args&&... args) {
    return std::invoke(std::forward<Callable>(c), std::forward<Args>(args)...);
}

// Single-Assignment Const Initialization via IIFE & Auto Range-Based Loop
const auto status_code = [&]() noexcept -> int32_t {
    if (init_primary()) return 0;
    if (init_fallback()) return 1;
    return -1;
}();

void process_elements(const std::vector<uint32_t>& elements) {
    for (const auto& elem : elements) {
        // Zero-overhead range iteration
    }
}
```

Section: Translation Unit Hygiene && Low-Level Optimization
Req: Compilation Boundaries && Hardware Predictability: Guarantee clean compilation units, lock-free concurrency, and bounded resource usage.
- Rule: TranslationUnitHygiene: Header files MUST NOT contain `using namespace` declarations to prevent global symbol pollution; `.cpp` files MAY contain `using namespace std;` strictly after all `#include` directives; internal linkage helpers MUST use anonymous `namespace {}`; type aliases MUST use `using NewName = Target;` and legacy `typedef` MUST NOT be used; Template Metaprogramming (TMP) MUST be restricted to minimal concepts.
- Rule: BranchPredictionHints: MUST enforce branch prediction annotations strictly on asymmetric branches (>99% || <1% execution probability); MUST NOT annotate balanced branches.
- Rule: StackCArrayPreallocation: Compile-time fixed buffers MUST use stack C-arrays `T buffer[N] = {};` to guarantee deterministic stack frames; Variable-Length Arrays (VLAs) and `alloca()` MUST NOT be used.
- Rule: LockFreeAtomicConcurrency: Multi-threaded state coordination MUST use `std::atomic` bitmasks with `compare_exchange_weak` retry loops and explicit `std::memory_order_acquire` / `std::memory_order_release` to guarantee lock-free throughput; unconstrained `std::memory_order_seq_cst` or uncoordinated shared mutations MUST NOT be used.
- Rule: RestrictedStandardLibraries: Heavy or non-deterministic standard libraries (`std::regex`, `std::locale`, `<codecvt>`) and heavy external frameworks (Boost) MUST NOT be linked; string parsing MUST use hand-rolled state machines, string views, or POSIX/C string transforms.

```cpp
// Cache-Line Isolated (False-Sharing Free) SPSC Ring Buffer Cursors
struct alignas(64) SpscCursor final {
    alignas(64) std::atomic<uint32_t> head_{0};
    alignas(64) std::atomic<uint32_t> tail_{0};
};
```
