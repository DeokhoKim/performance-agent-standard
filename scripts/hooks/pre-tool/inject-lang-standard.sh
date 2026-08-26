#!/bin/bash
set -euo pipefail

# This script is a PreToolUse hook that injects language standards based on the file extension.
# It uses the shared parse-hook-input.sh to extract TARGET_FILE.

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
RULES_DIR="${SCRIPT_DIR}/../../rules"

TARGET_FILE=""

parse_input() {
  local json_input=""
  [[ ! -t 0 ]] && json_input=$(cat)

  local parsed
  mapfile -t parsed < <(printf "%s" "$json_input" | "${SCRIPT_DIR}/../shared/parse-hook-input.sh")
  TARGET_FILE="${parsed[1]:-}"
}

inject_standards() {
  [[ -z "$TARGET_FILE" ]] && { printf '{"decision": "allow"}\n'; return; }

  local filename
  filename=$(basename "$TARGET_FILE")
  local ext="${filename##*.}"
  local standards=""

  # 1. Common Standards
  case "$ext" in
    rs|cpp|cc|c|hpp|h|sh|bash|py)
      standards+=$(cat "${RULES_DIR}/03-lang-standard-common.md")$'\n\n'
      ;;
  esac

  # 2. Native Standards
  case "$ext" in
    rs|cpp|cc|c|hpp|h)
      standards+=$(cat "${RULES_DIR}/04-lang-standard-native.md")$'\n\n'
      ;;
  esac

  # 3. Language-Specific Standards
  case "$ext" in
    rs)
      standards+=$(cat "${RULES_DIR}/05-lang-standard-rust.md")$'\n\n'
      ;;
    sh|bash)
      standards+=$(cat "${RULES_DIR}/06-lang-standard-bash.md")$'\n\n'
      ;;
    py)
      standards+=$(cat "${RULES_DIR}/09-lang-standard-python.md")$'\n\n'
      ;;
    md)
      standards+=$(cat "${RULES_DIR}/07-markdown-writing.md")$'\n\n'
      ;;
  esac

  [[ -z "$standards" ]] && { printf '{"decision": "allow"}\n'; return; }

  local escaped_msg
  escaped_msg=$(printf "Language Standards Injected:\n\n%s" "$standards" | jq -Rsa .)
  printf '{"decision": "allow", "message": %s}\n' "$escaped_msg"
}

parse_input
inject_standards
