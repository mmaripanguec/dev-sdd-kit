---
name: implement-task
description: Executes ONE task from a spec's plan with strict TDD protocol (F6 Construction). Use to implement tasks one at a time.
argument-hint: "<ruta-spec> <id-tarea>"
allowed-tools: Read Glob Grep Edit Write Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *)
---

Implement ONLY task $1 from spec $0. Protocol:

1. Harness startup: read harness/claude-progress.md and
   `git log --oneline -10`; run ./harness/init.sh and verify with a smoke
   test that the environment works BEFORE touching anything.
2. Read the full spec: the task is implemented against its acceptance
   criteria, not against your interpretation. Also load the context pack
   of the task's repo (`<prefijo>-<repo>`; the system one if the task
   crosses repos) — its "Pitfalls" exist so you don't repeat them.
3. TDD: write the tests that encode the criteria → verify they FAIL →
   commit the tests → implement until green WITHOUT touching the tests → refactor.
4. End-to-end verification of the functionality as a user would do it;
   only then update "passes" in harness/feature_list.json.
   FORBIDDEN to edit or delete feature descriptions from that file.
5. Clean closure: lint + typecheck green, commit with Conventional Commits
   referencing the spec, and an entry in harness/claude-progress.md
   (what was done, decisions, what's next).

If the task reveals ambiguity in the spec: STOP and escalate. Do not
improvise scope. If you discover unplanned work, note it as a new task in
the spec instead of doing it now.
