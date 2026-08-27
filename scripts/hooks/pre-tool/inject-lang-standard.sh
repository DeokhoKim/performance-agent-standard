#!/usr/bin/env bash
# ---
# purpose: PreToolUse hook that dynamically injects relevant coding standards into agent context.
# ---

set -euo pipefail

# Resolves rules directory across distribution layouts and source development tree.
resolve_rules_dir() {
  local plugin_root="$1"
  local candidate
  for candidate in \
    "${plugin_root}/rules" \
    "${plugin_root}/.claude/rules" \
    "${plugin_root}/.codex/rules" \
    "${plugin_root}/providers/shared/rules"; do
    [[ -d "$candidate" ]] && { printf "%s" "$candidate"; return 0; }
  done
}

# Finds and reads rule markdown file contents regardless of numeric or category prefixes.
read_rule() {
  local rules_dir="$1"
  local rule_name="$2"
  [[ -z "$rules_dir" || ! -d "$rules_dir" ]] && return 0

  local file
  file=$(find "$rules_dir" -maxdepth 1 -name "*${rule_name}.md" -print -quit 2>/dev/null)
  [[ -n "$file" && -f "$file" ]] && cat "$file"
}

# Declarative file extension to rule mapping (Open-Closed Principle).
get_rules_for_ext() {
  local ext="$1"
  case "$ext" in
    rs)
      printf "%s\n" "code-simplicity" "lang-standard-common" "lang-standard-native" "lang-standard-rust"
      ;;
    cpp|cc|c|hpp|h)
      printf "%s\n" "code-simplicity" "lang-standard-common" "lang-standard-native"
      ;;
    sh|bash)
      printf "%s\n" "code-simplicity" "lang-standard-common" "lang-standard-bash"
      ;;
    py)
      printf "%s\n" "code-simplicity" "lang-standard-common" "lang-standard-python"
      ;;
    md|mdc)
      printf "%s\n" "markdown-writing"
      ;;
  esac
}

# Collects all concatenated standard bodies for a given target file.
collect_standards() {
  local target_file="$1"
  local rules_dir="$2"
  [[ -z "$target_file" || -z "$rules_dir" ]] && return 0

  local filename
  filename=$(basename "$target_file")
  local ext="${filename##*.}"

  local rule_names
  mapfile -t rule_names < <(get_rules_for_ext "$ext")
  [[ ${#rule_names[@]} -eq 0 ]] && return 0

  local standards=""
  for name in "${rule_names[@]}"; do
    local content
    content=$(read_rule "$rules_dir" "$name")
    [[ -n "$content" ]] && standards+="${content}"$'\n\n'
  done

  printf "%s" "$standards"
}

main() {
  local script_dir
  script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
  local plugin_root
  plugin_root=$(cd -- "${script_dir}/../../.." &> /dev/null && pwd)

  local json_input=""
  [[ ! -t 0 ]] && json_input=$(cat)

  local parsed
  mapfile -t parsed < <(printf "%s" "$json_input" | bash "${script_dir}/../shared/parse-hook-input.sh")
  local target_file="${parsed[1]:-}"

  [[ -z "$target_file" ]] && { printf '{"decision": "allow"}\n'; return 0; }

  local rules_dir
  rules_dir=$(resolve_rules_dir "$plugin_root")

  local standards
  standards=$(collect_standards "$target_file" "$rules_dir")

  [[ -z "$standards" ]] && { printf '{"decision": "allow"}\n'; return 0; }

  local escaped_msg
  escaped_msg=$(printf "Language Standards Injected:\n\n%s" "$standards" | jq -Rsa .)
  printf '{"decision": "allow", "message": %s}\n' "$escaped_msg"
}

main "$@"
