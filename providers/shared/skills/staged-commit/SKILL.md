---
---

# Staged Commit Skill

Def: Purpose → Generate comprehensive commit message for staged changes, then commit immediately.

Section: Invocation Parameters

- `[language]`: Optional. Target language for the commit message. Defaults to Korean (한국어).

Section: Execution Flow

Step: 1. Pre-flight Validation:
- Run the pre-commit script `scripts/pre-commit-check.sh`.
- Rule: Agent MUST NOT perform manual check commands (e.g., `git status`, `git diff`). Rely entirely on `pre-commit-check.sh`.
- Rule: If `pre-commit-check.sh` fails (exit status > 0) → display output, suggest action, and stop execution immediately.

Step: 2. Diff Analysis & Context Isolation:
- Rule: Do NOT read raw diff content into the main orchestrator context.
- Delegate diff processing to the `diff-analyzer` subagent:
  - Input: `diff_file` (from `pre-commit-check.sh`), `commits_file=null`, `analysis_mode="commit_message"`.
  - Language: `[language]` (default Korean).
- Format: Conventional Commits (`<type>(<scope>): <subject>` + body).

Step: 3. Execution:
- Rule: Execute `git commit -m "<message>"` immediately using the commit message returned by `diff-analyzer`. No user confirmation required.
  - Exception: If the commit fails due to pre-commit hook fixes, the agent may run `git add` ONLY on already-staged files to update their index state, then retry the commit once. No other files can be added.
