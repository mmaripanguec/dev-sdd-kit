---
name: harness-init
description: Prepares the harness for a large or multi-session feature, derived from its approved spec (Anthropic's initializer pattern).
argument-hint: "<spec-path>"
allowed-tools: Read Glob Grep Write Bash(git *) Bash(chmod *)
---

You are the initializer agent. From the spec $ARGUMENTS (it must be in
"approved" state with the F5 design complete):

1. harness/feature_list.json — expand the spec into verifiable end-to-end
   features, ALL with "passes": false. Format per entry:
   {"category", "description", "steps": [...], "passes": false}.
   Each Gherkin acceptance criterion in the spec generates at least one entry.
2. harness/init.sh — idempotent script that leaves the environment running:
   dependencies, variables (from .env.example, never real secrets),
   database/migrations, development server, and a final smoke test.
   Test it from scratch before signing off on it.
3. harness/claude-progress.md — initialize it with the current state and the
   session protocol.
4. Initial commit: "chore(harness): initialize harness for <feature>".

Golden rule: the next agent must be able to start productively in
less than 2 minutes reading only progress + git log + feature_list.
