# Antigravity (Gemini) Agent Instructions

Section: Cross-Platform Compatibility
Explain: Guidelines for ensuring modifications are compatible across different agent environments.

Req: Compatibility Assurance: Verify cross-platform compatibility for modifications and predefined features.
- Rule: Modification Check: For every modification, Always check that compatibility of agent across antigravity, gemini-cli, claude and codex.
- Rule: Feature Verification: To use a keyword on frontmatter or pre-defined features, MUST search official document through web using subagent.

Section: Standard Design Principles
Req: Rule-Driven Enforcement: Design standards to dictate actionable behavior.
- Rule: Prefer Rule Over Explain: Exclusively use `- Rule:` directives instead of passive `- Explain:` blocks. Integrate the reasoning directly into the rule (e.g., "Enforce X to guarantee Y") so that executing the rule inherently fulfills the underlying purpose.
- Rule: Imperative Constraint Precision: Enforce unambiguous imperative action verbs (`Enforce`, `Prohibit`, `Prefix`, `Isolate`, `Require`) in rule directives; prohibit passive or advisory phrasing (`Prefer`, `Consider`, `Should`).

Req: Normative Standardization Modals: Enforce standard specification keywords for unambiguous conformance.
- Rule: Normative Modal Precision: Enforce RFC-2119/ISO modal verbs (`MUST`/`SHALL` for mandatory requirements, `MUST NOT`/`SHALL NOT` for absolute prohibitions, `MAY` for optional capabilities); prohibit ambiguous advisory language (`SHOULD`/`COULD`) unless documenting explicit, justified trade-offs.

Req: Context Window && Token Density Optimization: Maximize token efficiency without sacrificing semantic constraints.
- Rule: Zero-Bloat Density: Eliminate conversational fluff, narrative explanations, duplicate tables, && boilerplate; enforce symbolic operators (`&&`, `||`, `!`, `→`) to maximize meaning per token.
- Rule: Explicit Sub-Rule Naming: Enforce explicit PascalCase rule names on all sub-rules (e.g., `- Rule: <SubRuleName>: ...`) to guarantee structural consistency && addressability.

Req: Hierarchical Supplementation: Structure standards for clean, incremental reading.
- Rule: Independent Supplementation: Language-specific standards MUST act as concrete, specialized implementations of abstract principles defined in the common standard.
- Rule: Avoid Explicit Cross-Referencing: Write language-specific rules so they naturally supplement common rules. A hierarchical reading (common -> specific) MUST trivially create a complete, incremental view of information without the files needing to explicitly reference each other.

Section: External Dependencies Monitoring
Explain: The repository mirrors external skills, rules, && guidelines. Ensure local copies remain current without redundant network latency on every agent invocation.

Req: Synchronization Protocol: Monitor && synchronize dependencies using the table.
- Rule: Initialization Check: At session start, consult `External Dependencies Reference Table`.
- Rule: Timestamp Validation: Compare `Last Checked` timestamp with current time. If checked earlier than today, check the `External Source URL`. If checked today, skip check to conserve resources.
- Rule: Update && Log: Check the reference's last updated date instead of comparing content. If the reference's last updated date is earlier than or equal to the `Last Checked` time, do not update it. If it is newer, update the local file. Always update `Last Checked` date to current `YYYY-MM-DD` after checking. Do NOT modify core purpose of file during update.

Section: External Dependencies Reference Table
Explain: Reference for monitored dependencies.
| Dependency Name | Local Path | External Source URL | Last Checked |
| :--- | :--- | :--- | :--- |
| Karpathy Guidelines | `providers/shared/rules/karpathy-guidelines.md` | https://raw.githubusercontent.com/multica-ai/andrej-karpathy-skills/main/skills/karpathy-guidelines/SKILL.md | 2026-08-26 |
| Antigravity Plugin Design | `docs/agent-platform-specifics.md` | Official Docs | 2026-08-26 |
| Claude Plugin Verification | `docs/agent-platform-specifics.md` | Claude Code Docs | 2026-08-26 |
| Codex Plugin Verification | `docs/agent-platform-specifics.md` | Codex Hooks Docs | 2026-08-26 |
