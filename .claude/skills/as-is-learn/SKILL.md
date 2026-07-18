---
name: as-is-learn
description: Analiza los repos REALES para aprender como se definen y consumen las rutas, escribe extractores exactos por repo y regenera el mapa as-is. Usar cuando el grafo cross-repo salga vacio o incompleto, o cuando cambie el framework de un repo.
allowed-tools: Read Glob Grep Write Edit Bash(./scripts/generate-as-is.sh *) Bash(chmod *)
---

Objetivo: que el grafo de knowledge/as-is/system.md refleje la comunicacion
REAL entre repos, con evidencia del codigo — cero suposiciones.

## 0. Topologia declarada
Lee el registro (`. scripts/repo-lib.sh && registry_repos` y los campos
`role`/`entrypoint` de repos.yaml): que repos existen y que rol declara cada
uno. El analisis del paso 1 se hace POR CADA repo registrado y clonado.

## 1. Investigar con el codigo enfrente (citar archivo:linea en cada hallazgo)
Por cada repo del registro, segun su rol:
- Si EXPONE una API (backend, servicio): ¿donde se registran/definen sus
  endpoints? (framework, tabla struct, archivo de config, serverless.yml,
  handlers dinamicos, gRPC via .proto, worker sin API — y por que el
  extractor generico no lo vio).
- Si INTERMEDIA (proxy/BFF/gateway): ¿como define lo que expone y como llama
  a sus proveedores? (HTTP con URL base + literal, reverse-proxy por
  prefijo/config, gRPC, cola de mensajes — la config es mas fiel que
  cualquier grep del codigo).
- Si CONSUME (frontend, cliente): ¿como construye las URLs hacia sus
  proveedores? (constantes de entorno + literales, servicio HTTP central,
  endpoints en json).

## 2. Escribir el extractor exacto por repo que lo necesite
- Crear scripts/as-is.d/<repo>.sh (ejecutable) segun el contrato del README
  de esa carpeta. En comentarios: la evidencia (archivos:lineas) que justifica
  cada patron. Shell compatible bash 3.2: ${var} con llaves, solo ASCII.
- Si la comunicacion es gRPC: derivar "rutas" logicas de los servicios/metodos
  del .proto (formato /grpc/Servicio/Metodo) para que el grafo la represente.
- Si el proxy enruta por config: leer ESE archivo de config y emitir sus
  prefijos/paths — la config es mas fiel que cualquier grep del codigo.

## 3. Verificar contra la realidad, no contra el script
- Ejecutar ./scripts/generate-as-is.sh y revisar system.md.
- Contrastar cada flecha (y cada ausencia) con lo visto en el paso 1.
  Una flecha sin evidencia se investiga; una ausencia esperada (ej. worker
  sin API) se documenta en el api-surface.md del repo via el extractor.
- Ejecutar ./scripts/generate-as-is.sh --check (debe quedar en verde).

## 4. Cerrar
- Resumen: mecanismo de rutas por repo (con citas), flechas resultantes,
  limitaciones conocidas.
- Recordar commitear: knowledge/as-is/ + scripts/as-is.d/ al workspace.
NO modificar codigo de los repos. NO inventar rutas sin evidencia.
