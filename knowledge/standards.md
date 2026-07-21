# Factory standards map
> Which reference framework governs each artifact, for audit and onboarding.

| Area | Standard / Source | Where it is applied |
|---|---|---|
| Agentic cycle and harness | Anthropic — Effective harnesses for long-running agents; Claude Code (CLAUDE.md, skills, subagents) | CLAUDE.md, .claude/*, harness/ |
| Secure development | NIST SP 800-218 (SSDF: PO/PS/PW/RV groups) + SP 800-218A (GenAI) | .claude/rules/security.md, quality and release agents |
| AI risk | NIST AI RMF (govern/map/measure/manage) | human gates + settings.json (enforcement) |
| Application security | OWASP Top 10 / ASVS; Microsoft SDL (STRIDE threat modeling) | rules/security.md, architecture agent (F5), quality agent (F7) |
| Banking domain profile (OPTIONAL: repos with `domain: banking` in repos.yaml) | BIAN Service Landscape (service domains, semantic APIs, ISO 20022) | rules/domain-banking.md, requirements and architecture agents, the spec's "Business domain" field |
| API design | Google AIP / REST | rules/api-design.md |
| Decision documentation | ADR (Michael Nygard); C4 model (Simon Brown) | knowledge/decisiones/, architecture agent |
| Stories and criteria | INVEST (Bill Wake); Gherkin/BDD | requirements agent (F1), spec-review (DoR) |
| Prioritization | WSJF (SAFe) | estimation agent (F2) |
| Product quality | ISO/IEC 25010 | quality agent (F7), rules/testing.md |
| Code style and review | Google Style Guides + Google eng-practices | rules/code-style.md |
| Reliability | Google SRE: golden signals, SLOs, error budgets, blameless postmortems | rules/observability.md, operations agent, postmortem template |
| Delivery performance | DORA four keys (DevOps Research & Assessment) | knowledge/uso.md, CAB dossier |
| Change management | ITIL 4 change enablement (CAB) | release agent (F8) |
| Supply chain | NIST SSDF PS group: SBOM, dependencies, signatures | release agent, rules/security.md |
| Factory operating model | Developer Velocity (McKinsey), SPACE (Microsoft/GitHub), platform engineering (Gartner) | knowledge/uso.md + shared-context governance |
| Persistent as-is context | Docs-as-code + derived generation (avoid drift); fitness functions (dependency-cruiser/ArchUnit); commit seal | scripts/generate-as-is.sh, knowledge/as-is/, Stop hook, CI as-is-drift.yml, /as-is and /as-is-sync skills |
