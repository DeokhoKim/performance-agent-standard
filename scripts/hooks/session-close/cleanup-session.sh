#!/usr/bin/env bash
# ---
# purpose: Unix-optimized SessionEnd hook safely purging ephemeral session caches and stale temporary files on agent exit.
# ---

set -euo pipefail

SESSION_ID="${PAS_SESSION_ID:-${CLAUDE_SESSION_ID:-${GEMINI_SESSION_ID:-${CONVERSATION_ID:-}}}}"

# Safe session purger with strict boundary enforcement
cleanup_session() {
  local target_session="${1:-}"

  if [[ -n "$target_session" ]]; then
    # Sanitize session name: prevent directory traversal attacks
    local sanitized_session
    sanitized_session=$(printf "%s" "$target_session" | tr -cd 'a-zA-Z0-9_-')

    if [[ -n "$sanitized_session" && "$sanitized_session" != "." && "$sanitized_session" != ".." ]]; then
      local session_dir="/tmp/pas-read-cache-${sanitized_session}"
      [[ -d "$session_dir" && "$session_dir" =~ ^/tmp/pas-read-cache-[a-zA-Z0-9_-]+$ ]] && rm -rf "$session_dir"
    fi
  fi

  # Global stale cache sweeper: purge orphaned session caches older than 24 hours
  find /tmp -maxdepth 1 -type d -name "pas-read-cache-*" -mmin +1440 -exec rm -rf {} + 2>/dev/null || true
}

main() {
  local input=""
  [[ ! -t 0 ]] && input=$(cat)

  local payload_session=""
  if [[ -n "$input" ]]; then
    payload_session=$(printf "%s" "$input" | jq -r '.session_id // .sessionId // .conversation_id // ""' 2>/dev/null || true)
  fi

  local session_to_clean="${payload_session:-$SESSION_ID}"
  cleanup_session "$session_to_clean"

  printf '{"decision":"allow"}\n'
}

main "$@"
