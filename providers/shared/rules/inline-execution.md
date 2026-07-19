# Inline Execution Rules

This document defines the language preferences and safety constraints for inline commands and scripts executed dynamically by agents in this workspace.

Section: Tool Execution Guidelines
Req: Language Preference: Prioritize shell scripts (Bash) over Python for dynamic and inline operations.
- Rule: Pipeline Parallelism: Bash shell scripts MUST be the primary choice for task automation and inline execution. Leverage piped OS-native utilities (`awk`, `sed`, `grep`, `xargs`, `jq`) to maximize parallelism and avoid runtime execution overhead.
- Rule: Style & Safety Compliance: All inline shell code and dynamic scripts MUST comply with the Bash safety standards outlined in `lang-standard-bash.md` (e.g., `set -euo pipefail`, POSIX `printf`, and inline exit checks).

Req: Python Fallback Policy: Use Python only when shell scripts become overly complex.
- Rule: Complexity Threshold: Python is permitted only for operations requiring complex multidimensional data mappings, advanced API consumption, or deep stateful logic that would result in unreadable shell code.
- Rule: Dependency Constraints: Python scripts MUST adhere to virtualenv and dependency limitations:
  - If `uv` and a local `.venv/` exist in the workspace, custom third-party packages may be imported and used.
  - If `uv` or a local `.venv/` is absent, only Python's standard library (built-in modules like `os`, `sys`, `json`, `urllib`) is usable.
  - Explain: This prevents runtime failures in environments without package installers. For single-file scripts requiring external packages, utilize PEP 723 (Inline Script Metadata) blocks (e.g., `# /// script ...`) to allow modern runner utilities like `uv run` to dynamically install dependencies in a sandboxed, ephemeral runtime.
