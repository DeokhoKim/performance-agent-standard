# Performance Agent Standards Plugin

This repository provides baseline rules, hooks, and guidelines for development environments across multiple agent platforms including **Google Antigravity (Gemini)**, **Claude Code**, and **Codex**.

It uses a flexible compilation architecture to merge shared guidelines (e.g., High-Density Markdown Writing Rules) with provider-specific extensions while preventing config conflicts (like hook structures) across different agents.

## Architecture

To prevent structural and syntax conflicts, rules and hooks are isolated by provider in the `providers/` directory and compiled into `dist/` before deployment:

```text
performance-agent-standards/
├── .pre-commit-config.yaml     # Git hooks configuration
├── .gitignore                  # Git ignore rules for python virtualenvs and cache
├── pyproject.toml              # Python project packaging and dev tools layout
├── README.md                   # This documentation
├── providers/                  # Isolated configurations to prevent conflicts
│   ├── shared/                 # Shared base config & rules
│   │   └── rules/
│   │       ├── markdown-writing.md # Markdown Writing Rules
│   │       ├── markdown-reading.md # Markdown Reading & Translation Rules (Pseudocode)
│   │       ├── lang-standard-common.md # Common language standards (config/clamping)
│   │       ├── lang-standard-native.md # Native language standards (sorting/allocations)
│   │       ├── lang-standard-rust.md   # Rust implementation standards (panics/iterators)
│   │       ├── lang-standard-bash.md   # Bash scripting safety standards
│   │       ├── karpathy-guidelines.md  # Shared core engineering and coding instincts
│   │       ├── inline-execution.md     # Agent inline command and execution standards
│   │       └── workspace-hygiene.md    # Active workspace hygiene and speculative reading restrictions
│   ├── gemini/                 # Gemini / Antigravity specifics
│   │   ├── rules/
│   │   │   └── always-read.md  # Gemini core rules (always read)
│   │   ├── hooks.json          # Antigravity hook config (nested named hooks)
│   │   └── plugin.json         # Antigravity plugin manifest
│   ├── claude/                 # Claude Code specifics
│   │   ├── rules/
│   │   │   └── always-read.md  # Claude core rules (always read)
│   │   └── settings.json       # Claude settings/hooks (.claude/settings.json structure)
│   └── codex/                  # Codex specifics
│       ├── rules/
│       │   └── always-read.md  # Codex core rules (always read)
│       └── settings.json       # Codex settings/hooks (.codex/settings.json structure)
├── scripts/                    # Utility and hook scripts
│   ├── compile.sh              # Merges shared rules & configs with provider-specific ones
│   ├── install.sh              # Places the compiled files in appropriate user/workspace paths
│   └── validate-markdown.sh    # Tool/Git hook script to validate markdown syntax
```

## Compilation and Installation

The plugin provides scripts to easily compile and install the rules and hooks either globally (affecting all projects for that agent) or locally (affecting only the target workspace).

### Global Installation (User Configuration)
Installs rules and hooks to your user-level configuration folders (e.g., `~/.gemini/` or `~/.claude/`):

```bash
# Install all supported agent configurations globally
./scripts/install.sh --global

# Install only for a specific agent (e.g., Claude Code)
./scripts/install.sh --global --provider claude
```

### Local Workspace Installation
Installs rules and hooks to a specific workspace directory (e.g., copying compiled rules to a project root):

```bash
# Install all configurations locally to a target project
./scripts/install.sh --local /path/to/your/project

# Install only Gemini configurations locally
./scripts/install.sh --local /path/to/your/project --provider gemini
```

### Packaging Release Artifacts
To distribute the compiled rules without requiring end-users to run compilation or install scripts, you can package the compiled directory structures under `dist/` into separate zip release artifacts.

To package the artifacts manually:

```bash
# Ensure the rules are compiled first
./scripts/compile.sh

# Zip the compiled Gemini/Antigravity plugin
cd dist/gemini && zip -r ../../performance-agent-standards-gemini.zip . && cd ../..

# Zip the compiled Claude Code plugin
cd dist/claude && zip -r ../../performance-agent-standards-claude.zip . && cd ../..

# Zip the compiled Codex rules
cd dist/codex && zip -r ../../performance-agent-standards-codex.zip . && cd ../..
```

These generated `.zip` files can then be uploaded as release assets on the GitHub Releases page. End-users can install them by simply downloading and extracting them directly into their agent's isolated plugin directories:
- **Gemini**: Extract to `~/.gemini/antigravity-cli/plugins/performance-agent-standards/`
- **Claude**: Extract to `~/.claude/plugins/performance-agent-standards/`
- **Codex**: Extract to `~/.codex/plugins/performance-agent-standards/`


## Automated Quality-Control Hooks

This repository configures an automated post-tool hook (`validate-markdown.sh`) to guarantee rule compliance during agent editing sessions.

### Agent Post-Tool Hooks (PostToolUse)
These hooks run dynamically inside the agent's workspace immediately after any file-writing or editing tool completes execution.

*   **`validate-markdown.sh`**:
    *   **Role**: Validates that all newly created or modified Markdown (`.md`) files conform to High-Density Markdown (HDMD) guidelines.
    *   **Logic**: If inline topic tags (e.g., `#standards`, `#typing`) are used in a document, it enforces that the file must start with a YAML frontmatter block containing a `topics:` index key. It rejects the edit (exits 1) if this index is missing.
    *   **Integration**: Automatically registered under Gemini's `hooks.json` and Claude Code's `settings.json` for file edit events (`Write`, `Edit`, `write_to_file`, etc.).


## Development Environment Setup

This project uses `pyproject.toml` to manage formatting and the virtual environment. To set up and prepare the local development environment, use `uv` (a fast Python package installer and resolver):

1. **Install uv** (if not already installed):
   For installation details, see the [uv documentation](https://github.com/astral-sh/uv).

2. **Synchronize and build the virtual environment**:
   Run the following command to create a virtual environment (`.venv`) and install all project and development dependencies defined in `pyproject.toml`:
   ```bash
   uv sync
   ```

3. **Activate the environment**:
   Activate the virtual environment to use the installed packages and tools:
   - **Linux/macOS**:
     ```bash
     source .venv/bin/activate
     ```
   - **Windows**:
     ```powershell
     .venv\Scripts\Activate.ps1
     ```
