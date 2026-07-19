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

log_warn() {
  local yellow='\033[1;33m'
  printf "%b[WARN]%b %s\n" "$yellow" "$NC" "$1"
}

log_error() {
  local red='\033[0;31m'
  printf "%b[ERROR]%b %s\n" "$red" "$NC" "$1" >&2
}

print_usage() {
  printf "Usage: %s [options]\n" "$0"
  printf "Options:\n"
  printf "  --provider <name>         Limit installation to a specific provider (antigravity, gemini, claude, codex, all)\n"
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

install_antigravity() {
  local dest_plugin="${HOME}/.gemini/antigravity-cli/plugins/performance-agent-standards"
  local src_dir="${BASE_DIR}/dist/antigravity"

  log_info "Installing Antigravity globally to isolated plugin dir: $dest_plugin"
  mkdir -p "$dest_plugin"

  # Copy plugin files recursively (rules are isolated inside the plugin directory)
  cp -r "$src_dir"/* "$dest_plugin/"
  chmod +x "$dest_plugin/scripts"/*.sh
  if [[ -d "$dest_plugin/skills" ]]; then
    find "$dest_plugin/skills" -type f -name "*.sh" -exec chmod +x {} +
  fi

  # Register the plugin with the Antigravity CLI if available
  if command -v agy &>/dev/null; then
    log_info "Registering plugin with Antigravity CLI (agy)..."
    agy plugin install "$dest_plugin"
  else
    log_info "Antigravity CLI (agy) not found in PATH, skipping registration."
  fi
}

install_gemini() {
  local dest_plugin="${HOME}/.gemini/plugins/performance-agent-standards"
  local src_dir="${BASE_DIR}/dist/gemini"

  # Warn if modern agy is already installed to prevent confusion
  if [[ -d "${HOME}/.gemini/antigravity-cli" || -n "$(command -v agy)" ]]; then
    log_warn "Modern Antigravity CLI (agy) appears to be installed on this system. You are about to install the legacy 'gemini' plugin. If you meant to install the modern plugin, please cancel and run with --provider antigravity instead."
  fi

  log_info "Installing Legacy Gemini globally to isolated plugin dir: $dest_plugin"
  mkdir -p "$dest_plugin"

  # Copy plugin files recursively (rules are isolated inside the plugin directory)
  cp -r "$src_dir"/* "$dest_plugin/"
  chmod +x "$dest_plugin/scripts"/*.sh
  if [[ -d "$dest_plugin/skills" ]]; then
    find "$dest_plugin/skills" -type f -name "*.sh" -exec chmod +x {} +
  fi

  # Register the plugin with the Gemini CLI if available
  if command -v gemini &>/dev/null; then
    log_info "Registering plugin with Gemini CLI..."
    gemini plugin install "$dest_plugin"
  else
    log_info "Gemini CLI not found in PATH, skipping registration."
  fi
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
    # If settings.json does not exist, copy from plugin
    cp "${BASE_DIR}/dist/claude/.claude/settings.json" "$dest_dir/settings.json"
  fi

  if [[ -d "${BASE_DIR}/dist/claude/.claude/skills" ]]; then
    mkdir -p "${dest_dir}/skills"
    cp -r "${BASE_DIR}/dist/claude/.claude/skills"/* "${dest_dir}/skills/"
    find "${dest_dir}/skills" -type f -name "*.sh" -exec chmod +x {} +
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
    # If settings.json does not exist, copy from plugin
    cp "${BASE_DIR}/dist/codex/.codex/settings.json" "$dest_dir/settings.json"
  fi

  if [[ -d "${BASE_DIR}/dist/codex/.codex/skills" ]]; then
    mkdir -p "${dest_dir}/skills"
    cp -r "${BASE_DIR}/dist/codex/.codex/skills"/* "${dest_dir}/skills/"
    find "${dest_dir}/skills" -type f -name "*.sh" -exec chmod +x {} +
  fi


}

# Verify dist directory exists before installing
[[ ! -d "$BASE_DIR/dist" ]] && { log_error "dist directory not found. Please run scripts/compile.sh first."; exit 1; }

# Execute installation
case "$PROVIDER" in
  antigravity)
    install_antigravity
    ;;
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
    # Detect which Gemini/Antigravity flavor to install based on CLI command presence
    if command -v agy &>/dev/null; then
      install_antigravity
    elif command -v gemini &>/dev/null; then
      install_gemini
    else
      # Default fallback to modern Antigravity
      install_antigravity
    fi
    install_claude
    install_codex
    ;;
  *)
    log_error "Unsupported provider: $PROVIDER"
    exit 1
    ;;
esac

log_info "Installation completed successfully."
