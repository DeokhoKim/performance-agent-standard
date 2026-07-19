#!/bin/bash
set -euo pipefail

# This script compiles and merges shared rules & configs with provider-specific ones
# and outputs them into the `dist/` directory.

NC='\033[0m'

BASE_DIR=${BASE_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}
DIST_DIR=${DIST_DIR:-"${BASE_DIR}/dist"}

log_info() {
  local green='\033[0;32m'
  printf "%b[INFO]%b %s\n" "$green" "$NC" "$1"
}

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

# 1. Compile Gemini / Antigravity
log_info "Compiling Gemini / Antigravity..."
mkdir -p "${DIST_DIR}/gemini/rules"

# Compile Core Rule
cat "${BASE_DIR}/providers/gemini/rules/always-read.md" \
    <(printf "\n") \
    "${BASE_DIR}/providers/shared/rules/markdown-reading.md" \
    > "${DIST_DIR}/gemini/rules/00-gemini-core.md"

# Compile Shared Rules with dynamic frontmatters
for entry in "${SHARED_RULES[@]}"; do
  IFS='|' read -r prefix name trigger globs desc <<< "$entry"
  compile_rule \
    "${BASE_DIR}/providers/shared/rules/${name}.md" \
    "${DIST_DIR}/gemini/rules/${prefix}-${name}.md" \
    "$trigger" \
    "$desc" \
    "$globs"
done

cp "${BASE_DIR}/providers/gemini/hooks.json" "${DIST_DIR}/gemini/hooks.json"
sed "s/__VERSION__/${VERSION}/g" "${BASE_DIR}/providers/gemini/plugin.json" > "${DIST_DIR}/gemini/plugin.json"
mkdir -p "${DIST_DIR}/gemini/scripts"
cp "${BASE_DIR}/scripts/parse-hook-input.sh" "${DIST_DIR}/gemini/scripts/"
cp "${BASE_DIR}/scripts/validate-markdown.sh" "${DIST_DIR}/gemini/scripts/"
cp "${BASE_DIR}/scripts/validate-format.sh" "${DIST_DIR}/gemini/scripts/"

# 2. Compile Claude Code
log_info "Compiling Claude Code..."
mkdir -p "${DIST_DIR}/claude/.claude/rules"

# Compile Core CLAUDE.md
cat "${BASE_DIR}/providers/claude/rules/always-read.md" \
    <(printf "\n") \
    "${BASE_DIR}/providers/shared/rules/markdown-reading.md" \
    > "${DIST_DIR}/claude/CLAUDE.md"

# Compile Shared Rules (clean copy)
for entry in "${SHARED_RULES[@]}"; do
  IFS='|' read -r prefix name trigger globs desc <<< "$entry"
  compile_rule \
    "${BASE_DIR}/providers/shared/rules/${name}.md" \
    "${DIST_DIR}/claude/.claude/rules/${prefix}-${name}.md" \
    "none"
done

cp "${BASE_DIR}/providers/claude/settings.json" "${DIST_DIR}/claude/.claude/settings.json"
mkdir -p "${DIST_DIR}/claude/scripts"
cp "${BASE_DIR}/scripts/parse-hook-input.sh" "${DIST_DIR}/claude/scripts/"
cp "${BASE_DIR}/scripts/validate-markdown.sh" "${DIST_DIR}/claude/scripts/"
cp "${BASE_DIR}/scripts/validate-format.sh" "${DIST_DIR}/claude/scripts/"

# 3. Compile Codex
log_info "Compiling Codex..."
mkdir -p "${DIST_DIR}/codex/.codex/rules"

# Compile Core AGENTS.md (Codex convention — equivalent to CLAUDE.md)
cat "${BASE_DIR}/providers/codex/rules/always-read.md" \
    <(printf "\n") \
    "${BASE_DIR}/providers/shared/rules/markdown-reading.md" \
    > "${DIST_DIR}/codex/AGENTS.md"

# Compile Shared Rules (clean copy)
for entry in "${SHARED_RULES[@]}"; do
  IFS='|' read -r prefix name trigger globs desc <<< "$entry"
  compile_rule \
    "${BASE_DIR}/providers/shared/rules/${name}.md" \
    "${DIST_DIR}/codex/.codex/rules/${prefix}-${name}.md" \
    "none"
done

cp "${BASE_DIR}/providers/codex/settings.json" "${DIST_DIR}/codex/.codex/settings.json"
mkdir -p "${DIST_DIR}/codex/scripts"
cp "${BASE_DIR}/scripts/parse-hook-input.sh" "${DIST_DIR}/codex/scripts/"
cp "${BASE_DIR}/scripts/validate-markdown.sh" "${DIST_DIR}/codex/scripts/"
cp "${BASE_DIR}/scripts/validate-format.sh" "${DIST_DIR}/codex/scripts/"

log_info "Compilation complete. Output generated in: ${DIST_DIR}"
