---
---

# `build-permission` Skill

Section: Architecture & Layers
Req: Layer Segregation: Categorize commands strictly by their state mutation boundaries.
- Rule: Allow Layer: Enforce this layer exclusively for read-only operations and isolated actions that do not alter the user's primary working directory state.
- Rule: Sandbox Allow Layer: Enforce this layer for file mutations (writing/editing) that are strictly visible and easily revertible via repository status tracking.
- Rule: Ask Layer: Enforce this layer for operations that traverse the repository tree, obscure uncommitted work, alter remote states, or persist untrackable changes across mounted boundaries.
- Rule: Deny Layer: Enforce this layer exclusively for irreversibly destructive commands.

Section: Mutually Exclusive Pattern
Req: Unambiguous Compilation: Prevent rule overlap to guarantee strict execution layers.
- Rule: Auto-Wildcard Isolation: For commands where the base prefix and all subcommands inherently share the same layer boundary, exclusively register the base prefix. The compiler will natively expand it to match all arguments.
- Rule: Explicit Subcommand Segregation: For commands containing subcommands distributed across multiple layers, explicitly register the full subcommand strings and absolutely avoid registering the base prefix to prevent false-positive wildcard expansion.

Section: Compilation Logic
Req: Optimized Rule Generation: Compile patterns efficiently while maintaining execution security.
- Rule: Secure Inline Parsing: The compiler MUST prefix patterns with `(?:^|\s)` and suffix with `($|\s+[^|&;]+)` to securely allow inline environment variables while explicitly rejecting undetected pipeline chaining.
- Rule: Character Compression: The compiler MUST dynamically generate character-level shared prefixes using a trie algorithm for commands sharing a base executable to optimize evaluation performance.
- Rule: Cross-Provider Compatibility: The compiler MUST map outputs natively, generating compressed Regex for Antigravity, Codex, and Gemini, while strictly falling back to uncompressed Bash Globs for Claude's native parser constraints.

Section: Usage
Req: Standardized Deployment: Provide uniform execution targets for agent integration.
- Rule: JSON Block Generation: Execute `python3 scripts/compiler.py --provider <provider_name>` (e.g., `antigravity`, `gemini`, `claude`) to generate the raw JSON configuration block for that specific platform.
- Rule: Agent-Driven Merging: The compiler MUST NOT overwrite user configuration files directly. The executing AI agent MUST capture the JSON output, evaluate it against existing user settings (e.g. keeping existing manual additions untouched), and use its own file-editing tools to surgically merge the new rules into the global or local `settings.json`.
