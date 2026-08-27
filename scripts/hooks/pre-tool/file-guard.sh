#!/usr/bin/env bash
# ---
# purpose: Unix-optimized PreToolUse hook intercepting unauthorized mutations to sensitive files and lockfiles.
# ---

set -euo pipefail

# Static Security Rule Matrix: Array of "<regex_pattern>:::<concise_actionable_reason>"
RULES=(
  # 1. Cryptographic Secrets, Private Keys, and Certificates
  "(\.pem|\.key|\.pkcs12|\.pfx|\.p12|\.kdbx|\.keystore|id_rsa|id_ed25519|id_ecdsa|id_dsa)($|\.|\/):::[file-guard] Secret/key mutation blocked. Isolate credentials."

  # 2. Environment Configuration and State Files
  "(\.env|\.env\.[a-zA-Z0-9_.-]+|.*\.tfstate|.*\.tfstate\..*)($|\/):::[file-guard] Env/state mutation blocked. Protect secrets."

  # 3. Package Manager Lockfiles (Must be mutated only via package manager CLI)
  "(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|poetry\.lock|uv\.lock|composer\.lock|Gemfile\.lock)($|\/):::[file-guard] Lockfile mutation blocked. Use package manager CLI."

  # 4. Git Metadata & Internal Configurations
  "(^|\/)\.git(\/|$)(\.gitconfig|\.gitmodules|\.gitattributes)?:::[file-guard] Git metadata mutation blocked. Use git CLI."
)

# Universal Multi-Agent Envelope Parser (Antigravity TargetFile, Claude Code file_path, Codex/Gemini filePath)
parse_target_file() {
  local json_payload="${1:-}"
  [[ -n "${CLAUDE_TOOL_INPUT_FILE_PATH:-}" ]] && { printf "%s" "$CLAUDE_TOOL_INPUT_FILE_PATH"; return 0; }
  [[ -z "$json_payload" ]] && return 0

  printf "%s" "$json_payload" | jq -r '
    if .tool_input != null then
      if (.tool_input | type == "string") then
        .tool_input
      else
        (.tool_input.file_path // .tool_input.filePath // .tool_input.path // .tool_input.TargetFile // "")
      end
    elif (.toolCall != null or .arguments != null) then
      ( ( .toolCall.arguments // .arguments // {} ) |
        if type == "string" then (fromjson? // {}) else . end
      ) | (.TargetFile // .file_path // .filePath // .path // "")
    else
      .TargetFile // .file_path // .filePath // .path // ""
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

# Evaluates target file path against static security matrix.
evaluate_file() {
  local target_file="${1:-}"
  [[ -z "$target_file" ]] && return 0

  # Canonicalize path to neutralize relative traversals (../) and symlink aliasing
  local canonical_path
  canonical_path=$(realpath -m "$target_file" 2>/dev/null || printf "%s" "$target_file")
  local file_basename
  file_basename=$(basename "$canonical_path")

  for rule in "${RULES[@]}"; do
    local pattern="${rule%%:::*}"
    local message="${rule##*:::}"
    if printf "%s\n" "$file_basename" | grep -Eq "$pattern" || printf "%s\n" "$canonical_path" | grep -Eq "$pattern"; then
      emit_rejection "$message"
    fi
  done
}

main() {
  local input=""
  [[ ! -t 0 ]] && input=$(cat)

  local target_file=""
  target_file=$(parse_target_file "$input")

  evaluate_file "$target_file"

  printf '{"decision":"allow"}\n'
}

main "$@"
