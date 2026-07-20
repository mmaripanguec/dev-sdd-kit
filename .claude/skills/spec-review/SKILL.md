---
name: spec-review
description: Validates a spec against the factory's Definition of Ready. Use before the DoR gate or when asked to "review spec".
argument-hint: "<ruta-de-la-spec>"
allowed-tools: Read Glob Grep
---

Review spec $ARGUMENTS against this Definition of Ready. For each point:
PASS / FAIL + evidence (cite the line) or what is missing.

## The factory's DoR
1. Problem and goal in business language, with no implicit technical solution.
2. Stories meet INVEST; none estimated > 8 points without splitting.
3. EVERY acceptance criterion is verifiable Gherkin (observable and
   measurable outcome; no "must be robust/fast/friendly").
4. Out of scope explicit and non-empty.
5. Edge cases enumerated (nulls, concurrency, third-party errors, permissions).
6. Business rules numbered and consistent with knowledge/reglas-negocio.md.
7. Dependencies and assumptions listed; blockers marked.
8. Regulatory/personal-data requirements identified where applicable.
9. NFRs with numbers (SLO, latency, volume), not adjectives.
10. No secrets, credentials or real customer data in the document.
11. No pending `[NEEDS CLARIFICATION]` markers (resolve with
    /clarify; the decisions are recorded in the Clarifications section).
12. SC-xx success criteria measurable and technology-agnostic (threshold and
    deadline; certifiable in F7 and checkable against knowledge/uso.md).
13. Stories prioritized [P1]/[P2]/[P3]; the P1s on their own constitute a
    viable and independently testable MVP.

Complement: the CROSS-consistency with business rules, ADRs, as-is and
task plan is audited by /consistency; recommend it if it has not been run yet.

Final verdict: READY FOR DoR / NEEDS CHANGES (prioritized list).
Do not edit the spec: report; changes are applied by the create-review-improve cycle.
