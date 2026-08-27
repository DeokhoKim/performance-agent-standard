#!/usr/bin/env bash
# ---
# purpose: Unix-optimized PreToolUse hook intercepting destructive OS commands, in-place edits, and GitHub API mutations.
# ---

set -euo pipefail

# Security Rule Matrix: Array of "<regex_pattern>:::<concise_actionable_reason>"
RULES=(
  # 1. Permuted Recursive Deletion targeting root, home, or wildcards
  "rm\s+.*(-[a-zA-Z]*[rf][a-zA-Z]*[rf]|-[a-zA-Z]*r\s+.*-[a-zA-Z]*f|-[a-zA-Z]*f\s+.*-[a-zA-Z]*r|--recursive).*(\s+(\/|\/\*|~|\*)($|\s)):::[bash-guard] Root/wildcard deletion blocked. Use targeted paths."

  # 2. In-Place Stream Editing Bypasses (sed -i, perl -i, ruby -i, ed)
  "(sed\s+.*(-[a-zA-Z]*i|--in-place)|perl\s+.*-[a-zA-Z]*i|ruby\s+.*-[a-zA-Z]*i|(\s|^)ed\s+):::[bash-guard] In-place stream edit blocked. Use workspace file edit tools."

  # 3. GitHub CLI Mutating APIs & Destructive Commands
  "gh\s+(repo\s+delete|api\s+.*(-X\s*(DELETE|PUT|PATCH)|--method\s*(DELETE|PUT|PATCH))):::[bash-guard] GitHub API mutation blocked. Only read-only queries allowed."

  # 4. Low-Level Disk/Filesystem Destruction
  "(dd\s+.*(if=|of=)|mkfs(\..*)?|wipefs|fdisk|shred\s+.*|truncate\s+(-s\s*0|--size=0)):::[bash-guard] Disk/filesystem mutation utility blocked."

  # 5. Privilege Escalation, Global Perms, and Shell Forkbombs
  "(sudo\s+|chmod\s+-R\s+777|kill\s+-9\s+(-1|1)\b|:\(\)\{\s*:\|:&\s*\};:):::[bash-guard] Unsafe privilege/system operation blocked."
)

# Extracts command string across Antigravity (CommandLine), Claude Code (command), and Codex/Gemini (cmd) envelopes.
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

# Evaluates command line against security rule matrix.
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
