---
name: staged-commit
description: >
  Generates comprehensive git commit messages for staged changes and commits them.
  Compares staged changes against an optional target branch.
  This skill is ONLY activated via the /staged-commit slash command. Do NOT activate this skill from natural language commit requests.
argument-hint: "[target] [language]"
arguments:
  - name: target
    description: Optional target branch to compare staged changes/HEAD against. Defaults to the repository's default branch.
  - name: language
    description: Optional target language for the commit message. Defaults to Korean.
user-invokable: true
implicit: false
---

# Staged Commit Skill

Def: Purpose → Generate comprehensive commit message for staged changes, then commit immediately.

Section: Invocation Parameters

- `[target]`: Optional. Target branch to compare staged changes/HEAD against. Defaults to the repository's default branch (e.g., `main` or `master`).
- `[language]`: Optional. Target language for the commit message. Defaults to Korean (한국어), or English if user context is English.

Section: Execution Flow

Step: 1. Pre-flight Validation:
- Run the pre-commit script `scripts/pre-commit-check.sh`.
- Rule: Agent MUST NOT perform manual check commands (e.g., `git status`, `git diff`). Rely entirely on `pre-commit-check.sh`.
- Rule: If `pre-commit-check.sh` fails (exit status > 0) → display output, suggest action, and stop execution immediately.

Step: 2. Context Collection:
- Determine the target branch `[target]` (default: repository default branch).
- Rule: Collect the diff between `HEAD` and `[target]` to understand change context: `git diff [target]`.
- Rule: Collect staged changes diff: `git diff --cached`.

Step: 3. Commit Message Generation:
- Format: Conventional Commits (`<type>(<scope>): <subject>` + body).
- Language: Use `[language]` if specified, otherwise auto-detect (default Korean, English fallback).
- Subject: Max 50 chars, imperative mood, no trailing period.
- Body: Wrapped at 72 chars, explain what && why.

Step: 4. Execution:
- Rule: Execute `git commit -m "<message>"` immediately. No user confirmation required.
