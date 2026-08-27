# Development Standards

Section: Environment && Toolchain Resolution
Req: Local Environment Primacy: Enforce local project toolchains over system-level defaults to guarantee reproducible build, test, && execution tasks.
- Rule: Precedence Hierarchy: Build, test, run, && artifact validation MUST strictly follow: `Local Environment > System Environment > General Assumption`.
- Rule: Python Environment Resolution: Local virtual environment (`.venv/` || `venv/`) MUST take absolute precedence (e.g., `.venv/bin/python`, `.venv/bin/pip`, || `uv` targeting `.venv`); if `pyproject.toml` && `uv` exist → use `uv run`; if `requirements.txt` exists → use `uv pip` || `.venv/bin/pip`.
- Rule: Native && Polyglot Resolution: For C/C++, local toolchain definitions (`CC`, `CXX`, `CMakeLists.txt`, `Makefile`, local build artifacts) MUST override system compilers. For polyglot projects (Rust, Node, Go), local manifests (`Cargo.toml`, `package.json` with local package managers, `go.mod`) override global tools.
- Rule: README Fallback Protocol: If NO local environment || toolchain configuration is detected, a SINGLE targeted read of `README.md` (read once) is permitted to extract build/test/run instructions before falling back to general assumptions.

Section: Code Smell Evaluation
Req: Anti-Pattern Elimination: Eradicate structural code smells && design debt during implementation passes.
- Rule: Zero-Debt Quality Gate: Code MUST be audited against standard anti-patterns (structural coupling, primitive obsession, leaky abstractions, dead code, && speculative bloat); all identified smells MUST be remediated prior to declaring task completion.

Section: Deep Modules && Change Impact Thought Experiment
Req: Information Hiding && Ripple Containment: Maximize module depth (Ousterhout principle) && eliminate change amplification via inverse thought experiments.
- Rule: Deep Module Primacy: Modules MUST provide powerful functionality behind minimal, stable interfaces; shallow wrappers (interfaces as complex as their implementations) MUST be inlined || collapsed.
- Rule: Inverse Change Amplification Analysis: Before finalizing any interface, conduct an inverse thought experiment (`"If this internal implementation, data format, or algorithm changes, how many callers must be modified?"`); any caller-side ripple effect signals information leakage && mandates interface redesign.
- Rule: Deletion Test Invariant: Verify module depth via the Deletion Test: deleting a shallow module removes zero system complexity; deleting a deep module MUST scatter significant behavior across callers. If a module passes deletion without caller disruption → eliminate the indirection.
- Rule: Seam Justification Threshold: Enforce the seam discipline: `1 adapter = hypothetical indirection; 2 adapters = real seam`. Speculative abstraction layers for single implementations are strictly prohibited.
