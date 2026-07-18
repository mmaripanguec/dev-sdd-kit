---
paths:
  - "src/api/**"
  - "**/openapi*.{yaml,yml,json}"
---
# Diseño de APIs
> Base: service domains (capacidades de negocio) · Google AIP (aip.dev) · REST

- Cada API pertenece a UN dominio de servicio: una capacidad de negocio con
  límites claros, sin solapamiento con otros dominios. Nombrarla por la capacidad
  (p.ej. `order-management`, `user-profile`), no por la tabla o el equipo.
- Contrato primero: OpenAPI versionado en el repo ANTES de implementar; el contrato
  es parte de la spec y cambia por ADR si rompe compatibilidad.
- Recursos y verbos según Google AIP: sustantivos en plural, verbos HTTP estándar,
  errores con formato único (código, mensaje accionable, correlation-id).
- Versionado explícito (`/v1/`); los cambios incompatibles crean versión nueva,
  nunca mutan la existente.
- Idempotencia obligatoria (idempotency-key) en operaciones no reintentables
  con efectos externos; el perfil del dominio puede ampliar la lista
  (ver rules/domain-banking.md para repos con `domain: banking`).
