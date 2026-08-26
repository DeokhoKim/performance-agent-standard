#!/usr/bin/env python3
import json
import sys
import argparse
from collections import defaultdict
from dataclasses import dataclass, replace
from typing import Any, Iterable, Generator

try:
    from trieregex import TrieRegEx
except ImportError:
    print("Error: 'trieregex' is required to compress overlapping commands into optimized character-level regular expressions. Please install it using your system's package manager.")
    sys.exit(1)

def compile_layer(commands: list[str]) -> Generator[str, None, None]:
    base_groups: dict[str, list[str]] = defaultdict(list)
    for cmd in commands:
        parts = cmd.strip().split()
        if not parts:
            continue

        if parts[0] in ("git", "gh") and len(parts) > 1:
            base = f"{parts[0]} {parts[1]}"
        else:
            base = parts[0]

        base_groups[base].append(cmd.strip())

    for base, cmds in base_groups.items():
        # Native clean prefix compilation: Beginning command string is evaluated directly by agent engines.
        if len(cmds) == 1:
            yield cmds[0]
            continue

        tre = TrieRegEx(*cmds)
        pattern = tre.regex().replace(r'\ ', ' ')
        yield pattern

@dataclass(frozen=True, slots=True, kw_only=True)
class ProviderConfigs:
    claude: dict[str, Any]
    antigravity: dict[str, Any]
    gemini: dict[str, Any]
    codex: dict[str, Any]

def format_rule_for_agent(agent: str, decision: str, regexes: list[str]) -> list[Any]:
    """!
    @brief Formats compiled regex rules into provider-specific configuration formats.

    @details
    - **codex**: Uses physical boundary hooks (sandbox_mode) mapping to Regex() filters.
      @see https://platform.openai.com/docs/codex
    - **antigravity**: Employs a terminal jailing triple-list architecture (deny, ask, allow), matching command() directives.
      @see https://antigravity.google/docs
    - **gemini**: Implements a policy engine with integer priorities (lower number = higher priority) and decisions ('allow', 'deny', 'ask_user').
      @see https://ai.google.dev/docs/gemini_cli

    @param agent The target AI agent provider.
    @param decision The permission layer being compiled (allow, deny, ask).
    @param regexes A list of highly-compacted regular expressions.
    @return A list of formatted configuration objects native to the provider.
    """
    match agent:
        case "codex":
            return [f"Regex({r})" for r in regexes]
        case "antigravity":
            return [f"command({r})" for r in regexes]
        case "gemini":
            priority = 200 if decision == "allow" else 900
            gemini_decision = "ask_user" if decision == "ask" else decision
            return [
                {
                    "toolName": "run_shell_command",
                    "commandRegex": r,
                    "decision": gemini_decision,
                    "priority": priority
                }
                for r in regexes
            ]
        case _:
            raise ValueError(f"Unknown agent: {agent}")

def generate_globs(commands: list[str]) -> list[str]:
    globs = []
    for cmd in commands:
        c = cmd.strip()
        if c:
            globs.append(f"Bash({c})")
            globs.append(f"Bash({c} *)")
    return globs

def generate_agent_configs(layers: dict[str, list[str]]) -> ProviderConfigs:
    allow_raw = layers.get("allow", [])
    sandbox_raw = layers.get("sandbox_allow", [])
    deny_raw = layers.get("deny", [])
    ask_raw = layers.get("ask", [])

    allow_regexes = list(compile_layer(allow_raw))
    sandbox_regexes = list(compile_layer(sandbox_raw))
    deny_regexes = list(compile_layer(deny_raw))
    ask_regexes = list(compile_layer(ask_raw))

    combined_allow_regexes = allow_regexes + sandbox_regexes

    return ProviderConfigs(
        claude={
            "permissions": {
                "allow": generate_globs(allow_raw + sandbox_raw),
                "deny": generate_globs(deny_raw),
                "ask": generate_globs(ask_raw)
            }
        },
        codex={
            "hooks": {
                "PreToolUse": {
                    "allow_patterns": format_rule_for_agent("codex", "allow", combined_allow_regexes),
                    "deny_patterns": format_rule_for_agent("codex", "deny", deny_regexes)
                }
            }
        },
        antigravity={
            "permissions": {
                "allow": format_rule_for_agent("antigravity", "allow", combined_allow_regexes),
                "deny": format_rule_for_agent("antigravity", "deny", deny_regexes),
                "ask": format_rule_for_agent("antigravity", "ask", ask_regexes)
            }
        },
        gemini={
            "rules": format_rule_for_agent("gemini", "allow", combined_allow_regexes) + format_rule_for_agent("gemini", "ask", ask_regexes) + format_rule_for_agent("gemini", "deny", deny_regexes)
        }
    )

def _load_json(path: str) -> dict[str, list[str]]:
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading {path}: {e}")
        sys.exit(1)

def run(source_path: str, provider: str | None = None) -> None:
    layers = _load_json(source_path)
    configs = generate_agent_configs(layers)

    out_dict = {
        "claude": configs.claude,
        "codex": configs.codex,
        "antigravity": configs.antigravity,
        "gemini": configs.gemini
    }

    if provider:
        if provider not in out_dict:
            print(f"Error: Unknown provider '{provider}'")
            sys.exit(1)
        print(json.dumps(out_dict[provider], indent=2))
    else:
        print(json.dumps(out_dict, indent=2))

def main() -> None:
    parser = argparse.ArgumentParser(description="Compile cross-agent permissions.")
    parser.add_argument("--source", default="whitelist.json", help="Source whitelist JSON")
    parser.add_argument("--provider", help="Specific provider to output (e.g., claude, codex, antigravity, gemini)")
    args = parser.parse_args()

    run(args.source, args.provider)

if __name__ == "__main__":
    main()
