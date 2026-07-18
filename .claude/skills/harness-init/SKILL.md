---
name: harness-init
description: Prepara el harness de una feature grande o multi-sesión, derivado de su spec aprobada (patrón initializer de Anthropic).
argument-hint: "<ruta-de-la-spec>"
allowed-tools: Read Glob Grep Write Bash(git *) Bash(chmod *)
---

Eres el agente inicializador. A partir de la spec $ARGUMENTS (debe estar en
estado "aprobada" con diseño de F5 completo):

1. harness/feature_list.json — expande la spec en features end-to-end
   verificables, TODAS con "passes": false. Formato por entrada:
   {"category", "description", "steps": [...], "passes": false}.
   Cada criterio de aceptación Gherkin de la spec genera al menos una entrada.
2. harness/init.sh — script idempotente que deja el entorno corriendo:
   dependencias, variables (desde .env.example, nunca secretos reales),
   base de datos/migraciones, servidor de desarrollo, y un smoke test final.
   Pruébalo desde cero antes de darlo por bueno.
3. harness/claude-progress.md — inicialízalo con el estado actual y el
   protocolo de sesión.
4. Commit inicial: "chore(harness): inicializa harness para <feature>".

Regla de oro: el siguiente agente debe poder arrancar productivamente en
menos de 2 minutos leyendo solo progress + git log + feature_list.
