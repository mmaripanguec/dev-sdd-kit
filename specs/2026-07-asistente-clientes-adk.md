# Spec: Asistente digital de clientes (agente ADK + Gemini)

| Campo | Valor |
|---|---|
| Estado | borrador — SPEC DE EJEMPLO del flujo "aplicación nueva" (demo de la fábrica) |
| Tipo de requerimiento | nueva aplicación (triage F0: no existe repo; T0 lo crea) |
| Contexto cargado | ninguno previo (aplicación nueva); Google ADK + API Gemini como stack propuesto |
| Dominio de negocio | atención de clientes (customer-service) |
| Autor / Fecha | Claude + Marcos Maripangue / 2026-07-19 |
| Gate PO/TL | pendiente |
| Gate DoR | pendiente |
| Gate Arquitectura | pendiente |

> Esta spec es el EJEMPLO que acompaña al demo del README: muestra cómo la
> fábrica especifica una aplicación nueva de punta a punta. Se implementa
> solo si un humano aprueba sus gates, como cualquier otra.

## 1. Problema
Los clientes hacen las mismas consultas por canales saturados (horarios,
requisitos, estados de trámite) y esperan minutos por respuestas que están
en las FAQ. El equipo de soporte gasta su tiempo en lo repetitivo y llega
tarde a lo delicado, que es donde el juicio humano importa.

## 2. Objetivo
Un asistente digital conversacional — agente construido con Google ADK y
modelo Gemini — responde al instante las consultas frecuentes desde una
base de conocimiento controlada, y deriva a un humano (con borrador de
respuesta listo para aprobar) todo lo sensible.

## 3. Criterios de éxito
- SC-01 ≥ 70% de las consultas de FAQ se resuelven sin intervención humana
  (medido sobre el log de sesiones del primer mes).
- SC-02 El 100% de los temas marcados sensibles se escalan a un humano;
  cero respuestas automáticas en esa categoría (auditable por log).
- SC-03 Tiempo de primera respuesta < 5 segundos p95.

## 4. Fuera de alcance
- Ejecutar transacciones (pagos, cambios de datos): el asistente informa y
  deriva; no opera cuentas.
- Canales de voz y WhatsApp (v2; esta versión es chat web/terminal).
- Entrenamiento/fine-tuning de modelos: se usa Gemini vía API con contexto.

## 5. Clarificaciones
### Sesión 2026-07-19
- P: ¿Fuente de conocimiento? → R: archivo FAQ versionado en el repo
  (`knowledge/faq.md`), curado por el equipo — no scraping ni fuentes vivas
  (decide: Marcos como PO del ejemplo).
- P: ¿Temas sensibles: responder o escalar? → R: escalar SIEMPRE a un
  humano con borrador de respuesta propuesto; el humano aprueba, edita o
  descarta (decide: Marcos — es además la pieza que el demo evidencia).

## 6. Historias de usuario (F1 · INVEST)
### H1 [P1] — Responder consultas frecuentes
Como cliente, quiero preguntar en lenguaje natural y recibir al instante la
respuesta oficial, para no esperar a un ejecutivo por algo que está en las FAQ.
**Criterios de aceptación (Gherkin):**
- CA1.1 Dado el FAQ curado, cuando pregunto algo cubierto por él, entonces
  el agente responde usando SOLO ese contenido como fuente (con Gemini para
  comprensión y redacción) y cita la entrada del FAQ usada.
- CA1.2 Dado algo NO cubierto por el FAQ, cuando pregunto, entonces el
  agente lo dice explícitamente y ofrece derivar — nunca inventa (política
  "sin fuente ⇒ sin respuesta", coherente con RN-F4).
- CA1.3 Dado cualquier respuesta, cuando se emite, entonces queda en el log
  de sesión (pregunta, respuesta, fuente, latencia).

### H2 [P1] — Escalamiento con aprobación humana
Como responsable de soporte, quiero que los temas sensibles (reclamos,
fraude, datos personales, cancelaciones) lleguen a un humano con un
borrador listo, para responder rápido sin ceder el juicio a la máquina.
**Criterios de aceptación (Gherkin):**
- CA2.1 Dado un tema clasificado sensible, cuando el cliente lo consulta,
  entonces el agente informa que un humano lo atenderá y encola el caso con
  un borrador de respuesta propuesto.
- CA2.2 Dado el caso encolado, cuando el humano aprueba/edita el borrador,
  entonces esa respuesta se envía y la decisión queda registrada (quién,
  cuándo, qué cambió).
- CA2.3 Dado un caso sensible, cuando NO hay aprobación humana, entonces
  NINGUNA respuesta automática se envía (verificado por test).

### H3 [P2] — Sesión con contexto
Como cliente, quiero que el asistente recuerde lo dicho en la conversación,
para no repetir mis datos en cada pregunta.
**Criterios de aceptación (Gherkin):**
- CA3.1 Dado un diálogo en curso, cuando hago una pregunta de seguimiento,
  entonces el agente resuelve las referencias ("y eso cuánto demora")
  usando el estado de sesión de ADK.

## 7. Estimación (F2)
| Historia | Puntos | Complejidad | Supuestos |
|---|---|---|---|
| H1 agente + FAQ + citas | 5 | media | ADK Agent + tool de búsqueda en FAQ |
| H2 escalamiento humano | 5 | media | cola simple (archivo/estado) + CLI de aprobación |
| H3 contexto de sesión | 2 | baja | session state nativo de ADK |
Prioridad WSJF: H1 → H2 → H3 (H1+H2 son el MVP: valor + control humano).

## 8. Análisis (F4)
**Reglas de negocio:** RN-A1 el agente solo afirma lo que está en el FAQ
curado (sin fuente ⇒ deriva); RN-A2 tema sensible ⇒ aprobación humana
obligatoria, sin excepciones ni override del agente; RN-A3 el log de
sesiones no almacena datos personales más allá de la conversación misma.
**Dependencias:** Google ADK (paquete `google-adk`, Python ≥3.10) · API
Gemini (API key de Google AI Studio vía `GOOGLE_API_KEY`; jamás en el
repo — regla de secretos vigente).
**Casos límite:** pregunta ambigua entre FAQ y sensible (gana sensible) ·
API Gemini caída o rate-limited (mensaje honesto + derivación, sin
reintentos infinitos) · FAQ vacío (todo deriva) · idioma distinto al del
FAQ (responde en el idioma del cliente con el contenido del FAQ) ·
prompt injection del cliente ("ignora tus reglas") — las reglas RN-A1/A2
se aplican en CÓDIGO (clasificador + cola), no solo en el prompt.
**Supuestos:** clasificación de sensibilidad por lista de temas + Gemini
como segundo chequeo (convalida: gate Arquitectura) · español como idioma
principal del FAQ.
**Regulatorio:** datos personales en conversaciones — retención mínima y
sin uso para entrenamiento (términos de la API respetados).

## 9. Diseño (F5)
**Stack:** Python + Google ADK (`Agent` con `model="gemini-2.5-flash"`,
instrucciones + tools) · tool `buscar_faq` (lookup en knowledge/faq.md) ·
tool `escalar_a_humano` (encola caso con borrador) · CLI/`adk web` como
interfaz de conversación · cola de aprobación con comando `aprobar` para
el humano.
**Contratos:** interno (tools del agente tipadas); sin API pública en v1.
**ADR-01 (propuesta):** el control de sensibilidad vive FUERA del prompt
(clasificador en código + cola con aprobación) porque las instrucciones de
un LLM no son un mecanismo de control — mismo principio permisos>prompts
de la fábrica.
**Threat model (STRIDE):** aplica (datos personales + LLM expuesto a
entrada hostil): spoofing de identidad del humano aprobador → auth local;
prompt injection → reglas en código (RN-A2); information disclosure → el
FAQ es la única fuente; DoS por abuso → rate limit por sesión.
**NFRs:** p95 < 5 s (SC-03); costo por consulta monitoreado; 100% de
cobertura en la ruta de escalamiento (es la ruta crítica).

## 10. Plan de tareas (F6)
- [ ] T0 [workspace] crear repo `asistente-clientes` + /repo-add +
      scaffolding ADK (venv, google-adk, estructura de agente) + as-is y
      pack iniciales
- [ ] T1 [asistente-clientes] tests EN ROJO de RN-A1/RN-A2 (FAQ como única
      fuente; sensible nunca se auto-responde) — la ruta crítica primero
- [ ] T2 [asistente-clientes] agente ADK con tool `buscar_faq` + citas
      (CA1.1–CA1.3) hasta verde
- [ ] T3 [asistente-clientes] clasificador de sensibilidad + cola +
      comando de aprobación humana (CA2.1–CA2.3) hasta verde
- [ ] T4 [asistente-clientes] [P] estado de sesión (CA3.1) + log
- [ ] T5 [workspace] [P] knowledge/faq.md inicial curado por el PO

## 11. Certificación (F7)
/convergir sin brechas pendientes + veredicto del agente de calidad
(incluye SC-01..03 del §3) + gate QA/PR: __

## 12. Trazabilidad
Origen: pedido de Marcos (2026-07-19) como ejemplo demostrativo del flujo
"aplicación nueva" de la fábrica; acompaña al demo del README
(docs/assets/demo.svg y docs/demo-assistant.md). Estado: borrador hasta que
sus gates se aprueben — el demo muestra el camino, no lo salta.
