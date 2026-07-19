# Active Workspace Hygiene and Speculative Reading Restrictions

Def: Intermediate Implementation → Any source file, script, or configuration that does not belong to production-facing APIs, core input/output interfaces, user interfaces, or final distribution targets.
Def: Intermediate Document → Any volatile, transitional, or task-specific document created as a temporary developmental aid that is not explicitly defined as finalized, immutable, or system-required.

Section: Speculative Reading Restrictions
Req: Prevent Speculative File Access: Minimize target file reads to strictly relevant, non-transitional items.
- Rule: Agents MUST NOT read or scan intermediate implementations or documents unless the current user instruction explicitly requires inspecting or editing them.
- Rule: Speculative searching or pattern-matching (e.g., grepping for files by name or common keywords) is prohibited.
- Rule: Speculative reading or search is ONLY permitted when the agent is blocked by a concrete tool execution, compilation, or dependency resolution error that requires discovering a missing file or path.

Section: Rules Resolution Priority
Req: Resolve Rule Conflicts: Apply workspace-level priority when resolving duplicate or conflicting guidelines.
- Rule: Precedence hierarchy is: Local Workspace rules (highest priority) > Plugin rules (medium priority) > Global User rules (lowest priority).
- Rule: Higher priority rules override conflicting rules defined at lower priority levels.
