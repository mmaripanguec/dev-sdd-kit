<!-- Curated architecture narrative for a system.
     Copy to knowledge/architecture/<system>.narrative.md and author the
     ANALYSIS below (mental model, seams, decisions, risks, endpoints...).
     scripts/generate-architecture.sh reads this file to fill the
     <!-- NARRATIVE: KEY --> markers in templates/knowledge-architecture.md.
     The derived data (topology, dependencies, metrics) is injected by the
     generator — do NOT hand-write it here. Keep the @@ delimiters and write
     in the system's working language. Every claim carries file:line evidence. -->

<!-- @@ INTRO -->
<!-- What the system is, its users, and its main quality goals. Include the
     ★ mental model: the single claim that changes how everything else reads. -->

<!-- @@ CONSTRAINTS -->
<!-- Technical, organizational and security constraints, with evidence. -->

<!-- @@ CONTEXT -->
<!-- C4 Level 1 context: users and external systems. Include a ```mermaid
     C4Context ... ``` diagram. State the scope and what is out of scope. -->

<!-- @@ STRATEGY -->
<!-- Key structural decisions and how each one is resolved (table). -->

<!-- @@ BUILDING_BLOCKS -->
<!-- C4 Level 2 (```mermaid C4Container```) and Level 3 (```mermaid C4Component```)
     diagrams, plus any routing/seam maps and per-container component notes. -->

<!-- @@ INFORMATION -->
<!-- Information viewpoint (Rozanski & Woods): key entities/data objects, stores,
     data flows, ownership and retention. A ```mermaid erDiagram``` if useful. -->

<!-- @@ INTEGRATION -->
<!-- Integration & APIs: exposed and consumed contracts (OpenAPI/gRPC/events),
     providers/consumers, versioning. Point to the endpoint inventory (Annex A). -->

<!-- @@ MATRICES -->
<!-- Traceability matrices (TOGAF Phase C): Application/Function and
     Role/Application as tables — which component serves which capability/role. -->

<!-- @@ RUNTIME -->
<!-- Reference runtime flows (e.g. a ```mermaid sequenceDiagram``` for login). -->

<!-- @@ DEPLOYMENT -->
<!-- Deployment topology, environments, ports, CI/CD, deploy order. -->

<!-- @@ OPERATIONAL -->
<!-- Operational viewpoint / SRE: service overview, critical request flows,
     production setup, runbooks, monitoring/on-call. -->

<!-- @@ TRACEABILITY -->
<!-- Traceability matrix: requirement ↔ ADR ↔ building block ↔ file:line ↔
     assertion. One row per architecturally significant requirement. -->

<!-- @@ CROSSCUTTING -->
<!-- Cross-component seams verified at BOTH ends, security, config, observability. -->

<!-- @@ DECISIONS -->
<!-- Architecture decisions (ADR-style table); flag registry discrepancies. -->

<!-- @@ QUALITY -->
<!-- Quality scenarios and their validated status. -->

<!-- @@ RISKS -->
<!-- Risks and technical debt, ranked by severity, with file:line evidence. -->

<!-- @@ GLOSSARY -->
<!-- Domain and architecture terms used in this document. -->

<!-- @@ ENDPOINTS -->
<!-- Complete endpoint inventory: exposed routes per repo, consumed APIs/upstreams,
     async/gRPC channels, client-consumed paths. -->

<!-- @@ DEPS_NOTE -->
<!-- Notes on dependencies not captured by the derived tables (e.g. native
     plugins, vendored libs). Point to the manifests for exhaustive lists. -->

<!-- @@ VALIDATION -->
<!-- How the document was validated (indexed graph, assertions) and what it does
     NOT cover (explicit limits). -->
