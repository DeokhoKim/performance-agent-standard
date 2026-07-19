#!/usr/bin/env bash
# ---
# purpose: Compiles and merges shared rules, hooks, and skills into provider-specific distributions.
# ---

set -euo pipefail

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

BASE_DIR=${BASE_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}
DIST_DIR=${DIST_DIR:-"${BASE_DIR}/dist"}

# Extract project version from pyproject.toml
VERSION=$(sed -n 's/^version = "\(.*\)"/\1/p' "${BASE_DIR}/pyproject.toml")

# Clean build directory
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Rule Compiler Function (SOLID: Single Responsibility)
# Arguments:
#   $1: source_path
#   $2: dest_path
#   $3: trigger_type (always, glob, none)
#   $4: description (optional)
#   $5: glob_patterns (optional, comma-separated)
compile_rule() {
  local src="$1"
  local dest="$2"
  local trigger="${3:-none}"
  local desc="${4:-}"
  local globs="${5:-}"

  local dest_dir
  dest_dir=$(dirname "$dest")
  mkdir -p "$dest_dir"

  if [[ "$trigger" == "none" ]]; then
    # Clean copy without frontmatter
    cp "$src" "$dest"
  else
    # Compile with YAML frontmatter trigger block
    {
      printf -- "---\n"
      printf -- "trigger: %s\n" "$trigger"
      if [[ -n "$globs" ]]; then
        printf -- "globs:\n"
        IFS=',' read -ra ADDR <<< "$globs"
        for glob in "${ADDR[@]}"; do
          # Trim leading/trailing whitespace
          glob=$(printf "%s" "$glob" | xargs)
          printf -- "  - \"%s\"\n" "$glob"
        done
      fi
      if [[ -n "$desc" ]]; then
        printf -- "description: \"%s\"\n" "$desc"
      fi
      printf -- "---\n\n"
      cat "$src"
    } > "$dest"
  fi
}

# Skill Compiler Function (SOLID: Single Responsibility)
# Arguments:
#   $1: provider (gemini, claude, codex)
#   $2: dest_skills_dir
compile_provider_skills() {
  local provider="$1"
  local dest_skills_dir="$2"

  local src_skills_dir="${BASE_DIR}/providers/shared/skills"
  [[ ! -d "$src_skills_dir" ]] && return 0

  mkdir -p "$dest_skills_dir"

  (
    cd "$src_skills_dir"
    # Find all SKILL.md files to locate skills
    find . -type f -name "SKILL.md" | while read -r skill_file; do
      local skill_dir
      skill_dir=$(dirname "$skill_file")
      local skill_name
      skill_name=$(basename "$skill_dir")

      # Create target directory for this skill
      mkdir -p "${dest_skills_dir}/${skill_name}"

      # 1. Collect frontmatter components
      local base_fm="${skill_dir}/frontmatter.yaml"
      local provider_fm="${skill_dir}/frontmatter.${provider}.yaml"

      # 2. Extract body from the source SKILL.md (lines after the second ---)
      local body
      body=$(awk '
        BEGIN {count=0}
        /^---$/ {count++; next}
        count >= 2 {print}
      ' "$skill_file")

      # 3. Assemble and write the compiled SKILL.md
      {
        printf -- "---\n"
        if [[ -f "$base_fm" ]]; then
          cat "$base_fm"
        fi
        if [[ -f "$provider_fm" ]]; then
          cat "$provider_fm"
        fi
        if [[ ! -f "$base_fm" && ! -f "$provider_fm" ]]; then
          # Fallback to extracting frontmatter from SKILL.md if no YAML files exist
          awk '
            BEGIN {count=0}
            /^---$/ {count++; if (count >= 2) exit; next}
            count == 1 {print}
          ' "$skill_file"
        fi
        printf -- "---\n\n"
        printf "%s\n" "$body" | awk 'NF{found=1} found{print}'
      } > "${dest_skills_dir}/${skill_name}/SKILL.md"

      # Replace relative script paths with absolute paths inside the compiled SKILL.md
      # Note: Agent platforms handle custom skill directories differently:
      # - Gemini/Antigravity supports complete plugin isolation, where custom skills reside
      #   directly inside the plugin directory: ~/.gemini/antigravity-cli/plugins/<plugin-name>/skills/
      # - Claude Code and Codex require custom skills to be placed in their centralized, flat
      #   global skill directories (~/.claude/skills/ and ~/.codex/skills/ respectively).
      # Therefore, the target global path for rewriting relative script paths in SKILL.md
      # must correspond to each provider's native skill resolution layout.
      local global_skill_dir
      case "$provider" in
        antigravity)
          global_skill_dir="\$HOME/.gemini/antigravity-cli/plugins/performance-agent-standards/skills/${skill_name}"
          ;;
        gemini)
          global_skill_dir="\$HOME/.gemini/plugins/performance-agent-standards/skills/${skill_name}"
          ;;
        claude)
          global_skill_dir="\$HOME/.claude/skills/${skill_name}"
          ;;
        codex)
          global_skill_dir="\$HOME/.codex/skills/${skill_name}"
          ;;
        *)
          log_error "Unsupported provider for skill compilation: $provider"
          exit 1
          ;;
      esac
      sed -i "s|\`scripts/|\`$global_skill_dir/scripts/|g" "${dest_skills_dir}/${skill_name}/SKILL.md"

      # 4. Copy all other files in this skill folder (except frontmatter yaml files)
      find "$skill_dir" -maxdepth 1 -type f ! -name "SKILL.md" ! -name "frontmatter*" | while read -r support_file; do
        cp "$support_file" "${dest_skills_dir}/${skill_name}/"
      done

      # 5. Copy scripts or other directories inside this skill recursively if they exist
      find "$skill_dir" -mindepth 1 -maxdepth 1 -type d | while read -r sub_dir; do
        cp -r "$sub_dir" "${dest_skills_dir}/${skill_name}/"
      done
    done
  )
}

# Declarative Rule Registry (SOLID: Open-Closed Principle for adding new rules)
# Format: "ordering_prefix|rule_name|trigger_type|globs|description"
SHARED_RULES=(
  "01|karpathy-guidelines|always||Core coding instincts and developer workflow principles."
  "02|workspace-hygiene|always||Active workspace hygiene and speculative reading restrictions."
  "03|lang-standard-common|glob|*.rs, *.cpp, *.cc, *.c, *.hpp, *.h, *.sh, *.bash|Common language code quality and maintainability standards."
  "04|lang-standard-native|glob|*.rs, *.cpp, *.cc, *.c, *.hpp, *.h|Native language performance standards."
  "05|lang-standard-rust|glob|*.rs|Rust safety and collection idioms standards."
  "06|lang-standard-bash|glob|*.sh, *.bash|Bash scripting standards."
  "07|markdown-writing|glob|**/*.md|Guidelines and standards for writing High-Density Markdown (HDMD)."
  "08|inline-execution|always||Agent inline command and execution standards."
)

# Provider Compiler Function (SOLID: Open-Closed Principle for adding new agent platforms)
# Arguments:
#   $1: provider (gemini, claude, codex)
#   $2: core_dest_rel_path (e.g. rules/00-gemini-core.md, CLAUDE.md)
#   $3: config_prefix (e.g. "" or ".claude/" or ".codex/")
#   $4: force_trigger_none (1 or 0)
compile_provider() {
  local provider="$1"
  local core_dest_rel="$2"
  local prefix="${3:-}"
  local force_none="${4:-0}"

  # Dynamically map antigravity and gemini to use gemini source files
  local provider_src="$provider"
  if [[ "$provider" == "antigravity" || "$provider" == "gemini" ]]; then
    provider_src="gemini"
  fi

  log_info "Compiling ${provider^}..."

  local provider_dist="${DIST_DIR}/${provider}"
  local prefix_dir="${provider_dist}/${prefix}"

  # 1. Compile Core Rule
  local core_dest_path="${provider_dist}/${core_dest_rel}"
  mkdir -p "$(dirname "$core_dest_path")"
  cat "${BASE_DIR}/providers/${provider_src}/rules/always-read.md" \
      <(printf "\n") \
      "${BASE_DIR}/providers/shared/rules/markdown-reading.md" \
      > "$core_dest_path"

  # 2. Compile Shared Rules
  local rules_dest="${prefix_dir}rules"
  mkdir -p "$rules_dest"
  for entry in "${SHARED_RULES[@]}"; do
    IFS='|' read -r order_prefix name trigger globs desc <<< "$entry"
    local final_trigger="$trigger"
    if [[ "$force_none" -eq 1 ]]; then
      final_trigger="none"
    fi
    compile_rule \
      "${BASE_DIR}/providers/shared/rules/${name}.md" \
      "${rules_dest}/${order_prefix}-${name}.md" \
      "$final_trigger" \
      "$desc" \
      "$globs"
  done

  # 3. Copy Configuration Files
  if [[ "$provider" == "antigravity" || "$provider" == "gemini" ]]; then
    cp "${BASE_DIR}/providers/gemini/hooks.json" "${provider_dist}/hooks.json"
    sed "s/__VERSION__/${VERSION}/g" "${BASE_DIR}/providers/gemini/plugin.json" > "${provider_dist}/plugin.json"

    # Replace relative path with absolute/home-relative path in hooks.json for pre-built/extracted plugins
    local global_dest_plugin="\$HOME/.gemini/antigravity-cli/plugins/performance-agent-standards"
    if [[ "$provider" == "gemini" ]]; then
      global_dest_plugin="\$HOME/.gemini/plugins/performance-agent-standards"
    fi
    sed -i "s|\"./scripts/validate-markdown.sh\"|\"$global_dest_plugin/scripts/validate-markdown.sh\"|g" "${provider_dist}/hooks.json"
    sed -i "s|\"./scripts/validate-format.sh\"|\"$global_dest_plugin/scripts/validate-format.sh\"|g" "${provider_dist}/hooks.json"
  else
    cp "${BASE_DIR}/providers/${provider_src}/settings.json" "${prefix_dir}settings.json"

    # Replace relative path with absolute/home-relative path in settings.json for pre-built/extracted plugins for Claude and Codex
    local global_dest_plugin="\$HOME/.claude/plugins/performance-agent-standards"
    if [[ "$provider" == "codex" ]]; then
      global_dest_plugin="\$HOME/.codex/plugins/performance-agent-standards"
    fi
    if [[ -f "${prefix_dir}settings.json" ]]; then
      sed -i "s|\"./scripts/validate-markdown.sh\"|\"$global_dest_plugin/scripts/validate-markdown.sh\"|g" "${prefix_dir}settings.json"
      sed -i "s|\"./scripts/validate-format.sh\"|\"$global_dest_plugin/scripts/validate-format.sh\"|g" "${prefix_dir}settings.json"
    fi
  fi

  # 4. Copy Common Scripts
  local scripts_dest="${provider_dist}/scripts"
  mkdir -p "$scripts_dest"
  cp "${BASE_DIR}/scripts/parse-hook-input.sh" "$scripts_dest/"
  cp "${BASE_DIR}/scripts/validate-markdown.sh" "$scripts_dest/"
  cp "${BASE_DIR}/scripts/validate-format.sh" "$scripts_dest/"

  # 5. Compile Provider Skills
  compile_provider_skills "$provider" "${prefix_dir}skills"
}

# Run Compilation for all supported providers
compile_provider "antigravity" "rules/00-gemini-core.md" "" 0
compile_provider "gemini" "rules/00-gemini-core.md" "" 0
compile_provider "claude" "CLAUDE.md" ".claude/" 1
compile_provider "codex" "AGENTS.md" ".codex/" 1

log_info "Compilation complete. Output generated in: ${DIST_DIR}"
