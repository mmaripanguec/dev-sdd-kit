---
name: {{PREFIX}}-architecture
description: >-
  AS-IS architecture of system {{SYSTEM}} (arc42 + C4), the authoritative,
  code-derived CONTEXT. Load it for any question about {{SYSTEM}} or its repos
  ({{REPO_TRIGGERS}}): architecture, components, endpoints, consumed APIs,
  dependencies, integration seams, runtime flows, deployment, risks.
  Answer WITHOUT re-indexing or re-reading the code: the document already
  consolidates it.
version: 1.0.0
generado_desde:
{{SEALS_FRONTMATTER}}
verificado: {{FECHA}}
---

# {{PREFIX}}-architecture — architecture context for {{SYSTEM}}

It follows the factory's architecture documentation standard
(`docs/architecture-documentation-standard.md`).

**The authoritative document is `knowledge/architecture/{{SYSTEM}}.md`**
(human twin: `knowledge/architecture/{{SYSTEM}}.html`). It follows the
**arc42 + C4** standard, is derived from the code and validated by assertions.
Read it to answer about the `{{SYSTEM}}` system and any of its repositories.

## Usage policy — documentation first, code second
1. **Answer from the document** (`knowledge/architecture/{{SYSTEM}}.md`) and the
   context packs `{{PREFIX}}-system` / `{{PREFIX}}-<repo>`. They cover the mental
   model, integration seams, components, endpoints, consumed APIs, dependencies,
   deployment and risks.
2. **Do NOT re-index or re-read the code** for what is already documented. The
   goal is to keep the context and not repeat the analysis.
3. **Consult the code or the graph (codebase-memory) ONLY** when:
   - the question is **not documented** here or in the packs, and
   - the human **does not have the answer** or asks for more detail/precision.
4. If, while consulting the code, you discover something new or correct the
   document: update the narrative
   (`knowledge/architecture/{{SYSTEM}}.narrative.md`), regenerate with
   `./scripts/generate-architecture.sh`, and add an assertion in
   `scripts/assertions.d/{{SYSTEM}}.sh`.

## How it is maintained (do NOT hand-edit the .md/.html)
- The `.md` and `.html` are **generated** by `./scripts/generate-architecture.sh`,
  which also runs at the end of `./scripts/generate-as-is.sh` (i.e. after every
  indexing with `/repo-add`).
- The **curated** part (analysis) lives in
  `knowledge/architecture/{{SYSTEM}}.narrative.md`; the **derived** part
  (topology, dependencies, counts, seals) is injected by the generator.
- Verification: `scripts/assertions.sh {{SYSTEM}}` · `scripts/freshness.sh check`.

## Reading path
`{{PREFIX}}-architecture` (this context) → `knowledge/architecture/{{SYSTEM}}.md`
→ if detail is missing: pack `{{PREFIX}}-system` → `{{PREFIX}}-<repo>` →
codebase-memory graph / `knowledge/as-is/` → code (last resort).
