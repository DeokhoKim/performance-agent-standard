#!/usr/bin/env bash
# ---
# purpose: PreToolUse hook to intercept and block destructive git commands.
# ---

set -euo pipefail

# Blocklist patterns for destructive git operations
BLOCKLIST=(
  "git\s+push\s+--force"
  "git\s+push\s+-f"
  "git\s+reset\s+--hard"
  "git\s+clean\s+-f"
  "git\s+branch\s+-D"
)

# Extracts command string across Antigravity (CommandLine) and Claude Code (command) payloads.
parse_command_line() {
  local json_payload="$1"
  [[ -z "$json_payload" ]] && return 0

  printf "%s" "$json_payload" | jq -r '
    if .tool_input != null then
      .tool_input.command // .tool_input.CommandLine // .tool_input.cmd // ""
    else
      ( ( .toolCall.arguments // .arguments // {} ) |
        if type == "string" then (fromjson? // {}) else . end
      ) | (.CommandLine // .command // .cmd // "")
    end
  ' 2>/dev/null || true
}

# Evaluates git command line against destructive operation patterns.
evaluate_git_command() {
  local command_line="$1"
  [[ -z "$command_line" ]] && return 0

  # Only check git commands
  printf "%s" "$command_line" | grep -Eq "^\s*git\s+" || return 0

  for pattern in "${BLOCKLIST[@]}"; do
    printf "%s\n" "$command_line" | grep -Eq "$pattern" && {
      local reason="Command blocked by git-guard: matches destructive pattern '${pattern}'. Consider using softer alternatives or ask for user approval."
      local escaped_reason
      escaped_reason=$(printf "%s" "$reason" | jq -Rsa .)
      printf '{"decision": "reject", "message": %s}\n' "$escaped_reason"
      return 1
    }
  done

  return 0
}

main() {
  local input=""
  [[ ! -t 0 ]] && input=$(cat)

  local command_line
  command_line=$(parse_command_line "$input")

  evaluate_git_command "$command_line" || exit 0

  printf '{"decision": "allow"}\n'
}

main "$@"
