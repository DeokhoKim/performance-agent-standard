# Performance Agent Standards Plugin

This repository provides baseline rules, hooks, and guidelines for development environments across multiple agent platforms including **Google Antigravity (Gemini)**, **Claude Code**, and **Codex**.

It uses a flexible compilation architecture to merge shared guidelines (e.g., High-Density Markdown Writing Rules) with provider-specific extensions while preventing config conflicts (like hook structures) across different agents.

## User Guide

### Installation

You can install the rules and hooks for your supported agents using the universal installation script (without cloning the repo), from a local clone, or via pre-packaged zip releases.

#### Option 1: Universal Installation via URL (Recommended)
This method auto-detects which agents are installed on your system (Antigravity, Legacy Gemini, Claude Code, or Codex), downloads their latest precompiled release ZIPs (or clones and compiles if no release is found), and installs/registers the plugin hooks automatically.

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

### Automated Quality-Control Hooks

This plugin registers post-tool hooks that run dynamically in your workspace immediately after any file-writing or editing tool completes execution.

*   **`validate-format.sh`**:
    *   **Role**: Runs `prek` (pre-commit) format and quality checks on modified files after file editing tool executions.
    *   **Behavior**: Resolves workspace repository root, checks for `prek` in the local `.venv`, and runs `prek run --files <file>` (or all files if unspecified), truncating log output to save token consumption.
    *   **Integration**: Automatically registered under Gemini's `hooks.json`, Claude Code's `settings.json`, and Codex's `settings.json` for post-tool file modification events.

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
│   ├── install.sh              # Universal installer and update script
│   └── validate-format.sh      # Post-tool hook script running prek format checks
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
