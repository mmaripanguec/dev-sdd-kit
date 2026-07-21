---
name: spec-create
description: Generates a layered feature spec (F1-F5) using the factory template. Use when someone asks to "create spec", "specify feature" or describes new functionality before implementing it.
argument-hint: "<feature-name> [short description]"
allowed-tools: Read Glob Grep Write
---

## Context
- Existing specs: !`ls specs/ 2>/dev/null`
- Registered repos: !`. scripts/repo-lib.sh 2>/dev/null && registry_repos | tr '\n' ' '`
- Current business rules: see knowledge/business-rules.md

## STEP 0 — Requirement triage (MANDATORY before F1)

**0.1 Classify** against repos.yaml and the `mapa-sistemas` index:
- **A · EXISTING application**: the requirement touches registered repos.
  Identify WHICH ones and record it in the spec ("Requirement type" field).
- **B · NEW application**: no repo exists. The spec declares it; the stack and
  the architecture are decided in F5, and the task plan starts with a T0 for
  creation (create repo → /repo-add → scaffolding → as-is and pack at birth).
- **Mixed**: a combination; apply both protocols.
- If you cannot classify with certainty: ASK the user. Do not assume.

**0.2 Load context (scenario A)**: for each affected repo, load its
pack (`<prefijo>-<repo>`) and the system pack (`<prefijo>-sistema`).
- Pack doesn't exist? → generate it with /repo-map (or /system-map) BEFORE F1.
- It exists? → validate freshness: `scripts/freshness.sh check <pack>` and
  `scripts/assertions.sh <sistema>`. Stale → regenerate before continuing.

**0.3 Dependencies — ask, NEVER assume**: if the stories, the as-is
or the packs reveal that the application depends on another system/service:
- Is it registered in repos.yaml? NO → **STOP AND ASK** the user
  which is its repository (URL/path) or whether it is explicitly out of
  scope. With the answer: /repo-add + /repo-map for the dependency.
- YES → validate that its pack exists and is current (as in 0.2).
- Any INCONSISTENCY (pack contradicts code or registry, false
  assertion, declared dependency that does not appear in the code or vice
  versa): **ALWAYS ASK**; never normalize silently.

**0.4 Requirement ambiguity**: if the request admits interpretations
that change scope, design or certification, run /clarify BEFORE F1;
its decisions feed the spec and are recorded in its Clarifications section.

## Task
Create `specs/$(date +%Y-%m)-$0.md` from [specs/_template.md](../../../specs/_template.md):

1. Delegate story writing to the `requirements` subagent (phase 1).
2. With the stories approved by PO/TL, delegate estimation to the
   `estimation` subagent (phase 2).
3. Iterate refinement with /spec-review until the DoR is met, and close the
   phase with /consistency at a FIT FOR GATE verdict (phase 3).
4. Delegate analysis (rules, dependencies, edge cases) to the
   `analysis` subagent (phase 4).
5. Delegate design (contracts, C4, ADRs) to the `architecture` subagent (phase 5).

At each human gate: STOP, present the agent's summary and wait for
explicit approval. Record in the spec who approved and when.
Do not write code. Do not modify files outside specs/ and knowledge/.
