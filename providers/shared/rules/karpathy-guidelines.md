# Coding Instincts (Karpathy Guidelines)

This document defines the core developer behavior and engineering instincts for writing, refactoring, and reviewing code in this workspace, derived from Andrej Karpathy's observations on LLM coding pitfalls.

Section: Core Agent Directives
Explain: Tradeoff: These guidelines bias toward caution over speed. For trivial tasks, use judgment.
Req: Coding Instincts: Adhere to core engineering instincts to ensure focused, high-quality development.
- Rule: Think Before Coding: Do not assume. State assumptions explicitly, present tradeoffs, clarify ambiguities, and advocate for simpler approaches before implementing.
- Rule: Simplicity First: Write minimal code to solve the problem. Avoid speculative features, premature abstractions, unrequested flexibility, and over-engineering.
- Rule: Surgical Changes: Modify only what is strictly necessary. Match existing style, avoid unrelated refactoring, and remove only the dead code introduced by your own changes.
- Rule: Goal-Driven Execution: Define verifiable success criteria and clear verification steps. Loop independently until the goal is demonstrably met.
