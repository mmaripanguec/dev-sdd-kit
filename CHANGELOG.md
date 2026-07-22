# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-07-22

Knowledge-as-context architecture documents and clearer code-graph setup.

### Added
- **AS-IS architecture document as knowledge** (arc42 + C4). New generic
  templates (`templates/knowledge-architecture.{md,html,narrative.md}`) and
  generator (`scripts/generate-architecture.sh`) that writes
  `knowledge/architecture/<system>.md` and a self-contained `.html` twin
  (Mermaid C4 diagrams), combining a curated per-system narrative with data
  DERIVED from the code (topology, dependencies, counts, seals).
- The generator runs automatically at the end of `scripts/generate-as-is.sh`
  (i.e. after every `/repo-add` indexing), so the document stays current.
- `/system-map` now authors the narrative, generates the document and creates a
  `<prefix>-architecture` **context skill** (from `templates/skill-architecture.md`)
  that agents load on the system's repo-name triggers — encoding a **docs-first
  policy**: answer from the document; consult code only for undocumented gaps.
- `docs/codebase-memory-setup.md`: direct-engine vs fleet/Postgres-facade modes,
  and how each one indexes.
- `scripts/tests/test-architecture.sh`: self-test suite for the generator.

### Changed
- `/repo-add` documents both codebase-memory modes and treats the fleet-facade
  `-32601 (index_repository has no equivalent in the fleet graph)` as EXPECTED,
  not a hard failure — onboarding no longer looks broken on read-only facades.
- `CLAUDE.md`, `.env.example` and `init-system.sh` updated for the new
  `knowledge/architecture/` scaffolding (cleaned on instance init).

## [1.0.0] - 2026-07-19

First public release of the spec-driven factory template.

### Added — core factory
- Declarative system registry (`repos.yaml`): topology as data — repos,
  providers, roles, deploy order, domain profiles; no hardcoded repo names.
- Full F0–F9 lifecycle orchestration (`/orquestar`) with six human gates
  recorded per commit; gate enforcement backed by tool permissions.
- Repo onboarding (`/repo-add`, `scripts/setup.sh`): clone, register, seed
  per-repo context, index into the codebase-memory graph, derive the as-is map.
- Derived as-is map (`scripts/generate-as-is.sh`) with provenance seals,
  drift detection (`--check`) and per-repo extractor hooks.
- Context packs per repo and per system (loadable skills) with file:line
  evidence, freshness seals (`scripts/freshness.sh`) and executable
  assertions (`scripts/assertions.sh`).
- Multi-session agent harness (Anthropic initializer pattern).
- Template distribution: `scripts/init-sistema.sh` instantiates a clean
  system workspace; instances update via `git pull upstream main`.

### Added — quality mechanics (adopted from the spec-kit ecosystem analysis)
- `/clarificar`: structured ambiguity resolution (max 5 prioritized
  questions) recorded in the spec's Clarifications section.
- `/consistencia`: read-only cross-artifact analysis (6 detection passes;
  rule conflicts are automatically CRITICAL; single gate verdict).
- `/convergir`: append-only code↔spec functional convergence before
  certification.
- 12-section spec template: measurable success criteria (SC-xx), P1–P3
  story priorities with independent MVP, `[NECESITA CLARIFICACIÓN]` markers
  blocking the 13-point Definition of Ready.

### Added — measurement & documentation
- DORA metrics derived from git history and blameless postmortems
  (`scripts/dora.sh`): deployment frequency, lead time, CFR, MTTR — sealed,
  "no data" over made-up values (rule RN-F4).
- Generated architecture document in two editions
  (`docs/arquitectura.html` ES · `docs/architecture.en.html` EN) with a
  conceptual model diagram; live catalog of skills, agents, rules, topology
  and specs (`scripts/docs.sh`, CI-checked).
- Landing page (`docs/index.html`) ready for GitHub Pages.

### Added — publication package
- English public docs: README, CONTRIBUTING (the factory's real process),
  MIT LICENSE, issue/PR templates.
- Spanish operating guide preserved in full (`docs/guia-operativa.md`).
- CI (Bitbucket + GitHub Actions template): clones registry repos and
  auto-commits as-is map, DORA metrics and both documentation editions.

### Quality
- Three self-test suites, 99 asserts, all TDD-first (failing tests
  committed before implementation): `test-repo-lib.sh` (40),
  `test-dora.sh` (17), `test-docs.sh` (42).
- Independent multi-agent code review (26 agents) on the quality-mechanics
  release; all 10 confirmed findings fixed, including least-privilege
  permission tightening on new skills.

[1.0.0]: https://github.com/mmaripanguec/dev-sdd-kit/releases/tag/v1.0.0
