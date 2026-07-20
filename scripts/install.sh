#!/bin/bash
# ==============================================================================
# Universal Installer for Performance Agent Standards Plugin
# ==============================================================================
# This script installs/updates the agent standards plugin by fetching the latest
# pre-packaged release zip from GitHub, or cloning & compiling from git if no
# release is available.
#
# Supported providers:
#   - antigravity (modern Gemini TUI)
#   - gemini      (legacy Gemini TUI)
#   - claude      (Claude Code)
#   - codex       (Codex)
# ==============================================================================

set -euo pipefail

# Configuration
REPO_SLUG="DeokhoKim/performance-agent-standard"
DEFAULT_PROVIDER="auto"
FORCE_INSTALL=false

NC='\033[0m'
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
  printf "Usage: install.sh [options]\n"
  printf "Options:\n"
  printf "  --provider <name>  Assign a specific provider (antigravity, gemini, claude, codex, auto)\n"
  printf "                     Default is 'auto' (detects and installs all installed agents)\n"
  printf "  --force            Force installation even if the version matches the latest release/commit\n"
  printf "  --repo <slug>      GitHub repository owner/name (default: %s)\n" "$REPO_SLUG"
  printf "  -h, --help         Show this help message\n"
}

# Parse options
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --provider)
      [[ -z "${2:-}" ]] && { log_error "Missing provider name."; print_usage; exit 1; }
      DEFAULT_PROVIDER="$2"
      shift 2
      ;;
    --repo)
      [[ -z "${2:-}" ]] && { log_error "Missing repo slug."; print_usage; exit 1; }
      REPO_SLUG="$2"
      shift 2
      ;;
    --force)
      FORCE_INSTALL=true
      shift
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

# Check dependencies
for cmd in curl unzip; do
  if ! command -v "$cmd" &>/dev/null; then
    log_error "Required command '$cmd' is missing. Please install it first."
    exit 1
  fi
done

# OS-specific sed in-place setup
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE=(sed -i '')
else
  SED_INPLACE=(sed -i)
fi

# Detect providers present on the system
detect_providers() {
  local detected=()
  if command -v agy &>/dev/null || [[ -d "$HOME/.gemini/antigravity-cli" ]]; then
    detected+=("antigravity")
  fi
  if command -v gemini &>/dev/null || [[ -d "$HOME/.gemini/plugins" ]]; then
    # Only detect legacy gemini if modern agy is not installed to avoid double gemini config
    if [[ ! -d "$HOME/.gemini/antigravity-cli" ]]; then
      detected+=("gemini")
    fi
  fi
  if command -v claude &>/dev/null || [[ -d "$HOME/.claude" ]]; then
    detected+=("claude")
  fi
  if command -v codex &>/dev/null || [[ -d "$HOME/.codex" ]]; then
    detected+=("codex")
  fi

  # Fallback to antigravity if nothing is detected
  if [[ ${#detected[@]} -eq 0 ]]; then
    detected+=("antigravity")
  fi

  echo "${detected[@]}"
}

# Determine target install directory for a provider
get_dest_dir() {
  local provider="$1"
  case "$provider" in
    antigravity) echo "$HOME/.gemini/config/plugins/performance-agent-standards" ;;
    gemini)      echo "$HOME/.gemini/plugins/performance-agent-standards" ;;
    claude)      echo "$HOME/.claude/plugins/performance-agent-standards" ;;
    codex)       echo "$HOME/.codex/plugins/performance-agent-standards" ;;
    *)           log_error "Unknown provider: $provider"; exit 1 ;;
  esac
}

# Read currently installed version/commit
get_installed_version() {
  local dest_dir="$1"
  if [[ -f "$dest_dir/.installed-version" ]]; then
    cat "$dest_dir/.installed-version"
  else
    echo "none"
  fi
}

# Helper to merge compiled/extracted files into target locations
install_extracted_files() {
  local provider="$1"
  local src_dir="$2"
  local dest_plugin
  dest_plugin=$(get_dest_dir "$provider")

  case "$provider" in
    antigravity|gemini)
      # CLI uninstall first if available
      [[ "$provider" == "antigravity" ]] && command -v agy &>/dev/null && {
        log_info "Uninstalling existing plugin via Antigravity CLI (agy)..."
        agy plugin uninstall "performance-agent-standards" 2>/dev/null || true
      }
      [[ "$provider" == "gemini" ]] && command -v gemini &>/dev/null && {
        log_info "Uninstalling existing plugin via Legacy Gemini CLI..."
        gemini plugin uninstall "performance-agent-standards" 2>/dev/null || true
      }

      # Remove directory if it still exists
      [[ -d "$dest_plugin" ]] && {
        log_info "Cleaning up old plugin files in $dest_plugin..."
        rm -rf "$dest_plugin"
      }
      mkdir -p "$dest_plugin"

      log_info "Deploying $provider plugin files to $dest_plugin..."
      cp -r "$src_dir"/* "$dest_plugin/"
      chmod +x "$dest_plugin/scripts"/*.sh 2>/dev/null || true
      if [[ -d "$dest_plugin/skills" ]]; then
        find "$dest_plugin/skills" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
      fi

      # CLI registration
      [[ "$provider" == "antigravity" ]] && command -v agy &>/dev/null && {
        log_info "Registering plugin with Antigravity CLI (agy)..."
        agy plugin install "$src_dir"
      }
      [[ "$provider" == "gemini" ]] && command -v gemini &>/dev/null && {
        log_info "Registering plugin with Legacy Gemini CLI..."
        gemini plugin install "$src_dir"
      }
      ;;

    claude)
      local dest_dir="$HOME/.claude"

      # Clean up removed rules from global rules directory before wiping $dest_plugin
      [[ -d "$dest_plugin/.claude/rules" ]] && {
        for old_rule in "$dest_plugin/.claude/rules"/*.md; do
          [[ -f "$old_rule" ]] && {
            local rule_name="${old_rule##*/}"
            [[ ! -f "$src_dir/.claude/rules/$rule_name" ]] && {
              log_info "Removing obsolete rule: $dest_dir/rules/$rule_name"
              rm -f "$dest_dir/rules/$rule_name"
            }
          }
        done
      }

      # Clean up removed skills from global skills directory before wiping $dest_plugin
      [[ -d "$dest_plugin/.claude/skills" ]] && {
        find "$dest_plugin/.claude/skills" -type f | while IFS= read -r old_skill; do
          local rel_path="${old_skill#"$dest_plugin/.claude/skills/"}"
          [[ ! -e "$src_dir/.claude/skills/$rel_path" ]] && {
            log_info "Removing obsolete skill file: $dest_dir/skills/$rel_path"
            rm -f "$dest_dir/skills/$rel_path"
            local parent_dir="${dest_dir}/skills/${rel_path%/*}"
            rmdir -p "$parent_dir" 2>/dev/null || true
          }
        done
      }

      # Clean up existing plugin directory to prevent orphaned files
      [[ -d "$dest_plugin" ]] && {
        log_info "Cleaning up old plugin files in $dest_plugin..."
        rm -rf "$dest_plugin"
      }
      mkdir -p "$dest_plugin"
      mkdir -p "$dest_dir/rules"

      log_info "Deploying Claude Code plugin files to $dest_plugin..."
      cp -r "$src_dir/.claude" "$dest_plugin/"
      cp -r "$src_dir/scripts" "$dest_plugin/"
      chmod +x "$dest_plugin/scripts"/*.sh

      # Idempotent CLAUDE.md merge
      [[ -f "$dest_dir/CLAUDE.md" ]] && {
        log_info "Merging rules into existing global CLAUDE.md..."
        "${SED_INPLACE[@]}" '/# --- performance-agent-standards rules begin ---/,/# --- performance-agent-standards rules end ---/d' "$dest_dir/CLAUDE.md"
      }
      {
        printf "\n\n# --- performance-agent-standards rules begin ---\n"
        cat "$src_dir/CLAUDE.md"
        printf "\n# --- performance-agent-standards rules end ---\n"
      } >> "$dest_dir/CLAUDE.md"

      # Deploy rules
      cp "$src_dir/.claude/rules"/*.md "$dest_dir/rules/"

      # Idempotent settings.json hooks merge
      if command -v jq &>/dev/null; then
        local temp_json
        temp_json=$(mktemp)
        local settings_file="$dest_dir/settings.json"

        if [[ -f "$settings_file" ]]; then
          log_info "Merging hooks into existing global settings.json..."
          jq --arg cmd1 "$dest_plugin/scripts/validate-markdown.sh" \
             --arg cmd2 "$dest_plugin/scripts/validate-format.sh" '
            # Clean duplicate hooks
            .hooks.PreToolUse = [
              .hooks.PreToolUse[]?
              | .hooks = [
                  .hooks[]?
                  | select(.command != $cmd1 and .command != $cmd2)
                ]
              | select(.hooks | length > 0)
            ] + [{
              "matcher": "Write|Edit|Create",
              "hooks": [
                { "type": "command", "command": $cmd1 }
              ]
            }] |
            .hooks.PostToolUse = [
              .hooks.PostToolUse[]?
              | .hooks = [
                  .hooks[]?
                  | select(.command != $cmd1 and .command != $cmd2)
                ]
              | select(.hooks | length > 0)
            ] + [{
              "matcher": "Write|Edit|Create",
              "hooks": [
                { "type": "command", "command": $cmd2 }
              ]
            }]
          ' "$settings_file" > "$temp_json"
          mv "$temp_json" "$settings_file"
        else
          cp "$src_dir/.claude/settings.json" "$settings_file"
        fi
      else
        log_warn "jq command not found. Skipping settings.json hooks registration."
      fi

      # Deploy skills
      [[ -d "$src_dir/.claude/skills" ]] && {
        mkdir -p "$dest_dir/skills"
        cp -r "$src_dir/.claude/skills"/* "$dest_dir/skills/"
        find "$dest_dir/skills" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
      }
      ;;

    codex)
      local dest_dir="$HOME/.codex"

      # Clean up removed skills from global skills directory before wiping $dest_plugin
      [[ -d "$dest_plugin/skills" ]] && {
        find "$dest_plugin/skills" -type f | while IFS= read -r old_skill; do
          local rel_path="${old_skill#"$dest_plugin/skills/"}"
          [[ ! -e "$src_dir/.codex/skills/$rel_path" ]] && {
            log_info "Removing obsolete skill file: $dest_dir/skills/$rel_path"
            rm -f "$dest_dir/skills/$rel_path"
            local parent_dir="${dest_dir}/skills/${rel_path%/*}"
            rmdir -p "$parent_dir" 2>/dev/null || true
          }
        done
      }

      # Clean up existing plugin directory to prevent orphaned files
      [[ -d "$dest_plugin" ]] && {
        log_info "Cleaning up old plugin files in $dest_plugin..."
        rm -rf "$dest_plugin"
      }
      mkdir -p "$dest_plugin"

      log_info "Deploying Codex plugin files to $dest_plugin..."

      cp -r "$src_dir/.codex"/* "$dest_plugin/"
      cp -r "$src_dir/scripts" "$dest_plugin/"
      chmod +x "$dest_plugin/scripts"/*.sh

      # Idempotent AGENTS.md merge
      [[ -f "$dest_dir/AGENTS.md" ]] && {
        log_info "Merging rules into existing global AGENTS.md..."
        "${SED_INPLACE[@]}" '/# --- performance-agent-standards rules begin ---/,/# --- performance-agent-standards rules end ---/d' "$dest_dir/AGENTS.md"
      }
      {
        printf "\n\n# --- performance-agent-standards rules begin ---\n"
        cat "$src_dir/AGENTS.md"
        printf "\n# --- performance-agent-standards rules end ---\n"
      } >> "$dest_dir/AGENTS.md"

      # Idempotent settings.json hooks merge
      if command -v jq &>/dev/null; then
        local temp_json
        temp_json=$(mktemp)
        local settings_file="$dest_dir/settings.json"

        if [[ -f "$settings_file" ]]; then
          log_info "Merging hooks into existing global settings.json..."
          jq --arg cmd1 "$dest_plugin/scripts/validate-markdown.sh" \
             --arg cmd2 "$dest_plugin/scripts/validate-format.sh" '
            .hooks.PreToolUse = [
              .hooks.PreToolUse[]?
              | .hooks = [
                  .hooks[]?
                  | select(.command != $cmd1 and .command != $cmd2)
                ]
              | select(.hooks | length > 0)
            ] + [{
              "matcher": "Write|Edit|Create",
              "hooks": [
                { "type": "command", "command": $cmd1 }
              ]
            }] |
            .hooks.PostToolUse = [
              .hooks.PostToolUse[]?
              | .hooks = [
                  .hooks[]?
                  | select(.command != $cmd1 and .command != $cmd2)
                ]
              | select(.hooks | length > 0)
            ] + [{
              "matcher": "Write|Edit|Create",
              "hooks": [
                { "type": "command", "command": $cmd2 }
              ]
            }]
          ' "$settings_file" > "$temp_json"
          mv "$temp_json" "$settings_file"
        else
          cp "$src_dir/.codex/settings.json" "$settings_file"
        fi
      else
        log_warn "jq command not found. Skipping settings.json hooks registration."
      fi

      # Deploy skills
      [[ -d "$src_dir/.codex/skills" ]] && {
        mkdir -p "$dest_dir/skills"
        cp -r "$src_dir/.codex/skills"/* "$dest_dir/skills/"
        find "$dest_dir/skills" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
      }
      ;;
  esac
}

# Main installation process
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# 1. Resolve active providers
PROVIDERS_TO_INSTALL=()
if [[ "$DEFAULT_PROVIDER" == "auto" ]]; then
  read -r -a PROVIDERS_TO_INSTALL <<< "$(detect_providers)"
else
  PROVIDERS_TO_INSTALL=("$DEFAULT_PROVIDER")
fi

log_info "Target providers resolved to: ${PROVIDERS_TO_INSTALL[*]}"

# 2. Fetch latest release info from GitHub API
log_info "Querying latest release from GitHub API..."
LATEST_RELEASE_JSON=$(curl -sSf -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${REPO_SLUG}/releases/latest" 2>/dev/null || true)

LATEST_TAG=""
if [[ -n "$LATEST_RELEASE_JSON" ]]; then
  # Parse tag_name without requiring jq
  LATEST_TAG=$(echo "$LATEST_RELEASE_JSON" | grep -m1 '"tag_name":' | sed -E 's/.*"tag_name":\s*"(.*)".*/\1/' || true)
fi

# 3. Handle compilation fallback if no release tag found
if [[ -z "$LATEST_TAG" ]]; then
  log_warn "No latest release tag found or API limit hit. Falling back to git clone & compile..."
  if ! command -v git &>/dev/null; then
    log_error "git is required for compilation fallback but not found in PATH."
    exit 1
  fi

  CLONE_DIR="$TMP_DIR/clone"
  log_info "Cloning main branch..."
  git clone --depth 1 "https://github.com/${REPO_SLUG}.git" "$CLONE_DIR"

  LATEST_SHA=$(git -C "$CLONE_DIR" rev-parse --short HEAD)
  log_info "Latest commit SHA is $LATEST_SHA"

  # Run compile
  log_info "Running project compilation..."
  (cd "$CLONE_DIR" && chmod +x scripts/compile.sh && ./scripts/compile.sh)

  for prov in "${PROVIDERS_TO_INSTALL[@]}"; do
    dest_dir=$(get_dest_dir "$prov")
    installed_ver=$(get_installed_version "$dest_dir")

    if [[ "$installed_ver" == "$LATEST_SHA" ]] && [[ "$FORCE_INSTALL" == "false" ]]; then
      log_info "Plugin for '$prov' is already up-to-date (SHA: $installed_ver). Skipping."
      continue
    fi

    # Install
    install_extracted_files "$prov" "$CLONE_DIR/dist/$prov"

    # Save version
    echo "$LATEST_SHA" > "$dest_dir/.installed-version"
    log_info "Successfully installed '$prov' at commit SHA $LATEST_SHA"
  done

else
  # Release ZIP available!
  log_info "Latest release version is $LATEST_TAG"

  for prov in "${PROVIDERS_TO_INSTALL[@]}"; do
    dest_dir=$(get_dest_dir "$prov")
    installed_ver=$(get_installed_version "$dest_dir")

    if [[ "$installed_ver" == "$LATEST_TAG" ]] && [[ "$FORCE_INSTALL" == "false" ]]; then
      log_info "Plugin for '$prov' is already up-to-date (Version: $installed_ver). Skipping."
      continue
    fi

    log_info "Downloading release package for '$prov' ($LATEST_TAG)..."
    ZIP_PATH="$TMP_DIR/${prov}.zip"
    EXTRACT_DIR="$TMP_DIR/extract_${prov}"
    mkdir -p "$EXTRACT_DIR"

    # Fetch zip file
    DOWNLOAD_URL="https://github.com/${REPO_SLUG}/releases/download/${LATEST_TAG}/performance-agent-standards-${prov}.zip"
    if ! curl -L -sSf "$DOWNLOAD_URL" -o "$ZIP_PATH"; then
      log_error "Failed to download $DOWNLOAD_URL. Proceeding to next provider."
      continue
    fi

    unzip -q "$ZIP_PATH" -d "$EXTRACT_DIR"

    # Install
    install_extracted_files "$prov" "$EXTRACT_DIR"

    # Save version
    echo "$LATEST_TAG" > "$dest_dir/.installed-version"
    log_info "Successfully installed '$prov' at version $LATEST_TAG"
  done
fi

log_info "Universal installation process finished."
