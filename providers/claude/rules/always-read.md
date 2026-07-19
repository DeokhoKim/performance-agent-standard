# Claude Code Coding Guidelines

Section: Claude Agent Behavior
Req: Context & Token Optimization: Minimize conversation size and context footprint.
- Rule: Skip conversational preambles/fillers, reply in the most concise form, and use `/compact` or `/clear` to manage memory size. Keep `CLAUDE.md` under 100 lines as a lookup table (LUT) pointing to specific subdirectories/rules.
- Rule: Do not duplicate instructions or definitions across files loaded in the same context.

Req: Tool Operations: Prioritize surgical tool use and validation.
- Rule: Use specific tools (grep, find) over generic commands for searching, and verify test status before finalizing changes.
