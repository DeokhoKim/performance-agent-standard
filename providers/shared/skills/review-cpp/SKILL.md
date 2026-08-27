---
---

# C++ Code Review Skill

Def: Purpose → Execute hierarchical code review for C++ source files against registered standards.

Section: Invocation Parameters

- `[target]`: Optional. Target file, directory, or git diff range. Defaults to uncommitted changes or workspace.
- `[standard]`: Optional. C++ standard version (`cpp17`, `cpp20`, `cpp23`). Defaults to detected standard or C++17 baseline.

Section: Execution Flow

Step: 1. Standards Resolution:
- Rule: HierarchicalReadingSequence: Enforce sequential reading of registered standard rules before code inspection:
  1. `30-code-simplicity`
  2. `31-lang-standard-common`
  3. `40-lang-standard-native`
  4. `42-lang-standard-cpp`
  5. C++ version standard (as resolved by `[standard]` or build files): `43-lang-standard-cpp-17` || `44-lang-standard-cpp-20` || `45-lang-standard-cpp-23`

Step: 2. Target Scope Resolution:
- Rule: TargetFilter: Resolve review targets from `[target]` (or uncommitted git changes); filter strictly to C++ extensions (`*.cpp`, `*.cc`, `*.cxx`, `*.hpp`, `*.h`, `*.hxx`).

Step: 3. Review Execution && Report Generation:
- Rule: ReportStructure: Evaluate code strictly against the loaded standards and format report:
  1. **Summary**: Overall quality and conformance assessment.
  2. **Violations && Findings**: Itemized list of standard violations with exact line references (`file:///path/to/file#L1-L10`).
  3. **Surgical Recommendations**: Minimal, copy-paste ready code refactoring snippets.
