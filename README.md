# Performance Agent Standards Plugin

This repository provides deterministic rules, runtime hooks, and engineering standards for autonomous development across multi-agent platforms (Google Antigravity, Gemini CLI, Claude Code, and OpenAI Codex).

It uses a flexible compilation architecture to merge shared guidelines (e.g., High-Density Markdown Writing, Code Simplicity, Language-Specific Standards) with provider-specific extensions while enforcing runtime safety and token efficiency via zero-overhead POSIX hooks.

---

## User Guide

### Platform & OS Invariant
- **Strict Unix/POSIX Support**: This architecture is optimized natively for **Linux and macOS** (POSIX environments).
- **No Windows Support**: Windows, PowerShell, and `cmd.exe` environments are explicitly not supported to eliminate path-normalization shims, drive-letter layers, and multi-script maintenance.

### Installation

You can install the rules and hooks for your supported agents using the universal installation script (without cloning the repo), from a local clone, or via pre-packaged zip releases.

#### Option 1: Universal Installation via URL (Recommended)
This method auto-detects installed agent platforms, downloads their latest precompiled release ZIPs (or clones and compiles if no release is found), and installs/registers the plugin hooks automatically.

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
Download a pre-packaged `.zip` release from GitHub Releases and extract it into your agent's isolated plugin directory:
- **Antigravity / Gemini**: Extract to `~/.gemini/config/plugins/performance-agent-standards/`
- **Claude Code**: Extract to `~/.claude/plugins/performance-agent-standards/`
- **Codex**: Extract to `~/.codex/plugins/performance-agent-standards/`

---

### Automated Lifecycle Hooks

This plugin registers cross-platform lifecycle hooks (`PreToolUse`, `PostToolUse`, and `SessionEnd`) that protect repository integrity, conserve context tokens, dynamically inject coding standards, and validate file modifications.

#### 1. Pre-Tool Hooks (`scripts/hooks/pre-tool/`)
*   **`read-once.sh`**:
    *   **Role**: Conserves LLM context tokens by intercepting redundant file read tool calls (`view_file`, `Read`, `cat`).
    *   **Behavior**: Tracks file modification timestamps (`mtime`) and snapshots per session in `/tmp/pas-read-cache-${SESSION_ID}/`. If unmodified, it blocks the redundant read and directs the agent to its active context; if modified, it computes a compact unified diff (`diff -u`). Features subagent cache partitioning and dynamic amnesia bypass to prevent false-positive re-read blocks.
*   **`file-guard.sh`**:
    *   **Role**: Intercepts file mutation tools (`write_to_file`, `replace_file_content`, `Write`, `Edit`, `MultiEdit`) to protect sensitive assets and lockfiles.
    *   **Behavior**: Employs `realpath -m` path canonicalization to prevent traversal bypasses (`../`) and blocks unauthorized direct mutations to secrets/keys (`.pem`, `.key`, `id_rsa`), environment state (`.env*`, `*.tfstate`), package lockfiles (`package-lock.json`, `uv.lock`, `Cargo.lock`), and Git metadata (`.git`).
*   **`bash-guard.sh`**:
    *   **Role**: Intercepts shell execution tools (`run_command`, `Bash`, `Cmd`) to block dangerous OS commands, in-place file editing bypasses, and mutating GitHub APIs.
    *   **Behavior**: Blocks recursive deletions (`rm -rf /`, `rm -rf ~`), disk utilities (`dd`, `mkfs`, `fdisk`, `wipefs`, `shred`), privilege escalations (`sudo`, `chmod -R 777`), forkbombs, in-place stream edits (`sed -i`, `perl -i`, `ruby -i`), and destructive GitHub CLI operations (`gh repo delete`, `gh api DELETE/PUT/PATCH`).
*   **`git-guard.sh`**:
    *   **Role**: Intercepts shell execution tools to prevent destructive Git history/tree operations.
    *   **Behavior**: Features chaining-aware boundary parsing (`GIT_PREFIX`) across subshells, pipelines, and variable prefixes (`cd /repo && git reset --hard`). Blocks force pushes (`push -f`, `--force-with-lease`), destructive tree resets (`reset --hard`, `reset --merge`), untracked file purges (`clean -f`), branch force deletions (`branch -D`), working tree wipes (`checkout .`, `restore .`), stash purges (`stash drop`, `stash clear`), and validation bypasses (`--no-verify`, `commit -n`).
*   **`inject-lang-standard.sh`**:
    *   **Role**: Dynamically injects context-specific coding and language standards before file modifications.
    *   **Behavior**: Inspects the target file extension from tool arguments and injects relevant modular rules (e.g., Rust, C/C++, Bash, Python, Markdown) directly into the agent context.

#### 2. Post-Tool Hooks (`scripts/hooks/post-tool/`)
*   **`validate-format.sh`**:
    *   **Role**: Runs `prek` (pre-commit) format and quality checks on modified files after file editing tool executions.
    *   **Behavior**: Resolves workspace repository root, checks for `prek` in the local `.venv`, and runs `prek run --files <file>`, truncating log output to prevent context flooding.

#### 3. Session Lifecycle Hooks (`scripts/hooks/session-close/`)
*   **`cleanup-session.sh`**:
    *   **Role**: Safely purges ephemeral session caches upon session termination (`SessionEnd`).
    *   **Behavior**: Recursively removes `/tmp/pas-read-cache-${SESSION_ID}/` with strict path traversal validation, and sweeps orphaned temporary files older than 24 hours.

#### 4. Hook Utilities (`scripts/hooks/`)
*   **`parse-hook-input.sh`**:
    *   **Role**: Cross-platform JSON payload and environment variable parser.
    *   **Behavior**: Normalizes payload extraction across supported agent platforms to extract workspace paths, command lines, and target files.

---

## Developer Guide

### Architecture & File Structure

To prevent structural and syntax conflicts, rules and hooks are isolated by provider in the `providers/` directory and compiled into `dist/` before deployment:

```text
performance-agent-standards/
├── .pre-commit-config.yaml     # Git hooks configuration
├── .gitignore                  # Git ignore rules for python virtualenvs and cache
├── pyproject.toml              # Python project packaging and dev tools layout
├── README.md                   # Repository documentation
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
│   │   ├── hooks.json          # Hook configuration (PreToolUse, PostToolUse, SessionEnd)
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
│       │   ├── file-guard.sh           # Intercepts & blocks sensitive path / lockfile mutations
│       │   ├── git-guard.sh            # Intercepts & blocks destructive git operations
│       │   ├── inject-lang-standard.sh # Injects filetype-specific standards into context
│       │   └── read-once.sh            # Conserves tokens & manages diff-mode read cache
│       ├── post-tool/          # Post-tool execution validation
│       │   └── validate-format.sh      # Runs prek format & quality checks on modified files
│       ├── session-close/      # Session lifecycle hooks
│       │   └── cleanup-session.sh      # Purges /tmp/pas-read-cache-${SESSION_ID} on session close
│       └── parse-hook-input.sh # Cross-platform payload/environment parser
```

---

### Compilation & Manual Packaging

#### 1. Compile Rules
```bash
# Merge shared rules & configs with provider-specific ones into dist/
./scripts/compile.sh
```

#### 2. Package Release Artifacts
Package the compiled directory structures under `dist/` into zip release artifacts:

```bash
# Zip the compiled Antigravity plugin
(cd dist/antigravity && zip -r ../../performance-agent-standards-antigravity.zip .)

# Zip the compiled Gemini plugin
(cd dist/gemini && zip -r ../../performance-agent-standards-gemini.zip .)

# Zip the compiled Claude Code plugin
(cd dist/claude && zip -r ../../performance-agent-standards-claude.zip .)

# Zip the compiled Codex rules
(cd dist/codex && zip -r ../../performance-agent-standards-codex.zip .)
```

---

### Local Development Setup

This project uses `pyproject.toml` to manage formatting and the virtual environment. Use `uv` for local setup:

1. **Install uv** (if not already installed):
   For installation details, see the [uv documentation](https://github.com/astral-sh/uv).

2. **Synchronize virtual environment**:
   ```bash
   uv sync
   ```

3. **Activate environment** (Linux / macOS):
   ```bash
   source .venv/bin/activate
   ```

---

## References & Acknowledgements

This project synthesizes and adapts core concepts, engineering philosophies, and runtime security architectures from the broader AI agent research and open-source community:

*   **Andrej Karpathy's Engineering Guidelines**:
    *   The foundational instincts encoded in [`providers/shared/rules/karpathy-guidelines.md`](file:///home/duty/workspace/performance-agent-standards/providers/shared/rules/karpathy-guidelines.md) (Think Before Coding, Simplicity First, Surgical Changes, and Goal-Driven Execution) are directly derived from and inspired by [Andrej Karpathy's open-source skills repository](https://github.com/multica-ai/andrej-karpathy-skills).
*   **Boucle-Framework Architecture**:
    *   The runtime hook concepts for shell command gating (`bash-guard`) and git history protection (`git-guard`) are inspired by the security architectures explored in [Bande-a-Bonnot/Boucle-framework](https://github.com/Bande-a-Bonnot/Boucle-framework), re-engineered natively here for multi-platform Unix agent environments (`performance-agent-standards`).
*   **Ponytail Architecture & Rules**:
    *   The context token conservation patterns (`read-once`) and minimalist engineering instincts are inspired by the token-efficiency and anti-bloat paradigms explored in [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail).
*   **Multi-Platform Agent Ecosystems**:
    *   Runtime hook schemas, lifecycles, and tool interfaces are modeled for deterministic compatibility across [Google Antigravity](https://cloud.google.com/), [Gemini CLI](https://github.com/google-gemini/), [Claude Code](https://docs.anthropic.com/en/docs/claude-code), and [OpenAI Codex](https://openai.com/).
