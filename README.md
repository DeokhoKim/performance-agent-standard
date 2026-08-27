# Performance Agent Standards Plugin

This repository provides baseline rules, hooks, and guidelines for development environments across multiple agent platforms.

It uses a flexible compilation architecture to merge shared guidelines (e.g., High-Density Markdown Writing Rules) with provider-specific extensions while preventing config conflicts (like hook structures) across different agents.

## User Guide

### Installation

You can install the rules and hooks for your supported agents using the universal installation script (without cloning the repo), from a local clone, or via pre-packaged zip releases.

#### Option 1: Universal Installation via URL (Recommended)
This method auto-detects installed agent platforms, downloads their latest precompiled release ZIPs (or clones and compiles if no release is found), and installs/registers the plugin hooks automatically.

You can install it with a single shell command:
```bash
curl -sSfL https://raw.githubusercontent.com/DeokhoKim/performance-agent-standard/main/scripts/install.sh | bash
```

**Customizing Installation:**
*   **Specific Agent:** Force installation for a single agent only (e.g., `claude`):
    ```bash
    curl -sSfL https://raw.githubusercontent.com/DeokhoKim/performance-agent-standard/main/scripts/install.sh | bash -s -- --provider claude
    ```
*   **Force Reinstallation:** Overwrite matching versions:
    ```bash
    curl -sSfL https://raw.githubusercontent.com/DeokhoKim/performance-agent-standard/main/scripts/install.sh | bash -s -- --force
    ```

#### Option 2: Pre-packaged Zip Releases
Alternatively, you can download a pre-packaged `.zip` release from the GitHub Releases page and extract it directly into your agent's isolated plugin directory:
- **Gemini**: Extract to `~/.gemini/config/plugins/performance-agent-standards/`
- **Claude**: Extract to `~/.claude/plugins/performance-agent-standards/`
- **Codex**: Extract to `~/.codex/plugins/performance-agent-standards/`

### Automated Lifecycle Hooks

This plugin registers cross-platform lifecycle hooks (`PreToolUse` and `PostToolUse`) that protect repository integrity, dynamically inject relevant coding standards, and validate file modifications across supported agent platforms.

#### Pre-Tool Hooks (`scripts/hooks/pre-tool/`)
*   **`inject-lang-standard.sh`**:
    *   **Role**: Dynamically injects context-specific coding and language standards before file modifications (`write_to_file`, `replace_file_content`, `Write`, `Edit`, `MultiEdit`).
    *   **Behavior**: Inspects the target file extension from tool arguments and injects relevant modular rules (e.g., Rust, C/C++, Bash, Python, Markdown) directly into the agent context.
*   **`bash-guard.sh`**:
    *   **Role**: Intercepts shell execution tools (`run_command`, `Bash`, `Cmd`) to block dangerous or destructive system commands.
    *   **Behavior**: Blocks execution of high-risk patterns such as `rm -rf /`, `rm -rf ~`, `sudo`, `chmod -R 777`, `kill -9`, and unverified remote shell pipes (`curl | bash`, `wget | bash`).
*   **`git-guard.sh`**:
    *   **Role**: Intercepts shell execution tools to prevent destructive Git operations.
    *   **Behavior**: Blocks high-risk Git commands such as `git push --force` / `-f`, `git reset --hard`, `git clean -f`, and `git branch -D`.

#### Post-Tool Hooks (`scripts/hooks/post-tool/`)
*   **`validate-format.sh`**:
    *   **Role**: Runs `prek` (pre-commit) format and quality checks on modified files after file editing tool executions.
    *   **Behavior**: Resolves workspace repository root, checks for `prek` in the local `.venv`, and runs `prek run --files <file>` (or all files if unspecified), truncating log output to save token consumption.

#### Hook Utilities (`scripts/hooks/`)
*   **`parse-hook-input.sh`**:
    *   **Role**: Cross-platform JSON payload and environment variable parser.
    *   **Behavior**: Normalizes payload extraction across supported agent platforms to extract workspace paths, command lines, and target files.

## Developer Guide

### Architecture

To prevent structural and syntax conflicts, rules and hooks are isolated by provider in the `providers/` directory and compiled into `dist/` before deployment:

```text
performance-agent-standards/
├── .pre-commit-config.yaml     # Git hooks configuration
├── .gitignore                  # Git ignore rules for python virtualenvs and cache
├── pyproject.toml              # Python project packaging and dev tools layout
├── README.md                   # This documentation
├── providers/                  # Isolated configurations to prevent conflicts
│   ├── shared/                 # Shared base config, rules & skills
│   │   ├── rules/              # Modular shared rule definitions
│   │   │   ├── code-simplicity.md      # Minimalist engineering and simplicity standards
│   │   │   ├── development-standards.md# Toolchain, venv, and environment resolution
│   │   │   ├── inline-execution.md     # Agent inline command and execution standards
│   │   │   ├── karpathy-guidelines.md  # Shared core engineering instincts
│   │   │   ├── lang-standard-bash.md   # Bash scripting safety standards
│   │   │   ├── lang-standard-common.md # Common language standards (config/clamping)
│   │   │   ├── lang-standard-native.md # Native language standards (sorting/allocations)
│   │   │   ├── lang-standard-python.md # Python type hints and modern idioms
│   │   │   ├── lang-standard-rust.md   # Rust implementation standards (panics/iterators)
│   │   │   ├── markdown-reading.md     # Markdown Reading & Translation Rules (Pseudocode)
│   │   │   ├── markdown-writing.md     # Markdown Writing Rules
│   │   │   └── workspace-hygiene.md    # Active workspace hygiene and navigation rules
│   │   └── skills/             # Cross-platform skills (build-permission, create-pr, staged-commit)
│   ├── gemini/                 # Gemini / Antigravity specifics
│   │   ├── rules/
│   │   │   └── always-read.md  # Core rules (always read)
│   │   ├── hooks.json          # Hook configuration (PreToolUse & PostToolUse)
│   │   └── plugin.json         # Plugin manifest
│   ├── claude/                 # Claude Code specifics
│   │   ├── rules/
│   │   │   └── always-read.md  # Core rules (always read)
│   │   └── settings.json       # Settings and hook configuration
│   └── codex/                  # Codex specifics
│       ├── rules/
│       │   └── always-read.md  # Core rules (always read)
│       └── settings.json       # Settings and hook configuration
├── scripts/                    # Utility and hook scripts
│   ├── compile.sh              # Merges shared rules & configs with provider-specific ones
│   ├── install.sh              # Universal installer and update script
│   └── hooks/                  # Agent lifecycle hook implementations
│       ├── pre-tool/           # Pre-tool execution guards & context injectors
│       │   ├── bash-guard.sh           # Intercepts & blocks destructive shell commands
│       │   ├── git-guard.sh            # Intercepts & blocks destructive git operations
│       │   └── inject-lang-standard.sh # Injects filetype-specific standards into context
│       ├── post-tool/          # Post-tool execution validation
│       │   └── validate-format.sh      # Runs prek format & quality checks on modified files
│       └── parse-hook-input.sh # Cross-platform payload/environment parser
```

### Compilation & Manual Packaging

To compile changes or package the release artifacts manually:

#### 1. Compile Rules
```bash
# Merge shared rules & configs with provider-specific ones into dist/
./scripts/compile.sh
```

#### 2. Package Release Artifacts
You can package the compiled directory structures under `dist/` into separate zip release artifacts to distribute them without requiring end-users to run compilation or install scripts:

```bash
# Zip the compiled Antigravity plugin
(cd dist/antigravity && zip -r ../../performance-agent-standards-antigravity.zip .)

# Zip the compiled legacy Gemini plugin
(cd dist/gemini && zip -r ../../performance-agent-standards-gemini.zip .)

# Zip the compiled Claude Code plugin
(cd dist/claude && zip -r ../../performance-agent-standards-claude.zip .)

# Zip the compiled Codex rules
(cd dist/codex && zip -r ../../performance-agent-standards-codex.zip .)
```

These generated `.zip` files can then be uploaded as release assets on the GitHub Releases page.

### Local Development Setup

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
