#!/bin/bash
set -euo pipefail

# Validates that markdown files conform to HDMD rules (frontmatter + topic index).
# Triggered as a PostToolUse hook by Gemini (Antigravity) or Claude Code.

NC='\033[0m'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# --- Functions (Single Responsibility) ---

log_info() {
  local green='\033[0;32m'
  printf "%b[INFO]%b %s\n" "$green" "$NC" "$1"
}

log_error() {
  local red='\033[0;31m'
  printf "%b[ERROR]%b %s\n" "$red" "$NC" "$1" >&2
}

# Reads stdin and delegates to the shared parser utility.
# Sets global: WORKSPACE_PATH, FILE_PATH
parse_input() {
  local json_input=""
  [[ ! -t 0 ]] && json_input=$(cat)

  local parsed
  mapfile -t parsed < <(printf "%s" "$json_input" | "${SCRIPT_DIR}/parse-hook-input.sh")
  # parsed[0] (workspace path) is not used in this script
  FILE_PATH="${parsed[1]:-}"
}

# Returns 0 if the file is a valid markdown target, 1 otherwise.
is_valid_target() {
  [[ -n "$FILE_PATH" ]] && [[ "$FILE_PATH" == *.md ]] && [[ -f "$FILE_PATH" ]]
}

# Returns 0 if the file contains inline topic tags (e.g., #topic),
# excluding markdown headers (lines starting with '#+ ').
has_inline_topic_tags() {
  grep -q -vE '^#+ ' "$FILE_PATH" \
    && grep -qE '(^|[[:space:]])#[a-zA-Z][a-zA-Z0-9_-]*' "$FILE_PATH"
}

# Validates that a file with topic tags has proper YAML frontmatter
# containing a 'topics:' index key.
validate_frontmatter() {
  local first_line
  first_line=$(head -n 1 "$FILE_PATH")
  [[ "$first_line" != "---" ]] && {
    log_error "File '$FILE_PATH' has inline topic tags but missing YAML frontmatter ('---')."
    return 1
  }

  local frontmatter
  frontmatter=$(sed -n '2,/^---$/p' "$FILE_PATH" | grep -v '^---$')
  ! printf "%s\n" "$frontmatter" | grep -q "^topics:" && {
    log_error "File '$FILE_PATH' has frontmatter but missing 'topics:' index key."
    return 1
  }

  log_info "Markdown validation passed: '$FILE_PATH'"
}

# --- Main ---

FILE_PATH=""

parse_input

is_valid_target || exit 0
has_inline_topic_tags || exit 0
validate_frontmatter
