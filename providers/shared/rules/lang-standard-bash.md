# Bash Implementation Standards

Section: Bash Scripting Safety
Req: Bash Standards: Prevent common scripting errors and undefined variables.
- Rule: Safe Variable Checking: Always declare `set -u` or use `set -euo pipefail` at the top of scripts to avoid undefined variables and handle failures fast.

Req: Data-Flow Parallelism (Bash): Maximize shell pipeline streaming and OS buffering.
- Rule: Stream Pipelines: Utilize native shell pipelines (`cmd1 | cmd2 | cmd3`) and named pipes (`mkfifo`) to stream data between processes, allowing the OS kernel to automatically manage buffering, synchronization, and parallel execution.

Req: Bash Log Formatting & Inline Validation: Enforce clean inline test structures and portable colored logging.
- Rule: Inline Error Checking: Prefer compact inline test and exit chains over verbose multiline block statements. The pattern `[[ condition ]] && { log_command; exit 1; }` (or `||` for failure checking) is preferred.
- Rule: Standardized Format Logging: Always prefer `printf` over `echo` for logging and printing variables.
  - Explain: `printf` is standard POSIX compliant (avoiding cross-platform flags inconsistency like `-n` or `-e`), parses literal strings safely without flag interpretation, and provides robust formatting and reliable error exit statuses.
- Rule: Standardized Colored Logging: Map log levels to standard ANSI color codes and store them in named variables. Reset codes (`NC='\033[0m'`) MUST be applied at the end of every colored output.
  - Definition: Color Mapping Standards:
    - Debug: Cyan (`\033[0;36m`)
    - Info: Green (`\033[0;32m`)
    - Warn: Yellow (`\033[1;33m`)
    - Error: Red (`\033[0;31m`)
- Rule: Safe Variable Initialization: Prefer the parameter expansion initialization pattern `NAME=\${NAME:-initial_value\}` for user-configurable or environment-dependent variables. This allows environment variables to override defaults and prevents unbound variable errors under `set -u`.
  - Rule: Invariant Constants Exception: Invariant constants that must not be customized or overridden (such as terminal ANSI color codes like `RED` or `NC`) MUST use direct, immutable assignments (e.g., `RED='\033[0;31m'`) without fallback expansion patterns.

Req: Scoped Cleanup (Bash): Defensively manage exit states.
- Rule: Trap Exit Handlers: Register `trap` handlers (e.g., `trap 'cleanup' EXIT`) immediately after creating temp files, acquiring locks, or changing directories to guarantee exit cleanup under `set -e`.

