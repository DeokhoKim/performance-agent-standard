#!/usr/bin/env bash
# ---
# purpose: Parse stdin JSON payload or environment variables from agent hook triggers.
# ---

set -euo pipefail

# Parses workspace path from JSON payload.
parse_workspace() {
  local json_payload="$1"
  [[ -z "$json_payload" ]] && return 0
  printf "%s" "$json_payload" | jq -r '.workspacePaths[0] // .workspacePath // .cwd // ""' 2>/dev/null || true
}

# Parses target file path from environment variables or JSON payload.
parse_target_file() {
  local json_payload="$1"

  # 1. Detect via Claude Code environment variable if present
  [[ -n "${CLAUDE_TOOL_INPUT_FILE_PATH:-}" ]] && { printf "%s" "$CLAUDE_TOOL_INPUT_FILE_PATH"; return 0; }

  # 2. Extract from JSON payload envelope
  [[ -z "$json_payload" ]] && return 0
  printf "%s" "$json_payload" | jq -r '
    if .tool_input != null then
      if (.tool_input | type == "string") then
        .tool_input
      else
        (.tool_input.file_path // .tool_input.filePath // .tool_input.path // .tool_input.TargetFile // "")
      end
    else
      ( ( .toolCall.arguments // .arguments // {} ) |
        if type == "string" then (fromjson? // {}) else . end
      ) | (.TargetFile // .file_path // .filePath // .path // "")
    end
  ' 2>/dev/null || true
}

main() {
  local input=""
  [[ ! -t 0 ]] && input=$(cat)

  local workspace=""
  local target=""

  case "$(command -v jq &>/dev/null && echo "jq" || echo "none")" in
    jq)
      workspace=$(parse_workspace "$input")
      target=$(parse_target_file "$input")
      ;;
    none)
      [[ -n "${CLAUDE_TOOL_INPUT_FILE_PATH:-}" ]] && target="$CLAUDE_TOOL_INPUT_FILE_PATH"
      ;;
  esac

  # Print outputs sequentially (Line 1 = Workspace, Line 2 = Target File)
  printf "%s\n" "$workspace"
  printf "%s\n" "$target"
}

main "$@"
