# Comprehensive Technical Analysis: Boucle-Framework Security & Optimization Architecture

This report delivers a deep-dive technical investigation and comparative analysis of four core components from [Bande-a-Bonnot/Boucle-framework](https://github.com/Bande-a-Bonnot/Boucle-framework): **`read-once`**, **`bash-guard`**, **`git-safe`** (compared to local `git-guard`), and **`file-guard`**.

---

## 1. Architectural Overview & Component Taxonomy

The **Boucle-framework** provides deterministic, runtime hook primitives designed to safeguard autonomous AI agent execution, prevent catastrophic filesystem/git operations, and minimize LLM context degradation.

| Component | Target Lifecycle Event | Primary Purpose | Local Equivalent in `performance-agent-standards` |
| :--- | :--- | :--- | :--- |
| **`read-once`** | `PreToolUse` (`Read`, `view_file`) & `PostCompact` | Context token conservation & diff-mode inspection | *Not yet implemented* (Candidate for inclusion) |
| **`bash-guard`** | `PreToolUse` (`Bash`, `run_command`) | Destructive OS command & shell injection blocking | `scripts/hooks/pre-tool/bash-guard.sh` |
| **`git-safe`** | `PreToolUse` (`Bash`, `run_command`) | Destructive Git history/tree modification prevention | `scripts/hooks/pre-tool/git-guard.sh` |
| **`file-guard`** | `PreToolUse` (`Write`, `Edit`, `Bash` redirects) | Sensitive path isolation & file mutation gating | *Not yet implemented* (Candidate for inclusion) |

---

## 2. Deep-Dive Specification: `read-once`

### 2.0 Architectural Invariant: Pure Unix/POSIX Target & Windows Non-Support
- **Non-Support of Windows**: The architecture explicitly SHALL NOT support Windows or PowerShell environments.
- **Unix/POSIX Native Optimization**: Eliminating Windows compatibility avoids multi-layered abstractions, path normalization overhead (`\` vs `/`), and dual script maintenance (`.ps1` / `.sh`). All hooks are optimized strictly for native Linux and macOS POSIX shells with zero-overhead standard utilities (`grep`, `jq`, `stat`, `realpath`).

### 2.1 Purpose & Token Economy
Autonomous coding agents routinely engage in iterative "Think-Act-Verify" loops where entire source files are re-read repeatedly before and after trivial edits.
- **Context Degradation**: Redundant reads saturate the context window, causing rapid context compaction, higher latency, and "lost-in-the-middle" attention degradation.
- **Cost Inefficiency**: Reading a 600-line source file (~3,000 tokens) 5 times in a single session wastes 15,000 input tokens.
- **`read-once` Solution**: Deterministically intercepts redundant read tool requests, verifying filesystem modification timestamps (`mtime`). If unchanged, it blocks the tool execution and points the agent to its existing context. If modified, it returns an incremental unified diff instead of the full file.

```mermaid
flowchart TD
    A[Agent invokes Read / view_file] --> B{READ_ONCE_DISABLED == 1?}
    B -- Yes --> C[Pass tool execution through]
    B -- No --> D{File in Session Cache?}
    D -- No --> E[Record Snapshot & mtime -> Pass through]
    D -- Yes --> F{Current Time - Cached Time > TTL?}
    F -- Yes --> E
    F -- No --> G{Current mtime == Cached mtime?}
    G -- Yes --> H[INTERCEPT: Block Read<br/>'Content already in active context']
    G -- No --> I{READ_ONCE_DIFF == 1?}
    I -- No --> E
    I -- Yes --> J[Compute diff -u cached vs current]
    J --> K{Diff Line Count <= READ_ONCE_DIFF_MAX?}
    K -- Yes --> L[INTERCEPT: Return Unified Diff Only]
    K -- No --> E
```

### 2.2 Technical Implementation Mechanics

#### A. Hook Lifecycle Integration
- **`PreToolUse` Hook**:
  - Intercepts tool calls targeting file reads (`Read`, `view_file`, `cat`).
  - Evaluates session cache state prior to runner execution.
- **`PostCompact` Hook**:
  - Automatically flushes/clears `/tmp/read-once-${SESSION_ID}/` when the platform executes context compaction.
  - Ensures that when context memory is truncated or summarized, the agent is never blocked from re-reading necessary source files.

#### B. State Management & Cache Architecture
- **Cache Storage**: Scoped per session (`/tmp/read-once-${SESSION_ID}/` or `~/.cache/boucle/read-once/`).
- **Metadata Tracked per File**:
  - `path`: Canonical absolute path (resolved via `realpath` / `readlink -f`).
  - `mtime`: File modification epoch timestamp (`stat -c %Y` / `stat -f %m`).
  - `cached_at`: Timestamp when the snapshot was recorded.
  - `snapshot`: Byte-for-byte copy of the file content at last read.
- **Configurable Environment Variables**:
  - `READ_ONCE_TTL`: Cache entry time-to-live in seconds (Default: `1200` / 20 minutes).
  - `READ_ONCE_DIFF`: Toggle unified diff inspection mode (Default: `0` or `1`).
  - `READ_ONCE_DIFF_MAX`: Maximum diff line threshold before falling back to full read (Default: `40`).
  - `READ_ONCE_DISABLED`: Global bypass kill-switch (Default: `0`).

#### C. Interception & Response Payloads
When `read-once` intercepts a redundant read, it terminates the hook with code `2` (or structured rejection JSON) emitting context-preserving explanations:
- **Unmodified File**:
  ```text
  [read-once] File already read: /path/to/file.rs
  The file content is already present in your active context window. Re-read blocked to save tokens.
  ```
- **Modified File (Diff Mode)**:
  ```text
  [read-once] File modified since last read. Diff from previous version:
  --- a/src/main.rs
  +++ b/src/main.rs
  @@ -14,3 +14,3 @@
  -    let timeout = 30;
  +    let timeout = 60;
  ```

### 2.3 Edge Cases & Mitigation Strategies

| Edge Case / Failure Vector | Impact / Risk | `read-once` Mitigation Protocol |
| :--- | :--- | :--- |
| **Partial Range Slicing (`StartLine`/`EndLine`)** | Path-only cache blocks subsequent read of non-overlapping line ranges. | Cache keys MUST index `(path, start_line, end_line)`. If prior read was full, reject ranges; if prior read was partial, permit distinct ranges. |
| **Context Compaction Disconnect** | Hook blocks reads after agent context was compacted without a `PostCompact` trigger. | Passive `READ_ONCE_TTL` (20 min) invalidates stale entries automatically. |
| **Massive File Refactor** | Unified diff output exceeds size of full file. | `READ_ONCE_DIFF_MAX` threshold (40 lines) falls back to fresh full read. |
| **Symlinks & Relative Paths** | Different path strings referencing identical inodes bypass cache. | Path canonicalization via `realpath` before indexing. |
| **Multi-Agent Concurrency** | Race conditions or cross-agent cache collisions. | Isolate cache paths by unique session ID (`/tmp/read-once-$SESSION_ID/`). |

### 2.4 Token & Performance Metrics
- **Direct Redundant Read Savings**: Eliminates ~1,500 to 4,000 tokens per duplicate read call.
- **Diff Mode Verification Loops**: Reduces a 600-line re-read (~3,000 tokens) to a 15-line diff (~120 tokens), achieving **96% token reduction** per edit-verification cycle.
- **Session-Wide Impact**: In a 20-step coding workflow with 8–10 verification reads, `read-once` saves **15,000–30,000 tokens** (~20–35% of total input context).

---

## 3. Comparative Analysis: `bash-guard`

### 3.1 Architectural Design & Execution Models
- **Boucle-framework (`bash-guard`)**:
  - Tailored primarily for Claude Code ecosystem with dual POSIX Bash (`.sh`) and PowerShell (`.ps1`) scripts.
  - Implements the modern Claude Code hook schema (`hookSpecificOutput.permissionDecision = "deny"`).
  - Employs a broad, monolithic threat filter covering OS deletion, privilege escalation, disk manipulation, in-place file editing (`sed -i`), and GitHub CLI API mutations.
- **Local Implementation (`performance-agent-standards/scripts/hooks/pre-tool/bash-guard.sh`)**:
  - Architected as a universal multi-platform hook parser (`parse_command_line`) supporting Claude Code, Google Antigravity (Gemini), OpenAI Codex, and Gemini CLI.
  - Employs modular separation of concerns: OS command safety is isolated in `bash-guard.sh`, Git safety in `git-guard.sh`, and language rules in `inject-lang-standard.sh`.

```
                    ┌──────────────────────────────────────────────────────────┐
                    │               Incoming PreToolUse Payload                │
                    └─────────────────────────────┬────────────────────────────┘
                                                  │
                                                  ▼
                        ┌──────────────────────────────────────────────────┐
                        │      Universal Hook Parser (parse-hook-input)    │
                        │  Normalizes: .tool_input, .CommandLine, .cmd     │
                        └─────────────────────────┬────────────────────────┘
                                                  │
                         ┌────────────────────────┴────────────────────────┐
                         │                                                 │
                         ▼                                                 ▼
        ┌───────────────────────────────────┐             ┌───────────────────────────────────┐
        │          bash-guard.sh            │             │           git-guard.sh            │
        │ OS Destruction, Sudo, Kill, Pipe  │             │ Force Push, Reset, Clean, Branch  │
        └───────────────────────────────────┘             └───────────────────────────────────┘
```

### 3.2 Feature Matrix & Comparison

| Feature Dimension | Boucle-framework `bash-guard` | Local `bash-guard.sh` (Revised Design) | Architectural Assessment |
| :--- | :--- | :--- | :--- |
| **OS Target & Portability** | Dual POSIX Bash & Windows PowerShell | Strict Unix/POSIX (Linux/macOS) only | **No Windows Support**: Eliminates PowerShell abstraction overhead. |
| **Response Schema** | Modern Claude schema (`hookSpecificOutput`) | Dual/Universal Schema (`decision` + `hookSpecificOutput`) | **Universal Multi-Agent**: Fully compliant with Claude Code, Antigravity, Codex. |
| **OS Destruction Coverage** | `rm -rf`, `shred`, `truncate`, `wipefs`, `dd` | `rm -rf`, `shred`, `dd`, `mkfs`, `wipefs`, `fdisk`, forkbombs | Broadened Unix destruction protection. |
| **In-Place File Bypass Guard** | Blocks `sed -i`, `perl -i`, `ruby -i`, `ed` | Blocks `sed -i`, `perl -i`, `ruby -i`, `ed` | Closes stream-editing bypass of file tool hooks. |
| **GitHub CLI API Safeguards** | Blocks `gh repo delete`, `gh api DELETE/PUT/PATCH` | Granular API regex: blocks destructive `gh api (DELETE\|PUT\|PATCH)` | Deep protection against remote repo & branch tampering. |
| **Permutation Hardening** | Basic string matching | Flag & whitespace permutation regex (`-[a-zA-Z]*r...`) | Hardened against argument reordering (`rm -fr /`, `rm -r -f /`). |
| **Configuration Layering** | Requires `.bash-guard` allowlist file | Zero-Config Static Blocklist (No allowlist needed) | **Zero-IO Overhead**: Deterministic, token-efficient, zero config parsing. |
| **Feedback Verbosity** | Verbose multi-line guidance | Clarified & Concise High-Density Message | Minimizes token waste in LLM context across frequent tool calls. |

### 3.3 Pros & Cons Summary

#### Boucle-Framework `bash-guard`
- **Pros**:
  1. Broad security coverage including disk utilities (`dd`, `fdisk`, `wipefs`) and in-place file modifiers (`sed -i`).
  2. Protects against GitHub CLI infrastructure destruction (`gh repo delete`, branch protection tampering).
- **Cons**:
  1. Monolithic structure mixing PowerShell and Bash script maintenance.
  2. Single-platform payload parser tightly coupled only to Claude Code schema.
  3. Relies on allowlists adding filesystem read overhead.

#### Local `bash-guard.sh` (Target Architecture)
- **Pros**:
  1. Universal dual-schema response (`decision` + `hookSpecificOutput`) natively compatible with Antigravity, Gemini CLI, Claude Code, and Codex.
  2. Pure zero-overhead Unix/POSIX optimization without Windows/PowerShell clutter.
  3. Permutation-hardened regex for flags (`rm -fr /`, `rm -r -f /`, `rm --recursive -f`).
  4. Intercepts in-place stream mutations (`sed -i`, `perl -i`) preventing tool-hook circumvention.
  5. Intercepts destructive `gh api` mutation methods (`DELETE`, `PUT`, `PATCH`).
  6. Zero-config architecture (no allowlist required) with ultra-concise, high-density rejection messages.
- **Cons**:
  1. Strict blocklist requires disciplined regex maintenance.

---

## 4. Comparative Analysis: `git-safe` vs. `git-guard`

### 4.1 Architectural Design & Execution Models
- **Boucle-framework (`git-safe`)**:
  - Focuses on deep semantic safety for Git operations in Claude Code.
  - Provides actionable remediation feedback (e.g., suggesting `git stash` instead of `git reset --hard`, or `git clean -n` instead of `git clean -f`).
  - Intercepts `--no-verify` to prevent agents from evading repository pre-commit and pre-push hooks.
- **Local Implementation (`performance-agent-standards/scripts/hooks/pre-tool/git-guard.sh`)**:
  - Implements universal multi-agent JSON parsing and structured rejection messaging (`{"decision": "reject", "message": "..."}`).
  - Evaluates commands against a static `BLOCKLIST` array.

### 4.2 Critical Vulnerability in Local `git-guard.sh`
In `scripts/hooks/pre-tool/git-guard.sh` line 39:
```bash
printf "%s" "$command_line" | grep -Eq "^\s*git\s+" || return 0
```
- **Vulnerability**: The regex anchor `^\s*git\s+` requires `git` to appear at the very start of the command line.
- **Bypass Vectors**: Any compound, chained, or environment-prefixed command **completely bypasses** `git-guard.sh`:
  - `cd /path/to/repo && git reset --hard` (Bypasses guard)
  - `npm test && git push --force` (Bypasses guard)
  - `GIT_DIR=.git git clean -f` (Bypasses guard)
  - `(git branch -D main)` (Bypasses guard)

### 4.3 Feature Matrix & Comparison

| Feature Dimension | Boucle-framework `git-safe` | Local `git-guard.sh` | Architectural Assessment |
| :--- | :--- | :--- | :--- |
| **Compound Command Parsing** | Scans entire command string across pipelines | Uses strict `^\s*git\s+` anchor | **Critical Vulnerability in Local**; Boucle is secure against chaining. |
| **Command Coverage** | Push force, reset hard, clean, branch -D, checkout/restore `.`, stash drop/clear, reflog expire | Push force, reset hard, clean -f, branch -D | Boucle protects working tree wipes and stash destruction. |
| **Hook Bypass Prevention** | Explicitly blocks `--no-verify` | Ignored | Boucle prevents bypassing commit verification. |
| **Remediation Feedback** | Actionable: provides exact replacement commands | Generic rejection message | Boucle accelerates agent self-correction. |
| **Multi-Platform Support** | Claude Code only | Claude Code, Antigravity, Codex, Gemini | **Local is superior** in platform normalization. |

### 4.4 Pros & Cons Summary

#### Boucle-Framework `git-safe`
- **Pros**:
  1. Complete protection across working tree wipes (`git checkout .`, `git restore .`), stash drops, and reflogs.
  2. Intercepts `--no-verify` hook evasion.
  3. Actionable agent guidance reduces stuck agent loops.
- **Cons**:
  1. Lacks multi-platform envelope normalization.
  2. Requires separate `branch-guard` hook for branch protection.

#### Local `git-guard.sh`
- **Pros**:
  1. Universal platform decoding for Antigravity, Claude, Codex, and Gemini.
  2. Adheres to structured JSON hook contract (`{"decision": "reject", ...}`).
- **Cons**:
  1. Fatal bypass flaw on compound/chained shell commands (`cd repo && git push -f`).
  2. Narrow command blocklist missing `git restore .`, `git stash drop`, and `--no-verify`.

---

## 5. Architectural Specification: `file-guard`

### 5.1 Purpose & Threat Model
`file-guard` establishes deterministic, process-level boundary enforcement to ensure that protected repository assets, secret keys, and critical configuration files remain immutable or completely inaccessible.

```mermaid
flowchart LR
    A[PreToolUse: Write / Edit / Bash Redirection] --> B[parse_hook_input]
    B --> C[Canonicalize Path via realpath]
    C --> D{Match .file-guard Rules?}
    D -- No Match --> E[ALLOW Execution]
    D -- Match Write-Protect --> F{Operation Type?}
    F -- Read / view_file --> E
    F -- Write / Edit / rm / > --> G[REJECT: Mutation Blocked]
    D -- Match [deny] --> H[REJECT: Access Denied]
```

### 5.2 Interception Vectors
1. **Direct File Tool Calls**: Intercepts `Write`, `Edit`, `replace_file_content`, `patch_file`, `NotebookEdit`.
2. **Indirect Shell Redirection**: Scans `Bash` / `run_command` payloads for shell redirection operators (`>`, `>>`, `| tee`) and file deletion/overwrite binaries (`rm`, `truncate`, `mv`, `cp`).
3. **Path Canonicalization**: Resolves symlinks (`readlink -f`), relative traversals (`../`), and home expansion (`~`) before pattern matching to prevent path aliasing bypasses.

### 5.3 Configuration Specification (`.file-guard`)
Supports layered rules at repository root and user global configurations:
```text
# Write-Protection (Default: Read allowed, Write/Edit/Delete blocked)
.env
.env.*
*.pem
*.key
terraform.tfstate
uv.lock
package-lock.json

# Absolute Access Denial ([deny]: Read, Write, Grep, Glob completely blocked)
[deny] secrets/
[deny] ~/.ssh/
[deny] internal-credentials.json
```

---

## 6. Synthesis & Recommended Implementation Roadmap for `performance-agent-standards`

To unify the strengths of both architectures, the following concrete modifications SHALL be implemented in `performance-agent-standards`:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│               RECOMMENDED UNIFIED HOOK SUITE FOR PERFORMANCE-AGENT-STANDARDS            │
├──────────────────────────┬─────────────────────────────────────────────────────────────┤
│ Hook Script              │ Key Responsibilities & Capabilities                         │
├──────────────────────────┼─────────────────────────────────────────────────────────────┤
│ 1. `parse-hook-input.sh` │ Shared input parser supporting Antigravity, Claude, Codex.  │
│ 2. `read-once.sh`        │ Token conservation, mtime caching, and diff-mode inspection.│
│ 3. `bash-guard.sh`       │ Permutation-hardened OS safety, sed -i & gh API protection. │
│ 4. `git-guard.sh`        │ Chaining-aware Git safety, stash protection, --no-verify.   │
│ 5. `file-guard.sh`       │ Path canonicalization, .file-guard parsing, [deny] gating.  │
└──────────────────────────┴─────────────────────────────────────────────────────────────┘
```

### 6.1 Priority 1: Fix Chained Command Vulnerability in `git-guard.sh`
Replace the rigid `^\s*git\s+` check with pipeline/token-aware matching:
```bash
# Check if git is invoked anywhere in the command line
if ! printf "%s" "$command_line" | grep -Eq "(^|[;&|]\s*|\$\(|\`)\s*git\s+"; then
  return 0
fi
```
Expand `BLOCKLIST` in `git-guard.sh` to include:
```bash
BLOCKLIST=(
  "git(\s+.*)?\s+push(\s+.*)?\s+(--force|-f|--force-with-lease)"
  "git(\s+.*)?\s+reset(\s+.*)?\s+--hard"
  "git(\s+.*)?\s+clean(\s+.*)?\s+-[a-zA-Z]*f"
  "git(\s+.*)?\s+branch(\s+.*)?\s+-D"
  "git(\s+.*)?\s+(checkout|restore)(\s+.*)?\s+(\.|\-\-\s+\.)"
  "git(\s+.*)?\s+stash\s+(drop|clear)"
  "git(\s+.*)?\s+.*--no-verify"
)
```

### 6.2 Priority 2: Harden `bash-guard.sh` Against Permutations, In-Place Edits, and GitHub API Mutations
1. **Target Environment Constraint**: Strictly optimized for Unix-like environments (Linux, macOS). Windows/PowerShell support is explicitly rejected to eliminate abstraction layers.
2. **Zero Allowlist Policy**: Omit `.bash-guard` allowlists entirely. A static, zero-IO deterministic blocklist executes in `<1ms` without filesystem parsing overhead or privilege escalation holes.
3. **Handle Argument & Flag Permutations**:
   - Matches combined (`rm -fr /`), separated (`rm -r -f /`), and long-form (`rm --recursive --force /`) variations:
   ```bash
   "rm\s+.*(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive(\s+--force)?)\s+.*(/|~|\*)"
   ```
4. **Block In-Place Stream Editing Bypasses**:
   - Closes bypasses that edit files directly via shell commands:
   ```bash
   "sed\s+(-[a-zA-Z]*i|--in-place)"
   "perl\s+.*-[a-zA-Z]*i"
   "ruby\s+.*-[a-zA-Z]*i"
   "truncate\s+.*"
   ```
5. **Intercept Destructive GitHub CLI API Commands**:
   - Blocks destructive repository deletions and mutation methods (`DELETE`, `PUT`, `PATCH`) targeting branches, rulesets, secrets, and environments:
   ```bash
   "gh\s+repo\s+delete"
   "gh\s+api\s+.*(-X\s+(DELETE|PUT|PATCH)|--method\s+(DELETE|PUT|PATCH))\s+.*"
   ```

### 6.3 Priority 3: Adopt Dual Schema Output & Concise Token-Conscious Feedback
Rejection responses must comply simultaneously with Claude Code v0.11+ schema and universal standard JSON contracts (`decision: reject`), while keeping feedback ultra-concise to prevent context pollution:
```bash
emit_rejection() {
  local reason="$1"
  local escaped_reason
  escaped_reason=$(printf '%s' "$reason" | jq -Rs .)
  printf '{"decision":"reject","message":%s,"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$escaped_reason" "$escaped_reason"
  exit 0
}
```
Rejection messages must be dense and actionable:
```text
[bash-guard] Blocked destructive pattern 'rm -rf /'. Use scoped workspace paths or ask user approval.
```

### 6.4 Priority 4: Implement `read-once.sh` and `file-guard.sh`
1. Implement `scripts/hooks/pre-tool/read-once.sh` utilizing session cache (`/tmp/read-once-$SESSION_ID/`) with range offset checking and unified diff mode.
2. Implement `scripts/hooks/pre-tool/file-guard.sh` backed by canonical path evaluation and `.file-guard` rule files.
3. Register hooks across platform configurations in `providers/{antigravity,claude,codex,gemini}`.
