#!/usr/bin/env bash
# ---
# purpose: Unix-optimized PreToolUse hook intercepting destructive Git operations across multi-agent environments.
# ---

set -euo pipefail

# Invariant prefix matching git execution across chains (&&, ;, |), subshells, env vars, and sudo
GIT_PREFIX="(^|[;&|\`\$()'\"]|\s)(sudo\s+|env\s+|([a-zA-Z_][a-zA-Z0-9_]*=\S*\s+)*)*git(\s+-[^\s]+)*\s+"

# Security Rule Matrix: Array of "<regex_pattern>:::<concise_actionable_reason>"
RULES=(
  # 1. Force Push Operations (standard, leased, or flag-permuted)
  "${GIT_PREFIX}push\s+.*(-[a-zA-Z0-9]*f\b|--force\b|--force-with-lease|--force-if-includes):::[git-guard] Force push blocked. Rebase or pull first."

  # 2. Destructive Tree Resets (--hard, --merge)
  "${GIT_PREFIX}reset\s+.*(--hard\b|--merge\b):::[git-guard] Hard/merge reset blocked. Use soft reset or stash."

  # 3. Untracked File Purging (clean -f, -fd, -fx, -xdf, --force)
  "${GIT_PREFIX}clean\s+.*(-[a-zA-Z0-9]*f|--force\b):::[git-guard] Untracked file purge (clean -f) blocked. Delete specific paths."

  # 4. Branch Force Deletion (-D, -d -f, --delete --force)
  "${GIT_PREFIX}branch\s+.*(-[a-zA-Z0-9]*D\b|(-[a-zA-Z0-9]*d|--delete)\s+.*(-[a-zA-Z0-9]*f|--force)|(-[a-zA-Z0-9]*f|--force)\s+.*(-[a-zA-Z0-9]*d|--delete)):::[git-guard] Branch force deletion blocked. Use standard 'git branch -d'."

  # 5. Working Tree & Index Bulk Wipes (checkout/restore targeting '.' or root worktree)
  "${GIT_PREFIX}(checkout|restore)(\s+.*)?\s+(\.|\.\/|--\s+\.|--\s+\.\/)($|[\s;&|\`\(\)]):::[git-guard] Working tree wipe blocked. Target specific file paths."

  # 6. Unrecoverable Stash Purges (drop, clear)
  "${GIT_PREFIX}stash\s+(drop|clear)\b:::[git-guard] Stash destruction blocked. Preserve or inspect stashes."

  # 7. Quality Gate & Safety Hook Bypasses (--no-verify, commit -n, push -n)
  "${GIT_PREFIX}((commit|push|merge|rebase|cherry-pick)\s+.*(-[a-zA-Z0-9]*n\b|--no-verify\b)|.*--no-verify\b):::[git-guard] Hook bypass (--no-verify) blocked. Run validation checks."
)

# Universal Multi-Agent Envelope Parser (Antigravity CommandLine, Claude Code command, Codex/Gemini cmd)
parse_command_line() {
  local json_payload="${1:-}"
  [[ -z "$json_payload" ]] && return 0

  printf "%s" "$json_payload" | jq -r '
    if .tool_input != null then
      if (.tool_input | type == "string") then .tool_input else (.tool_input.command // .tool_input.CommandLine // .tool_input.cmd // "") end
    elif (.toolCall != null or .arguments != null) then
      ( ( .toolCall.arguments // .arguments // {} ) |
        if type == "string" then (fromjson? // {}) else . end
      ) | (.CommandLine // .command // .cmd // "")
    else
      .CommandLine // .command // .cmd // ""
    end
  ' 2>/dev/null || true
}

# Emits dual-schema rejection compatible with Claude Code v0.11+ and universal JSON hook consumers.
emit_rejection() {
  local reason="$1"
  local escaped_reason
  escaped_reason=$(printf "%s" "$reason" | jq -Rs .)
  printf '{"decision":"reject","message":%s,"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$escaped_reason" "$escaped_reason"
  exit 0
}

# Evaluates command line against the Security Rule Matrix.
evaluate_command() {
  local command_line="${1:-}"
  [[ -z "$command_line" ]] && return 0

  for rule in "${RULES[@]}"; do
    local pattern="${rule%%:::*}"
    local message="${rule##*:::}"
    if printf "%s\n" "$command_line" | grep -Eq "$pattern"; then
      emit_rejection "$message"
    fi
  done
}

main() {
  local input=""
  [[ ! -t 0 ]] && input=$(cat)

  local command_line=""
  command_line=$(parse_command_line "$input")

  evaluate_command "$command_line"

  printf '{"decision":"allow"}\n'
}

main "$@"
