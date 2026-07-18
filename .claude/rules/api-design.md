---
paths:
  - "src/api/**"
  - "**/openapi*.{yaml,yml,json}"
---
# Diseño de APIs
> Base: BIAN (semantic APIs / service domains) · Google AIP (aip.dev) · REST

- Cada API pertenece a UN service domain (BIAN): una capacidad de negocio con
  límites claros, sin solapamiento con otros dominios. Nombrarla por la capacidad
  (p.ej. `payment-order`, `customer-offer`), no por la tabla o el equipo.
- Contrato primero: OpenAPI versionado en el repo ANTES de implementar; el contrato
  es parte de la spec y cambia por ADR si rompe compatibilidad.
- Recursos y verbos según Google AIP: sustantivos en plural, verbos HTTP estándar,
  errores con formato único (código, mensaje accionable, correlation-id).
- Versionado explícito (`/v1/`); los cambios incompatibles crean versión nueva,
  nunca mutan la existente.
- Alinear vocabulario de payloads a ISO 20022 cuando el dominio sea de pagos.
- Idempotencia obligatoria en operaciones de dinero (idempotency-key).
