# Bash Implementation Standards

Section: Bash Scripting Safety
Req: Bash Standards: Prevent common scripting errors and undefined variables.
- Rule: Safe Variable Checking: Always declare `set -u` or use `set -euo pipefail` at the top of scripts to avoid undefined variables and handle failures fast.

Req: Data-Flow Parallelism (Bash): Maximize shell pipeline streaming and OS buffering.
- Rule: Stream Pipelines: Utilize native shell pipelines (`cmd1 | cmd2 | cmd3`) and named pipes (`mkfifo`) to stream data between processes, allowing the OS kernel to automatically manage buffering, synchronization, and parallel execution.

Req: Bash Log Formatting & Inline Validation: Enforce clean inline test structures and portable colored logging.
- Rule: Inline Error Checking: Prefer compact inline test or exit status check chains (e.g., `command || { log_command; exit 1; }`) over verbose multiline block statements.
- Rule: Standardized Format Logging: Always prefer `printf` over `echo` for logging and printing variables.
  - Explain: `printf` is standard POSIX compliant (avoiding cross-platform flags inconsistency like `-n` or `-e`), parses literal strings safely without flag interpretation, and provides robust formatting and reliable error exit statuses.
- Rule: Standardized Log Level Functions: Wrap colored logging into dedicated level-specific functions (e.g., `log_info`, `log_error`, `log_warn`, `log_debug`).
- Rule: Scoped ANSI Colors: The reset code variable (`NC='\033[0m'`) MUST be declared globally as a constant, as it is reused across all logging functions. Specific ANSI color code variables (e.g., `green`, `red`, `yellow`, `cyan`) MUST be declared as local variables within their respective logging functions. This keeps the namespace clean and prevents unused variable warnings (ShellCheck SC2034) if a script only calls a subset of logging levels.
  - Example:
    ```bash
    NC='\033[0m'

    log_info() {
      local green='\033[0;32m'
      printf "%b[INFO]%b %s\n" "$green" "$NC" "$1"
    }
    ```
  - Definition: Color Mapping Standards:
    - Debug: Cyan (`\033[0;36m`)
    - Info: Green (`\033[0;32m`)
    - Warn: Yellow (`\033[1;33m`)
    - Error: Red (`\033[0;31m`)
- Rule: Safe Variable Initialization: Prefer the parameter expansion initialization pattern `NAME=${NAME:-initial_value}` for user-configurable or environment-dependent variables. This allows environment variables to override defaults and prevents unbound variable errors under `set -u`.
  - Rule: Invariant Constants Exception: Invariant constants that must not be customized or overridden (such as terminal configuration properties like `NC`) MUST use direct, immutable assignments without fallback expansion patterns.

Req: Scoped Cleanup (Bash): Defensively manage exit states.
- Rule: Trap Exit Handlers: Register `trap` handlers (e.g., `trap 'cleanup' EXIT`) immediately after creating temp files, acquiring locks, or changing directories to guarantee exit cleanup under `set -e`.

Req: Documentation vs. Verification: Balance copy-paste readability with automated script safety.
- Rule: Documentation Scoped Happy-Path: Guide examples (e.g., `README.md`) should assume an "implicit happy path" to maximize readability. If directory changes are required, use a scoped subshell `(cd path && command)` to prevent shell state pollution without adding verbose checks.
- Rule: Non-Speculative Script Verification: Automated scripts must robustly check directory transitions, inputs, and commands (no happy paths). However, avoid speculative verification for highly remote or rare environment anomalies to keep scripts simple and prevent code bloat.
