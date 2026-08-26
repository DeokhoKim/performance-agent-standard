#!/bin/bash
set -euo pipefail

# This script is a PreToolUse hook that acts as a guard for git commands.
# It intercepts git commands to prevent destructive operations.

INPUT=""
[[ ! -t 0 ]] && INPUT=$(cat)

# Extract the command to execute
COMMAND_LINE=$(printf "%s" "$INPUT" | jq -r '
  if .tool_input != null then
    .tool_input.command // .tool_input.CommandLine // .tool_input.cmd // ""
  else
    ( ( .toolCall.arguments // .arguments // {} ) |
      if type == "string" then (fromjson? // {}) else . end
    ) | (.CommandLine // .command // .cmd // "")
  fi
' 2>/dev/null || true)

[[ -n "$COMMAND_LINE" ]] || { printf '{"decision": "allow"}\n'; exit 0; }
printf "%s" "$COMMAND_LINE" | grep -Eq "^\s*git\s+" || { printf '{"decision": "allow"}\n'; exit 0; }

# Blocklist patterns for git
BLOCKLIST=(
  "git\s+push\s+--force"
  "git\s+push\s+-f"
  "git\s+reset\s+--hard"
  "git\s+clean\s+-f"
  "git\s+branch\s+-D"
)

# Check for blocked patterns
for pattern in "${BLOCKLIST[@]}"; do
  printf "%s" "$COMMAND_LINE" | grep -Eq "$pattern" && {
    REASON="Command blocked by git-guard: matches destructive pattern '${pattern}'. Consider using softer alternatives or ask for user approval."
    ESCAPED_REASON=$(printf "%s" "$REASON" | jq -Rsa .)
    printf '{"decision": "reject", "message": %s}\n' "$ESCAPED_REASON"
    exit 0
  }
done

printf '{"decision": "allow"}\n'
exit 0
