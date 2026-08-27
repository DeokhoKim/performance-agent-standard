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
#   $6: provider (optional, e.g. antigravity, gemini, claude, codex)
compile_rule() {
  local src="$1"
  local dest="$2"
  local trigger="${3:-none}"
  local desc="${4:-}"
  local globs="${5:-}"
  local provider="${6:-}"

  local dest_dir
  dest_dir=$(dirname "$dest")
  mkdir -p "$dest_dir"

  [[ "$trigger" == "none" ]] && { cp "$src" "$dest"; return 0; }

  local fm_trigger=""
  local fm_glob_key="globs"

  case "$provider" in
    antigravity)
      case "$trigger" in
        always) fm_trigger="alwaysApply: true" ;;
        *)      fm_trigger="alwaysApply: false" ;;
      esac
      ;;
    claude)
      fm_glob_key="paths"
      ;;
    *)
      fm_trigger="trigger: ${trigger}"
      ;;
  esac

  # Compile with YAML frontmatter trigger block
  {
    printf -- "---\n"
    [[ -n "$fm_trigger" ]] && printf "%s\n" "$fm_trigger"
    if [[ -n "$globs" ]]; then
      printf "%s:\n" "$fm_glob_key"
      IFS=',' read -ra ADDR <<< "$globs"
      for glob in "${ADDR[@]}"; do
        glob=$(printf "%s" "$glob" | xargs)
        printf -- "  - \"%s\"\n" "$glob"
      done
    fi
    [[ -n "$desc" ]] && printf -- "description: \"%s\"\n" "$desc"
    printf -- "---\n\n"
    cat "$src"
  } > "$dest"
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
          [[ -f "$base_fm" ]] && cat "$base_fm"
          [[ -f "$provider_fm" ]] && cat "$provider_fm"
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
      #   directly inside the plugin directory: ~/.gemini/config/plugins/<plugin-name>/skills/
      # - Claude Code and Codex require custom skills to be placed in their centralized, flat
      #   global skill directories (~/.claude/skills/ and ~/.codex/skills/ respectively).
      # Therefore, the target global path for rewriting relative script paths in SKILL.md
      # must correspond to each provider's native skill resolution layout.
      local global_skill_dir
      case "$provider" in
        antigravity)
          global_skill_dir="\$HOME/.gemini/config/plugins/performance-agent-standards/skills/${skill_name}"
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
# Numbering uses 2-digit hexadecimal where the first digit represents the category:
#   0x: Platform Core / Bootstrap
#   1x: Agent Core Instincts & Workflow Directives
#   2x: Document & Writing Standards
#   3x: Common / Polyglot Language Standards
#   4x: Native & Compiled System Languages
#   5x: Interpreted & Scripting Languages
SHARED_RULES=(
  "10|karpathy-guidelines|always||Read before writing, refactoring, or reviewing code. Enforces simplicity-first principles, surgical modifications, explicit assumptions, and goal-driven verification."
  "11|workspace-hygiene|always||Read when planning multi-file tasks, navigating files, or managing context. Enforces pre-execution mapping, batched surgical edits, subagent context isolation, anti-speculation reading, and rule precedence."
  "12|inline-execution|always||Read before executing shell commands or running dynamic inline scripts. Enforces shell-first pipeline parallelism, POSIX utility standards, and Python fallback constraints."
  "13|development-standards|always||Read before building, testing, running, or resolving toolchains. Enforces local environment primacy (Local > System > Assumption), virtualenv priority, native compiler overrides, and README single-read fallback."
  "20|markdown-writing|glob|**/*.md, **/*.mdc|Read when creating, editing, or refactoring Markdown files or documentation. Enforces token efficiency, zero context-loss preservation, structural formatting, and semantic tag conventions."
  "30|code-simplicity|glob|*.rs, *.cpp, *.cc, *.c, *.hpp, *.h, *.sh, *.bash, *.py|Read when implementing, designing, or refactoring source code across any language. Enforces simplicity-first hierarchy, platform-native primacy, trust-boundary safety invariants, actionable NOTE/TODO debt tracking, and zero-bloat output formatting."
  "31|lang-standard-common|glob|*.rs, *.cpp, *.cc, *.c, *.hpp, *.h, *.sh, *.bash, *.py|Read when implementing or refactoring source code across any language. Enforces pragmatic SOLID design, dependency injection, scoped resource cleanup (RAII), zero-copy memory patterns, and pipeline concurrency."
  "40|lang-standard-native|glob|*.rs, *.cpp, *.cc, *.c, *.hpp, *.h|Read when writing or modifying native/compiled systems code. Enforces in-place algorithms, collection capacity pre-allocation, zero-copy buffer management, && RAII resource destruction."
  "41|lang-standard-rust|glob|*.rs|Read when writing, reviewing, or optimizing Rust source code (*.rs). Enforces panic-safe arithmetic, zero-cost iterator pipelines, allocation-free borrowing, channel concurrency, and Drop cleanup."
  "50|lang-standard-bash|glob|*.sh, *.bash|Read when creating, modifying, or reviewing Bash shell scripts (*.sh, *.bash). Enforces strict error handling (set -euo pipefail), pipeline streaming, POSIX formatted logging with scoped ANSI colors, and trap cleanup."
  "51|lang-standard-python|glob|*.py|Read when writing, reviewing, or optimizing Python source code (*.py). Enforces modern built-in type hints, immutable dataclasses, match/case pattern matching, generator pipelines, context managers, and vectorized numerical operations."
)

# Provider Compiler Function (SOLID: Open-Closed Principle for adding new agent platforms)
# Arguments:
#   $1: provider (antigravity, gemini, claude, codex)
#   $2: core_dest_rel_path (e.g. rules/GEMINI.md, CLAUDE.md, AGENTS.md)
#   $3: config_prefix (e.g. "" or ".claude/" or ".codex/")
compile_provider() {
  local provider="$1"
  local core_dest_rel="$2"
  local prefix="${3:-}"

  # Dynamically map antigravity and gemini to use gemini source files
  local provider_src="$provider"
    [[ "$provider" == "antigravity" || "$provider" == "gemini" ]] && provider_src="gemini"

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
  local ref_content=""
  for entry in "${SHARED_RULES[@]}"; do
    IFS='|' read -r order_prefix name trigger globs desc <<< "$entry"

    local final_trigger="$trigger"
    case "$provider" in
      codex)
        final_trigger="none"
        ;;
      claude)
        [[ "$trigger" == "always" ]] && final_trigger="none"
        ;;
    esac

    compile_rule \
      "${BASE_DIR}/providers/shared/rules/${name}.md" \
      "${rules_dest}/${order_prefix}-${name}.md" \
      "$final_trigger" \
      "$desc" \
      "$globs" \
      "$provider"

    local rel_rule_path="${prefix}rules/${order_prefix}-${name}.md"
    case "$trigger" in
      always)
        case "$provider" in
          antigravity|gemini|claude)
            ref_content="${ref_content}- @[${rel_rule_path}]\n"
            ;;
          *)
            ref_content="${ref_content}- [${name^}](${rel_rule_path}) (Always Apply)\n"
            ;;
        esac
        ;;
      glob)
        ref_content="${ref_content}- [${name^}](${rel_rule_path}) (Paths: ${globs})\n"
        ;;
    esac
  done

  [[ -n "$ref_content" ]] && {
    printf "\n## Rule References\n"
    printf "%b" "$ref_content"
  } >> "$core_dest_path"

  # 3. Copy Configuration Files
  case "$provider" in
    antigravity|gemini)
      cp "${BASE_DIR}/providers/gemini/hooks.json" "${provider_dist}/hooks.json"
      sed "s/__VERSION__/${VERSION}/g" "${BASE_DIR}/providers/gemini/plugin.json" > "${provider_dist}/plugin.json"

      # Replace relative path with absolute/home-relative path in hooks.json for pre-built/extracted plugins
      local global_dest_plugin="\$HOME/.gemini/config/plugins/performance-agent-standards"
      [[ "$provider" == "gemini" ]] && global_dest_plugin="\$HOME/.gemini/plugins/performance-agent-standards"
      sed -i "s|\"./scripts/hooks/|\"$global_dest_plugin/scripts/hooks/|g" "${provider_dist}/hooks.json"
      ;;
    claude|codex)
      cp "${BASE_DIR}/providers/${provider_src}/settings.json" "${prefix_dir}settings.json"

      # Replace relative path with absolute/home-relative path in settings.json for pre-built/extracted plugins for Claude and Codex
      local global_dest_plugin="\$HOME/.claude/plugins/performance-agent-standards"
      [[ "$provider" == "codex" ]] && global_dest_plugin="\$HOME/.codex/plugins/performance-agent-standards"
      [[ -f "${prefix_dir}settings.json" ]] && sed -i "s|\"./scripts/hooks/|\"$global_dest_plugin/scripts/hooks/|g" "${prefix_dir}settings.json"
      ;;
  esac

  # 4. Copy Common Scripts
  local scripts_dest="${provider_dist}/scripts"
  mkdir -p "$scripts_dest"
  cp -r "${BASE_DIR}/scripts/hooks" "$scripts_dest/"

  # 5. Compile Provider Skills
  compile_provider_skills "$provider" "${prefix_dir}skills"
}

# Run Compilation for all supported providers
compile_provider "antigravity" "rules/GEMINI.md" ""
compile_provider "gemini" "rules/GEMINI.md" ""
compile_provider "claude" "CLAUDE.md" ".claude/"
compile_provider "codex" "AGENTS.md" ".codex/"

log_info "Compilation complete. Output generated in: ${DIST_DIR}"
