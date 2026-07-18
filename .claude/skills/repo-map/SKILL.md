---
name: repo-map
description: Genera el mapa profundo de un repositorio — arquitectura, dependencias y para qué se usan, tecnologías, integraciones, datos y flujos principales — en knowledge/mapas/<repo>.md con evidencia archivo:línea. Usar cuando pidan "mapear un repo", "entender la arquitectura/dependencias de un repo", "generar el contexto del repo", o después de /repo-add.
argument-hint: "<nombre-repo-del-registro> [pregunta o foco opcional]"
allowed-tools: Read Glob Grep Write Bash(./scripts/generate-as-is.sh *) Bash(git -C *) Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *)
---

Genera (o actualiza) `knowledge/mapas/<repo>.md` para el repo $ARGUMENTS.

Distinción de capas — respétala siempre:
- `knowledge/as-is/` = HECHOS deterministas (los escribe solo el script).
- `knowledge/mapas/` = INTERPRETACIÓN de la arquitectura, escrita por esta
  skill CON EVIDENCIA, sellada con el commit analizado y commiteada al
  workspace. Sin evidencia citada, una afirmación no entra al mapa.

## 1. Insumos (en este orden, del más barato al más caro)
1. Registro: rol, dominio, entrypoint del repo en repos.yaml.
2. Hechos del as-is: `knowledge/as-is/<repo>/modules.md` (estructura,
   dependencias, servicios externos, datos, infra, comandos) y
   `api-surface.md` (rutas). Si el sello no coincide con el HEAD del repo
   (`git -C repos/<repo> rev-parse --short HEAD`), corre
   `./scripts/generate-as-is.sh` primero.
3. Grafo de código del MCP codebase-memory si el repo está indexado
   (`get_architecture`, `search_graph`, `trace_path` para los flujos).
   Si el MCP no responde, sigue sin él y decláralo en "Limitaciones".
4. Lectura dirigida del código: entrypoint del proceso, wiring/DI, routers,
   capa de datos, clientes de servicios externos. Lee lo necesario para
   respaldar cada afirmación, no el repo entero.

## 2. Contenido del mapa (plantilla)
```markdown
# <repo> — mapa de arquitectura
> Interpretado desde <repo>@<commit> el <fecha> por /repo-map.
> Hechos base: knowledge/as-is/<repo>/ (misma versión). Regenerable.

## Propósito y rol en el sistema
## Arquitectura interna
(capas/módulos reales y cómo se conectan + diagrama mermaid; cada flecha
con su evidencia archivo:línea)
## Dependencias clave y para qué se usan
(las que definen la arquitectura — framework, DB driver, colas, HTTP —
con el punto exacto donde se usan; no repetir la lista completa del as-is)
## Integraciones y servicios externos
(qué servicio, desde qué módulo, para qué; incluir otros repos del sistema)
## Datos
(esquema/migraciones: entidades principales y dónde se definen)
## Flujos principales
(2–4 flujos end-to-end: request → capas → persistencia/salida, con la
cadena de archivos; usa trace_path si hay grafo)
## Riesgos y deuda observada
(acoplamientos, código sin dueño aparente, dependencias desactualizadas,
rutas sin contrato OpenAPI)
## Limitaciones de este mapa
(qué no se pudo verificar: MCP caído, código generado, áreas no leídas)
```

## 3. Verificación y cierre
- Toda flecha del diagrama y todo flujo tienen cita archivo:línea. Lo no
  verificado va a "Limitaciones", no al cuerpo.
- Si detectas contradicción con un ADR vigente o con el rol declarado en
  repos.yaml, repórtala como drift y ESCALA al gate de Arquitectura
  (igual que /as-is-sync); el mapa igual dice la verdad.
- Commit en el workspace: `docs(mapas): mapa de <repo> @<commit>`.
- Cierra con un resumen de 5 líneas + brechas detectadas; si el usuario dio
  un foco en $ARGUMENTS, respóndelo explícitamente al final.
