#!/bin/bash
set -euo pipefail

# Runs prek (pre-commit) format checks after file modifications.
# Triggered as a PostToolUse hook by Gemini (Antigravity) or Claude Code.

# --- Constants ---
NC='\033[0m'
MAX_LOG_LINES=10

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# --- Functions (Single Responsibility) ---

log_warn() {
  local yellow='\033[1;33m'
  printf "%b[WARN]%b %s\n" "$yellow" "$NC" "$1" >&2
}

log_error() {
  local red='\033[0;31m'
  printf "%b[ERROR]%b %s\n" "$red" "$NC" "$1" >&2
}

# Reads stdin and delegates to the shared parser utility.
# Sets global: WORKSPACE_PATH, TARGET_FILE
parse_input() {
  local json_input=""
  [[ ! -t 0 ]] && json_input=$(cat)

  local parsed
  mapfile -t parsed < <(printf "%s" "$json_input" | "${SCRIPT_DIR}/../shared/parse-hook-input.sh")
  WORKSPACE_PATH="${parsed[0]:-}"
  TARGET_FILE="${parsed[1]:-}"
}

# Resolves the git repository root from workspace path or cwd.
# Sets global: REPO_ROOT. Returns 1 if not in a git repo.
resolve_repo_root() {
  REPO_ROOT=""
  [[ -n "$WORKSPACE_PATH" && -d "$WORKSPACE_PATH" ]] && REPO_ROOT=$(git -C "$WORKSPACE_PATH" rev-parse --show-toplevel 2>/dev/null || true)
  [[ -z "$REPO_ROOT" ]] && REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
  [[ -n "$REPO_ROOT" ]]
}

# Returns 0 if prek can be run (venv, config, and binary all present).
# Sets global: PREK_BIN
is_prek_available() {
  [[ -d "${REPO_ROOT}/.venv" ]] || return 1
  [[ -f "${REPO_ROOT}/.pre-commit-config.yaml" || -f "${REPO_ROOT}/prek.toml" ]] || return 1

  PREK_BIN="${REPO_ROOT}/.venv/bin/prek"
  [[ -x "$PREK_BIN" ]] || {
    log_warn "prek not installed in .venv — run uv sync or pip install prek"
    return 1
  }
}

# Runs prek on target file or staged files, truncating logs for token savings.
run_prek() {
  cd "$REPO_ROOT"

  local log_output=""
  local exit_code=0

  local target_args=()
  [[ -n "$TARGET_FILE" && -f "$TARGET_FILE" ]] && target_args=("--files" "$TARGET_FILE")

  log_output=$("$PREK_BIN" run "${target_args[@]}" --color=never 2>&1) || exit_code=$?

  [[ "$exit_code" -eq 0 ]] && return 0

  local err_msg="prek validation failed"
  [[ -n "$TARGET_FILE" ]] && err_msg="$err_msg for: $TARGET_FILE"
  log_error "$err_msg"

  printf "%s\n" "$log_output" | head -n "$MAX_LOG_LINES" >&2
  [[ $(printf "%s\n" "$log_output" | wc -l) -gt $MAX_LOG_LINES ]] && \
    log_warn "... logs truncated to save agent token consumption."
}

# Outputs the allow decision for the hook framework.
allow() {
  printf '{"decision": "allow"}\n'
}

# --- Main ---

WORKSPACE_PATH=""
TARGET_FILE=""
REPO_ROOT=""
PREK_BIN=""

parse_input
resolve_repo_root || { allow; exit 0; }
is_prek_available  || { allow; exit 0; }
run_prek
allow
