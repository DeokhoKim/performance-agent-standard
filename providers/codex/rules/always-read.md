# Codex Coding Guidelines

Section: Codex Agent Behavior
Req: Autocomplete & Code Optimization: Code in structures that improve prediction accuracy.
- Rule: Document functions with inline JSDoc/Docstring blocks preceding implementation, use fully descriptive names, and limit individual function implementations to under 40 lines.

Req: Execution Control & Hygiene: Prevent verbose outputs and context drift.
- Rule: Skip conversational preambles/summaries. For non-trivial modifications, decompose the task into a sequential plan first. Empower Codex to automatically run tests, parse error logs, and iterate on fixes.
- Rule: Do not duplicate guidelines or naming schemas across files loaded in the same context.
