---
name: consistency
description: Read-only cross-consistency analysis between a spec and the rest of the factory's artifacts (business rules, ADRs, as-is, .claude/rules rules, task plan). Use before the DoR gate and the Architecture gate, or when asked to "analyze consistency" of a spec.
argument-hint: "<spec-path>"
allowed-tools: Read Glob Grep
---

Analyze the consistency of spec $ARGUMENTS against the factory's
knowledge. STRICTLY READ-ONLY: do not edit any artifact; only report.

## Semantic model (build first)
1. Spec inventory: stories (Hx, priority), ACs in Gherkin, SC-xx,
   RN-xx cited, plan tasks (Tx with repo label).
2. Contrast artifacts: `knowledge/business-rules.md`,
   `knowledge/decisions/` (current ADRs), `knowledge/as-is/` (INDEX and
   affected repos), `.claude/rules/*.md` (including the domain profile if the
   repo declares it in repos.yaml), context packs of the affected repos.

## Six detection passes
- **A · Duplication**: stories/ACs/SCs that repeat the same thing in other words.
- **B · Ambiguity**: non-measurable adjectives ("fast, robust, scalable,
  intuitive, secure" without a number), pronouns without a referent, pending
  `[NEEDS CLARIFICATION]` markers.
- **C · Underspecification**: story without AC, AC without an observable
  outcome, SC without a threshold, dependency mentioned but not registered
  in repos.yaml.
- **D · Alignment with rules**: contradictions with `.claude/rules/*` or with
  `knowledge/business-rules.md` (cited RN that does not exist, or a current
  one the spec violates). **Every conflict in this pass is automatically CRITICAL.**
- **E · Coverage**: requirements (AC/SC) without a task in the plan and tasks
  without a requirement justifying them — in BOTH directions. Task REPO
  labels that are neither registered repos nor `[workspace]` (the `[P]`
  parallelism marker and the `[P1]`/`[P2]`/`[P3]` story priorities are not
  repo labels; do not flag them). If the spec has no plan yet, skip the
  pass and declare it.
- **F · Contradictions**: spec vs as-is (claims something the code
  contradicts), spec vs current ADR, terminology drift (same entity with
  two names), tasks whose order violates `deploy_order`.

## Report (maximum 50 findings)
| ID | Pass | Severity | Location | Finding | Recommendation |
Severities: CRITICAL (blocks gate) / HIGH / MEDIUM / LOW. Then an
AC/SC ↔ tasks coverage table. Final verdict:
- **FIT FOR GATE** — no CRITICAL and no unjustified HIGH.
- **DO NOT PASS THE GATE** — there are CRITICAL (or unjustified HIGH)
  findings; prioritized list of corrections. The changes are applied by the
  create-review-improve cycle, never by this skill.
