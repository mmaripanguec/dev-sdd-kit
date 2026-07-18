---
name: repo-add
description: Da de alta un repositorio en la fábrica (URL git o ruta local): clona, registra en repos.yaml, completa su CLAUDE.md con datos reales, lo indexa en codebase-memory y regenera el mapa as-is. Usar cuando pidan "agregar/ingresar/onboarding de un repo" o "configurar el análisis de un repositorio".
argument-hint: "<url-o-ruta> [--role \"rol\"] [--entrypoint] [--domain banking] [--system-name s]"
allowed-tools: Read Glob Grep Edit Write Bash(./scripts/repo-add.sh *) Bash(./scripts/generate-as-is.sh *) Bash(git add *) Bash(git commit *) Bash(git status *) Bash(git diff *)
---

Objetivo: que el repo $ARGUMENTS quede LISTO PARA ESPECIFICAR (/spec-create)
en una sola pasada. El registro repos.yaml es la única fuente de verdad de
la topología: nunca escribas nombres de repos en scripts o skills.

## 1. Alta en el registro
- Ejecuta `./scripts/repo-add.sh $ARGUMENTS` (clona/actualiza, registra en
  repos.yaml, siembra CLAUDE.md). Si falla, diagnostica con el mensaje del
  script (credenciales → .env, ver .env.example) y detente: no improvises
  el registro a mano.
- Si el usuario no dio `--role`, dedúcelo del repo (README, package.json,
  estructura) y actualiza el campo con
  `./scripts/repo-add.sh <origen> --role "<rol deducido>"` (es idempotente).

## 2. Completar el CLAUDE.md del repo con datos REALES
Lee el repo recién clonado (README, package.json/Makefile/pom.xml/etc.) y
reemplaza cada `<completar>` de `repos/<nombre>/CLAUDE.md` que puedas
respaldar con evidencia: comandos de instalar/dev/test/lint reales, rol,
convenciones visibles. Lo que no tenga evidencia se deja marcado
`<completar>` — no inventes comandos. Recuerda: ese archivo se commitea EN
ESE repo, no en el workspace.

## 3. Indexar en codebase-memory (grafo de código)
- Invoca `index_repository` del MCP codebase-memory sobre `repos/<nombre>`
  y verifica con `index_status`/`list_projects`.
- Si el MCP no está disponible o falla: NO bloquees el alta; dilo
  explícitamente en el reporte final ("indexación pendiente: correr
  /repo-add de nuevo o index_repository cuando el MCP esté arriba").

## 4. Mapa as-is
- Ejecuta `./scripts/generate-as-is.sh` y revisa el resultado.
- Si hay ≥2 repos registrados y el grafo cross-repo salió vacío o
  incompleto, recomienda `/as-is-learn` (escribe extractores exactos por
  repo con evidencia del código).
- Commitea `repos.yaml` + `knowledge/as-is/` en el workspace:
  `chore(repos): alta de <nombre> + mapa as-is`.

## 5. Reporte final (contrato de salida)
Resume: nombre y rol registrado, stack detectado, estado de indexación MCP,
estado del mapa as-is (con o sin grafo), y cierra con los siguientes pasos:
"listo para `/spec-create <feature>`" (y `/as-is <pregunta>` para explorar).
