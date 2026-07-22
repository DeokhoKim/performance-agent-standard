---
---

# Create Pull Request Skill

Def: Purpose → Create a pull request from HEAD to target branch programmatically, handling detached HEAD and generating optimized descriptions.

Section: Invocation Parameters

- `[target]`: Optional. Target branch to compare and open the PR against. Defaults to the repository's default branch.
- `[draft/ready]`: Optional. PR status. Defaults to `draft`.
- `[language]`: Optional. Target language for the PR title and description. Defaults to Korean (한국어).

Section: Execution Flow

Step: 1. Pre-flight Validation:
- Run `scripts/pre-pr-check.sh [target]` (pass `[target]` only if specified).
- Rule: Agent MUST NOT run any manual git/gh inspection commands (e.g., `git log`, `git diff`, `git branch`, `gh repo view`). Rely entirely on `pre-pr-check.sh` for all environment and context data.
- Rule: If script exits non-zero → display stderr, suggest action, and stop.
- Parse stdout as `KEY=value` pairs: `TARGET_BRANCH`, `RESOLVED_TARGET`, `CURRENT_BRANCH`, `IS_DETACHED`, `IS_TRIVIAL`, `COMMITS_FILE`, `DIFF_FILE`.

Step: 2. Branch Checkout (if detached):
- If `IS_DETACHED=true`: generate a short descriptive branch name from `COMMITS_FILE` content.
- Rule: Execute `git checkout -b <branch-name>` immediately. Update `CURRENT_BRANCH` to the new name.

Step: 3. Remote Push:
- Rule: Execute `git push -u origin <CURRENT_BRANCH>`.

Step: 4. PR Message Generation & Context Isolation:
- Rule: Do NOT read raw `COMMITS_FILE` or `DIFF_FILE` directly into the main orchestrator context.
- Delegate PR title & description generation to `diff-analyzer` subagent:
  - Input: `commits_file=COMMITS_FILE`, `diff_file=DIFF_FILE`, `analysis_mode="pr_description"`, `strategy="auto"`.
  - Language: `[language]` (default Korean).
- `diff-analyzer` handles automatic quality evaluation (Fast Path via commits if comprehensive; Deep Path via diff if trivial).

Step: 5. PR Creation:
- Rule: Execute `gh pr create --base <TARGET_BRANCH>` with the generated title and body.
- Flag: Append `--draft` unless `[draft/ready]` is explicitly `ready`.
