# Plugin Verification History && Confirmed Details

Section: Antigravity Plugin Design
Req: Prevent misconfiguration of Antigravity plugins && hooks.
- Rule: Plugin Directory Placement: Antigravity plugins MUST be installed to `~/.gemini/config/plugins/` (NOT `~/.gemini/antigravity-cli/plugins/`). This was a historical failure point where plugins were placed in the wrong path.
- Rule: Hooks Visibility: Plugin-defined hooks do NOT appear in the `/hooks` TUI command. The `/hooks` UI only shows project-local && global user hooks. Plugin hooks are still evaluated actively at runtime despite being hidden from the UI.
- Rule: Hook Format: Standard schema (`PreToolUse` && `PostToolUse` inside `hooks.json`) is fully supported.

Section: Claude Code Plugin Verification
Req: Ensure Claude Code hooks trigger correctly for file modifications.
- Rule: Hook Lifecycle: Claude Code natively supports `PreToolUse` && `PostToolUse` lifecycle events within `.claude/settings.json`.
- Rule: Hook Matchers: Claude Code uses `Edit` && `Write` as the internal matcher names for file operations. Use a regex matcher like `Write|Edit` to reliably intercept file changes.

Section: Codex Plugin Verification
Req: Ensure Codex agent hooks intercept operations correctly.
- Rule: Hook Execution: Codex supports `PreToolUse` && `PostToolUse` inside `.codex/settings.json`.
- Rule: Hook Matchers: Codex uses matchers like `Edit`, `Write`, and `MultiEdit`, requiring `Edit|Write|MultiEdit` configurations.

Section: Cross-Platform Skill Invocability & Two-Loads Architecture
Req: Prevent context pollution by normalizing skill invocability across agent platforms.
- Rule: Two-Loads Segregation: Segregate model-invoked execution primitives from user-invoked operational workflows (`disable-model-invocation: true`) to eliminate ambient token waste during implementation turns.
- Rule: Frontmatter Invocability: Antigravity, Gemini CLI, and Claude Code skills MUST declare `disable-model-invocation: true` in `SKILL.md` frontmatter for interactive/slash-only skills.
- Rule: Codex Manifest Sidecar: OpenAI Codex and `skills.sh` skills MUST define `agents/openai.yaml` with `policy.allow_implicit_invocation: false` for user-invoked skills.
- Rule: Compiler Automation: `scripts/compile.sh` MUST automatically normalize frontmatter and generate platform-specific invocability metadata across Antigravity, Gemini CLI, Claude Code, and Codex.
