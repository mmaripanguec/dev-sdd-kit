# Reglas de negocio
> Fuente de verdad del dominio. F4 (análisis) las extrae y consulta; los gates
> humanos las validan. Una regla nueva o cambiada entra por PR.

| ID | Regla | Service domain | Origen (spec/regulación) | Vigente desde |
|---|---|---|---|---|
| RN-01 | <ej.: una orden de pago sobre $X requiere segundo factor> | payment-order | specs/____.md | |
| RN-F1 | El peso del proceso es proporcional al riesgo: el triage F0 decide si aplica /clarificar y qué controles carga | proceso-fábrica | specs/2026-07-mejoras-spec-kit.md | 2026-07-19 |
| RN-F2 | Ninguna skill edita artefactos que no le pertenecen: /consistencia y /spec-review son read-only; /convergir solo añade al plan de su spec; la garantía se respalda en allowed-tools, no en instrucciones | proceso-fábrica | specs/2026-07-mejoras-spec-kit.md | 2026-07-19 |
| RN-F3 | Un marcador [NECESITA CLARIFICACIÓN] pendiente bloquea la DoR (máximo 3 vivos por spec) | proceso-fábrica | specs/2026-07-mejoras-spec-kit.md | 2026-07-19 |
| RN-F4 | Toda métrica publicada en knowledge/ declara fuente y período, o declara "sin datos"; prohibido el valor sin procedencia (DORA se deriva con scripts/dora.sh) | proceso-fábrica | specs/2026-07-metricas-dora.md | pendiente gate |
