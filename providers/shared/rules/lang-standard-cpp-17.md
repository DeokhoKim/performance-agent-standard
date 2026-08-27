# C++17 Dialect Standards

Section: Permitted Modern Idioms, Views && PMR Lifecycle
Req: Zero-Allocation Views && Deterministic Branching: Enforce C++17 modern idioms, zero-copy parameter passing, and local arena memory management.
- Rule: StringViewPassByValue: MUST enforce `std::string_view` passed by value for non-owning read-only string parameters (fits in 2 CPU registers: pointer + size); MUST NOT pass `const std::string_view&` or `const std::string&` in view interfaces to prevent redundant indirection.
- Rule: StructuredBindingsDeconstruction: MUST enforce structured bindings (`auto [k, v] = ...`) for tuples, pairs, and aggregate returns; MUST NOT use `std::tie` or manual index extraction (`std::get<I>`).
- Rule: ConstexprIfBranching: MUST enforce `if constexpr` within generic template functions to isolate type-dependent branches and discard dead code at compile time; MUST NOT rely on runtime tag dispatching.
- Rule: FoldExpressionReduction: MUST enforce fold expressions (`(... + args)`) for variadic parameter pack reductions; MUST NOT write recursive template helper instantiations.
- Rule: SumTypeErrorHandling: MUST enforce `std::variant<T, ErrorCode>` or `std::optional<T>` for operations with recoverable failure paths; MUST NOT use out-parameter error codes (`bool func(T* out, Error* err)`) to prevent uninitialized memory access.
- Rule: MonotonicStackArenaPMR: MUST enforce `std::pmr::monotonic_buffer_resource` backed by local stack memory arrays (`std::array<std::byte, N>`) for high-frequency inner-loop container allocations to eliminate global heap allocator churn.

```cpp
#include <string_view>
#include <variant>
#include <optional>
#include <memory_resource>
#include <array>
#include <type_traits>

void process_tag(std::string_view tag) noexcept { /* Passed in 2 registers */ }

template <typename... Args>
constexpr auto sum_all(Args... args) noexcept { return (... + args); }

template <typename T>
constexpr auto scale_val(T val) noexcept {
    if constexpr (std::is_integral_v<T>) return val << 1;
    else return val * 2.0;
}

enum class ErrorCode : uint8_t { NotFound, Invalid };
using ParseResult = std::variant<uint32_t, ErrorCode>;

void run_workload() noexcept {
    std::pair<int, double> item{1, 4.5};
    auto [id, score] = item;
    std::array<std::byte, 512> stack_pool;
    std::pmr::monotonic_buffer_resource arena(stack_pool.data(), stack_pool.size());
    std::pmr::vector<int> numbers(&arena);
    numbers.push_back(42);
}
```

Section: Dialect Prohibitions && Unavailable Standards Fallback Matrix
Req: Dialect Boundary Enforcement: Prevent invocation of unavailable post-C++17 language and library constructs.
- Rule: ProhibitConceptsAndRequires: MUST NOT use `concept` or `requires` clauses (unavailable in C++17); MUST enforce `std::enable_if_t` in template parameter defaults or function returns (`template <typename T, std::enable_if_t<std::is_integral_v<T>, int> = 0>`).
- Rule: ProhibitNativeSpan: MUST NOT use `std::span` (unavailable in C++17); MUST enforce `(const T* data, std::size_t size)` pointer-length pairs or vetted `tcb::span`.
- Rule: ProhibitSpaceshipOperator: MUST NOT use three-way comparison (`<=>` unavailable in C++17); MUST declare explicit relational operator overloads (`operator==`, `operator<`).
- Rule: ProhibitJThreadAndStopToken: MUST NOT use `std::jthread` or `<stop_token>` (unavailable in C++17); MUST wrap `std::thread` in an RAII guard to guarantee `join()` on destruction; unjoined thread destruction MUST NOT invoke `std::terminate`.
- Rule: ProhibitDesignatedInitializers: MUST NOT use designated initializers (`Struct{.field = val}` unavailable in C++17); MUST enforce aggregate brace initialization (`Struct{val1, val2}`).
- Rule: ProhibitExpectedAndMonadicFlow: MUST NOT use `std::expected` or monadic `.and_then()` (unavailable in C++17); MUST enforce `std::variant<T, E>` / `std::optional<T>` or vetted `tl::expected`.
- Rule: ProhibitConstevalAndConstinit: MUST NOT use `consteval` or `constinit` (unavailable in C++17); MUST enforce `constexpr`.
