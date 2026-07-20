---
name: as-is-sync
description: Regenerates the as-is map from the code and commits the result. Use after structural changes (new modules, endpoints, migrations) or when /as-is detects it is out of date.
allowed-tools: Bash(./scripts/generate-as-is.sh *) Bash(git add knowledge/as-is/*) Bash(git commit *) Bash(git diff *) Read
---

1. Run `./scripts/generate-as-is.sh`.
2. Review `git diff knowledge/as-is/` and summarize IN ARCHITECTURE LANGUAGE
   what actually changed: new module, new dependency between domains,
   endpoint added/removed, schema migration.
3. CRITICAL VALIDATION — compare the changes against the rules:
   - Does a new dependency violate service domain boundaries
     (rules/api-design.md) or any current ADR? → report it as architectural
     drift and ESCALATE to the Architecture gate. Do not normalize it
     by committing it silently.
   - Did an endpoint appear without an OpenAPI contract? → flag it as debt.
4. If everything is legitimate: commit
   `chore(as-is): sync map with <commit> — <1-line summary>`.
5. If you detected architectural drift: commit the map anyway (the as-is
   ALWAYS tells the truth) but leave the finding recorded for the gate.
