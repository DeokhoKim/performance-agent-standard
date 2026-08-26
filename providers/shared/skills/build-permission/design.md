# Permission Architecture & Design Considerations

This document serves as the foundational design reasoning behind the `build-permission` skill. Because `SKILL.md` strictly enforces concise rules over narrative explanation, this supplement captures the context, security constraints, and platform quirks that shaped the skill's architecture.

## 1. The Four-Layer Trust Model
The permission configuration is deeply tied to how operations impact the host filesystem and git repository state.

### Allow (Inherently Safe)
Reserved exclusively for read-only operations (e.g., `git log`, `cat`, `gh issue list`) and purely isolated workspace commands (`git clone`, `git worktree`). These commands cannot negatively impact the active branch or destroy data.

### Sandbox Allow (Trackable File Mutations)
Many agents operate within lightweight jails (e.g., Bubblewrap, nsjail) that prevent host escalation.
- **The Rationale**: If a command mutates files within the workspace (e.g., `eslint --fix`, `npm run build`), it is allowed autonomously *only if* the changes can be trivially tracked and reverted using `git status`.
- **The Benefit**: It eliminates prompt fatigue for routine formatting and test-running.

### Ask (Untrackable or Tree-Modifying)
Explicit user authorization is mandated for commands that obscure state or bypass the sandbox isolation.
- **Git Tree Modifiers**: Commands like `git commit`, `git checkout`, and `git reset` move HEAD. The agent must never autonomously alter the tree state without the user knowing.
- **Mounted Bleeding (The `npm install` problem)**: If an agent writes ignored directories (`node_modules`) or modifies configurations (`.git/config`), these changes bypass `git status`. If the workspace is volume-mounted from the host OS, these changes permanently bleed onto the host system untracked. They MUST require authorization.

### Deny (Catastrophic)
Strictly blocks `rm -rf /`, `mkfs`, and destructive `chmod` commands. Note that standard `git push --force` or specific file `rm` commands belong in `Ask`, as they are occasionally necessary.

## 2. Structural Regex & Pipeline Security
A major vulnerability in AI agent CLI tools is that platforms evaluate configurations against the *raw bash string*, not a parsed Abstract Syntax Tree (AST).

If a simple prefix wildcard `^git status($| .*)` is used:
- **Pipeline Bypass**: An agent could execute `git status | git push --force`. The regex matches the safe prefix (`git status`), ignoring the dangerous pipe, allowing a destructive action autonomously.

### The Solution: Boundary Enforcements
The compiler generates heavily restricted regexes (e.g., `(?:^|\s)git status($|\s+[^|&;]+)`) to safely emulate AST parsing:
1. **The Word Boundary (`(?:^|\s)`)**: Replaces the strict `^` start-of-line anchor. This allows the command to follow inline environment variables (`FOO=bar git status`) or directory changes (`cd src && git status`), while preventing spoofed substring matches (`legit status`).
2. **The Metacharacter Block (`($|\s+[^|&;]+)`)**: Replaces the dangerous `.*` wildcard. It explicitly rejects strings containing shell pipes (`|`), ANDs (`&`), or semicolons (`;`) *after* the command. If an agent tries to chain a command, the regex instantly fails, dropping the execution into the `Ask` layer for human review.

## 3. Provider-Specific Compilation Nuances
The compiler natively accommodates the parsing engines of four different agent platforms.

- **Antigravity & Gemini**: Fully support Python-style PCRE regular expressions. The compiler aggressively compresses overlapping subcommands using a Trie (e.g., `git (?:branch|log)`).
- **Codex CLI**: Expects literal Regex strings injected directly into its `PreToolUse` hooks (`hooks.json`).
- **Claude Code**: The native `permissions.allow` array in Claude's `settings.json` strictly utilizes **Bash Globs** (e.g., `Bash(* git status *)`), not Regex. If fed a Trie regex, Claude's glob parser will fail. The compiler explicitly bypasses Trie compression for Claude, gracefully degrading to raw glob strings to ensure 100% native compatibility.

## 4. The Mutually Exclusive JSON Pattern
To prevent false-positive matches across layers, `whitelist.json` must be curated using the "Mutually Exclusive Pattern."
- If *all* options for a tool (e.g., `git diff`) belong in `Allow`, only the base prefix `"git diff"` is written. The compiler auto-expands it.
- If options straddle layers (e.g., `git stash list` [Allow] vs `git stash pop` [Ask]), they MUST be written out fully. Writing `"git stash"` in Allow would cause a wildcard collision, falsely allowing `git stash pop`.
