---
name: as-is-sync
description: Regenera el mapa as-is desde el código y commitea el resultado. Usar tras cambios estructurales (módulos nuevos, endpoints, migraciones) o cuando /as-is detecte desactualización.
allowed-tools: Bash(./scripts/generate-as-is.sh *) Bash(git add knowledge/as-is/*) Bash(git commit *) Bash(git diff *) Read
---

1. Ejecuta `./scripts/generate-as-is.sh`.
2. Revisa `git diff knowledge/as-is/` y resume EN LENGUAJE DE ARQUITECTURA
   qué cambió realmente: módulo nuevo, dependencia nueva entre dominios,
   endpoint añadido/retirado, migración de esquema.
3. VALIDACIÓN CRÍTICA — compara los cambios contra las reglas:
   - ¿Una dependencia nueva viola límites de service domain
     (rules/api-design.md) o algún ADR vigente? → repórtalo como drift
     arquitectónico y ESCALA al gate de Arquitectura. No lo normalices
     commiteándolo en silencio.
   - ¿Apareció un endpoint sin contrato OpenAPI? → márcalo como deuda.
4. Si todo es legítimo: commit
   `chore(as-is): sincroniza mapa con <commit> — <resumen de 1 línea>`.
5. Si detectaste drift arquitectónico: commitea el mapa igualmente (el as-is
   SIEMPRE dice la verdad) pero deja el hallazgo registrado para el gate.
