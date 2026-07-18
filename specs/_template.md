# Spec: <título>

| Campo | Valor |
|---|---|
| Estado | borrador → aprobada → implementada |
| Dominio de negocio | <capacidad de negocio; con el landscape del perfil del dominio si existe (p.ej. BIAN en banking)> |
| Autor / Fecha | |
| Gate PO/TL | aprobado por __ el __ (commit __) |
| Gate DoR | aprobado por __ el __ (commit __) |
| Gate Arquitectura | aprobado por __ el __ (commit __) |

## 1. Problema
Qué duele hoy, para quién y con qué evidencia (datos de knowledge/uso.md si existen).

## 2. Objetivo
Resultado observable al terminar. Una o dos frases en lenguaje de negocio.

## 3. Fuera de alcance
Lo que explícitamente NO se hará en esta iteración. No dejar vacío.

## 4. Historias de usuario (F1 · INVEST)
### H1 — <título>
Como <rol>, quiero <acción>, para <valor>.
**Criterios de aceptación (Gherkin):**
- CA1.1 Dado <contexto>, cuando <acción>, entonces <resultado medible>.

## 5. Estimación (F2)
| Historia | Puntos | Complejidad | Supuestos |
|---|---|---|---|
Prioridad WSJF: <orden y justificación>

## 6. Análisis (F4)
**Reglas de negocio:** RN-01 … (sincronizadas con knowledge/reglas-negocio.md)
**Dependencias:** <dominios, sistemas, equipos; bloqueantes marcados>
**Casos límite:** nulos/extremos · concurrencia · fallos de terceros ·
zonas horarias/monedas · permisos · volumen (cada uno con su CA en Gherkin)
**Regulatorio:** <requisitos de datos personales/transaccionales aplicables>

## 7. Diseño (F5)
**Contratos:** enlace a OpenAPI/esquemas de eventos versionados.
**Diagramas C4 (mermaid):** contenedores y componentes.
**ADRs:** enlaces a knowledge/decisiones/ADR-____.md
**Threat model (STRIDE):** aplica sí/no; mitigaciones en el ADR.
**NFRs / SLOs:** disponibilidad __%, latencia p99 __ms, volumen __.

## 8. Plan de tareas (F6)
Formato multi-repo: cada tarea se etiqueta con el nombre de su repositorio
destino tal como aparece en repos.yaml (las etiquetas válidas son SOLO los
repos registrados; `[workspace]` para cambios en este repo de contexto).
- [ ] T1 [<repo-registrado>] … (una tarea = un commit EN ESE repo; TDD; /implement-task)
- [ ] T2 [<repo-registrado>] …
Orden de despliegue: según `deploy_order` del registro (proveedor antes que
consumidor; compatibilidad hacia atrás).

## 9. Certificación (F7)
Veredicto del agente de calidad + gate QA/PR: __

## 10. Trazabilidad
Spec → ADRs → commits → expediente CAB → postmortems relacionados.
