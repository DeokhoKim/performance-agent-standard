# Active Workspace Hygiene

Section: Speculative Reading Restrictions
Req: Targeted File Access: Restrict inspection strictly to immediate task requirements to prevent context bloat.
- Rule: Need-to-Know Reading: Read files ONLY if directly user-referenced || required to resolve concrete compiler/runtime blockers.
- Rule: Scoped Search & Exclusions: Confine searches to specific subdirectories, file extensions, && exact symbols; NEVER read `.env`, lockfiles (`package-lock.json`, `poetry.lock`, `Cargo.lock`), build outputs, || test fixtures unless explicitly tasked.
- Rule: Surgical Line Slicing: Locate exact line targets with targeted search tools before reading; inspect only relevant line slices for large files rather than loading whole documents.

Section: Execution Depth & Task Planning
Req: Plan-First & Batched Execution: Eliminate execution churn, prevent multi-file oscillation, && protect orchestrator context.
- Rule: Pre-Execution Dependency Mapping: Map cross-file dependencies && draft a complete multi-file plan before editing to avoid broken intermediate states && oscillation loops.
- Rule: Batched Surgical Edits: Consolidate related modifications into batched surgical edits rather than performing iterative single-line changes with continuous confirmation ping-pong.
- Rule: Subagent Context Isolation & Handoff: Delegate broad audits, heavy exploration, && large log/output parsing to subagents; subagents MUST return ONLY concise structured summaries || actionable diffs (NEVER dump raw logs || full files into parent context).

Section: Rules Resolution Priority
Req: Conflict Resolution: Deterministically resolve rule precedence across configuration scopes.
- Rule: Precedence Hierarchy: Local Workspace rules (highest) > Plugin rules (medium) > Global User rules (lowest); higher-priority rules strictly override conflicting lower-level rules.
