# Mapas de arquitectura por repositorio

Capa de INTERPRETACIÓN sobre los hechos del as-is, generada por la skill
`/repo-map <repo>`:

- `knowledge/as-is/` dice QUÉ HAY (hechos deterministas, solo del script).
- `knowledge/mapas/<repo>.md` dice CÓMO ESTÁ ARMADO: arquitectura interna,
  dependencias clave y su uso, integraciones, datos y flujos principales —
  cada afirmación con evidencia `archivo:línea` y sello del commit analizado.
- Los ADRs (`knowledge/decisiones/`) siguen diciendo POR QUÉ.

Un mapa cuyo sello no coincide con el HEAD del repo está desactualizado:
regenerarlo con `/repo-map <repo>`. Si un mapa contradice un ADR o el rol
declarado en `repos.yaml`, eso es drift arquitectónico y se escala al gate
de Arquitectura — no se normaliza en silencio.
