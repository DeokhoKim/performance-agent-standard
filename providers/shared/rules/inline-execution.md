# Inline Execution Rules

Section: Tool Execution Guidelines
Req: Language Preference: Prioritize shell scripts (Bash) over Python for dynamic and inline operations.
- Rule: Pipeline Parallelism: Bash shell scripts MUST be the primary choice for task automation and inline execution. Leverage piped OS-native utilities (`awk`, `sed`, `grep`, `xargs`, `jq`) to maximize parallelism and avoid runtime execution overhead.
- Rule: Style & Safety Compliance: All inline shell code and dynamic scripts MUST comply with standard Bash safety practices (e.g., `set -euo pipefail`, POSIX `printf`, and inline exit checks).

Req: Python Fallback Policy: Use Python only when shell scripts become overly complex.
- Rule: Complexity Threshold: Python is permitted only for operations requiring complex multidimensional data mappings, advanced API consumption, or deep stateful logic that would result in unreadable shell code.
- Rule: Dependency Constraints: Python scripts MUST adhere to the resolved environment priority:
  - Third-party packages are permitted only when installed in the resolved local environment.
  - For standalone scripts requiring external packages outside a resolved local environment, declare PEP 723 metadata (`# /// script ...`) with `uv run` to guarantee sandboxed execution.
  - In the absence of third-party package dependencies, restrict execution strictly to the Python standard library (`os`, `sys`, `json`, `urllib`).
