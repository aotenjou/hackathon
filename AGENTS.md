# Project Agent Instructions

These instructions supplement the global agent rules for this repository.

## Subagent Usage Preference

- For any non-trivial task, first look for independent workstreams that can run in parallel.
- When the active runtime permits subagents, prefer launching multiple focused subagents instead of doing all exploration or implementation serially.
- Use explorer subagents for bounded codebase questions, especially when several questions can be answered independently.
- Use worker subagents for implementation slices with disjoint file ownership. Tell each worker which files or subsystem it owns, and that other agents may be editing nearby code.
- Keep the main agent on the critical path: do not delegate the immediate blocker if waiting for it would stall progress.
- After subagents return, integrate their results locally, review changed files, and run the smallest useful verification.

## Coordination Defaults

- Split work by subsystem, not by vague topic. Examples: scene data, UI/HUD, tests, art assets, documentation.
- Prefer two to four subagents for broad tasks; use one subagent for a narrow side investigation; skip subagents for trivial edits.
- Avoid duplicate assignments. Each subagent should have a concrete output and a non-overlapping responsibility.
- Keep user-facing updates concise: mention when parallel agents are launched, what each owns, and which results are being integrated.
