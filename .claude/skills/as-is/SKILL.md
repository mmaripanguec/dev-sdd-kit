---
name: as-is
description: Consulta el mapa as-is real del repositorio (módulos, dependencias, APIs, datos). Usar cuando pregunten cómo está estructurada la aplicación, qué depende de qué, qué APIs existen, o antes de diseñar (F5).
allowed-tools: Read Glob Grep
---

## Estado VIVO (calculado ahora, no persistido)
- Repos registrados: !`. scripts/repo-lib.sh 2>/dev/null && registry_repos | tr '\n' ' '`
- Working tree: !`git status --short 2>/dev/null | head -15`
- Último sello del mapa: !`head -2 knowledge/as-is/INDEX.md 2>/dev/null | tail -1`

## Instrucciones
1. Compara la fecha del sello con el último cambio de los repos
   (`git -C repos/<repo> log -1 --format=%cs`). Si el mapa quedó atrás,
   ADVIERTE que puede estar desactualizado y sugiere /as-is-sync antes de
   decisiones de arquitectura.
2. GRAFO DE CÓDIGO PRIMERO: para preguntas de estructura fina (qué funciones
   existen, quién llama a quién, cadenas de llamadas, impacto de un cambio)
   usa el MCP codebase-memory — search_graph, trace_path, get_architecture,
   get_code_snippet — sobre los repos indexados (`list_projects` para ver
   cuáles). Si un repo no está indexado, indícalo y sugiere /repo-add o
   index_repository.
3. El mapa markdown es el respaldo persistido y citable. Carga SOLO la vista
   relevante a la pregunta:
   - Visión del sistema / qué repo hace qué / quién llama a quién →
     knowledge/as-is/system.md
   - Estructura de UN repo → knowledge/as-is/<repo>/modules.md
   - Contratos/endpoints de UN repo → knowledge/as-is/<repo>/api-surface.md
4. Responde citando la fuente (archivo y sello, o consulta al grafo) —
   trazabilidad siempre.
5. Si la pregunta es sobre la INTENCIÓN (por qué es así, hacia dónde va),
   complementa con specs/ y knowledge/decisiones/ — el as-is dice QUÉ HAY,
   los ADRs dicen POR QUÉ y el to-be QUÉ DEBERÍA HABER. Señala brechas.
