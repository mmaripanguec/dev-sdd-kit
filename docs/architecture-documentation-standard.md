# Architecture documentation standard (AI-consumable)

> The standard the factory follows to produce **maximum-detail application
> architecture documentation** that feeds an AI knowledge base for
> spec-driven development. It defines *what* an architecture document must
> contain so that an agent answers **from the document**, consulting code only
> for undocumented gaps ("documentation-first"). The generated instance lives
> in `knowledge/architecture/<system>.md` (+`.html`) — see
> `scripts/generate-architecture.sh` and `templates/knowledge-architecture.*`.

## 1. The layered model

There is no single standard; professional, maximum-detail documentation is a
**stack of complementary standards**, each contributing what the others omit.
The factory adopts arc42 as the operative skeleton and layers the rest onto it.

| Layer | Standard | Contribution |
|---|---|---|
| Metamodel / ontology | **ISO/IEC/IEEE 42010** | Formal vocabulary (Stakeholders, Concerns, Viewpoints, Views, Models, Model Kinds), Correspondences for traceability, Decisions + Rationale |
| Operative template | **arc42** (12 sections) | The document skeleton |
| Diagrams as code | **C4 model** | Hierarchical Context/Container/Component views |
| View catalogue | **Rozanski & Woods** | 7 viewpoints (incl. Information, Deployment, Operational) + quality perspectives |
| Quality (NFRs) | **AWS / Azure Well-Architected** | Verifiable quality pillars |
| Traceability & inventory | **TOGAF ADM Phase C** | Catalogs + matrices (Application/Function, Role/Application), ADD, ARS |
| Classification ontology | **Zachman** | 6×6 W5H taxonomy to verify coverage |
| Domain as code | **DDD / Context Mapper (CML)** | Bounded contexts + context maps as versionable text |
| View validation | **4+1 (Kruchten)** | Scenarios as the cross-view validation thread |
| Decisions | **ADR (Nygard) + Google Design Docs** | Decision atom with Goals/Non-Goals, Alternatives Considered, trade-offs |
| Operational | **Google SRE** | Service overviews, request flows, production readiness |
| Governance | **Gartner Pace-Layering** | How much rigor per system (Record / Differentiation / Innovation) |

## 2. The four axes of a compliant document

1. **Structure** — arc42's 12 sections, extended with an **Information view**
   (data) and an **Operational view** (Rozanski & Woods), and a **Context Map**
   (DDD) in the context/building-block sections.
2. **Evidence & traceability** — every building block, contract and decision
   anchored with `file:line`; typed **Correspondences** (42010); **traceability
   matrices** (TOGAF: application ↔ function ↔ role); and **Scenarios**
   (Kruchten): each critical use case traced to the structures that support it.
3. **Quality (NFRs)** — Well-Architected pillars + Rozanski & Woods perspectives
   documented as **verifiable scenarios**, not prose.
4. **AI consumption** — machine-readable front-matter (42010 metadata +
   provenance seals), **Zachman W5H** coverage checklist, **C4/CML diagrams as
   code**, and **enriched ADRs** (Goals/Non-Goals, Alternatives Considered,
   Consequences, Confidence, Status; append-only, immutable).

## 3. Required sections (mapped to arc42)

| # | Section | Adds (beyond a bare C4 diagram) |
|---|---|---|
| 1 | Introduction & goals | **Goals / Non-Goals** (Google), quality goals |
| 2 | Constraints | technical, organizational, security |
| 3 | Context & scope (C4 L1) | system context + **bounded-context map** (DDD) |
| 4 | Solution strategy | key structural decisions + trade-offs |
| 5 | **Building block view** (C4 L2–L3) | components/modules with **contracts/APIs** and `file:line`; **Information view** (data); **Integration/APIs view**; **traceability matrices** (TOGAF) |
| 6 | Runtime view | critical flows; **request flows** (SRE) |
| 7 | Deployment view | infra, environments, **production setup** (SRE) |
| 8 | Crosscutting concepts | security, config, observability, i18n |
| 9 | **Architecture decisions** | ADRs (§5 below) |
| 10 | **Quality requirements** | scenario per Well-Architected pillar + perspectives |
| 11 | Risks & technical debt | with evidence; gaps (TOGAF gap analysis); pace-layer |
| 12 | Glossary | domain + architecture terms |
| A | Endpoint inventory | exposed routes, consumed APIs, channels |
| B | Dependencies | derived per repo |
| C | Validation & regeneration | how it is generated/verified |
| D | **Traceability matrix** | requirement ↔ ADR ↔ building block ↔ `file:line` ↔ assertion |

## 4. Viewpoints (Rozanski & Woods → arc42)

| Viewpoint | arc42 section | What to document |
|---|---|---|
| Context | §3 | actors, external systems, scope |
| **Functional** (cornerstone) | §5 | runtime functional elements, responsibilities, interfaces, interactions |
| **Information** | §5 (data) | entities, stores, flows, ownership, retention |
| Concurrency | §6 | processes, threads, synchronization |
| Development | §5 | module/code organization |
| **Deployment** | §7 | runtime environment, mapping to infrastructure |
| **Operational** | §7/§11 | how the system is operated, administered, supported (SRE) |

Quality **perspectives** (Security, Performance & Scalability, Availability &
Resilience, Evolution, Location, Development Resource, Internationalization)
apply *across* the views and are documented in §10.

## 5. Architecture Decision Records (ADR)

Per ISO/IEC/IEEE 42010 (Decisions + Rationale), arc42 §9 (Nygard) and Azure
Well-Architected, an ADR captures **one architecturally significant decision**
— "a justified design choice that addresses a functional or non-functional
requirement that is architecturally significant" (adr.github.io). Enriched
format (Nygard + Google Design Docs):

```
# ADR-NNN: <title>
Status: Proposed | Accepted | Deprecated | Superseded-by ADR-MMM
Confidence: low | medium | high
Traces: <requirement id> · <file:line>
## Context (problem, constraints, goals / non-goals)
## Options considered  (each with trade-offs)
## Decision  (the chosen option and why)
## Consequences  (positive, negative, follow-ups)
```

Rules: **append-only and immutable** — never edit an accepted record; a changed
decision is a **new ADR that supersedes** the original and links to it,
preserving the history of reasoning (Azure Well-Architected).

## 6. AI-consumption metadata (front-matter)

The document is generated with a machine-readable front-matter so agents can
route and trust it without re-reading code:

```yaml
name: architecture-<system>
standard: arc42 + C4 + ISO/IEC/IEEE 42010 (see docs/architecture-documentation-standard.md)
viewpoints: [context, functional, information, deployment, operational]
quality_attributes: [security, reliability, performance, cost, operability]
zachman_coverage: [what, how, where, who, when, why]
generado_desde: { <repo>: <commit-seal> }
verificado: <date>
```

**Zachman W5H checklist** — before publishing, verify the document answers all
six: *What* (data), *How* (function), *Where* (deployment/network), *Who*
(roles/stakeholders), *When* (runtime/events), *Why* (decisions/rationale).

## 7. Governance (what to document, how deeply)

Apply Gartner **Pace-Layering** to calibrate rigor per system: Systems of
Record (stable, high rigor), Systems of Differentiation, Systems of Innovation
(fast-moving, lighter). Record the layer in §11 / the registry.

## 8. How this maps to what the factory already generates

`scripts/generate-architecture.sh` already produces the arc42 + C4 skeleton.
This standard **extends** it (no rewrite): the template
(`templates/knowledge-architecture.md`) and the curated narrative
(`knowledge/architecture/<system>.narrative.md`) gain the Information,
Integration and Operational views, the traceability matrix, the enriched ADRs
and the front-matter metadata; the derived data (topology, dependencies,
metrics, seals) keeps being injected by the generator.

---

### Sources (verified, adversarial 3-vote)

ISO/IEC/IEEE 42010 (iso-architecture.org; iso.org/std/74393) · arc42
(arc42.org; docs.arc42.org/section-9) · C4 (faq.arc42.org/B-17) · Rozanski &
Woods (viewpoints-and-perspectives.info) · AWS Well-Architected
(aws.amazon.com) · Azure Well-Architected (learn.microsoft.com/azure/well-architected)
· TOGAF ADM Phase C (pubs.opengroup.org; via verbatim mirrors) · Zachman
(zachman.com) · Context Mapper / CML (contextmapper.org) · 4+1 (Kruchten, IEEE
Software 1995, arxiv 2006.04975) · Google Design Docs
(industrialempathy.com) · Google SRE (sre.google/sre-book) · ADR (adr.github.io)
· Gartner Pace-Layering (gartner.com glossary; ThoughtWorks Radar).

Coverage gaps (not verified): ArchiMate application layer and the published
thought leadership of BCG / Accenture / McKinsey (mostly behind registration).
