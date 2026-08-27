---
---

# Python Code Review Skill

Def: Purpose → Execute hierarchical code review for Python source files against registered standards.

Section: Invocation Parameters

- `[target]`: Optional. Target file, directory, or git diff range. Defaults to uncommitted changes or workspace.

Section: Execution Flow

Step: 1. Standards Resolution:
- Rule: HierarchicalReadingSequence: Enforce sequential reading of registered standard rules before code inspection:
  1. `30-code-simplicity`
  2. `31-lang-standard-common`
  3. `51-lang-standard-python`

Step: 2. Target Scope Resolution:
- Rule: TargetFilter: Resolve review targets from `[target]` (or uncommitted git changes); filter strictly to Python extensions (`*.py`).

Step: 3. Review Execution && Report Generation:
- Rule: ReportStructure: Evaluate code strictly against the loaded standards and format report:
  1. **Summary**: Overall quality and conformance assessment.
  2. **Violations && Findings**: Itemized list of standard violations with exact line references (`file:///path/to/file#L1-L10`).
  3. **Surgical Recommendations**: Minimal, copy-paste ready code refactoring snippets.
