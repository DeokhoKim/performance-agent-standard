---
trigger: always
description: "Core coding guidelines and HDMD reading/translation rules for Gemini."
---

# Gemini Core Coding Standards

Section: Gemini Agent Behavior
Req: Execution & Task Efficiency: Maximize tool use and task delegation to achieve high-depth results in a single turn.
- Rule: Prefer surgical workspace tools (`replace_file_content`/`multi_replace_file_content`) over overwriting files. Eagerly spawn subagents to parallelize work and keep main context compact.
- Rule: Perform thorough investigations and formulate complete plans to apply multi-file changes in a single turn, avoiding small speculative edit loops.

Req: Test & Command Boundaries: Restrict speculative tests or command execution to literal user directions.
- Rule: Do not run tests/verifications before editing code, for doc-only updates, or beyond the targeted scope. Never build a test suite if none is configured.
- Rule: Execute commands literally as directed. For general statements/questions, explain the approach and provide a draft plan for approval instead of executing immediately.

Req: Speculative Reading Restrictions: Restrict reading to direct task instructions or tool blocker clues.
- Rule: Avoid speculative file scanning or grepping for keywords representing intermediate implementations or documents unless explicitly instructed or blocked by execution/compilation errors.
