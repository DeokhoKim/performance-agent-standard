---
name: generate-rule
description: "Generates concise, clarified, and machine-enforceable rules by spawning multi-directional subagents to produce candidate tries (default: 2 per direction), performing multi-dimensional comparative analysis, and synthesizing the champion HDMD rule."
disable-model-invocation: true
context: fork
---

# Rule Generation & Distillation Skill

Def: Purpose → Systematically design, evaluate, and distill high-density, machine-enforceable rules for AI agent platforms by inspecting target rule files, generating candidate iterations across orthogonal design paradigms (configurable tries, default 2 per direction), and synthesizing the champion rule set.

Section: Invocation Parameters

- `[target-file]`: Required. The path to the rule file to inspect, create, refactor, or distill (e.g., `providers/shared/rules/development-standards.md`). Rule topic, existing domain scope, tool bindings, and operational constraints are derived directly from the file itself and workspace architecture.
- `[additional-constraints]`: Optional. Supplementary operational constraints, requirement deltas, or tool bindings not discoverable from `[target-file]`.
- `[tries]`: Optional. Number of candidate tries to generate per direction. Defaults to `2` (yielding 12 total candidate variations across 6 orthogonal paradigms: 6 directions × 2 tries).

Section: Execution Flow

Step: 1. Target Inspection & Zero-Loss Checklist:
- Rule: Context & Constraint Extraction: Inspect `[target-file]` (or its target directory/parent hierarchy if new) to autonomously extract the rule topic, domain scope, existing constraints, tool bindings, and integration context. Merge with `[additional-constraints]` into an explicit numbered checklist ($C_1, C_2, \dots, C_n$). Every candidate rule set MUST achieve 100% Zero Context Loss against this checklist.
- Rule: Tag Standard Verification: Enforce High-Density Markdown (HDMD) structure (`# Title`, `Section: Name`, `Req: Goal`, `- Rule: RuleName: Constraint`), ensuring all sub-rules are explicitly named with PascalCase descriptors.
- Rule: Imperative Constraint Precision: Enforce unambiguous imperative action verbs (`Enforce`, `Prohibit`, `Prefix`, `Isolate`, `Require`) in rule directives; prohibit passive or advisory phrasing (`Prefer`, `Consider`, `Should`).
- Rule: Normative Modal Enforcement: Candidate rules MUST utilize standard RFC-2119/ISO modal verbs (`MUST`/`SHALL` for mandatory requirements, `MUST NOT`/`SHALL NOT` for prohibitions, `MAY` for optional features) to establish unambiguous conformance boundaries.
- Rule: Negative Prohibition: NEVER allow passive `- Explain:` blocks. Enforce "Prefer Rule Over Explain" by integrating reasoning directly into rule directives (`Enforce X to guarantee Y` / `Prohibit X to prevent Z`).

Step: 2. Multi-Direction Subagent Dispatch:
- Rule: Configurable Multi-Try Execution: Concurrently invoke specialized subagents using `invoke_subagent` across 6 mutually exclusive, expandable design directions, instructing each subagent to produce exactly `[tries]` distinct candidate tries (default: 2 tries per direction = 12 candidate tries total):
  1. Direction 1 (Axiomatic & Symbolic Logic): Compress constraints into atomic propositions and boolean invariants using symbolic operators (`&&`, `||`, `!`, `→`, `>`).
  2. Direction 2 (Sequential Lifecycle Phasing): Structure rules along a chronological execution pipeline (Discovery/Pre-flight Gate → Transformation Gate → Verification/Commit Gate).
  3. Direction 3 (Normative Guardrails & Negative Fences): Enforce rigid RFC-2119 / ISO modals (`MUST NOT...; MUST...; SHALL NOT...`), assertion boundaries, anti-patterns, and anti-hallucination fences.
  4. Direction 4 (Algorithmic Procedures & Decision Matrices): Formulate rules as deterministic pseudocode blocks (`FUNCTION Resolve...`, `MATCH/CASE`), truth tables, and predicate decision matrices.
  5. Direction 5 (Interface Contracts & Pre/Post Conditions): Formulate rules as strict API-style specifications with explicit precondition assertions, input validation contracts, and postcondition verification guarantees.
  6. Direction 6 (Failure Modes & Resilient Fallbacks): Formulate rules centered on edge-case detection, recovery branching, graceful degradation, and exception-handling workflows.
- Rule: Full Granularity: Every try MUST contain the complete, ready-to-use markdown rule text with exact tool and parameter names in backticks.

Step: 3. Multi-Dimensional Comparative Analysis:
- Rule: Benchmark all candidate tries across 5 orthogonal evaluation dimensions:
  1. **Token Economy & Footprint**: Quantitative audit of line count, word count, character count, and token compression ratio vs baseline.
  2. **Constraint Coverage Audit**: 100% Zero Context Loss verification against the checklist created in Step 1.
  3. **LLM Cognitive Ergonomics**: Evaluate instruction-following clarity, absence of conversational padding, and prompt attention sharpness.
  4. **Tool-Action Grounding**: Verify exact tool names (`view_file`, `grep_search`, `replace_file_content`) and parameter flags.
  5. **Cross-Platform Compatibility**: Validate native AST and Markdown parsing across Antigravity, Gemini CLI, Claude Code, and Codex.

Step: 4. Final Champion Synthesis:
- Rule: Attribute Merging: Synthesize the highest-scoring qualities (e.g., symbolic density + clean HDMD headers + dual-clause guardrails) into the single finalized champion rule set.
- Rule: Context Window & Token Density Optimization: Eliminate conversational fluff, narrative explanations, duplicate tables, and redundant boilerplate while preserving 100% semantic constraints, enforcing symbolic density (`&&`, `||`, `!`, `→`) to maximize meaning per token.
- Rule: Dead Code Elimination: Purge all vestigial or unreferenced `Def:` tags, redundant connectives, and narrative explanations.

Step: 5. Authorization & Application:
- Rule: User Precedence Check: Present the comparative analysis and finalized champion rule to the user.
- Rule: Invariant Application: Upon user authorization, write the champion rule to the target file, register it in compiler manifests (if shared), and execute compilation scripts (`scripts/compile.sh`).
