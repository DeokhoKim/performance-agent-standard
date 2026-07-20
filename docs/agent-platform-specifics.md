# Plugin Verification History && Confirmed Details

Section: Antigravity Plugin Design
Req: Prevent misconfiguration of Antigravity plugins && hooks.
- Rule: Plugin Directory Placement: Antigravity plugins MUST be installed to `~/.gemini/config/plugins/` (NOT `~/.gemini/antigravity-cli/plugins/`). This was a historical failure point where plugins were placed in the wrong path.
- Rule: Hooks Visibility: Plugin-defined hooks do NOT appear in the `/hooks` TUI command. The `/hooks` UI only shows project-local && global user hooks. Plugin hooks are still evaluated actively at runtime despite being hidden from the UI.
- Rule: Hook Format: Standard schema (`PreToolUse` && `PostToolUse` inside `hooks.json`) is fully supported.

Section: Claude Code Plugin Verification
Req: Ensure Claude Code hooks trigger correctly for file modifications.
- Rule: Hook Lifecycle: Claude Code natively supports `PreToolUse` && `PostToolUse` lifecycle events within `.claude/settings.json`.
- Rule: Hook Matchers: Claude Code uses `Edit` && `Write` as the internal matcher names for file operations (mapping to tools like `StrReplaceEditTool`). Use a regex matcher like `Write|Edit|Create` to reliably intercept file changes.

Section: Codex Plugin Verification
Req: Ensure Codex agent hooks intercept operations correctly.
- Rule: Hook Execution: Codex supports `PreToolUse` && `PostToolUse` inside `.codex/settings.json`.
- Rule: Hook Matchers: Codex also resolves tools against matchers like `Edit` && `Write`, allowing shared `Write|Edit|Create` configurations across platforms.
