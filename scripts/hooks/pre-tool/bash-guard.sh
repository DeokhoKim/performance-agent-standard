#!/bin/bash
set -euo pipefail

# This script is a PreToolUse hook that acts as a guard for shell commands.
# It intercepts bash commands to prevent system-level damage.

INPUT=""
[[ ! -t 0 ]] && INPUT=$(cat)

# Extract the command to execute
# Works for both Antigravity (run_command / CommandLine) and Claude Code (Bash / command)
COMMAND_LINE=$(printf "%s" "$INPUT" | jq -r '
  if .tool_input != null then
    .tool_input.command // .tool_input.CommandLine // .tool_input.cmd // ""
  else
    ( ( .toolCall.arguments // .arguments // {} ) |
      if type == "string" then (fromjson? // {}) else . end
    ) | (.CommandLine // .command // .cmd // "")
  fi
' 2>/dev/null || true)

[[ -z "$COMMAND_LINE" ]] && { printf '{"decision": "allow"}\n'; exit 0; }

# Blocklist patterns
BLOCKLIST=(
  "rm\s+-rf\s+/"
  "rm\s+-rf\s+/\*"
  "rm\s+-rf\s+~"
  "rm\s+-rf\s+\*"
  "sudo\s+"
  "chmod\s+-R\s+777"
  "kill\s+-9"
  "curl\s+.*\|\s*bash"
  "wget\s+.*\|\s*bash"
)

# Check for blocked patterns
for pattern in "${BLOCKLIST[@]}"; do
  printf "%s\n" "$COMMAND_LINE" | grep -Eq "$pattern" && {
    REASON="Command blocked by bash-guard: matches dangerous pattern '${pattern}'. Please use safer alternatives."
    ESCAPED_REASON=$(printf "%s" "$REASON" | jq -Rsa .)
    printf '{"decision": "reject", "message": %s}\n' "$ESCAPED_REASON"
    exit 0
  }
done

printf '{"decision": "allow"}\n'
exit 0
