# dev-sdd-kit · Multi-Repo Digital Factory

A **spec-driven development (SDD) workspace template** for building and
maintaining any system made of one or more code repositories, operated with
[Claude Code](https://claude.com/claude-code). Register a repo (git URL or
local path) and the factory clones, indexes and maps it on its own — leaving
it ready to take requirements as specs with human gates, strict TDD and full
traceability.

**Code lives in each repo; the system's knowledge lives here.**

## Why

AI agents write code fast; what breaks teams is everything around it:
requirements lost in chat, architecture decisions nobody recorded,
documentation that lies, and agents that ship to production unchecked. This
factory encodes the discipline that industry research (DORA, McKinsey,
Anthropic, Thoughtworks) identifies in high performers:

- **The spec is the contract** — every non-trivial change starts as a spec
  and is certified against it (spec-anchored, not vibe coding).
- **Human gates backed by permissions**, not instructions: agents hold no
  production credentials and cannot approve their own work.
- **Derived, never hand-written**: the as-is map, DORA metrics and the
  architecture document are generated from the real sources with provenance
  seals — they cannot go stale or lie ("no data" beats made-up data).
- **Strict TDD**: failing tests are committed first; agents are forbidden
  from editing tests to make them pass.
- **Process proportional to risk**: a triage step decides how much ceremony
  each change deserves.

## Architecture at a glance

A requirement flows through 10 phases (F0 triage → F9 operations) with six
human gates. Phases F0–F5 write the spec; construction and certification
run *against* it; operations feeds knowledge back into the next feature.

- 📐 **[Architecture & usage document (English)](docs/architecture.en.html)**
- 📐 **[Documento de arquitectura y guía (español)](docs/arquitectura.html)**

Both are generated from the live workspace by `./scripts/docs.sh` — they are
always up to date with the actual skills, agents, rules and topology.

## Quickstart

Prerequisites: git, bash 3.2+, python3, [Claude Code](https://claude.com/claude-code) CLI.

```bash
# 1. Instantiate the template for your system
git clone <this-repo-url> my-system && cd my-system
./scripts/init-sistema.sh

# 2. Register your repositories (clones, indexes, seeds context, maps as-is)
claude   # always launch from the workspace root
/repo-add https://github.com/your-org/your-repo.git

# 3. Specify your first feature (triage → user stories → design, with gates)
/spec-create my-feature short description of what you need
```

Joining an existing system on a new machine instead:

```bash
cp .env.example .env      # credentials per git provider
./scripts/setup.sh        # clones/updates every repo in the registry
```

## Documentation

| Document | Language | Purpose |
|---|---|---|
| [docs/architecture.en.html](docs/architecture.en.html) | English | Architecture, technical spec, model & usage guide (generated) |
| [docs/arquitectura.html](docs/arquitectura.html) | Español | Same document in the factory's working language (generated) |
| [docs/guia-operativa.md](docs/guia-operativa.md) | Español | Complete operating guide: installation, auth per provider, E2E cycle, governance |
| [docs/instructivo-repo-existente.md](docs/instructivo-repo-existente.md) | Español | Step-by-step: onboarding an existing repo up to the first spec |
| [CONTRIBUTING.md](CONTRIBUTING.md) | English | How to contribute following the factory's own process |

> **A note on language**: public-facing documentation is in English; the
> factory's *working* artifacts (skills, rules, specs, knowledge base) are
> in Spanish by design — it is a working template, and its teams operate in
> Spanish. Everything is structured markdown; translating for your team is
> straightforward.

## What's inside

```
repos.yaml            # System topology — the single source of truth
.claude/              # 13 skills (slash commands), 7 phase agents, 6 rule sets
specs/                # Feature specs: the contracts (12-section template)
knowledge/            # ADRs, blameless postmortems, business rules, DORA metrics
scripts/              # Automation: repo onboarding, as-is map, DORA, docs (+ tests)
docs/                 # Generated architecture docs + operating guides
harness/              # Multi-session agent harness (Anthropic initializer pattern)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). In short: every change follows the
factory's own process — spec first, human gates, failing tests before code,
one commit per task, and the three test suites green
(`scripts/tests/*.sh`).

## License

[MIT](LICENSE) © 2026 Marcos Maripangue
