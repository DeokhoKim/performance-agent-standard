# C++23 Dialect Standards

Section: Permitted C++23 Modern Capabilities && Monadic Flow
Req: Modern Algebraic Flow && Cache-Conscious Data: Maximize cache locality, monadic error chaining, and modern language abstractions.
- Rule: ExpectedMonadicHandling: MUST enforce `std::expected<T, E>` for all fallible operations; MUST chain logic via `.and_then()`, `.transform()`, and `.or_else()`; raw out-parameters and sentinel error codes MUST NOT be used.
- Rule: FlatAssociativeContainers: MUST enforce `std::flat_map` and `std::flat_set` for associative lookups when capacity $N < 10000$ to maximize cache locality; node-based `std::map`/`std::set` MUST NOT be used.
- Rule: MultiDimensionalSpan: MUST enforce `std::mdspan` for multi-dimensional contiguous buffer layouts; raw pointer arithmetic (`ptr[i * cols + j]`) and pointer-of-pointers (`T**`) MUST NOT be used.
- Rule: ExplicitThisDeducing: MUST enforce explicit object parameters (`this auto&& self`) for perfect forwarding, qualifier deduction, and elimination of CRTP boilerplate.
- Rule: NativeStdPrint: MUST enforce `std::print` and `std::println` for type-safe, direct formatted I/O; `std::cout`, `std::cerr`, and manual format streaming MUST NOT be used.
- Rule: UnreachableOptimizationHint: MUST enforce `std::unreachable()` in exhaustive switch/branch statements to eliminate branch penalties and inform compiler optimizations.
- Rule: CoroutineGeneratorRanges: MUST enforce `std::generator<T>` for lazy ranges and sequential stream generation; custom iterator boilerplate structs MUST NOT be written.
- Rule: MoveOnlyFunctionCallbacks: MUST enforce `std::move_only_function<void()>` for move-only callable wrappers; `std::function` MUST NOT be used when wrapping move-only captures (`std::unique_ptr`).

```cpp
#include <expected>
#include <flat_map>
#include <mdspan>
#include <print>
#include <generator>
#include <functional>
#include <string_view>
#include <utility>

enum class ParseError : uint8_t { Empty, Invalid };

struct PacketParser final {
    template <typename Self>
    auto parse(this Self&& self, std::string_view raw) -> std::expected<uint32_t, ParseError> {
        if (raw.empty()) return std::unexpected(ParseError::Empty);
        return 42;
    }
};

auto generate_sequence(int limit) -> std::generator<int> {
    for (int i = 0; i < limit; ++i) co_yield i;
}

void process_data() {
    std::flat_map<uint32_t, float> cache{{1, 10.5f}, {2, 20.0f}};
    float buffer[4] = {1.0f, 2.0f, 3.0f, 4.0f};
    std::mdspan grid(buffer, 2, 2);
    PacketParser parser;
    auto res = parser.parse("payload")
        .transform([](uint32_t v) { return v * 2; })
        .value_or(0);
    std::println("Parsed value: {}, Grid[1,1]: {}", res, grid[1, 1]);
}
```

Section: Dialect Prohibitions && Superseded Standards Fallback Matrix
Req: Feature Deprecation && Boundary Guardrails: Restrict obsolete patterns and unstandardized extensions.
- Rule: ProhibitLegacyErrorOutParams: MUST NOT use error-code out-parameters (`bool fn(T*, Error*)`) or sentinel return codes; MUST enforce `std::expected<T, E>`.
- Rule: ProhibitNodeAssociativeContainers: MUST NOT use node-based `std::map` / `std::set` when dataset capacity $N < 10000$; MUST enforce `std::flat_map` / `std::flat_set`.
- Rule: ProhibitCRTPBoilerplate: MUST NOT use template CRTP base classes for deducing const/ref member qualifiers; MUST enforce explicit `this auto&& self`.
- Rule: ProhibitBleedingEdgeC26Features: MUST NOT use experimental C++26 features (Contracts P2900, Static Reflection P2996, Pack Indexing P2661) until standardized in ISO LTS compilers.
