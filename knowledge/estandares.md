# Mapa de estándares de la fábrica
> Qué marco de referencia gobierna cada artefacto, para auditoría y onboarding.

| Área | Estándar / Fuente | Dónde está aplicado |
|---|---|---|
| Ciclo agéntico y harness | Anthropic — Effective harnesses for long-running agents; Claude Code (CLAUDE.md, skills, subagents) | CLAUDE.md, .claude/*, harness/ |
| Desarrollo seguro | NIST SP 800-218 (SSDF: grupos PO/PS/PW/RV) + SP 800-218A (GenAI) | .claude/rules/security.md, agentes calidad y publicacion |
| Riesgo de IA | NIST AI RMF (govern/map/measure/manage) | gates humanos + settings.json (enforcement) |
| Seguridad de aplicaciones | OWASP Top 10 / ASVS; Microsoft SDL (threat modeling STRIDE) | rules/security.md, agente arquitectura (F5), agente calidad (F7) |
| Arquitectura bancaria | BIAN Service Landscape (service domains, semantic APIs, ISO 20022) | rules/api-design.md, agente arquitectura, campo "service domain" de la spec |
| Diseño de APIs | Google AIP / REST | rules/api-design.md |
| Documentación de decisiones | ADR (Michael Nygard); C4 model (Simon Brown) | knowledge/decisiones/, agente arquitectura |
| Historias y criterios | INVEST (Bill Wake); Gherkin/BDD | agente requisitos (F1), spec-review (DoR) |
| Priorización | WSJF (SAFe) | agente estimacion (F2) |
| Calidad de producto | ISO/IEC 25010 | agente calidad (F7), rules/testing.md |
| Estilo y revisión de código | Google Style Guides + Google eng-practices | rules/code-style.md |
| Confiabilidad | Google SRE: señales doradas, SLOs, error budgets, postmortems sin culpables | rules/observability.md, agente operacion, plantilla postmortem |
| Desempeño de entrega | DORA four keys (DevOps Research & Assessment) | knowledge/uso.md, expediente CAB |
| Gestión del cambio | ITIL 4 change enablement (CAB) | agente publicacion (F8) |
| Cadena de suministro | NIST SSDF grupo PS: SBOM, dependencias, firmas | agente publicacion, rules/security.md |
| Operating model de fábrica | Developer Velocity (McKinsey), SPACE (Microsoft/GitHub), platform engineering (Gartner) | knowledge/uso.md + gobernanza del contexto compartido |
| Contexto persistente as-is | Docs-as-code + generación derivada (evitar drift); fitness functions (dependency-cruiser/ArchUnit); sello de commit | scripts/generate-as-is.sh, knowledge/as-is/, hook Stop, CI as-is-drift.yml, skills /as-is y /as-is-sync |
