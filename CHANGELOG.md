# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/).

## [1.6.1] - 2026-09-08

### Fixed
- README: the directory tree listed files that do not exist
  (`docs/publicacion-github.md`, `docs/difusion/`); skill count (15), suite
  count (7) and assert count (178) now match the tree; ES script aliases
  documented; test badge derived from the real suites.
- Landing (`docs/index.html`): language note aligned with the README (factory
  in English, working language chosen at init); `claude` step added between
  `init-system.sh` and `/repo-add`.
- Comparison table: replaced the vague "limited" cells with what each tool
  actually offers for brownfield; tagline softened from "cannot lie" to
  "derived from real sources, with provenance seals" (README, landing, banner).
- `test-dora.sh`: fixture commits carry an explicit git identity, so the suite
  passes on clean runners without `user.name`/`user.email`.
- `test-docs.sh`: the smoke run over the real workspace now writes to a temp
  copy; running the suite no longer modifies tracked `docs/*.html`.
- `generate-as-is.sh`: structure step no longer aborts on empty repos under
  `pipefail`; vendored `contracts/` are excluded from consumption detection.
- `.gitignore`: `harness/.venv/`.

## [1.6.0] - 2026-07-25

### Changed — /context-report skill & documentation standard
- `/context-report`: added the *committee-recurring findings* the reports keep
  tripping on, so future runs pre-empt them — valid CML (declare every context
  used in a relation, correct upstream/downstream direction, one strategy per
  upstream), ADRs as decision atoms with Options considered, Given/When/Then
  quality scenarios, cross-document count reconciliation, complete Annex A
  inventories, and honest severity calibration (a parametrized query with a
  constant-bounded table name is a *mitigated* smell, not a critical
  injection — reward calibration, reject both alarmism and omission).
- Documentation standard (§5 ADR): added a *Common pitfalls* note (outcome-only
  ADRs, terse quality assertions, and invalid/inverted CML are the three most
  frequent failures).

## [1.5.0] - 2026-07-25

### Added — repository file structure as derived documentation
- `scripts/repo-tree.sh <path> [depth]`: deterministic file-structure tree
  (tracked files only — respects .gitignore — recursive per-directory
  counts, root files listed, `find` fallback for non-git dirs). Suite
  `scripts/tests/test-repo-tree.sh` (17 asserts, committed red first).
- System architecture document: new derived section **5.2.1 Repository file
  structure** — `generate-architecture.sh` injects a depth-2 tree per
  registered repo on every regeneration (`{{FILE_TREES}}` placeholder in
  `templates/knowledge-architecture.md`).
- Documentation standard: new required **Annex E — repository file
  structure** (derived tree + curated directory → role → section
  annotations) in the section checklist.
- `/context-report` skill: Annex E requirements encoded (root depth 2,
  source first level only, annotation table, structure-driven finding
  mining) plus the **E.4 sibling-repos** pattern for standalone reports and
  the system-doc regeneration step.

## [1.4.0] - 2026-07-25

### Added — application context reports (/context-report)
- New skill `/context-report <repo> [--update]`: generates the maximum-detail
  **application** architecture & context report (arc42 + C4 + 42010) —
  parallel file:line mining, graph queries, obsolescence research with
  sources, a business-flow traceability matrix (UI route → front module →
  service → consumed domains → upstream route), an end-to-end view with a
  per-hop table, sequence diagrams, enriched ADRs, numbered verifiable
  quality scenarios, and a mandatory **adversarial review committee**
  (architecture + quality agents) before the human gate. Hard-won
  non-negotiables encoded (re-derive inherited numbers, adversarial
  refutation of security claims, cluster-label skepticism).
- Corporate HTML twin for application reports:
  `templates/knowledge-architecture-app.html` (light/dark palette with
  semantic category colors, provenance-box header) +
  `scripts/app-architecture-html.py` (reuses the md→html converter embedded
  in `generate-architecture.sh` — single source of truth). Test suite:
  `scripts/tests/test-app-architecture-html.sh` (14 asserts, committed red
  before the implementation).

### Added — remote fleet support (codebase-memory-pg)
- `docs/codebase-memory-setup.md`: new "Remote fleet — Cloud Run deployment"
  section — client configuration for a cloud-deployed fleet facade,
  including the `X-Flota-Authorization` header contract (Cloud Run strips
  the `Authorization` token signature after its IAM check), audience and
  identity (`sub`) rules, project-naming requirement, and the remote seeding
  flow (`/admin/apply` → staging upload → audited `/publish`).

## [1.3.0] - 2026-07-22

AI-consumable architecture documentation standard, synthesized from the major
frameworks and consultancies (adversarially fact-checked).

### Added
- **`docs/architecture-documentation-standard.md`** — the standard the factory
  follows to produce maximum-detail, AI-consumable application architecture
  docs. Layers arc42 + C4 + ISO/IEC/IEEE 42010 with TOGAF (traceability matrices,
  ADD/ARS), Zachman (W5H coverage), Rozanski & Woods (Information/Operational
  viewpoints + quality perspectives), DDD/Context Mapper, 4+1 (Kruchten),
  Google Design Docs & SRE, AWS/Azure Well-Architected, and Gartner Pace-Layering
  — each cited.
- The knowledge-architecture templates now realize the standard: front-matter
  metadata (`standard`, `viewpoints`, `quality_attributes`, `zachman_coverage`),
  new **Information view** (data), **Integration & APIs view**, TOGAF
  **traceability matrices**, **Operational view** (SRE), an enriched **§9 ADR**
  format (Nygard + Google: goals/non-goals, alternatives, confidence,
  append-only), and an **Annex D traceability matrix** (requirement ↔ ADR ↔
  building block ↔ file:line ↔ assertion). The generator needs no change (the
  new curated sections are narrative-driven).

### Changed
- `CLAUDE.md`, README and the `<prefix>-architecture` skill point at the
  standard; `test-architecture.sh` covers the new sections (147 asserts total).

## [1.2.0] - 2026-07-22

Automatic code-graph indexing for the fleet/Postgres facade.

### Added
- `scripts/codebase-memory.sh` — real, configurable code (not just guidance)
  that handles the read-only fleet/Postgres facade: it **seeds** a repo through
  the fleet CLI and **wires** a gitignored workspace `.mcp.json` at the seeded
  project. Subcommands: `index <repo>`, `mcp-config [repo…]`, `mode`.
- `repo-add.sh` now calls it after registration (non-blocking): with the fleet
  configured in `.env`, onboarding indexes the repo automatically; otherwise it
  prints direct-engine guidance. Nothing hardcoded — all fleet specifics
  (`CBM_MODE`, `CBM_FLEET_SEED`, `CBM_FLEET_URL`, `CBM_FLEET_TOKEN`,
  `CBM_FLEET_PROJECT`) live in `.env` (see `.env.example`).
- `scripts/tests/test-codebase-memory.sh` (5th self-test suite; 141 asserts total).

### Changed
- `docs/codebase-memory-setup.md` documents the automatic path and the `.env`
  config; `.gitignore` now ignores `.mcp.json`; the `/repo-add` skill notes that
  the fleet seed + `.mcp.json` wiring happen automatically when configured.

## [1.1.2] - 2026-07-22

Cleanup release (docs only, no code changes).

### Removed
- The last example-system reference from the public tree; the operating guide
  now describes `repos.yaml` generically (created at instantiation via
  `init-system.sh`, populated with `/repo-add`), which also fixes a stale note.

## [1.1.1] - 2026-07-22

Documentation follow-up for the architecture-as-context capability (no code
changes).

### Changed
- **Operating guide (ES)** — documents the generated arc42+C4 architecture
  document as agent context, the docs-first policy and the
  `<prefix>-architecture` skill, the codebase-memory fleet/Postgres facade
  troubleshooting (`-32601`), and structure/shared-memory/governance updates.
- **README** — front-page highlight of the AS-IS architecture as agent context,
  plus updated comparison-table rows (brownfield grounding, derived docs).

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
