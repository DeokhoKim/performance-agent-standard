# C++20 Dialect Standards

Section: Permitted C++20 Modern Capabilities && Concurrency
Req: Native C++20 Ergonomics: Enforce compile-time concept checking, zero-copy views, range transformations, and cooperative concurrency.
- Rule: ConceptsOverSFINAE: MUST enforce `template <Concept T>` or trailing `requires` clauses on generic functions and classes; MUST NOT use `std::enable_if_t` or `std::void_t` boilerplate.
- Rule: NativeSpanPassByValue: MUST enforce `std::span<const T>` passed by value for contiguous memory slices; MUST NOT use raw pointer-length parameter pairs (`const T*, size_t`) in public interfaces.
- Rule: SpaceshipOperatorThreeWay: MUST enforce `auto operator<=>(const T&) const = default;` for aggregate comparison; MUST NOT write manual relational operator overloads (`<`, `>`, `<=`, `>=`).
- Rule: CooperativeJThreadRAII: MUST enforce `std::jthread` with `std::stop_token` for automatic joining and cooperative cancellation; raw unjoined `std::thread` MUST NOT be spawned.
- Rule: DesignatedInitializers: MUST enforce C99-style designated initializers (`Struct{.field = val}`) for configuration aggregates; verbose builder classes MUST NOT be constructed.
- Rule: RangePipelineTransformations: MUST enforce `std::ranges` algorithms and `std::views` composition pipelines (`rng | std::views::filter(...)`); intermediate allocation loops MUST NOT be written.
- Rule: ConstevalAndConstinitGuarantees: MUST enforce `consteval` for strictly compile-time execution and `constinit` for non-dynamic static/thread-local initialization to guarantee zero runtime initialization cost.
- Rule: ZeroAllocationFormat: MUST enforce `std::format` for type-safe, locale-independent string formatting; `std::stringstream` and `sprintf` MUST NOT be used.
- Rule: AtomicNotificationWait: MUST enforce `std::atomic<T>::wait()` and `notify_one()` / `notify_all()` for futex-assisted synchronization; busy-spin polling loops MUST NOT be used.

```cpp
#include <span>
#include <ranges>
#include <format>
#include <thread>
#include <atomic>
#include <cstdint>

template <typename T>
concept Numeric = std::is_arithmetic_v<T>;

struct PacketHeader final {
    uint32_t seq{0};
    uint16_t id{0};
    auto operator<=>(const PacketHeader&) const = default;
};

consteval uint32_t align_size(uint32_t n) { return (n + 7) & ~7; }
constinit static uint32_t g_header_align = align_size(60);

void process_payload(std::span<const uint8_t> buffer, std::stop_token st) {
    auto filtered = buffer | std::views::filter([](uint8_t b) { return b > 0; })
                           | std::views::transform([](uint8_t b) { return b ^ 0xFF; });
    for (uint8_t byte : filtered) {
        if (st.stop_requested()) [[unlikely]] break;
    }
}
```

Section: Dialect Prohibitions && Unavailable Standards Fallback Matrix
Req: Dialect Boundary Enforcement: Prevent invocation of unsupported C++23 features and unstable toolchain extensions.
- Rule: ProhibitExpectedAndMonadicChaining: MUST NOT use `std::expected` or monadic `.and_then()` (unavailable in C++20); MUST enforce `std::variant<T, E>` / `std::optional<T>` or vetted `tl::expected`.
- Rule: ProhibitFlatAssociativeContainers: MUST NOT use `std::flat_map` or `std::flat_set` (unavailable in C++20); MUST enforce contiguous sorted `std::vector` with `std::lower_bound`.
- Rule: ProhibitMultiDimensionalSpan: MUST NOT use `std::mdspan` (unavailable in C++20); MUST enforce 1D contiguous indexing (`data[i * cols + j]`) or vetted Kokkos `mdspan`.
- Rule: ProhibitExplicitThisDeducing: MUST NOT use explicit object parameter syntax (`this auto&& self` unavailable in C++20); MUST enforce standard CRTP or explicit `const&`/`&&` member overloads.
- Rule: ProhibitStdPrintDirect: MUST NOT use `std::print` or `std::println` (unavailable in C++20); MUST enforce `std::format` with buffered POSIX I/O.
- Rule: ProhibitModulesInCrossPlatform: MUST NOT use C++20 Modules (`import`, `module`) in cross-platform builds due to compiler binary module interface (BMI) divergence; MUST enforce `#pragma once` header includes.
