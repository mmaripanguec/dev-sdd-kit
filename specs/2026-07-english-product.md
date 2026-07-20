# Spec: Product machinery fully in English

| Field | Value |
|---|---|
| Status | implemented |
| Requirement type | existing `[workspace]` (factory product language) |
| Context loaded | full inventory of Spanish product files after the review "veo la documentación en español" |
| Author / Date | Claude + Marcos Maripangue / 2026-07-19 |
| PO/TL gate | approved by Marcos Maripangue on 2026-07-19 (review request: project documentation must read in English) |
| DoR gate | approved together with QA/PR (direct-order scope, mechanical translation) |
| Architecture gate | N/A |

## 1. Problem
A public-template visitor reads CLAUDE.md, the 14 skills, 7 agents, 6 rules,
the spec template and the knowledge scaffolding — and all of it was Spanish.
The earlier "public docs EN / internal ES" split breaks down for a template:
its internal machinery IS the product documentation.

## 2. Objective
The factory's machinery is fully English (product = English); each instance
chooses its working language for authored artifacts via `system.lang`.
Spanish operating guides remain as clearly-labeled extras; historical
Spanish specs remain as authentic artifacts of the factory building itself.

## 3. Success criteria
- SC-01 Every product file (CLAUDE.md, skills, agents, rules, spec template,
  templates/*.md, knowledge scaffolding, harness) reads in English.
- SC-02 Agent names are English identifiers (requirements, estimation,
  analysis, architecture, quality, release, operations) with all live
  references updated.
- SC-03 Cross-artifact markers unified in English ([NEEDS CLARIFICATION],
  Clarifications, Session, Convergence) across template and skills.
- SC-04 All three suites green; both architecture editions regenerate.

## 4. Out of scope
- Historical Spanish specs (authentic record) and ES guides
  (guia-operativa, instructivo — labeled).
- Derived-artifact generators' output strings (dora.sh table labels,
  generate-as-is.sh seals) — follow-up spec candidate.
- Script filenames beyond those already standardized.

## 10. Task plan (F6)
- [x] T1 [workspace] skills batch 1 translated (as-is*, clarify,
      consistency, converge, harness-init)
- [x] T2 [workspace] skills batch 2 translated (implement-task, orchestrate,
      repo-add, repo-map, spec-create, spec-review, system-map)
- [x] T3 [workspace] agents renamed + translated; 6 rules translated
- [x] T4 [workspace] core translated: CLAUDE.md, spec template,
      templates/*.md, knowledge scaffolding, harness
- [x] T5 [workspace] unification pass: English markers everywhere, harness
      echos, agent names in README tree / HTML templates / SVG diagrams /
      ES guides; language notes rewritten (README + EN doc)

## 11. Certification (F7)
SC-01..03 verified by grep (no live Spanish command/agent names; markers
unified). SC-04: test-docs 42/42 · test-repo-lib 40/40 · test-dora 17/17;
both editions regenerated. QA/PR gate: approved by Marcos Maripangue on
2026-07-19 upon publication review.

## 12. Traceability
Origin: review request by Marcos (2026-07-19). Branch:
feature/english-product. Executed by 4 parallel translation agents + a
unification pass.
