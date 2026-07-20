# Antigravity (Gemini) Agent Instructions

Section: External Dependencies Monitoring
Explain: The repository mirrors external skills, rules, && guidelines. Ensure local copies remain current without redundant network latency on every agent invocation.

Req: Synchronization Protocol: Monitor && synchronize dependencies using the table.
- Rule: Initialization Check: At session start, consult `External Dependencies Reference Table`.
- Rule: Timestamp Validation: Compare `Last Checked` timestamp with current time. If checked earlier than today, fetch `External Source URL`. If checked today, skip check to conserve resources.
- Rule: Update && Log: If fetched content differs from `Local Path`, update local file. Always update `Last Checked` date to current `YYYY-MM-DD` after checking. Do NOT modify core purpose of file during update.

Section: External Dependencies Reference Table
Explain: Reference for monitored dependencies.
| Dependency Name | Local Path | External Source URL | Last Checked |
| :--- | :--- | :--- | :--- |
| Karpathy Guidelines | `providers/shared/rules/karpathy-guidelines.md` | https://raw.githubusercontent.com/multica-ai/andrej-karpathy-skills/main/skills/karpathy-guidelines/SKILL.md | 2026-07-20 |
| Antigravity Plugin Design | `docs/agent-platform-specifics.md` | Official Docs | 2026-07-20 |
| Claude Plugin Verification | `docs/agent-platform-specifics.md` | Claude Code Docs | 2026-07-20 |
| Codex Plugin Verification | `docs/agent-platform-specifics.md` | Codex Hooks Docs | 2026-07-20 |
