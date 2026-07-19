#!/bin/bash
set -euo pipefail

# This script installs compiled rules and hooks globally or locally.

# Standard log colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BASE_DIR=${BASE_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}
MODE=${MODE:-""}
PROVIDER=${PROVIDER:-"all"}
TARGET_PATH=${TARGET_PATH:-""}

print_usage() {
  printf "Usage: %s [options]\n" "$0"
  printf "Options:\n"
  printf "  --global                  Install globally to user settings directories\n"
  printf "  --local <target-path>     Install locally to a target project path\n"
  printf "  --provider <name>         Limit installation to a specific provider (gemini, claude, codex, all)\n"
  printf "  -h, --help                Show this help message\n"
}

# Parse command line options
[[ "$#" -lt 1 ]] && { print_usage; exit 1; }

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --global)
      MODE="global"
      shift
      ;;
    --local)
      MODE="local"
      [[ -z "${2:-}" ]] && { printf "${RED}[ERROR]${NC} Missing target path for --local.\n" >&2; print_usage; exit 1; }
      TARGET_PATH="${2:-}"
      shift 2
      ;;
    --provider)
      [[ -z "${2:-}" ]] && { printf "${RED}[ERROR]${NC} Missing provider name.\n" >&2; print_usage; exit 1; }
      PROVIDER="${2:-}"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      printf "${RED}[ERROR]${NC} Unknown option: %s\n" "$1" >&2
      print_usage
      exit 1
      ;;
  esac
done

# Ensure mode is selected
[[ -z "$MODE" ]] && { printf "${RED}[ERROR]${NC} Either --global or --local must be specified.\n" >&2; print_usage; exit 1; }

# Install function
install_gemini() {
  if [[ "$MODE" == "global" ]]; then
    local dest_plugin="${HOME}/.gemini/antigravity-cli/plugins/performance-agent-standards"

    printf "${GREEN}[INFO]${NC} Installing Gemini / Antigravity globally to isolated plugin dir: %s\n" "$dest_plugin"
    mkdir -p "$dest_plugin"

    # Copy plugin files recursively (rules are isolated inside the plugin directory)
    cp -r "${BASE_DIR}/dist/gemini"/* "$dest_plugin/"
    chmod +x "$dest_plugin/scripts"/*.sh

    # Replace relative path with absolute plugin path in hooks.json
    sed -i "s|\"./scripts/validate-markdown.sh\"|\"$dest_plugin/scripts/validate-markdown.sh\"|g" "$dest_plugin/hooks.json"
    sed -i "s|\"./scripts/validate-format.sh\"|\"$dest_plugin/scripts/validate-format.sh\"|g" "$dest_plugin/hooks.json"
  else
    local dest_plugin="${TARGET_PATH}/.agents/plugins/performance-agent-standards"
    local dest_rules="${TARGET_PATH}/.gemini/rules"

    printf "${GREEN}[INFO]${NC} Installing Gemini / Antigravity locally to workspace: %s\n" "$TARGET_PATH"
    mkdir -p "$dest_plugin"
    mkdir -p "$dest_rules"

    cp -r "${BASE_DIR}/dist/gemini"/* "$dest_plugin/"
    cp "${BASE_DIR}/dist/gemini/rules"/*.md "$dest_rules/"
    chmod +x "$dest_plugin/scripts"/*.sh

    # Replace relative path with workspace-relative path within plugin folder in hooks.json
    sed -i "s|\"./scripts/validate-markdown.sh\"|\"./.agents/plugins/performance-agent-standards/scripts/validate-markdown.sh\"|g" "$dest_plugin/hooks.json"
    sed -i "s|\"./scripts/validate-format.sh\"|\"./.agents/plugins/performance-agent-standards/scripts/validate-format.sh\"|g" "$dest_plugin/hooks.json"
  fi
}

install_claude() {
  if [[ "$MODE" == "global" ]]; then
    local dest_dir="${HOME}/.claude"
    local dest_plugin="${dest_dir}/plugins/performance-agent-standards"

    printf "${GREEN}[INFO]${NC} Installing Claude Code globally to isolated plugin dir: %s\n" "$dest_plugin"
    mkdir -p "$dest_plugin"

    # Copy plugin files recursively (keeps ~/.claude clean)
    cp -r "${BASE_DIR}/dist/claude/.claude" "$dest_plugin/"
    cp -r "${BASE_DIR}/dist/claude/scripts" "$dest_plugin/"
    chmod +x "$dest_plugin/scripts"/*.sh

    # Programmatically merge CLAUDE.md instead of overwriting global file (SOLID & Safe)
    if [[ -f "$dest_dir/CLAUDE.md" ]]; then
      printf "${GREEN}[INFO]${NC} Appending rules to existing global CLAUDE.md...\n"
      printf "\n\n# --- performance-agent-standards rules begin ---\n" >> "$dest_dir/CLAUDE.md"
      cat "${BASE_DIR}/dist/claude/CLAUDE.md" >> "$dest_dir/CLAUDE.md"
      printf "\n# --- performance-agent-standards rules end ---\n" >> "$dest_dir/CLAUDE.md"
    else
      cp "${BASE_DIR}/dist/claude/CLAUDE.md" "$dest_dir/CLAUDE.md"
    fi

    cp "${BASE_DIR}/dist/claude/.claude/rules"/*.md "$dest_dir/rules/"

    # Programmatically merge hooks instead of overwriting global settings.json (SOLID & Safe)
    if [[ -f "$dest_dir/settings.json" ]]; then
      printf "${GREEN}[INFO]${NC} Merging hooks into existing global settings.json...\n"
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
  else
    local dest_dir="${TARGET_PATH}/.claude"

    printf "${GREEN}[INFO]${NC} Installing Claude Code locally to workspace: %s\n" "$TARGET_PATH"
    mkdir -p "$dest_dir/scripts"
    mkdir -p "$dest_dir/rules"

    cp "${BASE_DIR}/dist/claude/CLAUDE.md" "${TARGET_PATH}/CLAUDE.md"
    cp "${BASE_DIR}/dist/claude/.claude/settings.json" "$dest_dir/settings.json"
    cp "${BASE_DIR}/dist/claude/.claude/rules"/*.md "$dest_dir/rules/"
    cp -r "${BASE_DIR}/dist/claude/scripts"/* "$dest_dir/scripts/"
    chmod +x "$dest_dir/scripts"/*.sh

    # Replace relative path with workspace-relative settings path in settings.json
    sed -i "s|\"./scripts/validate-markdown.sh\"|\"./.claude/scripts/validate-markdown.sh\"|g" "$dest_dir/settings.json"
    sed -i "s|\"./scripts/validate-format.sh\"|\"./.claude/scripts/validate-format.sh\"|g" "$dest_dir/settings.json"
  fi
}

install_codex() {
  if [[ "$MODE" == "global" ]]; then
    local dest_dir="${HOME}/.codex"
    local dest_plugin="${dest_dir}/plugins/performance-agent-standards"

    printf "${GREEN}[INFO]${NC} Installing Codex globally to isolated plugin dir: %s\n" "$dest_plugin"
    mkdir -p "$dest_plugin"

    # Copy plugin files recursively
    cp -r "${BASE_DIR}/dist/codex/.codex"/* "$dest_plugin/"
    cp -r "${BASE_DIR}/dist/codex/scripts" "$dest_plugin/"
    chmod +x "$dest_plugin/scripts"/*.sh

    # Deploy AGENTS.md to global config
    if [[ -f "$dest_dir/AGENTS.md" ]]; then
      printf "${GREEN}[INFO]${NC} Appending rules to existing global AGENTS.md...\n"
      printf "\n\n# --- performance-agent-standards rules begin ---\n" >> "$dest_dir/AGENTS.md"
      cat "${BASE_DIR}/dist/codex/AGENTS.md" >> "$dest_dir/AGENTS.md"
      printf "\n# --- performance-agent-standards rules end ---\n" >> "$dest_dir/AGENTS.md"
    else
      cp "${BASE_DIR}/dist/codex/AGENTS.md" "$dest_dir/AGENTS.md"
    fi

    # Merge hooks into global settings.json
    if [[ -f "$dest_dir/settings.json" ]]; then
      printf "${GREEN}[INFO]${NC} Merging hooks into existing global settings.json...\n"
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
  else
    local dest_dir="${TARGET_PATH}/.codex"

    printf "${GREEN}[INFO]${NC} Installing Codex locally to workspace: %s\n" "$TARGET_PATH"
    mkdir -p "$dest_dir/rules"
    mkdir -p "$dest_dir/scripts"

    cp "${BASE_DIR}/dist/codex/AGENTS.md" "${TARGET_PATH}/AGENTS.md"
    cp "${BASE_DIR}/dist/codex/.codex/settings.json" "$dest_dir/settings.json"
    cp "${BASE_DIR}/dist/codex/.codex/rules"/*.md "$dest_dir/rules/"
    cp -r "${BASE_DIR}/dist/codex/scripts"/* "$dest_dir/scripts/"
    chmod +x "$dest_dir/scripts"/*.sh

    # Replace relative path with workspace-relative settings path
    sed -i "s|\"./scripts/validate-markdown.sh\"|\"./.codex/scripts/validate-markdown.sh\"|g" "$dest_dir/settings.json"
    sed -i "s|\"./scripts/validate-format.sh\"|\"./.codex/scripts/validate-format.sh\"|g" "$dest_dir/settings.json"
  fi
}

# Verify dist directory exists before installing
[[ ! -d "$BASE_DIR/dist" ]] && { printf "${RED}[ERROR]${NC} dist directory not found. Please run scripts/compile.sh first.\n" >&2; exit 1; }

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
    printf "${RED}[ERROR]${NC} Unsupported provider: %s\n" "$PROVIDER" >&2
    exit 1
    ;;
esac

printf "${GREEN}[INFO]${NC} Installation completed successfully.\n"
