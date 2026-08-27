# Bash Implementation Standards

Section: Bash Scripting Safety
Req: Bash Standards: Prevent common scripting errors && undefined variables.
- Rule: Safe Variable Checking: Enforce `set -u` || `set -euo pipefail` at the top of scripts to avoid undefined variables && handle failures fast.

Req: Data-Flow Parallelism (Bash): Maximize shell pipeline streaming && OS buffering.
- Rule: Stream Pipelines: Enforce native shell pipelines (`cmd1 | cmd2 | cmd3`) && named pipes (`mkfifo`) to stream data between processes, delegating buffering, synchronization, && parallel execution directly to the OS kernel.

Req: Bash Log Formatting && Inline Validation: Enforce clean inline test structures && portable colored logging.
- Rule: Inline Error Checking: Enforce compact inline test || exit status check chains (e.g., `command || { log_command; exit 1; }`) over verbose multiline block statements.
- Rule: Standardized Format Logging: Enforce `printf` over `echo` for logging && printing variables to guarantee POSIX compliance, avoid cross-platform flag inconsistencies (`-n`/`-e`), && provide reliable exit statuses.
- Rule: Standardized Log Level Functions: Wrap colored logging into dedicated level-specific functions (e.g., `log_info`, `log_error`, `log_warn`, `log_debug`).
- Rule: Scoped ANSI Colors: Declare the reset constant (`NC='\033[0m'`) globally for cross-function reuse && declare specific ANSI color variables (`green`, `red`, `yellow`, `cyan`) as local variables inside their respective logging functions to isolate namespaces && eliminate ShellCheck `SC2034` warnings.
  - Def: Color Debug → Cyan (`\033[0;36m`)
  - Def: Color Info → Green (`\033[0;32m`)
  - Def: Color Warn → Yellow (`\033[1;33m`)
  - Def: Color Error → Red (`\033[0;31m`)
  - Example:
    ```bash
    NC='\033[0m'

    log_info() {
      local green='\033[0;32m'
      printf "%b[INFO]%b %s\n" "$green" "$NC" "$1"
    }
    ```
- Rule: Safe Variable Initialization: Enforce parameter expansion `${NAME:-initial_value}` on user-configurable || environment-dependent variables to allow environment overrides && prevent unbound variable errors under `set -u`.
  - Rule: Invariant Constants Exception: Enforce direct, immutable assignments without fallback expansion patterns for invariant constants (e.g., `NC`).

Req: Scoped Cleanup (Bash): Defensively manage exit states.
- Rule: Trap Exit Handlers: Enforce `trap` handlers (e.g., `trap 'cleanup' EXIT`) immediately after creating temp files, acquiring locks, || changing directories to guarantee exit cleanup under `set -e`.

Req: Documentation vs. Verification: Balance copy-paste readability with automated script safety.
- Rule: Documentation Scoped Happy-Path: Enforce implicit happy paths in guide examples (e.g., `README.md`) for readability; use scoped subshells `(cd path && command)` when changing directories to prevent shell state pollution.
- Rule: Non-Speculative Script Verification: Enforce explicit directory transition, input, && command checks in automated scripts; prohibit speculative verification for remote || rare anomalies to prevent code bloat.
