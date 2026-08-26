# Comprehensive Architectural, Algorithmic, and Technical Analysis of the Ponytail Repository

> **Repository Target**: [dietrichgebert/ponytail](https://github.com/dietrichgebert/ponytail)
> **Subject**: Full-Scale Architectural, Runtime, Rule-Hierarchy, Benchmark, and Script Analysis
> **Report Target**: `./REPORD.md`

---

## Executive Summary & Core Philosophy

**Ponytail** is an advanced AI agent enhancement plugin and instruction framework designed to curb AI verbosity, over-engineering, and architectural bloat. It embodies the persona of a **"lazy senior developer"** whose governing axiom is:

$$\text{The best code is the code that is never written.}$$

Modern Large Language Models (LLMs) powering coding agents (such as Claude 3.5 Sonnet, GPT-4o, and Gemini 1.5 Pro) exhibit a systemic structural bias toward "over-delivering." When prompted for a simple task, standard models frequently generate unsolicited multi-tiered architectures, premature abstractions, speculative utility functions, multiple variations, unrequested styling/framework wrappers, and verbose explanatory prose.

### The Value Proposition
Ponytail converts coding agents from verbose, over-engineering junior/mid-level generators into disciplined, minimalist senior engineers. Empirical metrics published within the repository demonstrate:
- **Code Volume Reduction**: Generates **54% to 94% less code** across typical programming tasks by eliminating speculative bloat and leveraging native platform capabilities.
- **Token Economy**: Reduces total token consumption by **~22% on multi-turn agentic workflows** and **40% to 75% on single-shot generation**.
- **Cost & Latency Optimization**: Yields an average **~20% monetary cost reduction** and **~27% to 3–6× completion speedups** due to slashed generation tokens.
- **Safety Invariant**: "Lazy, not careless." Ponytail explicitly forbids skipping input validation at trust boundaries, error handling preventing data loss, security sanitization, and accessibility.

```
                  ┌──────────────────────────────────────────────┐
                  │           User Coding Request                │
                  └──────────────────────┬───────────────────────┘
                                         │
                                         ▼
                  ┌──────────────────────────────────────────────┐
                  │    The Ladder of Simplicity (7 Tiers)        │
                  │  1. YAGNI (Skip speculative code)            │
                  │  2. Codebase Reuse (No duplicate logic)      │
                  │  3. Standard Library (Native stdlib first)   │
                  │  4. Native Platform (Browser/OS built-ins)   │
                  │  5. Installed Dependencies (No new packages) │
                  │  6. One-Liners (Compact primitives)          │
                  │  7. Minimum Working Code (Core only)         │
                  └──────────────────────┬───────────────────────┘
                                         │
                   ┌─────────────────────┴─────────────────────┐
                   ▼                                           ▼
┌──────────────────────────────────────┐   ┌───────────────────────────────────────┐
│     Strict Brevity Format            │   │      Non-Negotiable Safety Gates      │
│ - Code first                         │   │ - Input validation at trust boundaries│
│ - At most 3 lines of prose           │   │ - Data-loss error prevention          │
│ - "[code] -> skipped: X, add when Y" │   │ - Security & sanitize injections      │
│ - Dense tag-based reviews/audits     │   │ - ONE runnable verification check     │
└──────────────────────────────────────┘   └───────────────────────────────────────┘
```

---

## 1. Rule Hierarchy & The Behavioral Engine

The core behavioral rules of Ponytail are defined primarily in `AGENTS.md` (the universal instruction document) and `skills/ponytail/SKILL.md` (the primary skill definition), and are mirrored byte-for-byte across platform-specific rule directories.

### 1.1 The 7-Rung Ladder of Simplicity
Before generating any implementation, the agent is constrained to evaluate candidate solutions against an ordered 7-rung hierarchy:

```
[Rung 1] YAGNI (You Aren't Gonna Need It)
         └── If the requirement is speculative, prospective, or unstated: DO NOT IMPLEMENT.
[Rung 2] Codebase Reuse
         └── Search the current repository for existing functions, utilities, or types.
[Rung 3] Standard Library First
         └── Prefer built-in language standard libraries over introducing imports or abstractions.
[Rung 4] Native Platform Features
         └── Use native HTML elements (<dialog>, <input type="date">), modern browser APIs
             (IntersectionObserver, structuredClone, URLSearchParams, Object.groupBy),
             or OS primitives rather than JavaScript libraries.
[Rung 5] Existing Installed Dependencies
         └── If stdlib/native is insufficient, use only packages already present in package.json/uv.lock.
[Rung 6] One-Line Implementation
         └── Prefer concise, readable inline expressions over multi-line function/class scaffolding.
[Rung 7] Minimum Working Code
         └── When code must be written, write only the minimal working logic needed to fulfill the prompt.
```

### 1.2 The Three Intensity Tiers
Ponytail supports three distinct runtime intensity levels that adjust how aggressively the agent enforces simplicity:

| Intensity Tier | Mode Identifier | Behavioral Mandate | Agent Output Style |
| :--- | :--- | :--- | :--- |
| **Lite** | `lite` | Builds the requested solution faithfully, but appends a concise comment or note highlighting a substantially lazier/simpler alternative. | Functional implementation + 1-line lazy alternative recommendation. |
| **Full (Default)** | `full` | Strictly enforces the 7-rung ladder. Replaces frameworks/libraries with standard library and platform-native built-ins. Rejects unprompted abstractions. | Code first. Max 3 lines explaining what was skipped and when to add it. |
| **Ultra** | `ultra` | "YAGNI extremist." Deletion-first mindset. Aggressively challenges user requirements, proposes deleting code before adding, and refactors aggressively. | Minimalist code or deletion diff + challenge to requirement assumptions. |

In addition, Ponytail includes an isolated session mode:
- **`review`**: A diff-focused mode that evaluates proposed changes strictly for over-engineering and dependency bloat.

### 1.3 The Non-Negotiable Safety & Quality Invariants
A critical innovation in Ponytail is that it decouples **laziness in architecture** from **carelessness in execution**. The framework explicitly defines what an agent is **NOT** allowed to simplify away:

1. **Input Validation at Trust Boundaries**: Any external input (API payloads, query strings, user form input, file system paths, CLI arguments) must be strictly validated.
2. **Error Handling for Data Loss**: Errors that could corrupt state, lose data, or panic unhandled must be caught and handled cleanly.
3. **Security Invariants**: SQL injection prevention (parameterized queries), path traversal prevention (sanitizing relative paths), XSS prevention, and credential protection cannot be omitted for brevity.
4. **Accessibility (a11y)**: HTML/UI primitives must preserve accessible labels and semantic structure.
5. **Hardware & Domain Calibration**: Hardware controls, timing boundaries, and domain-critical precision checks must never be stripped.
6. **The Single Runnable Check Rule**: Every piece of written code must include **exactly ONE runnable self-verification** (e.g., an `assert`-based inline block, a minimal test function, or a CLI command). Ponytail states: *"Lazy code without its check is unfinished."* Heavy test suites with complex mocking frameworks are banned unless specifically requested.

### 1.4 Technical Debt Tracking: The Ceiling Comment Syntax
When Ponytail intentionally takes a shortcut or implements a simplified heuristic, it forbids silent technical debt. It enforces the **Ceiling Comment convention**:

```typescript
// ponytail: <assumed ceiling limit>, upgrade to <full solution> when <trigger condition>
```

**Real-world Examples from Ponytail**:
```python
# ponytail: assumes ASCII-only slugs, upgrade to unidecode when international titles are needed
slug = re.sub(r'[^a-zA-Z0-9]+', '-', text.lower()).strip('-')
```
```javascript
// ponytail: in-memory Map max 1000 items, upgrade to Redis LRU when multi-instance deployed
const cache = new Map();
```

If an agent leaves a `# ponytail:` comment without a concrete upgrade trigger, it is classified as **"silent rot"** by the `-debt` auditor.

### 1.5 Output Compression & Communication Rules
Ponytail strictly governs the conversational format of the AI:
- **Code First**: Emit the code immediately without conversational pleasantries ("Sure! Here is the code...").
- **3-Line Prose Ceiling**: Natural language text is limited to at most 3 concise lines.
- **The Omission Rationale Formula**:
  $$\text{\texttt{[code]} } \longrightarrow \text{\texttt{skipped: [Feature X], add when [Trigger Y].}}$$
- **Prose Ban**: If the conversational explanation exceeds the length of the code itself, the output violates Ponytail invariants.

### 1.6 The 9 Canonical Rule Invariants (Enforced via CI)
The repository enforces rule integrity across 8 different platform distributions using a dedicated verification script (`scripts/check-rule-copies.js`). The script asserts that the following **9 exact strings** exist without alteration in both `AGENTS.md` and `skills/ponytail/SKILL.md`:

```javascript
const INVARIANTS = [
  'in this codebase',
  'naive heuristic',
  'ONE runnable check',
  'flimsier algorithm',
  'input validation at trust boundaries',
  'prevents data loss',
  'security',
  'accessibility',
  'Lazy code without its check is unfinished'
];
```

---

## 2. Skills and Commands Deep-Dive

Ponytail provides 6 core skills and 6 corresponding slash commands:

```
ponytail/
├── skills/
│   ├── ponytail/SKILL.md         <-- Persistent persona & ladder
│   ├── ponytail-audit/SKILL.md   <-- Whole-repo over-engineering scan
│   ├── ponytail-debt/SKILL.md    <-- Tech debt & ceiling comments ledger
│   ├── ponytail-gain/SKILL.md    <-- Benchmark scoreboard
│   ├── ponytail-help/SKILL.md    <-- Reference & configuration guide
│   └── ponytail-review/SKILL.md  <-- Diff review for bloat
└── commands/
    ├── ponytail.toml             <-- Fast CLI slash command
    ├── ponytail-audit.toml       <-- Fast CLI slash command
    ├── ponytail-debt.toml        <-- Fast CLI slash command
    ├── ponytail-gain.toml        <-- Fast CLI slash command
    ├── ponytail-help.toml        <-- Fast CLI slash command
    └── ponytail-review.toml      <-- Fast CLI slash command
```

### 2.1 `skills/ponytail` & `commands/ponytail.toml`
- **Purpose**: Activates the persistent "lazy senior developer" persona.
- **Invocation**: `/ponytail [lite|full|ultra|off]` or natural language triggers ("be lazy", "minimal code").
- **Behavior**: Sets the system instructions to filter and enforce the 7-rung ladder according to the specified intensity.
- **TOML Implementation**:
  ```toml
  description = "Set ponytail minimalism intensity (lite | full | ultra | off)"
  prompt = """
  Set Ponytail mode. Intensity levels:
  - lite: Build what was asked, but name the lazier alternative.
  - full: (Default) Ladder enforced. Stdlib/native first.
  - ultra: YAGNI extremist. Deletion before addition. Challenge reqs.
  - off: Deactivate Ponytail rules.
  """
  ```

### 2.2 `skills/ponytail-audit` & `commands/ponytail-audit.toml`
- **Purpose**: Performs a whole-repository scan strictly focused on detecting over-engineering, unneeded abstractions, and redundant dependencies.
- **Scope**: Ignores correctness and styling; focuses purely on dead weight.
- **The 5-Tag Taxonomy**:
  1. `delete:` Code or files that can be eliminated entirely with zero functional loss.
  2. `stdlib:` Third-party dependencies replaceable by language standard library primitives.
  3. `native:` JavaScript/CSS/HTML libraries replaceable by modern platform-native APIs.
  4. `yagni:` Premature abstractions (factories with one implementation, generic wrappers).
  5. `shrink:` Overly complex algorithms replaceable with simple, readable primitives.
- **Output Format**:
  ```text
  <tag> <what to cut>. <replacement>. [<filepath>:<line>]
  ...
  net: -<N> lines, -<M> deps possible. (or "Lean already. Ship.")
  ```

### 2.3 `skills/ponytail-debt` & `commands/ponytail-debt.toml`
- **Purpose**: Aggregates all `# ponytail:` ceiling comments into a consolidated technical debt ledger.
- **Execution Command**: Automatically triggers:
  ```bash
  grep -rnE '(#|//) ?ponytail:' .
  ```
- **Ledger Output Format**:
  ```text
  <filepath>:<line>, <what was simplified>. ceiling: <limit named>. upgrade: <trigger>.
  ...
  <N> markers, <M> with no trigger.
  ```
  *(Markers missing a trigger are flagged with a `no-trigger` warning).*

### 2.4 `skills/ponytail-gain` & `commands/ponytail-gain.toml`
- **Purpose**: Renders an ASCII benchmark scoreboard showing median token, cost, and LOC savings across Claude Haiku, Sonnet, and Opus models.
- **The Honesty Boundary**: A hard constraint in the skill:
  $$\text{\textbf{NEVER print a per-repo savings number.}}$$
  Because single-session savings cannot be reliably measured without historical baselines, Ponytail prohibits hallucinatory per-repo savings metrics. All figures come from empirically verified Promptfoo benchmarks:
  ```text
  ┌───────────────────────────────────────────────────────────┐
  │ Ponytail Benchmark Medians (Claude 3.5 Sonnet / Haiku / Opus)│
  ├──────────────────┬──────────────┬─────────────┬─────────────┤
  │ Metric           │ Baseline     │ Ponytail    │ Net Gain    │
  ├──────────────────┼──────────────┼─────────────┼─────────────┤
  │ Code Volume      │ 100%         │ 6% - 20%    │ -80% to -94%│
  │ Generation Cost  │ 100%         │ 23% - 53%   │ -47% to -77%│
  │ Generation Speed │ 1.0x         │ 3.0x - 6.0x │ 3x - 6x     │
  └──────────────────┴──────────────┴─────────────┴─────────────┘
  ```

### 2.5 `skills/ponytail-help` & `commands/ponytail-help.toml`
- **Purpose**: Provides quick-reference command documentation and details the configuration resolution hierarchy:
  1. Environment Variable: `PONYTAIL_DEFAULT_MODE`
  2. Config File: `~/.config/ponytail/config.json` (`{"defaultMode": "full"}`)
  3. Default Fallback: `full`

### 2.6 `skills/ponytail-review` & `commands/ponytail-review.toml`
- **Purpose**: Inspects active git diffs (`git diff HEAD` or staged changes) and flags over-engineering.
- **Output Format**:
  ```text
  L<line_number>: <tag> <what is over-engineered>. <concise replacement>.
  ```
- **Boundary**: Explicitly instructs the agent: *"Do NOT review for correctness, security, or style. Those belong in a standard code review. Flag ONLY over-engineering."*

---

## 3. Runtime Architecture & Execution Hooks Deep-Dive

Ponytail operates as an active runtime engine across multiple CLI agent environments (Claude Code, OpenAI Codex, GitHub Copilot, and Qoder). The runtime subsystem is located in `hooks/`.

```
hooks/
├── claude-codex-hooks.json   <-- Lifecycle hook mappings for Claude Code & Codex
├── copilot-hooks.json        <-- Lifecycle hook mappings for VS Code Copilot
├── qoder-hooks.json          <-- Lifecycle hook mappings for Qoder IDE
├── ponytail-activate.js      <-- SessionStart initialization & statusline setup
├── ponytail-config.js        <-- Configuration loading & path validation
├── ponytail-instructions.js  <-- Markdown filtering & prompt injection
├── ponytail-mode-tracker.js  <-- UserPromptSubmit stream parser & mode switch
├── ponytail-runtime.js       <-- Platform detection & I/O formatting
├── ponytail-subagent.js      <-- SubagentStart context propagation
├── ponytail-statusline.sh    <-- POSIX ANSI terminal statusline
└── ponytail-statusline.ps1   <-- PowerShell ANSI terminal statusline
```

### 3.1 Lifecycle Execution Sequence

1. **Session Start (`ponytail-activate.js`)**:
   - Fires upon `startup`, `resume`, `clear`, or `compact`.
   - Resolves configured mode via `getDefaultMode()`.
   - Writes state to `.ponytail-active`.
   - Injects filtered system instructions.
   - For Claude Code, checks `~/.claude/settings.json` and initiates statusline setup if absent.
2. **User Interaction Turn (`ponytail-mode-tracker.js`)**:
   - Intercepts prompt stream on `UserPromptSubmit`.
   - Handles slash commands (`/ponytail <mode>`) or natural deactivations ("stop ponytail").
   - Updates `.ponytail-active` on the fly.
3. **Subagent Spawning (`ponytail-subagent.js`)**:
   - Hooks into `SubagentStart` or `PreToolUse(Task)`.
   - Inherits active mode and injects filtered rules into the child agent context.
4. **Terminal Statusline (`ponytail-statusline.sh` / `.ps1`)**:
   - Renders active mode dynamically in ANSI colors (Green for `full`/`lite`, Amber for `ultra`).

---

### 3.2 Detailed Module-by-Module Code Analysis

#### `hooks/ponytail-config.js` (Configuration & Validation Engine)
- **Constants**:
  ```javascript
  const DEFAULT_MODE = 'full';
  const VALID_MODES = ['off', 'lite', 'full', 'ultra', 'review'];
  const RUNTIME_MODES = ['off', 'lite', 'full', 'ultra'];
  ```
- **Path Resolution**: Resolves configuration directory across platforms via:
  1. `$XDG_CONFIG_HOME/ponytail` (Linux/macOS)
  2. `%APPDATA%/ponytail` (Windows)
  3. `~/.config/ponytail` (Fallback)
- **`isShellSafe(p)`**: Validates file paths using the strict regex:
  ```javascript
  const SAFE_PATH_RE = /^[A-Za-z0-9 _.\-:/\\~]+$/;
  function isShellSafe(p) {
    return typeof p === 'string' && p.length > 0 && SAFE_PATH_RE.test(p);
  }
  ```
  *Prevents arbitrary shell command injection when statusline script paths are written to settings.*
- **`isDeactivationCommand(text)`**: Strips trailing punctuation (`/[.!?\s]+$/`) and matches exact strings:
  - `"stop ponytail"`, `"disable ponytail"`, `"normal mode"`
- **UTF-8 BOM Stripping**: Cleans Windows config files:
  ```javascript
  const content = fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, '');
  ```

#### `hooks/ponytail-runtime.js` (Platform Abstraction & Output Multiplexing)
- **Platform Detection**:
  ```javascript
  const isCopilot = Boolean(process.env.COPILOT_PLUGIN_DATA) || isVsCodeCopilotRoot(process.env.CLAUDE_PLUGIN_ROOT);
  const isCodex = Boolean(process.env.PLUGIN_DATA) && !isCopilot;
  const isQoder = Boolean(process.env.QODER_SESSION_ID) && !isCopilot && !isCodex;
  ```
- **State Management**:
  - `setMode(mode)`: Atomically writes mode to `.ponytail-active`.
  - `clearMode()`: Unlinks `.ponytail-active` inside a `try-catch` block.
  - `readMode()`: Reads current mode; returns `null` on error.
- **`writeHookOutput(event, mode, context)`**: Multiplexes outputs into the precise schema required by each host:
  - **GitHub Copilot**: Emits JSON `{ additionalContext: context }` on `SessionStart`.
  - **OpenAI Codex**: Emits JSON `{ systemMessage: "PONYTAIL:" + mode.toUpperCase(), hookSpecificOutput: { hookEventName: event, additionalContext: context } }`.
  - **Qoder**: Emits JSON `{ hookSpecificOutput: { hookEventName: event, additionalContext: context } }`.
  - **Claude Code**: Emits JSON for `SubagentStart`; emits **raw text** for `SessionStart`.

#### `hooks/ponytail-instructions.js` (Dynamic Markdown Filter)
- **Purpose**: Parses `skills/ponytail/SKILL.md` and filters rules based on the active mode to prevent token waste.
- **Filtering Logic (`filterSkillBodyForMode`)**:
  1. Strips YAML frontmatter: `body.replace(/^---[\s\S]*?---\s*/, '')`.
  2. Filters markdown intensity tables: Matches lines starting with `| **mode** |` and retains only rows matching `effectiveMode`.
  3. Filters worked examples: Matches lines `^-\s*([^:]+):\s*"` and includes only examples tagged with the active mode.
  4. Global rules (ladder, safety invariants) are preserved unconditionally.
- **Fallback Engine (`getFallbackInstructions`)**: If `SKILL.md` is deleted or unreadable, emits a hardcoded, zero-dependency fallback instruction set containing the full 7-rung ladder.

#### `hooks/ponytail-activate.js` (`SessionStart` Entrypoint)
1. Resolves `getDefaultMode()`. If `off`, clears `.ponytail-active` and exits cleanly.
2. Writes mode to `.ponytail-active`.
3. Loads instructions via `getPonytailInstructions(mode)`.
4. **Statusline Nudge Mechanism (Claude Code Native)**:
   - Reads `~/.claude/settings.json`.
   - If `statusLine` is missing and `.ponytail-statusline-nudged` does not exist:
     - Sets the nudge marker file.
     - Generates the shell command (`bash <path>/ponytail-statusline.sh` or `powershell -File <path>/ponytail-statusline.ps1`).
     - Appends an instruction directing Claude to suggest adding the statusline to the user's `settings.json`.
5. Emits context using `writeHookOutput('SessionStart', mode, instructions)`.

#### `hooks/ponytail-mode-tracker.js` (`UserPromptSubmit` Stream Parser)
- **Deadlock-Proof Stream Handling**: Handles a critical Windows PowerShell bug where standard input `end` events are swallowed by `if {}` wrappers:
  ```javascript
  const timer = setTimeout(() => {
    finish();
    process.exit(0);
  }, 1000);
  if (timer.unref) timer.unref();
  ```
- **Command Dispatcher**:
  - Matches `/ponytail default <mode>` -> Calls `writeDefaultMode(mode)`.
  - Matches `/ponytail <mode>` -> Calls `setMode(mode)`.
  - Matches `isDeactivationCommand` -> Calls `clearMode()`.
- **Qoder Continuous Injection**: Because Qoder lacks a `SessionStart` hook, `ponytail-mode-tracker.js` performs double-duty on Qoder: it initializes state on the first prompt and injects `getPonytailInstructions()` into `hookSpecificOutput` on every turn.

#### `hooks/ponytail-subagent.js` (`SubagentStart` Context Propagator)
- **Regex Scoping (`PONYTAIL_SUBAGENT_MATCHER`)**:
  Allows users to selectively apply Ponytail only to certain subagent types (e.g., `PONYTAIL_SUBAGENT_MATCHER=coder|executor`).
- **Logic**:
  1. Checks if active mode is set and not `off`.
  2. If no matcher environment variable is set, injects instructions immediately and exits (avoids reading stdin).
  3. If matcher is set, reads `agent_type` from stdin JSON. If it matches the regex, injects instructions; otherwise exits without modification.

#### `hooks/ponytail-statusline.sh` & `.ps1` (Terminal Statusline Monitors)
- **POSIX Shell (`.sh`)**:
  ```bash
  mode=$(head -n1 "$flag" 2>/dev/null | tr -d '[:space:]')
  case "$mode" in
    ultra) printf "\033[38;5;173m[PONYTAIL:ULTRA]\033[0m " ;;
    lite)  printf "\033[38;5;108m[PONYTAIL:LITE]\033[0m " ;;
    *)     printf "\033[38;5;108m[PONYTAIL]\033[0m " ;;
  esac
  ```
- **PowerShell (`.ps1`)**:
  Reads `$Flag` using `Get-Content`, trims whitespace, and emits matching ANSI escape sequences: ANSI 173 (Amber/Orange) for `ultra`, ANSI 108 (Muted Green) for `full` and `lite`.

---

## 4. Cross-Platform Manifests & Ecosystem Adapters

Ponytail achieves universal portability by implementing customized adapter layers across 11+ AI coding platforms:

```
Platform Support Architecture
├── Deep Plugin-Tier (Hooks + Dynamic State + Subagents)
│   ├── Claude Code (`.claude-plugin/plugin.json`, `hooks/claude-codex-hooks.json`)
│   ├── OpenAI Codex (`.codex-plugin/plugin.json`, `hooks/claude-codex-hooks.json`)
│   ├── GitHub Copilot (`copilot-hooks.json`, `plugin.json`)
│   ├── Qoder (`.qoder-plugin/plugin.json`, `hooks/qoder-hooks.json`)
│   ├── Hermes Agent (`plugin.yaml`, `__init__.py`)
│   └── Pi Agent (`package.json`, `pi-extension/index.js`)
├── Extension & Configuration-Tier
│   ├── Google Antigravity / Gemini CLI (`gemini-extension.json`)
│   ├── OpenCode (`opencode.json`, `.opencode/plugins/ponytail.mjs`)
│   ├── Devin CLI (`.devin-plugin/plugin.json`)
│   └── OpenClaw / ClawHub (`.openclaw/skills/`)
└── Instruction-Tier (Direct Rule Ingestion)
    ├── Windsurf (`.windsurf/rules/ponytail.md`)
    ├── Cursor (`.cursorrules` / `.cursor/rules/ponytail.mdc`)
    ├── Cline (`.clinerules`)
    ├── Zed (`.zed/rules.md`)
    └── VS Code / Roo Code (`AGENTS.md`)
```

### 4.1 Manifest Specifications

#### 1. Claude Code & OpenAI Codex (`.codex-plugin/plugin.json`)
```json
{
  "name": "ponytail",
  "version": "0.1.0",
  "description": "Lazy senior developer mode for Claude. Less code, fewer deps, stdlib-first.",
  "author": "Dietrich Gebert",
  "license": "MIT",
  "interface": {
    "brandColor": "#111111",
    "composerIcon": "assets/logo-dark.png"
  },
  "capabilities": ["Instructions", "Lifecycle hooks"],
  "hooks": "./hooks/claude-codex-hooks.json",
  "skills": "./skills/"
}
```

#### 2. Google Antigravity / Gemini CLI (`gemini-extension.json`)
```json
{
  "name": "ponytail",
  "version": "0.1.0",
  "description": "Lazy senior developer mode for Gemini CLI. Less code, fewer deps, stdlib-first.",
  "author": "Dietrich Gebert",
  "license": "MIT",
  "contextFileName": "AGENTS.md"
}
```
*Antigravity and Gemini CLI consume `AGENTS.md` directly through `contextFileName`, while discovering skills in `skills/` automatically.*

#### 3. Hermes Agent (`plugin.yaml` & `__init__.py`)
- **`plugin.yaml`**:
  ```yaml
  name: ponytail
  version: 0.1.0
  description: Lazy senior developer mode for Hermes.
  hooks:
    pre_llm_call: __init__.py:pre_llm_call
    pre_gateway_dispatch: __init__.py:pre_gateway_dispatch
  ```
- **`__init__.py`**: Intercepts gateway commands before LLM dispatch. If a user types `/ponytail-review`, it rewrites the gateway prompt:
  ```python
  def pre_gateway_dispatch(ctx, event):
      if event.text.startswith('/ponytail-review'):
          event.text = "Load and follow the Hermes plugin skill ponytail:ponytail-review. Review the current diff for over-engineering."
  ```

#### 4. OpenCode (`opencode.json` & `package.json`)
- **`opencode.json`**:
  ```json
  {
    "$schema": "https://opencode.ai/schema/plugin.json",
    "name": "ponytail",
    "plugin": ["./.opencode/plugins/ponytail.mjs"]
  }
  ```
- Uses standard ES Module exports in `package.json` pointing to an OpenCode wrapper.

#### 5. Pi Platform Extension (`pi-extension/` & `package.json`)
- **`package.json`**:
  ```json
  "pi": {
    "extensions": ["./pi-extension/index.js"],
    "skills": ["./skills"]
  }
  ```

---

## 5. Standalone Subsystems: MCP Server & Pi Extension

### 5.1 The Ponytail MCP Server (`ponytail-mcp/`)
For AI hosts that do not support passive lifecycle hooks (e.g., standard Claude Desktop, Cursor MCP, LibreChat), Ponytail provides a standard **Model Context Protocol (MCP)** server built using `@modelcontextprotocol/sdk`.

- **Transport**: Standard I/O streams (`StdioServerTransport`).
- **Exposed Prompt**:
  - Name: `ponytail`
  - Argument: `mode` (`lite | full | ultra`)
  - Output: Injects filtered Ponytail instructions into the prompt template.
- **Exposed Tool**:
  - Name: `ponytail_instructions`
  - Hints: `readOnlyHint: true`, `openWorldHint: false`
  - Output: Returns `{ mode, instructions }` as structured JSON and Markdown text for tool-calling agents.
- **Architecture Note**: `ponytail-mcp/instructions.js` imports core filtering logic directly from `../hooks/ponytail-instructions.js` to guarantee zero drift between the MCP server and CLI hooks.

### 5.2 The Native Pi Extension (`pi-extension/index.js`)
The `pi-extension` integrates directly into the event-driven Pi agent lifecycle:
1. **Event Hooks**:
   - `session_start`: Recovers active mode from previous session states via `pi.sessionManager.getEntries()`.
   - `agent_start` / `agent_end`: Updates UI activity indicator.
   - `before_agent_start`: Intercepts `event.systemPrompt` and prepends `getPonytailInstructions(currentMode)`.
   - `input`: Intercepts user text to catch deactivation commands (`stop ponytail`).
2. **Commands**: Registers `/ponytail [status | set-mode | default]` and aliases for all 5 sub-skills (`/ponytail-review`, `/ponytail-audit`, etc.).
3. **UI Integration**: Dynamically draws ANSI-colored status markers using `ctx.ui.setStatus` and `ctx.ui.theme.fg()`.

---

## 6. Build, Maintenance & Consistency Scripts

The `scripts/` directory contains automated verification, packaging, and distribution tooling:

```
scripts/
├── build-openclaw-skills.js    <-- Compiles canonical skills for OpenClaw
├── check-rule-copies.js        <-- Validates byte-for-byte rule sync
├── check-versions.js           <-- Enforces SemVer sync across 8 manifests
├── publish-openclaw-skills.js  <-- Deploys compiled skills to ClawHub
└── uninstall.js                <-- Safe, fault-tolerant uninstaller
```

### 6.1 `scripts/check-rule-copies.js` (Rule Drift Prevention)
- Compares the canonical `AGENTS.md` against platform-specific copies:
  - `.windsurf/rules/ponytail.md`
  - `.qoder/rules/ponytail.md`
- Normalizes line endings (`\r\n` -> `\n`) and strips file-specific headers. Asserts byte-for-byte equality.
- Evaluates `skills/ponytail/SKILL.md` against the 9 core invariant strings. Any drift immediately breaks CI builds.

### 6.2 `scripts/check-versions.js` (Version Synchronization)
- Inspects 8 version-bearing manifest files:
  1. `package.json`
  2. `pi-extension/package.json`
  3. `ponytail-mcp/package.json`
  4. `.codex-plugin/plugin.json`
  5. `.devin-plugin/plugin.json`
  6. `.qoder-plugin/plugin.json`
  7. `gemini-extension.json`
  8. `plugin.yaml`
- Extracts version strings via regex `/"version":\s*"([^"]+)"/` and `/version:\s*([^\s]+)/`.
- Asserts that all 8 manifests declare the **identical SemVer string**.
- In GitHub Actions release tags (`GITHUB_REF_TYPE === 'tag'`), asserts the manifest version matches `GITHUB_REF_NAME` (stripping leading `v`).

### 6.3 `scripts/build-openclaw-skills.js` & `publish-openclaw-skills.js`
- **OpenClaw Build Constraint**: OpenClaw requires YAML frontmatter descriptions to be a **single line under 160 characters without quotes**.
- `build-openclaw-skills.js` reads each canonical `skills/*/SKILL.md`, replaces frontmatter with strict, truncated descriptions, and writes the output to `.openclaw/skills/*/SKILL.md`. The skill body is copied verbatim.
- `publish-openclaw-skills.js` iterates over `.openclaw/skills/` and shells out to:
  ```bash
  clawhub skill publish .openclaw/skills/<slug> --slug <slug> --name <Name> --version <version> --tags latest
  ```

### 6.4 `scripts/uninstall.js` (Surgical State Cleanup)
- Unlinks `.ponytail-active` flag and `.config/ponytail/config.json`.
- Safely cleans `settings.json` without breaking concurrent plugins:
  ```javascript
  // Splitting by '&&' or ';' allows removing ponytail-statusline while preserving other tools
  const parts = command.split(/\s*(&&|;)\s*/);
  const filtered = parts.filter(seg => !seg.includes('ponytail-statusline'));
  ```
- Wrapped in defensive `try-catch` blocks to ensure malformed JSON never crashes the uninstall process.

---

## 7. Empirical Benchmarks & Evaluation Framework

Ponytail features an extensive evaluation suite (`benchmarks/`) comprising two distinct evaluation paradigms:
1. **Single-Shot Promptfoo Benchmark** (`benchmarks/promptfooconfig*.yaml`, `benchmarks/loc.js`, `benchmarks/correctness.js`)
2. **Multi-Turn Agentic Benchmark** (`benchmarks/agentic/run.py`, `complete.py`, `judge.py`)

### 7.1 Single-Shot Evaluation Suite

```
benchmarks/
├── arms/
│   ├── baseline.js         <-- Default system prompt
│   ├── caveman.js          <-- Naive brevity ("caveman mode")
│   └── ponytail.js         <-- Ponytail ruleset
├── behavior.js & .yaml     <-- Tests heuristic edge-case adherence
├── correctness.js & .test  <-- Functional test harness for generated code
├── loc.js & loc.test.js    <-- Pure code block line counter (excluding prose)
├── robustness-audit.js     <-- 12 algorithmic edge-case tasks
└── benchmark-local.py      <-- Offline runner for local models (Llama 3.2)
```

#### Metrics & Harness Implementation
- **LOC Extractor (`loc.js`)**: Uses regex to extract code inside triple backticks (` ``` `). It ignores all conversational text, blank lines, and pure comment lines to ensure fair code density measurement.
- **Correctness Gate (`correctness.js`)**: Spawns isolated Node.js and Python subprocesses to execute generated code against strict assertion suites:
  - `csv-sum`: Validates integer/float summation, missing columns, and empty files.
  - `debounce`: Validates timer cancellation, arguments forwarding, and immediate trailing calls.
  - `email`: Tests RFC validity, domain structure, and newline injection.

### 7.2 Multi-Turn Agentic Benchmark (`benchmarks/agentic/`)

The agentic benchmark runs real, multi-turn coding sessions using headless `claude` CLI instances operating on an isolated FastAPI/React project template:

```
benchmarks/agentic/
├── run.py       <-- Spawns isolated headless Claude sessions
├── tasks.py     <-- Task definitions & adversarial test suites
├── complete.py  <-- Automated completeness judge (0-3 scale)
└── judge.py     <-- Over-engineering & quality auditor
```

#### Adversarial Safety Tasks (`tasks.py`)
To prove that brevity does not create security vulnerabilities, Ponytail tests 6 adversarial scenarios:
1. `safe-path`: Tests directory traversal attacks (`../../etc/passwd`).
2. `sql-user`: Tests SQL injection payloads (`' OR '1'='1`).
3. `critic-email`: Tests log/header injection using embedded newlines (`user@domain.com\nevil`).
4. `rate-limit`: Tests global DoS exhaustion on FastAPI routes.
5. `todo-null`: Tests crash handling when parsing literal `null` JSON payloads.
6. `trace-transfer`: Multi-file root-cause bug isolation.

### 7.3 Empirical Benchmark Findings

```
Benchmark Comparison across Core Evaluation Dimensions
┌─────────────────────────┬─────────────────┬─────────────────┬─────────────────┐
│ Metric / Dimension      │ Standard Baseline│ Naive Brevity   │ Ponytail        │
│                         │ (No Plugin)     │ ("Caveman Mode")│ (Lazy Senior)   │
├─────────────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Lines of Code (LOC)     │ High (100%)     │ Ultra-low (8%)  │ Minimal (10-18%)│
│ Prose Overhead          │ Very High (100%)│ Zero (0%)       │ Minimal (<=3 L) │
│ Correctness Pass Rate   │ 98%             │ 72% (Broken!)   │ 99% (Passed)    │
│ Adversarial Safety Pass │ 100%            │ 80% (Vulnerable)│ 100% (Passed)   │
│ Platform Native Use     │ Low (Uses NPM)  │ Low (Broken JS) │ High (Built-in) │
│ Token Cost Savings      │ 0%              │ -60%            │ -47% to -77%    │
│ Generation Speedup      │ 1.0x            │ 4.5x            │ 3.0x - 6.0x     │
└─────────────────────────┴─────────────────┴─────────────────┴─────────────────┘
```

#### Key Empirical Insights from `benchmarks/results/`:
1. **The Caveman Failure Mode (`2026-06-12-caveman-vs-ponytail.md`)**:
   Naive brevity instructions ("be brief", "caveman mode") cause models to drop essential cleanup handlers (e.g., `clearInterval`), skip input guards, or use brittle shortcuts (`JSON.parse(JSON.stringify())`). Ponytail achieves similar token savings while maintaining **100% correctness gate pass rates**.
2. **Feature Traps (`2026-06-18-agentic.md`)**:
   When prompted to "add date filtering," standard agents generated a 404-line custom date picker component. Ponytail generated **23 lines** using the native `<input type="date">`.
3. **Small Model Boundaries (`2026-06-15-llama3.2-local.md`)**:
   Empirical testing against local models (Llama 3.2 3B) showed that smaller models struggle to follow the multi-tier ladder, occasionally confusing "skip unneeded code" with "omit function bodies." Ponytail is optimized for reasoning-capable models (Claude 3.5 Sonnet, GPT-4o, Gemini 1.5 Pro).

---

## 8. Quality Assurance & Test Suite Architecture

The repository maintains an extensive test suite across 15 dedicated test files in `tests/`:

```
tests/
├── behavior.test.js        <-- Tests heuristic rule classification
├── commands.test.js        <-- Verifies command mappings across Pi, TOML, MD
├── copilot-plugin.test.js  <-- Copilot manifest & hook schema validation
├── correctness.test.js     <-- Tests correctness evaluator timeouts & gates
├── gemini-extension.test.js<-- Gemini extension manifest & invariant checks
├── grok-plugin.test.js     <-- Grok plugin structure & passive hook checks
├── hermes-plugin.test.js   <-- Python Hermes hook execution & gateway rewrites
├── hooks.test.js           <-- Full mock lifecycle for Claude, Copilot, Qoder
├── hooks-windows.test.js   <-- Windows PowerShell deadlock & path regressions
├── openclaw-skills.test.js <-- OpenClaw description length & frontmatter
├── opencode-plugin.test.js <-- OpenCode ESM module dynamic import & CRLF tests
├── package.test.js         <-- NPM package.json distribution integrity
├── package-scripts.test.js <-- Sub-package test linkage
├── qoder-plugin.test.js    <-- Qoder hook wiring & rules byte-matching
└── uninstall.test.js       <-- Surgical uninstaller & settings safety
```

### 8.1 Defensive Cross-Platform Testing Patterns
1. **Windows Lifecycle Deadlock Prevention (`tests/hooks-windows.test.js`)**:
   Simulates PowerShell CLI wrappers using `child_process.spawn` with an open, unclosed `stdin` pipe. Asserts that `ponytail-mode-tracker.js` exits cleanly within 1.2 seconds due to its `.unref()` timer rather than deadlocking the user's terminal.
2. **Filesystem Isolation (`tests/hooks.test.js`)**:
   Uses `fs.mkdtempSync` to generate isolated sandbox environments for `HOME`, `PLUGIN_DATA`, `COPILOT_PLUGIN_DATA`, and `CLAUDE_CONFIG_DIR`. Tests verify that platform configurations never cross-pollinate.
3. **Shell Metacharacter Sanitization**:
   Tests verify that paths containing malicious injection vectors (e.g., `/tmp/test; calc.exe`, `$(rm -rf /)`) are rejected by `isShellSafe` and omitted from automated statusline setup commands.

---

## 9. Real-World Case Studies & Code Transformations

The `examples/` directory illustrates the concrete before-and-after transformations enforced by Ponytail:

```
examples/
├── csv-sum.md            <-- Stdlib csv parsing vs pandas/external scripts
├── debounce.md           <-- Concise timer cancellation vs lodash.debounce
├── deep-clone.md         <-- Native structuredClone vs lodash.cloneDeep
├── email-validation.md   <-- Regex trust-boundary check vs email-validator package
├── group-by.md           <-- Native Object.groupBy vs lodash.groupBy
├── infinite-scroll.md    <-- Native IntersectionObserver vs React library
├── modal-dialog.md       <-- Native HTML <dialog> vs Radix/Headless UI wrapper
├── number-formatting.md  <-- Native Intl.NumberFormat vs numeral.js
├── rate-limit.md         <-- Minimal FastAPI middleware vs multi-strategy tutorial
└── react-countdown.md    <-- 9-line hook vs 267-line component framework
```

### Case Study Comparisons

#### 1. Deep Clone (`examples/deep-clone.md`)
```typescript
// STANDARD AI OUTPUT (42 lines + dependencies):
// Imports lodash/cloneDeep or creates recursive type-traversal object graph handlers...

// PONYTAIL OUTPUT (1 line):
const clone = structuredClone(target);
// skipped: custom class instance prototypes, add when cloning non-plain objects.
```

#### 2. Modal Dialog (`examples/modal-dialog.md`)
```jsx
// STANDARD AI OUTPUT (120+ lines):
// Installs @radix-ui/react-dialog, builds DialogOverlay, DialogContent, DialogPortal,
// DialogTitle, DialogDescription, and custom focus-trapping hooks.

// PONYTAIL OUTPUT (8 lines):
export function Modal({ isOpen, onClose, children }) {
  const ref = useRef(null);
  useEffect(() => {
    isOpen ? ref.current?.showModal() : ref.current?.close();
  }, [isOpen]);
  return <dialog ref={ref} onClose={onClose}>{children}</dialog>;
}
// skipped: CSS backdrop animation, add when visual polish required.
```

#### 3. React Countdown Timer (`examples/react-countdown.md`)
```jsx
// STANDARD AI OUTPUT: 267 lines across 4 files (custom hook, styled component, formatter, presets).
// PONYTAIL OUTPUT: 9 lines (Exact core interval + clearInterval cleanup + 0 boundary guard).
export function Countdown({ seconds, onComplete }) {
  const [rem, setRem] = useState(seconds);
  useEffect(() => {
    if (rem <= 0) { onComplete?.(); return; }
    const id = setInterval(() => setRem(r => r - 1), 1000);
    return () => clearInterval(id);
  }, [rem, onComplete]);
  return <span>{rem}</span>;
}
```

---

## 10. Architectural Insights & Takeaways for Agent Engineering

Analyzing Ponytail reveals several critical architectural principles for building high-performance AI agent plugins and standards:

1. **Rule Distribution via Single Source of Truth + Invariant CI**:
   Instead of manually editing rules across 8 ecosystems, keep a master `AGENTS.md` and enforce byte-matching and invariant string checks in CI.
2. **Non-Blocking Hook Architecture**:
   In CLI hook systems, stdin pipes can hang on Windows. Always pair stream parsing with an unreferenced timeout (`setTimeout(...).unref()`) that exits the process cleanly.
3. **Surgical Scope Confinement in Reviews**:
   When creating specialized agent modes (like `/ponytail-review` or `/ponytail-audit`), strictly command the model to ignore orthogonal concerns (e.g., formatting, security) to prevent context diffusion and prompt bloat.
4. **Declarative Tagging for Output Density**:
   Enforce structured taxonomies (`delete:`, `stdlib:`, `native:`, `yagni:`, `shrink:`) rather than free-form prose to drastically compress output tokens and improve machine-readability.
5. **Separation of Architecture Laziness from Execution Carelessness**:
   A successful minimalist standard must explicitly enumerate non-negotiable safety gates (trust boundaries, error handling, security) to prevent the LLM from generating truncated or vulnerable code.

---

## Summary File-to-Function Reference Table

| File Path | Primary Function / Role | Key Exported Functions / Symbols | Primary Trigger / Platform |
| :--- | :--- | :--- | :--- |
| `AGENTS.md` | Canonical universal rule definition | The 7-Rung Ladder, Invariants, Ceiling Comments | Universal / Ingested by all agents |
| `skills/ponytail/SKILL.md` | Primary skill & intensity levels | `lite`, `full`, `ultra` mode matrix | Slash command / MCP tool / CLI |
| `skills/ponytail-audit/SKILL.md` | Whole-repo over-engineering scan | `delete`, `stdlib`, `native`, `yagni`, `shrink` | `/ponytail-audit` |
| `skills/ponytail-debt/SKILL.md` | Technical debt & ceiling tracker | `grep -rnE '(#\|//) ?ponytail:' .` | `/ponytail-debt` |
| `skills/ponytail-gain/SKILL.md` | Benchmark score table | Benchmark median ASCII table, Honesty rule | `/ponytail-gain` |
| `skills/ponytail-help/SKILL.md` | Reference and configuration card | Mode config precedence reference | `/ponytail-help` |
| `skills/ponytail-review/SKILL.md` | Diff-focused bloat reviewer | `L<line>: <tag> <what>. <replacement>.` | `/ponytail-review` |
| `hooks/ponytail-runtime.js` | Platform detection & state manager | `setMode`, `clearMode`, `readMode`, `writeHookOutput` | Claude Code, Codex, Copilot, Qoder |
| `hooks/ponytail-config.js` | Config reader & path security | `getDefaultMode`, `isShellSafe`, `isDeactivationCommand` | Internal hook runtime |
| `hooks/ponytail-instructions.js` | Dynamic markdown rule filter | `filterSkillBodyForMode`, `getPonytailInstructions` | Pre-LLM prompt injection |
| `hooks/ponytail-activate.js` | Session initialization hook | Statusline setup nudge, mode registration | `SessionStart` / Startup |
| `hooks/ponytail-mode-tracker.js` | Prompt interceptor & mode switcher | Stdin stream parser, timeout unref, `/ponytail` routing | `UserPromptSubmit` |
| `hooks/ponytail-subagent.js` | Subagent context injector | `PONYTAIL_SUBAGENT_MATCHER` regex evaluator | `SubagentStart`, `PreToolUse` |
| `hooks/ponytail-statusline.sh` | POSIX terminal statusline | ANSI 108/173 formatting | Active Claude Code / Codex statusline |
| `hooks/ponytail-statusline.ps1` | Windows PowerShell statusline | ANSI escape sequences | Active Windows statusline |
| `ponytail-mcp/index.js` | Model Context Protocol Server | `ponytail` prompt, `ponytail_instructions` tool | Standard MCP Clients (Claude Desktop) |
| `pi-extension/index.js` | Native Pi Agent Extension | `session_start`, `before_agent_start`, `input` hooks | Pi Agent Ecosystem |
| `scripts/check-rule-copies.js` | Rule synchronization validator | `INVARIANTS` string assertion, byte-matching | CI / Pre-commit |
| `scripts/check-versions.js` | Manifest SemVer validator | 8-manifest version synchronization check | CI / Pre-release |
| `scripts/build-openclaw-skills.js` | OpenClaw skill builder | Frontmatter description truncation (<160 chars) | OpenClaw Distribution |
| `scripts/publish-openclaw-skills.js` | OpenClaw publisher | `clawhub skill publish` subprocess dispatcher | Release workflow |
| `scripts/uninstall.js` | Fault-tolerant uninstaller | Safe regex-based `settings.json` command cleaner | Clean uninstallation |
| `__init__.py` | Hermes agent integration module | `pre_llm_call`, `pre_gateway_dispatch` | Hermes Gateway |
