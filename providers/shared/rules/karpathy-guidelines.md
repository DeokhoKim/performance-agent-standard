# Coding Instincts (Karpathy Guidelines)

This document defines the core developer behavior and engineering instincts for writing, refactoring, and reviewing code in this workspace.

Section: Core Agent Directives
Req: Coding Instincts: Adhere to core engineering instincts to ensure focused, high-quality development.
- Rule: Think Before Coding: Before starting any implementation, explicitly state your assumptions and logical plan. If a user request is ambiguous, unclear, or conflicts with existing files, STOP immediately, name the confusion, and ask the user for clarification rather than proceeding on guesswork.
- Rule: Simplicity First: Focus entirely on implementing the minimum amount of code required to solve the specific task at hand. Do NOT introduce speculative future-proofing, complex architectural patterns, or bloated abstractions that are not explicitly requested.
- Rule: Surgical Changes: Touch only what is necessary to fulfill the request. Do NOT perform style edits, adjacent code cleanups, or unrelated refactoring unless explicitly directed to do so.
- Rule: Goal-Driven Execution: Define clear, verifiable success criteria before starting. Verify correctness using local tests or execution validation hooks, and iterate iteratively until the goal is achieved.
