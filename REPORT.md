# Shared Rules Audit & Revision Report

> **Date:** 2026-08-27
> **Scope:** `providers/shared/rules/` (12 files) + `scripts/compile.sh`
> **Net Change:** 14 files modified, +173 / -197 lines (**net -24 lines**)
> **Compilation:** ✅ All 4 providers (Antigravity, Gemini, Claude, Codex)

---

## 1. Objective

Perform a multi-directional analysis of all shared rule files to eliminate redundancy, enforce strict HDMD (High-Density Markdown) compliance, validate cross-platform compilation, and verify the language standards hierarchy — ensuring that reading rules from general to specific trivially supplements and specifies details without repetition.

## 2. Analysis Methodology

The analysis followed 4 orthogonal directions modeled after the [`generate-rule` SKILL.md](.agents/skills/generate-rule/SKILL.md) multi-direction pattern:

| Direction | Focus | Key Question |
|:----------|:------|:-------------|
| **D1: Redundancy & Layering** | Cross-rule overlap, hierarchical flow, orphaned files | Do rules repeat each other? Does general→specific reading accumulate cleanly? |
| **D2: HDMD Tag Compliance** | Tag standard violations, `Explain:` prohibition, symbolic density | Are all rules machine-enforceable with proper HDMD structure? |
| **D3: Cross-Platform Compatibility** | `compile.sh` frontmatter, triggers, globs, assembly | Does compilation produce correct output for all 4 agent platforms? |
| **D4: Language Standards Hierarchy** | Abstract→concrete traceability, language contamination, missing implementations | Does each language file ONLY add concrete specifics without repeating abstract principles? |

## 3. Files Inventory (Post-Revision)

| Order | File | Trigger | Glob | Lines | Category |
|:------|:-----|:--------|:-----|------:|:---------|
| — | [`markdown-reading.md`](providers/shared/rules/markdown-reading.md) | core | — | 57 | HDMD Core |
| 10 | [`karpathy-guidelines.md`](providers/shared/rules/karpathy-guidelines.md) | always | — | 9 | Agent Instincts |
| 11 | [`workspace-hygiene.md`](providers/shared/rules/workspace-hygiene.md) | always | — | 17 | Agent Instincts |
| 12 | [`inline-execution.md`](providers/shared/rules/inline-execution.md) | always | — | 13 | Agent Instincts |
| 13 | [`development-standards.md`](providers/shared/rules/development-standards.md) | always | — | 8 | Agent Instincts |
| 20 | [`markdown-writing.md`](providers/shared/rules/markdown-writing.md) | glob | `**/*.md` | 67 | Document Standards |
| 30 | [`code-simplicity.md`](providers/shared/rules/code-simplicity.md) | glob | `*.rs, *.cpp, *.cc, *.c, *.hpp, *.h, *.sh, *.bash, *.py` | 36 | Common/Polyglot |
| 31 | [`lang-standard-common.md`](providers/shared/rules/lang-standard-common.md) | glob | `*.rs, *.cpp, *.cc, *.c, *.hpp, *.h, *.sh, *.bash, *.py` | 29 | Common/Polyglot |
| 40 | [`lang-standard-native.md`](providers/shared/rules/lang-standard-native.md) | glob | `*.rs, *.cpp, *.cc, *.c, *.hpp, *.h` | 17 | Native/Compiled |
| 41 | [`lang-standard-rust.md`](providers/shared/rules/lang-standard-rust.md) | glob | `*.rs` | 19 | Rust-Specific |
| 50 | [`lang-standard-bash.md`](providers/shared/rules/lang-standard-bash.md) | glob | `*.sh, *.bash` | 36 | Bash-Specific |
| 51 | [`lang-standard-python.md`](providers/shared/rules/lang-standard-python.md) | glob | `*.py` | 59 | Python-Specific |
| ❌ | ~~`lang-native-standard.md`~~ | — | — | — | **Deleted** (orphan) |

**Total:** 12 active rule files, 367 lines.

## 4. Direction 1: Redundancy & Layering Audit

### 4.1 Orphaned Duplicate — Deleted

**Finding:** `lang-native-standard.md` (14 lines) existed in `providers/shared/rules/` but was **not registered** in `SHARED_RULES` in `compile.sh`. It was a strict subset of `lang-standard-native.md` (missing the RAII section).

**Action:** Deleted `lang-native-standard.md`. The canonical file is `lang-standard-native.md`.

### 4.2 Cross-Rule Semantic Overlaps — Resolved

#### Simplicity Principle Triple-Statement

The anti-speculation/simplicity principle appeared in 3 files:

| Source | Original Statement |
|:-------|:-------------------|
| `karpathy-guidelines.md` L9 | "Write minimal code... Avoid speculative features, premature abstractions" |
| `code-simplicity.md` L6 | "NEVER implement speculative features, future-proofing parameters..." |
| `lang-standard-common.md` L11 | "explicitly avoiding speculative future-proofing, bloated design abstractions" |

**Action:** Removed the redundant anti-speculation clause from `lang-standard-common.md`. Rewritten as: `Apply SOLID pragmatically to keep code modular && readable without unnecessary design overhead (Simplicity First).` — a back-reference to the principle without restating it.

#### Duplicate Tag Dictionary Table

Both `markdown-reading.md` and `markdown-writing.md` contained near-identical 6-row Tag Dictionary tables.

**Action:** Removed the table from `markdown-writing.md`. The reference is already loaded via the core system prompt (`markdown-reading.md` is concatenated into `GEMINI.md`/`CLAUDE.md`/`AGENTS.md`).

### 4.3 Hierarchical Incremental Flow — Verified

The reading order from general to specific correctly supplements without repetition:

```
always-read (core) → karpathy (10) → workspace-hygiene (11) → inline-execution (12) → development-standards (13)
                                                                                          ↓
                                                             [*.rs file triggers glob rules]
                                                                                          ↓
                                                     code-simplicity (30) → lang-standard-common (31)
                                                                                          ↓
                                                                        lang-standard-native (40)
                                                                                          ↓
                                                                          lang-standard-rust (41)
```

Each layer adds concrete depth without repeating the parent's abstract principle.

## 5. Direction 2: HDMD Tag Compliance & Density Audit

### 5.1 Passive `Explain:` Blocks — Eliminated (2 instances)

| File | Before | After |
|:-----|:-------|:------|
| `karpathy-guidelines.md` L6 | `Explain: Tradeoff: These guidelines bias toward caution over speed.` | `- Rule: Caution Bias: Enforce deliberate caution over speed to prevent regressions; apply pragmatic judgment ONLY for provably trivial tasks.` |
| `lang-standard-bash.md` L13 | `- Explain: printf is standard POSIX compliant (avoiding cross-platform flags inconsistency like -n or -e)...` | Merged into parent Rule: `Enforce \`printf\` over \`echo\`... to guarantee POSIX compliance, avoid cross-platform flag inconsistencies (\`-n\`/\`-e\`)...` |

### 5.2 Conversational Prose — Folded (7 instances)

| File | Line | Prose Removed | Integration |
|:-----|:-----|:--------------|:------------|
| `karpathy-guidelines.md` | 3 | "This document defines the core developer behavior..." | Deleted — `# Title` && `Req:` already communicate purpose |
| `lang-standard-bash.md` | 15 | "This keeps the namespace clean and prevents..." | Folded into rule: `...to isolate namespaces && eliminate ShellCheck \`SC2034\` warnings.` |
| `lang-standard-bash.md` | 30 | "This allows environment variables to override..." | Folded into rule: `...to allow environment overrides && prevent unbound variable errors under \`set -u\`.` |
| `markdown-writing.md` | 22 | "This eliminates conversational prose and maximizes semantic accuracy." | Folded into rule suffix |
| `markdown-writing.md` | 38 | "This allows agents to quickly evaluate relevance..." | Folded: `...to enable instant relevance evaluation without full-document parsing.` |
| `lang-standard-common.md` | 19 | "(which are easily bypassed by errors)" | Rewritten: `Prohibit manual cleanup calls at function endpoints; enforce...` |
| `lang-standard-common.md` | 28 | "Do not communicate by sharing memory; instead, share memory by communicating." | Replaced with: `Prohibit raw threads synchronized by manual locks...` |

### 5.3 Non-Standard Section Headers — Converted (5 instances)

All `## Section N:` headers in `markdown-writing.md` converted to HDMD `Section:` tags:

| Before | After |
|:-------|:------|
| `## Section 1: Zero Context Loss (Absolute Priority)` | `Section: Zero Context Loss (Absolute Priority)` |
| `## Section 2: Conciseness & Token Efficiency` | `Section: Conciseness && Token Efficiency` |
| `## Section 3: Compact Formatting` | `Section: Compact Formatting` |
| `## Section 4: Agent-Extractable Structure (Semantic-Friendly)` | `Section: Agent-Extractable Structure` |
| `## Section 5: Procedural Writing Flow (Pseudocode Guide)` | `Section: Procedural Writing Flow` |

### 5.4 Sub-Rules Named (12 instances)

Added `RuleName:` to all unnamed sub-rules across:

| File | Count | Examples |
|:-----|------:|:--------|
| `lang-standard-common.md` | 4 | `Parameterized Configs`, `Usable Defaults`, `Pragmatic Application`, `Native Deterministic Cleanup` |
| `lang-standard-python.md` | 5 | `Dataclass Field Invariants`, `Localized Branching Delegation`, `Traceable Iteration`, `O(1) Memory Streaming`, `Partial Dependency Freezing` |
| `inline-execution.md` | 3 | `Local Dependency Isolation`, `Standalone Script Metadata`, `Standard Library Fallback` |

### 5.5 Untagged Bullets Tagged

All descriptive bullets in `markdown-writing.md` (formatting rules) and `inline-execution.md` (dependency constraints) prefixed with `- Rule:`.

### 5.6 Deprecated `Explain:` Tag — Removed from Reference

Removed `Explain: / Explanation:` row from the Tag Translation Reference table in `markdown-reading.md` to align with the "Prefer Rule Over Explain" directive. The `TranslateNode` pseudocode parser retains backward compatibility for legacy files.

### 5.7 Symbolic Density — Applied Globally

Replaced natural language connectives with symbolic operators across all 12 rule files:

| Before | After | Instances |
|:-------|:------|----------:|
| `and` / `&` | `&&` | ~80 |
| `or` | `\|\|` | ~40 |
| `->` | `→` | 2 |

### 5.8 Entity Grounding — Fixed

| File | Entity | Fix |
|:-----|:-------|:----|
| `inline-execution.md` | `printf` | Wrapped in backticks |
| `lang-standard-bash.md` | `SC2034` | Wrapped in backticks |

## 6. Direction 3: Cross-Platform Compatibility Audit

### 6.1 Frontmatter Generation — Verified Correct

The `compile_rule` function in `compile.sh` generates correct YAML frontmatter per provider:

| Provider | Trigger Key | Glob Key | Status |
|:---------|:------------|:---------|:-------|
| Antigravity | `alwaysApply: true/false` | `globs:` | ✅ |
| Gemini | `trigger: always/glob` | `globs:` | ✅ |
| Claude | — (no trigger for always) | `paths:` | ✅ |
| Codex | — (all plain copy) | — | ✅ |

### 6.2 SHARED_RULES Registry — Fixed

- **Renamed** `lang-native-standard` → `lang-standard-native` in the registry to match the `lang-standard-*` family naming convention
- **Description updated** from `"compiled systems code (C, C++)"` to `"native/compiled systems code"` to reflect language-agnostic scope
- **Orphaned file** `lang-native-standard.md` deleted

### 6.3 Compilation Verification

All 4 providers compile successfully with correct `40-lang-standard-native.md` output:

```
[INFO] Compiling Antigravity...
[INFO] Compiling Gemini...
[INFO] Compiling Claude...
[INFO] Compiling Codex...
[INFO] Compilation complete.
```

Dist rule counts: 11 rules + 1 core system prompt per provider.

## 7. Direction 4: Language Standards Hierarchy Audit

### 7.1 Language Contamination — Fixed

`lang-standard-native.md` contained Rust-specific constructs in what should be a cross-native rule:

| Line | Before (Rust-contaminated) | After (Language-agnostic) |
|:-----|:---------------------------|:--------------------------|
| L5 | `select_nth_unstable` (Rust-only) | "in-place linear-time selection algorithms" (generic) |
| L6 | `Vec` / `Vec::with_capacity` (Rust) | "collection structures" / "pre-allocate capacity" (generic) |

C++-specific qualifiers (e.g., `(C++)` in Req names) removed. The file now serves as the common intermediate layer for all native languages.

### 7.2 Abstract-to-Concrete Hierarchy — Verified

Three core concepts traced from abstract to concrete:

**Scoped Resource / RAII:**
| Layer | File | Concrete Implementation |
|:------|:-----|:------------------------|
| Abstract | `lang-standard-common.md` | `Scoped Return Pattern` — generic principle |
| Native | `lang-standard-native.md` | `RAII Guard Pattern` — compiler-managed lifetimes |
| Rust | `lang-standard-rust.md` | `RAII && Drop Trait` — `MutexGuard`, `Drop` |
| Bash | `lang-standard-bash.md` | `Trap Exit Handlers` — `trap 'cleanup' EXIT` |
| Python | `lang-standard-python.md` | `Generator-Based Context Managers` — `@contextlib.contextmanager` |

**Zero-Copy Data Transfer:**
| Layer | File | Concrete Implementation |
|:------|:-----|:------------------------|
| Abstract | `lang-standard-common.md` | Views > copies, move semantics, mmap/splice |
| Native | `lang-standard-native.md` | Reference views, ownership transfer, `mmap`/`sendfile` |
| Rust | `lang-standard-rust.md` | `&[u8]`/`&str`, `Arc`, `Cow`, `memmap2` |
| Bash | — | Correctly absent (N/A for shell) |
| Python | `lang-standard-python.md` | `memoryview()`, `np.empty`, in-place operators |

**Data-Flow Parallelism:**
| Layer | File | Concrete Implementation |
|:------|:-----|:------------------------|
| Abstract | `lang-standard-common.md` | Message passing > shared state, pipeline architecture |
| Native | `lang-standard-native.md` | Concurrent queues, task-based designs, pipeline architectures |
| Rust | `lang-standard-rust.md` | `mpsc`, `crossbeam`, `rayon` |
| Bash | `lang-standard-bash.md` | Shell pipelines, `mkfifo` |
| Python | `lang-standard-python.md` | `asyncio`, `concurrent.futures.ProcessPoolExecutor` (**NEW**) |

### 7.3 Missing Implementation — Added

Python was the only language file missing a `Data-Flow Parallelism` section. Added:

```markdown
Section: Concurrency && Parallelism
Req: Data-Flow Parallelism (Python): Enforce async && message-passing concurrency over thread locks.
- Rule: Async Pipeline Architecture: Enforce `asyncio` tasks && `asyncio.Queue` for I/O-bound concurrency;
  enforce `concurrent.futures.ProcessPoolExecutor` for CPU-bound parallelism over manual `threading.Thread`
  with shared locks.
```

### 7.4 Naming Convention — Standardized

All language standard files now follow the `lang-standard-*` family convention:

| Order | File | Scope |
|:------|:-----|:------|
| 31 | `lang-standard-common.md` | All languages (abstract principles) |
| 40 | `lang-standard-native.md` | All native/compiled languages (intermediate depth) |
| 41 | `lang-standard-rust.md` | Rust-specific implementations |
| 50 | `lang-standard-bash.md` | Bash-specific implementations |
| 51 | `lang-standard-python.md` | Python-specific implementations |

### 7.5 Bash Logging Example — Preserved

The canonical logging code block was retained in `lang-standard-bash.md` to ensure agents always generate consistent logging patterns:

```bash
NC='\033[0m'

log_info() {
  local green='\033[0;32m'
  printf "%b[INFO]%b %s\n" "$green" "$NC" "$1"
}
```

## 8. Change Summary

### Files Modified (13)

| File | Lines Changed | Key Changes |
|:-----|:-------------|:------------|
| `karpathy-guidelines.md` | -7 / +5 | Deleted intro fluff, `Explain:` → `Rule: Caution Bias`, symbolic density |
| `workspace-hygiene.md` | -4 / +4 | Symbolic density (`and`→`&&`, `or`→`||`) |
| `inline-execution.md` | -7 / +7 | Tagged 3 sub-rules with RuleNames, backticked `printf` |
| `development-standards.md` | -4 / +4 | Symbolic density |
| `markdown-writing.md` | -35 / +25 | 5 headers converted, duplicate Tag Dict removed, bullets tagged, prose folded |
| `markdown-reading.md` | -1 / +0 | Deprecated `Explain:` row removed from Tag Dictionary |
| `code-simplicity.md` | -29 / +29 | Symbolic density, `->` → `→` in omission formula |
| `lang-standard-common.md` | -22 / +22 | 4 sub-rules named, prose folded, redundant anti-spec clause removed |
| `lang-standard-native.md` | -11 / +11 | Rust contamination fixed, C++ qualifiers removed, language-agnostic |
| `lang-standard-rust.md` | -11 / +11 | Symbolic density, passive→active directives |
| `lang-standard-bash.md` | -19 / +17 | `Explain:` eliminated, prose folded, `Def:` tags for colors, example preserved |
| `lang-standard-python.md` | -33 / +37 | 5 sub-rules named, new Concurrency section added |
| `compile.sh` | -1 / +1 | SHARED_RULES entry: `lang-standard-native` name + description |

### Files Deleted (1)

| File | Reason |
|:-----|:-------|
| `lang-native-standard.md` | Orphaned duplicate not registered in `SHARED_RULES`; strict subset of `lang-standard-native.md` |

### Totals

| Metric | Value |
|:-------|:------|
| Files touched | 14 |
| Lines added | 173 |
| Lines removed | 197 |
| Net reduction | **-24 lines** |
| Passive `Explain:` blocks eliminated | 2 |
| Conversational prose instances folded | 7 |
| Non-standard headers converted | 5 |
| Unnamed sub-rules named | 12 |
| Symbolic density replacements | ~120 |
| New sections added | 1 (Python Concurrency) |
| Orphaned files deleted | 1 |
| Compilation status | ✅ All 4 providers |
