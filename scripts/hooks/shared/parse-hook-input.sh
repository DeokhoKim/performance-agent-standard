#!/bin/bash
set -euo pipefail

# This script parses stdin JSON or environment variables passed by Gemini/Claude hooks.
# Output:
# Line 1: WORKSPACE_PATH
# Line 2: TARGET_FILE

INPUT=""
[[ ! -t 0 ]] && INPUT=$(cat)

TARGET_FILE=""
WORKSPACE_PATH=""

# 1. Detect via Claude Code environment variables if available
[[ -n "${CLAUDE_TOOL_INPUT_FILE_PATH:-}" ]] && TARGET_FILE="$CLAUDE_TOOL_INPUT_FILE_PATH"

# 2. Extract from stdin JSON envelope (works for both Claude and Gemini)
[[ -n "$INPUT" ]] && command -v jq >/dev/null 2>&1 && {
  # Parse workspace path
  WORKSPACE_PATH=$(printf "%s" "$INPUT" | jq -r '.workspacePaths[0] // .workspacePath // .cwd // ""' 2>/dev/null || true)

  # Parse target file if not already detected from env
  [[ -z "$TARGET_FILE" ]] && TARGET_FILE=$(printf "%s" "$INPUT" | jq -r '
    if .tool_input != null then
      if (.tool_input | type == "string") then
        .tool_input
      else
        (.tool_input.file_path // .tool_input.filePath // .tool_input.path // .tool_input.TargetFile // "")
      fi
    else
      ( ( .toolCall.arguments // .arguments // {} ) |
        if type == "string" then (fromjson? // {}) else . end
      ) | (.TargetFile // .file_path // .filePath // .path // "")
    fi
  ' 2>/dev/null || true)
}

# Print outputs sequentially (Line 1 = Workspace, Line 2 = Target File)
printf "%s\n" "$WORKSPACE_PATH"
printf "%s\n" "$TARGET_FILE"
