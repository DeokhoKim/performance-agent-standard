#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Read stdin JSON or use env vars
json_input=""
[[ ! -t 0 ]] && json_input=$(cat)

# Parse WORKSPACE_PATH and FILE_PATH using shared utility
mapfile -t parsed < <(printf "%s" "$json_input" | "${SCRIPT_DIR}/parse-hook-input.sh")
WORKSPACE_PATH="${parsed[0]:-}"
FILE_PATH="${parsed[1]:-}"

# We only care about markdown files
[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" != *.md ]] && exit 0

# Create a deterministic state file based on the workspace
# This ensures it tracks state across the same session/project
HASH=$(echo -n "${WORKSPACE_PATH:-default}" | md5sum | awk '{print $1}')
STATE_FILE="/tmp/md_rule_injected_${HASH}"

# If the rule was already injected in the last 60 minutes, allow the write
if [[ -f "$STATE_FILE" ]] && [[ -n $(find "$STATE_FILE" -mmin -60 -print 2>/dev/null) ]]; then
  exit 0
fi

# Mark the rule as injected for this session
touch "$STATE_FILE"

cat << EOF >&2
[ERROR] Rule Injection:
Before writing markdown files, you MUST ensure they conform to the standard rules.
Please read the installed rule "07-markdown-writing.md" and re-run your tool call with the correct format.
EOF

exit 1
