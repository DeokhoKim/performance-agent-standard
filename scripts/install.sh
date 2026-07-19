#!/bin/bash
set -euo pipefail

# This script installs compiled rules and hooks globally to user settings directories.

NC='\033[0m'

BASE_DIR=${BASE_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}
PROVIDER=${PROVIDER:-"all"}

log_info() {
  local green='\033[0;32m'
  printf "%b[INFO]%b %s\n" "$green" "$NC" "$1"
}

log_error() {
  local red='\033[0;31m'
  printf "%b[ERROR]%b %s\n" "$red" "$NC" "$1" >&2
}

print_usage() {
  printf "Usage: %s [options]\n" "$0"
  printf "Options:\n"
  printf "  --provider <name>         Limit installation to a specific provider (gemini, claude, codex, all)\n"
  printf "  -h, --help                Show this help message\n"
}

# Parse command line options
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --provider)
      [[ -z "${2:-}" ]] && { log_error "Missing provider name."; print_usage; exit 1; }
      PROVIDER="${2:-}"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      print_usage
      exit 1
      ;;
  esac
done

install_gemini() {
  local dest_plugin="${HOME}/.gemini/antigravity-cli/plugins/performance-agent-standards"

  log_info "Installing Gemini / Antigravity globally to isolated plugin dir: $dest_plugin"
  mkdir -p "$dest_plugin"

  # Copy plugin files recursively (rules are isolated inside the plugin directory)
  cp -r "${BASE_DIR}/dist/gemini"/* "$dest_plugin/"
  chmod +x "$dest_plugin/scripts"/*.sh

  # Replace relative path with absolute plugin path in hooks.json
  sed -i "s|\"./scripts/validate-markdown.sh\"|\"$dest_plugin/scripts/validate-markdown.sh\"|g" "$dest_plugin/hooks.json"
  sed -i "s|\"./scripts/validate-format.sh\"|\"$dest_plugin/scripts/validate-format.sh\"|g" "$dest_plugin/hooks.json"

  # Register the plugin with the Antigravity CLI if available
  command -v agy &>/dev/null || { log_info "Antigravity CLI (agy) not found in PATH, skipping CLI registration."; return 0; }
  log_info "Registering plugin with Antigravity CLI..."
  agy plugin install "$dest_plugin"
}

install_claude() {
  local dest_dir="${HOME}/.claude"
  local dest_plugin="${dest_dir}/plugins/performance-agent-standards"

  log_info "Installing Claude Code globally to isolated plugin dir: $dest_plugin"
  mkdir -p "$dest_plugin"
  mkdir -p "$dest_dir/rules"

  # Copy plugin files recursively (keeps ~/.claude clean)
  cp -r "${BASE_DIR}/dist/claude/.claude" "$dest_plugin/"
  cp -r "${BASE_DIR}/dist/claude/scripts" "$dest_plugin/"
  chmod +x "$dest_plugin/scripts"/*.sh

  # Programmatically merge CLAUDE.md instead of overwriting global file (SOLID & Safe)
  if [[ -f "$dest_dir/CLAUDE.md" ]]; then
    log_info "Appending rules to existing global CLAUDE.md..."
    {
      printf "\n\n# --- performance-agent-standards rules begin ---\n"
      cat "${BASE_DIR}/dist/claude/CLAUDE.md"
      printf "\n# --- performance-agent-standards rules end ---\n"
    } >> "$dest_dir/CLAUDE.md"
  else
    cp "${BASE_DIR}/dist/claude/CLAUDE.md" "$dest_dir/CLAUDE.md"
  fi

  cp "${BASE_DIR}/dist/claude/.claude/rules"/*.md "$dest_dir/rules/"

  # Programmatically merge hooks instead of overwriting global settings.json (SOLID & Safe)
  if [[ -f "$dest_dir/settings.json" ]]; then
    log_info "Merging hooks into existing global settings.json..."
    local temp_json
    temp_json=$(mktemp)
    jq --arg cmd1 "$dest_plugin/scripts/validate-markdown.sh" \
       --arg cmd2 "$dest_plugin/scripts/validate-format.sh" '
      .hooks.PostToolUse = (.hooks.PostToolUse // []) + [{
        "matcher": "Write|Edit|Create",
        "hooks": [
          {
            "type": "command",
            "command": $cmd1
          },
          {
            "type": "command",
            "command": $cmd2
          }
        ]
      }]
    ' "$dest_dir/settings.json" > "$temp_json"
    mv "$temp_json" "$dest_dir/settings.json"
  else
    # If settings.json does not exist, copy from plugin and rewrite paths
    cp "${BASE_DIR}/dist/claude/.claude/settings.json" "$dest_dir/settings.json"
    sed -i "s|\"./scripts/validate-markdown.sh\"|\"$dest_plugin/scripts/validate-markdown.sh\"|g" "$dest_dir/settings.json"
    sed -i "s|\"./scripts/validate-format.sh\"|\"$dest_plugin/scripts/validate-format.sh\"|g" "$dest_dir/settings.json"
  fi
}

install_codex() {
  local dest_dir="${HOME}/.codex"
  local dest_plugin="${dest_dir}/plugins/performance-agent-standards"

  log_info "Installing Codex globally to isolated plugin dir: $dest_plugin"
  mkdir -p "$dest_plugin"

  # Copy plugin files recursively
  cp -r "${BASE_DIR}/dist/codex/.codex"/* "$dest_plugin/"
  cp -r "${BASE_DIR}/dist/codex/scripts" "$dest_plugin/"
  chmod +x "$dest_plugin/scripts"/*.sh

  # Deploy AGENTS.md to global config
  if [[ -f "$dest_dir/AGENTS.md" ]]; then
    log_info "Appending rules to existing global AGENTS.md..."
    {
      printf "\n\n# --- performance-agent-standards rules begin ---\n"
      cat "${BASE_DIR}/dist/codex/AGENTS.md"
      printf "\n# --- performance-agent-standards rules end ---\n"
    } >> "$dest_dir/AGENTS.md"
  else
    cp "${BASE_DIR}/dist/codex/AGENTS.md" "$dest_dir/AGENTS.md"
  fi

  # Merge hooks into global settings.json
  if [[ -f "$dest_dir/settings.json" ]]; then
    log_info "Merging hooks into existing global settings.json..."
    local temp_json
    temp_json=$(mktemp)
    jq --arg cmd1 "$dest_plugin/scripts/validate-markdown.sh" \
       --arg cmd2 "$dest_plugin/scripts/validate-format.sh" '
      .hooks.PostToolUse = (.hooks.PostToolUse // []) + [{
        "matcher": "Write|Edit|Create",
        "hooks": [
          {
            "type": "command",
            "command": $cmd1
          },
          {
            "type": "command",
            "command": $cmd2
          }
        ]
      }]
    ' "$dest_dir/settings.json" > "$temp_json"
    mv "$temp_json" "$dest_dir/settings.json"
  else
    cp "${BASE_DIR}/dist/codex/.codex/settings.json" "$dest_dir/settings.json"
    sed -i "s|\"./scripts/validate-markdown.sh\"|\"$dest_plugin/scripts/validate-markdown.sh\"|g" "$dest_dir/settings.json"
    sed -i "s|\"./scripts/validate-format.sh\"|\"$dest_plugin/scripts/validate-format.sh\"|g" "$dest_dir/settings.json"
  fi
}

# Verify dist directory exists before installing
[[ ! -d "$BASE_DIR/dist" ]] && { log_error "dist directory not found. Please run scripts/compile.sh first."; exit 1; }

# Execute installation
case "$PROVIDER" in
  gemini)
    install_gemini
    ;;
  claude)
    install_claude
    ;;
  codex)
    install_codex
    ;;
  all)
    install_gemini
    install_claude
    install_codex
    ;;
  *)
    log_error "Unsupported provider: $PROVIDER"
    exit 1
    ;;
esac

log_info "Installation completed successfully."
