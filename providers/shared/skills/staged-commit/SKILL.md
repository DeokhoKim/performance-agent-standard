---
---

# Staged Commit Skill

Def: Purpose → Generate comprehensive commit message for staged changes, then commit immediately.

Section: Invocation Parameters

- `[language]`: Optional. Target language for the commit message. Defaults to Korean (한국어), or English if user context is English.

Section: Execution Flow

Step: 1. Pre-flight Validation:
- Run the pre-commit script `scripts/pre-commit-check.sh`.
- Rule: Agent MUST NOT perform manual check commands (e.g., `git status`, `git diff`). Rely entirely on `pre-commit-check.sh`.
- Rule: If `pre-commit-check.sh` fails (exit status > 0) → display output, suggest action, and stop execution immediately.

Step: 2. Context Collection:
- Rule: Use the output of `pre-commit-check.sh` (from Step 1) as the sole diff context. Do NOT run any additional git commands.
- Rule: `git commit` always applies staged changes to the current HEAD regardless of branch state (attached or detached). No branch comparison is needed or performed.

Step: 3. Commit Message Generation:
- Format: Conventional Commits (`<type>(<scope>): <subject>` + body).
- Language: Use `[language]` if specified, otherwise auto-detect (default Korean, English fallback).
- Subject: Max 50 chars, imperative mood, no trailing period.
- Body: Wrapped at 72 chars, explain what && why.

Step: 4. Execution:
- Rule: Execute `git commit -m "<message>"` immediately. No user confirmation required.
