---
name: orchestrate
description: Walks the E2E 9-phase cycle for a feature, delegating to the per-phase agents and stopping at each human gate. Only invocable by humans.
disable-model-invocation: true
argument-hint: "<spec o descripción de la feature>"
---

Run the E2E cycle for: $ARGUMENTS

## Global orchestrator rules
- Sequential: advance phase by phase; NEVER skip a human gate.
- After each phase: write the artifact in specs/ or knowledge/ and commit
  before moving on (a mid-flow failure does not lose previous phases).
- Escalate: on ambiguity, contradiction or impossible verification,
  stop and ask the human at the nearest gate. Do not assume.
- Accountability: record in each gate's artifact who approved,
  when, and on which version (commit).

## Sequence
F0 Triage          → STEP 0 of /spec-create: existing application or
                     new application? · load the current context packs ·
                     dependencies without context => ASK (repo, onboarding,
                     pack), never assume · inconsistency => ASK ·
                     ambiguity detected => /clarify (max. 5 questions;
                     the decisions feed /spec-create and, once the spec
                     is created, are recorded in its Clarifications section)
F1 Requirement     → requirements subagent  → INVEST stories P1-P3 → PO/TL GATE
F2 Estimation      → estimation subagent    → points + WSJF
F3 Refinement      → loop /spec-review + fixes until DoR;
                     /consistency with FIT FOR GATE verdict           → DoR GATE
F4 Analysis        → analysis subagent      → rules, deps, limits
F5 Design          → architecture subagent  → contracts, C4, ADRs;
                     /consistency with FIT FOR GATE verdict           → Architecture GATE
F6 Construction    → /harness-init if multi-session; then
                     /implement-task for each task in the plan (TDD)
F7 Certification   → /converge (gaps → TC tasks, implemented
                     with TDD) + quality subagent → verdict             → QA/PR GATE
F8 Production      → release subagent       → risk dossier          → CAB Committee GATE
F9 Operations      → operations subagent    → monitoring, postmortem → DevOps/SRE GATE

When F9 finishes: verify the cycle closed — postmortems and incidents
fed knowledge/, and the spec ended in "implemented" state with its
full traceability (spec → ADR → commits → dossier → operations).
