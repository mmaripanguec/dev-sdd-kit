# Spec: <title>

| Field | Value |
|---|---|
| Status | draft → approved → implemented |
| Requirement type | existing `[affected repos]` · new application · mixed (F0 triage) |
| Context loaded | packs used and their `verificado:` (e.g. `xx-sistema@2026-07-19`) |
| Business domain | <business capability; using the domain profile's landscape if one exists (e.g. BIAN in banking)> |
| Author / Date | |
| PO/TL gate | approved by __ on __ (commit __) |
| DoR gate | approved by __ on __ (commit __) |
| Architecture gate | approved by __ on __ (commit __) |

> Ambiguity: resolve with /clarify before F1. Whatever remains unresolved
> is marked inline as `[NEEDS CLARIFICATION: concrete question]`
> (maximum 3 markers; priority scope > security/privacy > UX >
> technical detail; the rest is assumed and documented in the Assumptions
> block of § Analysis). A pending marker blocks the DoR.

## 1. Problem
What hurts today, for whom, and with what evidence (data from knowledge/uso.md if available).

## 2. Goal
Observable outcome once finished. One or two sentences in business language.

## 3. Success criteria
Measurable and technology-agnostic (what changes for the business/user,
not how). Certified in F7 and contrasted in F9 against knowledge/uso.md.
- SC-01 <metric + threshold + deadline; e.g. "onboarding a repo takes < 5 min">
- SC-02 …

## 4. Out of scope
What explicitly will NOT be done in this iteration. Do not leave empty.

## 5. Clarifications
Record of /clarify sessions (the answers are ALSO integrated into the
relevant section; this is the decision trace).
### Session YYYY-MM-DD
- Q: <question> → A: <chosen answer> (decided by: <who>)

## 6. User stories (F1 · INVEST)
Each story carries a priority: [P1] = MVP (the P1s on their own must be a
viable and independently testable product), [P2] = important, [P3] = nice to have.
### H1 [P1] — <title>
As a <role>, I want <action>, so that <value>.
**Acceptance criteria (Gherkin):**
- CA1.1 Given <context>, when <action>, then <measurable result>.

## 7. Estimation (F2)
| Story | Points | Complexity | Assumptions |
|---|---|---|---|
WSJF priority: <order and rationale>

## 8. Analysis (F4)
**Business rules:** RN-01 … (kept in sync with knowledge/reglas-negocio.md)
**Dependencies:** <domains, systems, teams; blockers flagged.
Any dependency without context in the factory: ask for its repository,
onboard it (/repo-add + /repo-map) or explicitly mark it out of
scope — never assume its behavior>
**Edge cases:** nulls/extremes · concurrency · third-party failures ·
time zones/currencies · permissions · volume (each with its Gherkin CA)
**Assumptions:** <ambiguities assumed with a reasonable default (including
those /clarify did not ask); each assumption states who validates it>
**Regulatory:** <applicable personal/transactional data requirements>

## 9. Design (F5)
**Contracts:** link to versioned OpenAPI/event schemas.
**C4 diagrams (mermaid):** containers and components.
**ADRs:** links to knowledge/decisiones/ADR-____.md
**Threat model (STRIDE):** applies yes/no; mitigations in the ADR.
**NFRs / SLOs:** availability __%, p99 latency __ms, volume __.

## 10. Task plan (F6)
Multi-repo format: each task is tagged with the name of its target
repository exactly as it appears in repos.yaml (the only valid tags are the
registered repos; `[workspace]` for changes in this context repo).
Tasks with no files or dependencies in common may additionally carry `[P]`
(parallelizable among themselves). Group by story, P1 first (MVP).
If the triage was "new application", T0 creates the application:
- [ ] T0 [workspace] create repo + /repo-add + scaffolding per F5 design + initial as-is and pack
- [ ] T1 [<registered-repo>] … (one task = one commit IN THAT repo; TDD; /implement-task)
- [ ] T2 [<registered-repo>] [P] …
Deploy order: per the registry's `deploy_order` (provider before
consumer; backward compatibility).
When closing F6, /converge appends here a subsection `### Convergence (date)`
with the code↔spec gaps detected (append-only); if there are no gaps,
that subsection is never created and the plan remains intact.

## 11. Certification (F7)
/converge with no pending gaps + quality agent verdict
(includes SC-xx from §3) + QA/PR gate: __

## 12. Traceability
Spec → ADRs → commits → CAB dossier → related postmortems.
