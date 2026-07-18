---
name: as-is
description: Consulta el mapa as-is real del repositorio (módulos, dependencias, APIs, datos). Usar cuando pregunten cómo está estructurada la aplicación, qué depende de qué, qué APIs existen, o antes de diseñar (F5).
allowed-tools: Read Glob Grep
---

## Estado VIVO (calculado ahora, no persistido)
- Commit actual: !`git rev-parse --short HEAD 2>/dev/null && git log -1 --format=%s 2>/dev/null`
- Working tree: !`git status --short 2>/dev/null | head -15`
- Último sello del mapa: !`head -2 knowledge/as-is/INDEX.md 2>/dev/null | tail -1`

## Instrucciones
1. Compara el commit del sello con el commit actual. Si difieren, ADVIERTE
   que el mapa puede estar desactualizado y sugiere /as-is-sync antes de
   decisiones de arquitectura.
2. Carga bajo demanda SOLO la vista relevante a la pregunta:
   - Visión del sistema / qué repo hace qué / quién llama a quién →
     knowledge/as-is/system.md
   - Estructura de UN repo → knowledge/as-is/<repo>/modules.md
   - Contratos/endpoints de UN repo → knowledge/as-is/<repo>/api-surface.md
3. Responde citando el archivo y el commit del sello (trazabilidad).
4. Si la pregunta es sobre la INTENCIÓN (por qué es así, hacia dónde va),
   complementa con specs/ y knowledge/decisiones/ — el as-is dice QUÉ HAY,
   los ADRs dicen POR QUÉ y el to-be QUÉ DEBERÍA HABER. Señala brechas.
