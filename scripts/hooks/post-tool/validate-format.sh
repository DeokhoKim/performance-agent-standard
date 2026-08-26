#!/usr/bin/env bash
# ---
# purpose: PostToolUse hook to run prek format validation on modified files.
# ---

set -euo pipefail

NC='\033[0m'
MAX_LOG_LINES=${MAX_LOG_LINES:-10}

log_warn() {
  local yellow='\033[1;33m'
  printf "%b[WARN]%b %s\n" "$yellow" "$NC" "$1" >&2
}

log_error() {
  local red='\033[0;31m'
  printf "%b[ERROR]%b %s\n" "$red" "$NC" "$1" >&2
}

# Resolves git repository root from workspace path.
resolve_repo_root() {
  local workspace_path="$1"
  [[ -n "$workspace_path" && -d "$workspace_path" ]] && {
    git -C "$workspace_path" rev-parse --show-toplevel 2>/dev/null || true
    return 0
  }
  git rev-parse --show-toplevel 2>/dev/null || true
}

# Checks if prek binary and configuration are available in the repository.
get_prek_bin() {
  local repo_root="$1"
  [[ -d "${repo_root}/.venv" ]] || return 1
  [[ -f "${repo_root}/.pre-commit-config.yaml" || -f "${repo_root}/prek.toml" ]] || return 1

  local prek_bin="${repo_root}/.venv/bin/prek"
  [[ -x "$prek_bin" ]] && { printf "%s" "$prek_bin"; return 0; }

  log_warn "prek not installed in .venv — run uv sync or pip install prek"
  return 1
}

# Runs prek using a scoped subshell to avoid polluting caller shell state.
run_prek() {
  local repo_root="$1"
  local prek_bin="$2"
  local target_file="$3"

  local target_args=()
  [[ -n "$target_file" && -f "$target_file" ]] && target_args=("--files" "$target_file")

  local log_output=""
  local exit_code=0

  log_output=$(
    cd "$repo_root"
    "$prek_bin" run "${target_args[@]}" --color=never 2>&1
  ) || exit_code=$?

  [[ "$exit_code" -eq 0 ]] && return 0

  local err_msg="prek validation failed"
  [[ -n "$target_file" ]] && err_msg="$err_msg for: $target_file"
  log_error "$err_msg"

  printf "%s\n" "$log_output" | head -n "$MAX_LOG_LINES" >&2
  [[ $(printf "%s\n" "$log_output" | wc -l) -gt $MAX_LOG_LINES ]] && \
    log_warn "... logs truncated to save agent token consumption."
}

main() {
  local script_dir
  script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

  local json_input=""
  [[ ! -t 0 ]] && json_input=$(cat)

  local parsed
  mapfile -t parsed < <(printf "%s" "$json_input" | bash "${script_dir}/../shared/parse-hook-input.sh")
  local workspace_path="${parsed[0]:-}"
  local target_file="${parsed[1]:-}"

  local repo_root
  repo_root=$(resolve_repo_root "$workspace_path")
  [[ -z "$repo_root" ]] && { printf '{"decision": "allow"}\n'; return 0; }

  local prek_bin
  if prek_bin=$(get_prek_bin "$repo_root"); then
    run_prek "$repo_root" "$prek_bin" "$target_file"
  fi

  printf '{"decision": "allow"}\n'
}

main "$@"
