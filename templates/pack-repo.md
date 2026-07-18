---
name: {{PACK}}
description: >-
  <qué es este repo en una frase y cuándo usar este pack: temas, módulos y
  preguntas que responde — esta descripción es el GATILLO que hace que un
  agente lo cargue cuando un requerimiento menciona el aplicativo>.
  Lee ANTES el pack {{PREFIJO}}-sistema: el modelo mental y las uniones viven allí.
version: 1.0.0
generado_desde:
  {{REPO}}: {{SELLO}}
verificado: {{FECHA}}
---

> **Lee `{{PREFIJO}}-sistema` primero.** <Si otro pack corrigió algo que este
> repo declara mal, la corrección va aquí arriba.>

# {{REPO}} — <nombre real / qué es>

<Qué es, qué NO es, stack y versión — con evidencia `archivo:línea`.>

## Arranque y estructura
<Entrypoint del proceso, wiring/registro de rutas, módulos reales — con
`archivo:línea`. No el árbol de carpetas (eso está en el as-is): el CÓMO.>

## ⭐ <El mecanismo central del repo>
<El hallazgo que más cuesta descubrir leyendo, con su cadena de evidencia
completa paso a paso (`archivo:línea` en cada eslabón).>

## <Secciones por tema>
<Endpoints, datos, integraciones, config por ambiente... solo lo que un
agente necesita para trabajar SIN releer todo el repo.>

## Trampas — no caigas en estas
| Afirmación falsa | Realidad |
|---|---|
| <error que cometería quien no leyó el código, o que este pack cometió antes> | <realidad, con evidencia> |

## Qué NO sé
- <límites explícitos: qué no se exploró, qué es inferencia y no hecho>

**Este pack no demuestra su completitud.** Si conoces el repo y algo te
chirría, probablemente el pack esté mal, no tú: corrígelo y convierte la
corrección en aserción (`scripts/afirmaciones.d/{{SISTEMA}}.sh`).
