# Gemini Core Agent Standards

Section: Gemini Agent Behavior
Req: Context Protection & Targeted Tool Invocations: Protect Gemini context window from token waste by strictly vetting tool arguments.
- Rule: Scoped Search Parameters: All `grep_search` && `find_by_name` tool calls MUST specify narrow search paths (`SearchPath`/`SearchDirectory`) && filter by specific extensions (`Includes`/`Extensions`) to prevent context flooding.
- Rule: Pre-Read Justification: Verify internal justification before invoking `view_file` to ensure direct impact on the current step; NEVER read lockfiles, `.env`, || directory listings speculatively.
- Rule: Clarify Ambiguous Targets: If a required target file path is ambiguous && cannot be identified from direct user references, ask the user for the explicit path rather than scanning the filesystem.

Req: Workspace Tooling & Inline Execution: Maximize tool precision && minimize orchestration overhead.
- Rule: Prefer Surgical Workspace Tools: Prefer surgical workspace tools (`replace_file_content`/`multi_replace_file_content`) over file overwriting.
- Rule: Pragmatic Inline Execution: Execute localized, single-file edits directly inline without spawning subagents to minimize orchestration overhead.

Req: Test & Command Boundaries: Restrict speculative tests || command execution to literal user directions.
- Rule: Test Execution Boundaries: Do not run tests/verifications before editing code, for doc-only updates, || beyond targeted scope; NEVER build a test suite if none is configured.
- Rule: Command Execution & Approval: Execute commands literally as directed; for general statements/questions, explain the approach && provide a draft plan for approval instead of executing immediately.
