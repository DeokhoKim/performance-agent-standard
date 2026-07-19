#!/bin/bash
set -euo pipefail

# This script parses stdin JSON or environment variables passed by Gemini/Claude hooks.
# Output:
# Line 1: WORKSPACE_PATH
# Line 2: TARGET_FILE

INPUT=""
if [[ ! -t 0 ]]; then
  INPUT=$(cat)
fi

TARGET_FILE=""
WORKSPACE_PATH=""

# 1. Detect via Claude Code environment variables if available
if [[ -n "${CLAUDE_TOOL_INPUT_FILE_PATH:-}" ]]; then
  TARGET_FILE="$CLAUDE_TOOL_INPUT_FILE_PATH"
fi

# 2. Extract from stdin JSON envelope (works for both Claude and Gemini)
if [[ -n "$INPUT" ]] && command -v jq >/dev/null 2>&1; then
  # Parse workspace path
  WORKSPACE_PATH=$(jq -r '.workspacePaths[0] // .workspacePath // .cwd // ""' <<< "$INPUT" 2>/dev/null || true)

  # Parse target file if not already detected from env
  if [[ -z "$TARGET_FILE" ]]; then
    TARGET_FILE=$(jq -r '
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
    ' <<< "$INPUT" 2>/dev/null || true)
  fi
fi

# Print outputs sequentially (Line 1 = Workspace, Line 2 = Target File)
printf "%s\n" "$WORKSPACE_PATH"
printf "%s\n" "$TARGET_FILE"
