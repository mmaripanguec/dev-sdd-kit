# Spec: Derivación automática de métricas DORA en knowledge/uso.md

| Campo | Valor |
|---|---|
| Estado | borrador |
| Tipo de requerimiento | existente `[workspace]` (triage F0: solo scripts y knowledge; no toca repos de código) |
| Contexto cargado | knowledge/uso.md, agente operacion, plantilla postmortem, scripts/repo-lib.sh (sesión 2026-07-19) |
| Dominio de negocio | proceso de la fábrica (medición DORA) |
| Autor / Fecha | Claude + Marcos Maripangue / 2026-07-19 |
| Gate PO/TL | aprobado por Marcos Maripangue el 2026-07-19 ("avanzar con los pendientes") |
| Gate DoR | pendiente |
| Gate Arquitectura | N/A — sin arquitectura de código de sistema; scripts del workspace |

## 1. Problema
`knowledge/uso.md` tiene las tablas DORA vacías desde su creación. Sin datos,
F2 prioriza WSJF sin historial de estimado-vs-real y F8 evalúa el riesgo CAB
sin change failure rate — dos gates decidiendo a ciegas. El hueco quedó
registrado en el análisis comparativo del 2026-07-19 (DORA 2025: "medir con
métricas de sistema, no con sensación de velocidad").

## 2. Objetivo
Las cuatro métricas DORA de `uso.md` se derivan automáticamente de fuentes
verificables (historial git de los repos registrados y postmortems), con
sello de procedencia y sin editar a mano — igual que el mapa as-is.

## 3. Criterios de éxito
- SC-01 `scripts/dora.sh` calcula las 4 métricas cuando hay repos clonados y
  declara "sin datos" (con la causa) cuando no los hay — nunca inventa.
- SC-02 La tabla DORA de uso.md siempre exhibe sello `[GENERADO]` con fecha y
  commits de origen; las secciones manuales de uso.md quedan intactas.
- SC-03 El cierre de un incidente (F9) actualiza CFR y MTTR con un solo
  comando, sin edición manual de tablas.

## 4. Fuera de alcance
- Telemetría de producción real (Prometheus, APM): la fábrica no tiene ni
  debe tener credenciales de producción; se deriva solo de git y knowledge/.
- Dashboards; uso.md sigue siendo la vista.
- Poblar "Estimado vs. real" y "Uso real de features": siguen siendo
  registro manual de F9/F2 (requieren juicio, no derivación).
- Clonar los repos del sistema (requiere credenciales; ver Supuestos).

## 5. Clarificaciones
### Sesión 2026-07-19
- P: ¿Fuente de "despliegue"? → R: merges a la rama por defecto de cada repo
  registrado (proxy estándar sin acceso a CD; tags `v*` si existen se
  prefieren) (decide: Claude por principio "derivar, no redactar";
  convalida: Marcos en gate DoR).
- P: ¿Automatización o registro manual? → R: script derivador con sello,
  patrón generate-as-is.sh (decide: Claude, mismo principio; convalida:
  Marcos en gate DoR).
- P: ¿Se clonan los repos ahora para tener datos reales? → R: fuera de
  alcance — setup.sh exige credenciales (.env) vetadas a los agentes; el
  mecanismo queda listo y degrada con "sin datos" hasta que un humano corra
  setup.sh (decide: Claude por security.md; convalida: Marcos).

## 6. Historias de usuario (F1 · INVEST)
### H1 [P1] — Derivar las 4 métricas DORA
Como TL en F2/F8, quiero que frecuencia de despliegue, lead time, CFR y MTTR
se calculen desde git y postmortems, para priorizar y evaluar riesgo con
datos y no con percepción.
**Criterios de aceptación (Gherkin):**
- CA1.1 Dado un repo registrado y clonado con merges en su rama por defecto,
  cuando corro `scripts/dora.sh`, entonces la frecuencia (merges/semana del
  período) y el lead time mediano (primer commit de la rama → merge) se
  calculan por repo y agregado.
- CA1.2 Dado postmortems INC-* con campo `MTTR:` poblado, cuando corro el
  script, entonces MTTR es la mediana de los incidentes del período y CFR es
  incidentes con despliegue asociado / total de despliegues.
- CA1.3 Dado que repos/ está vacío o un postmortem no declara MTTR, cuando
  corro el script, entonces la celda muestra "sin datos" y el motivo — jamás
  un valor inventado.
- CA1.4 Dado uso.md con secciones manuales pobladas, cuando el script
  reescribe la tabla DORA entre sus marcadores, entonces el resto del
  archivo queda byte a byte intacto.

### H2 [P2] — Cierre de incidente actualiza métricas
Como agente de operación (F9), quiero que al commitear un postmortem el
recálculo sea un solo comando, para que uso.md nunca quede desactualizado
tras un incidente.
**Criterios de aceptación (Gherkin):**
- CA2.1 Dado un postmortem nuevo en knowledge/incidentes/, cuando corro
  `scripts/dora.sh`, entonces CFR y MTTR reflejan el incidente y el sello
  cambia de fecha.
- CA2.2 Dado el agente operacion, cuando cierra un incidente, entonces su
  instrucción indica correr el script (no editar tablas a mano).

## 7. Estimación (F2)
| Historia | Puntos | Complejidad | Supuestos |
|---|---|---|---|
| H1 script + tests | 5 | media | git log basta como fuente; bash 3.2 |
| H2 integración F9 | 1 | baja | solo instrucciones del agente + README |
Prioridad WSJF: H1 → H2 (H1 es el valor; H2 evita el drift futuro).

## 8. Análisis (F4)
**Reglas de negocio:** RN-F4 (propuesta): toda métrica publicada en
knowledge/ declara su fuente y período o declara "sin datos"; prohibido el
valor sin procedencia. Consistente con RN-F2 (el script solo escribe entre
sus marcadores en uso.md).
**Dependencias:** git ≥ 2.x y bash 3.2 (ya requeridos); repos/ poblado por
setup.sh (humano con credenciales) para datos reales; ninguna nueva.
**Casos límite:** repos/ vacío (CA1.3) · repo sin merges en el período
(frecuencia 0, no "sin datos") · postmortem sin MTTR o con formato libre
(se excluye y se lista como advertencia) · rama por defecto no llamada
main/master (se detecta con `git symbolic-ref`) · período sin incidentes
(CFR 0% con despliegues > 0; "sin datos" si tampoco hay despliegues) ·
re-ejecución sin cambios (idempotente: mismo contenido, mismo sello de
commits — solo cambia la fecha de generación si se fuerza).
**Supuestos:** merge a rama por defecto ≈ despliegue (convalida: Marcos;
si el CAB de F8 registra despliegues reales, esa fuente lo reemplazará) ·
período de análisis: últimos 90 días (trimestre DORA).
**Regulatorio:** N/A (metadatos de git; sin datos personales — se agregan
conteos, no autores).

## 9. Diseño (F5)
**Contratos:** N/A. **ADRs:** decisión en esta spec: derivación tipo as-is
con marcadores en archivo mixto (generado + manual), en lugar de archivo
100% generado, porque uso.md tiene secciones de juicio humano.
**Mecanismo:** `scripts/dora.sh` (bash 3.2, sin dependencias): lee
`registry_repos` de repo-lib.sh → por repo clonado: merges y lead time con
`git log --merges --first-parent` (90 días) → postmortems: grep de
`MTTR:` y fecha → reescribe uso.md SOLO entre `<!-- DORA:BEGIN -->` y
`<!-- DORA:END -->` con sello `[GENERADO vN] <fecha> desde <repo>@<commit>…`.
Modo `--check`: exit 1 si la tabla difiere de lo recalculado (patrón
generate-as-is.sh para CI).
**Threat model (STRIDE):** no aplica — lectura de git local y escritura
acotada a un bloque de un archivo de knowledge; sin credenciales.
**NFRs:** una pasada; < 5 s con repos clonados; salida determinista.

## 10. Plan de tareas (F6)
- [ ] T1 [workspace] tests primero (TDD): `scripts/tests/test-dora.sh` con
      fixtures (repos git sintéticos con merges fechados + postmortems
      sintéticos) cubriendo CA1.1–CA1.4 y CA2.1 — deben FALLAR
- [ ] T2 [workspace] `scripts/dora.sh` hasta poner verde test-dora.sh sin
      tocar los tests + marcadores DORA en knowledge/uso.md
- [ ] T3 [workspace] integración F9: instrucción en el agente operacion +
      fila en la tabla de scripts del README + regla RN-F4 propuesta en
      knowledge/reglas-negocio.md (entra vigente al aprobarse esta spec)

## 11. Certificación (F7)
/convergir sin brechas pendientes + veredicto del agente de calidad
(incluye SC-01..03 del §3) + gate QA/PR: __

## 12. Trazabilidad
Origen: pendiente registrado al cierre de specs/2026-07-mejoras-spec-kit.md
(hueco #7 del análisis comparativo del 2026-07-19). Rama:
`feature/metricas-dora`. Fuentes: dora.dev/dora-report-2025 ·
knowledge/estandares.md (DORA) · patrón scripts/generate-as-is.sh.
