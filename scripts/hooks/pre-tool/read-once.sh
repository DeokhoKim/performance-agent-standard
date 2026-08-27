#!/usr/bin/env bash
# ---
# purpose: Unix-optimized PreToolUse hook intercepting redundant file reads, computing diffs, and isolating subagent caches.
# ---

set -euo pipefail

# Configuration parameters with intelligent runtime defaults
SESSION_ID="${PAS_SESSION_ID:-${CLAUDE_SESSION_ID:-${GEMINI_SESSION_ID:-${CONVERSATION_ID:-default}}}}"
READ_ONCE_DISABLED="${READ_ONCE_DISABLED:-0}"
READ_ONCE_DIFF="${READ_ONCE_DIFF:-1}"
READ_ONCE_DIFF_MAX="${READ_ONCE_DIFF_MAX:-40}"
READ_ONCE_TTL="${READ_ONCE_TTL:-1200}"

# Emits dual-schema rejection compatible with Claude Code v0.11+ and universal JSON hook consumers.
emit_rejection() {
  local reason="${1:-}"
  local escaped_reason
  escaped_reason=$(printf "%s" "$reason" | jq -Rs .)
  printf '{"decision":"reject","message":%s,"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$escaped_reason" "$escaped_reason"
  exit 0
}

# Multi-platform fast hashing cascade (sha256 -> shasum -> md5sum -> md5 -> cksum)
hash_identifier() {
  local input="${1:-}"
  if command -v sha256sum >/dev/null 2>&1; then
    printf "%s" "$input" | sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    printf "%s" "$input" | shasum -a 256 | awk '{print $1}'
  elif command -v md5sum >/dev/null 2>&1; then
    printf "%s" "$input" | md5sum | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then
    printf "%s" "$input" | md5 -q
  else
    printf "%s" "$input" | cksum | awk '{print $1}'
  fi
}

# Multi-platform file modification timestamp extraction (Linux stat -c, macOS stat -f, date -r)
get_file_mtime() {
  local target="${1:-}"
  stat -c %Y "$target" 2>/dev/null || stat -f %m "$target" 2>/dev/null || date -r "$target" +%s 2>/dev/null || date +%s
}

# Slice geometry evaluation: verifies if requested range is fully satisfied by cached range
is_slice_satisfied() {
  local req_start="${1:-}"
  local req_end="${2:-}"
  local cached_start="${3:-}"
  local cached_end="${4:-}"

  # If cached read was the entire file (empty start and end), any slice is satisfied
  [[ -z "$cached_start" && -z "$cached_end" ]] && return 0

  # If cached read was a slice, requested slice must fit inside cached bounds
  if [[ -n "$cached_start" && -n "$req_start" ]]; then
    if (( req_start >= cached_start )); then
      [[ -z "$cached_end" ]] && return 0
      [[ -n "$req_end" ]] && (( req_end <= cached_end )) && return 0
    fi
  fi

  return 1
}

# Atomic file update to prevent race conditions during concurrent subagent tool calls
atomic_write_meta() {
  local target_meta="${1:-}"
  local mtime="${2:-}"
  local now="${3:-}"
  local start="${4:-}"
  local end="${5:-}"
  local tmp_file="${target_meta}.tmp.$$"
  trap 'rm -f "${tmp_file:-}" 2>/dev/null || true' EXIT
  printf "%s\n%s\n%s\n%s\n" "$mtime" "$now" "$start" "$end" > "$tmp_file"
  mv -f "$tmp_file" "$target_meta"
}

# Atomic snapshot copy with trap cleanup
atomic_copy_snapshot() {
  local src="${1:-}"
  local dst="${2:-}"
  local tmp_file="${dst}.tmp.$$"
  trap 'rm -f "${tmp_file:-}" 2>/dev/null || true' EXIT
  cp "$src" "$tmp_file" 2>/dev/null && mv -f "$tmp_file" "$dst"
}

evaluate_read() {
  local file_path="${1:-}"
  local start_line="${2:-}"
  local end_line="${3:-}"
  local subagent_id="${4:-}"
  local parent_agent_id="${5:-}"
  local is_subagent="${6:-false}"
  local workspace_mode="${7:-inherit}"
  local payload_session="${8:-}"

  [[ -z "$file_path" || "$READ_ONCE_DISABLED" == "1" ]] && return 0
  [[ ! -f "$file_path" ]] && return 0

  # Subagent Fail-Safe: If running in an isolated subagent without inherited context, bypass caching
  [[ "$is_subagent" == "true" && -z "$subagent_id" && "$workspace_mode" == "branch" ]] && return 0

  local canonical_path
  canonical_path=$(realpath "$file_path" 2>/dev/null || printf "%s" "$file_path")
  local path_hash
  path_hash=$(hash_identifier "$canonical_path")

  # Dynamic Partitioning: compute agent cache directory hierarchy
  local agent_namespace="main"
  if [[ -n "$subagent_id" ]]; then
    if [[ -n "$parent_agent_id" ]]; then
      agent_namespace="${parent_agent_id}/${subagent_id}"
    else
      agent_namespace="subagents/${subagent_id}"
    fi
  fi

  local raw_session="${payload_session:-$SESSION_ID}"
  local safe_session
  safe_session=$(printf "%s" "$raw_session" | tr -cd 'a-zA-Z0-9_-')
  [[ -z "$safe_session" ]] && safe_session="default"

  local session_cache_dir="/tmp/pas-read-cache-${safe_session}/${agent_namespace}"
  local meta_file="${session_cache_dir}/${path_hash}.meta"
  local snapshot_file="${session_cache_dir}/${path_hash}.snapshot"

  mkdir -p "$session_cache_dir"

  local current_mtime
  current_mtime=$(get_file_mtime "$canonical_path")
  local now
  now=$(date +%s)

  if [[ -f "$meta_file" && -f "$snapshot_file" ]]; then
    local cached_mtime="" cached_time="" cached_start="" cached_end=""
    local meta_lines=()
    mapfile -t meta_lines < "$meta_file" 2>/dev/null || true
    cached_mtime="${meta_lines[0]:-}"
    cached_time="${meta_lines[1]:-0}"
    cached_start="${meta_lines[2]:-}"
    cached_end="${meta_lines[3]:-}"

    # Check TTL expiration
    if (( now - cached_time < READ_ONCE_TTL )); then
      # Check if file has remained unchanged
      if [[ "$current_mtime" == "$cached_mtime" ]]; then
        # Check slice geometry coverage
        if is_slice_satisfied "$start_line" "$end_line" "$cached_start" "$cached_end"; then
          emit_rejection "[read-once] File already read: ${file_path}. Content is in active context."
        fi
      elif [[ "$READ_ONCE_DIFF" == "1" ]]; then
        # File modified: compute compact unified diff
        local diff_output
        diff_output=$(diff -u "$snapshot_file" "$canonical_path" 2>/dev/null || true)
        local diff_lines
        diff_lines=$(printf "%s\n" "$diff_output" | wc -l)

        if [[ -n "$diff_output" ]] && (( diff_lines <= READ_ONCE_DIFF_MAX )); then
          # Atomic snapshot & metadata update
          atomic_copy_snapshot "$canonical_path" "$snapshot_file"
          atomic_write_meta "$meta_file" "$current_mtime" "$now" "$start_line" "$end_line"
          emit_rejection "[read-once] File modified since last read. Incremental diff:\n${diff_output}"
        fi
      fi
    fi
  fi

  # Record initial snapshot & metadata
  atomic_copy_snapshot "$canonical_path" "$snapshot_file"
  atomic_write_meta "$meta_file" "$current_mtime" "$now" "$start_line" "$end_line"
}

main() {
  local input=""
  [[ ! -t 0 ]] && input=$(cat)
  [[ -z "$input" ]] && { printf '{"decision":"allow"}\n'; exit 0; }

  local parsed_fields=()
  mapfile -t parsed_fields < <(printf "%s" "$input" | jq -r '
    def get_val(o; k1; k2; k3; k4):
      o[k1] // o[k2] // o[k3] // o[k4] // "";

    (if .tool_input != null then
      if (.tool_input | type == "string") then {file: .tool_input} else .tool_input end
    elif (.toolCall != null or .arguments != null) then
      ((.toolCall.arguments // .arguments // {}) | if type == "string" then (fromjson? // {}) else . end)
    else . end) as $args |

    [
      (get_val($args; "AbsolutePath"; "TargetFile"; "file_path"; "path")),
      (get_val($args; "StartLine"; "start_line"; "offset"; "") | tostring),
      (get_val($args; "EndLine"; "end_line"; "limit"; "") | tostring),
      (.subagent_id // .subagentId // .conversationId // .conversation_id // ""),
      (.parent_agent_id // .parentAgentId // ""),
      (.is_subagent // .isSubagent // false | tostring),
      (.workspace_mode // .workspace // "inherit" | tostring),
      (.session_id // .sessionId // .conversation_id // "")
    ][]
  ' 2>/dev/null || true)

  local file_path="${parsed_fields[0]:-}"
  local start_line="${parsed_fields[1]:-}"
  local end_line="${parsed_fields[2]:-}"
  local subagent_id="${parsed_fields[3]:-}"
  local parent_agent_id="${parsed_fields[4]:-}"
  local is_subagent="${parsed_fields[5]:-false}"
  local workspace_mode="${parsed_fields[6]:-inherit}"
  local payload_session="${parsed_fields[7]:-}"

  evaluate_read "$file_path" "$start_line" "$end_line" "$subagent_id" "$parent_agent_id" "$is_subagent" "$workspace_mode" "$payload_session"

  printf '{"decision":"allow"}\n'
}

main "$@"
