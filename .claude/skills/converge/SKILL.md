---
name: converge
description: Closes the functional code↔spec gap at the end of construction (F6/F7) — evaluates the real code against the spec's stories and criteria and ADDS the remaining work as convergence tasks. Use before F7 certification or when asked to "converge the spec" / "what is missing from the spec".
argument-hint: "<spec-path>"
allowed-tools: Read Glob Grep Edit
---

Converge spec $ARGUMENTS against the real code of the affected repos.
This is NOT a git diff tool: it evaluates the CURRENT STATE of the code
against what the spec promises, without looking at history or branches.

## Step 1 — Context
Read the full spec (stories with ACs, SC-xx, task plan) and identify
the affected repos via the task labels. Load the as-is of those repos
(`knowledge/as-is/<repo>/`) and use the codebase-memory MCP graph
(search_graph/trace_path) if it responds; if not, Grep directly in
`repos/<repo>` — graceful degradation, declare it in the report.

## Step 2 — Story-by-story evaluation
For each AC (and each SC verifiable in code): look for the real evidence
and classify with `file:line`:
- **SATISFIED** — implemented and covered by a test.
- **PARTIAL** — implemented without a test, or covers only part of the AC.
- **ABSENT** — no implementation.
ACs of stories explicitly out of scope or of P3 stories not started are
listed as NOT STARTED (they are not a gap if the plan did not mark them done).

## Step 3 — Record (append-only)
- If there are gaps (PARTIAL/ABSENT with a task marked `[x]`, or AC without
  a task): ADD at the end of the spec's task plan the subsection
  `### Convergence (<today's date>)` with one new task per gap,
  labeled with its repo and referencing the AC (`- [ ] TC1 [<repo>] cover
  CA2.3: …`). **NEVER rewrite, edit or delete existing tasks** — if
  there are no gaps, the plan stays byte-for-byte identical and the report
  declares it.
- Idempotent re-run: before adding, review the previous convergences;
  a gap already recorded and still open is not duplicated.

## Final report
Table AC/SC → status → evidence; summary of gaps added (or "no
gaps"); reminder that TC tasks are executed with /implement-task
(TDD) before the quality agent's verdict. Do not touch code or tests:
this skill only reads code and writes to the spec's plan section.
