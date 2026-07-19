# Uso y desempeño de la fábrica
> Métricas DORA (Google/DORA) + aprendizajes. F9 escribe; F1/F2 leen para
> priorizar y estimar. Actualización: al cierre de cada feature e incidente.

## Métricas DORA (por trimestre)
Derivadas por `scripts/dora.sh` (git de los repos + postmortems); nunca
editar a mano dentro de los marcadores. Verificación en CI: `dora.sh --check`.
<!-- DORA:BEGIN -->
[GENERADO v1] 2026-07-19 · período: últimos 90 días · fuentes: ninguna · no editar a mano (scripts/dora.sh)

| Métrica | Actual | Objetivo | Fuente |
|---|---|---|---|
| Frecuencia de despliegue | sin datos (ningún repo clonado — correr scripts/setup.sh) | ≥ 1/día | tags v* o merges a rama por defecto |
| Lead time (commit→prod) | sin datos (ningún repo clonado — correr scripts/setup.sh) | < 1 día | primer commit de la rama → merge |
| Change failure rate | sin datos (ningún repo clonado — correr scripts/setup.sh) | < 15% | knowledge/incidentes vs despliegues |
| MTTR | sin datos (ningún repo clonado — correr scripts/setup.sh) | < 1 hora | campo MTTR de los postmortems |

Sin datos de: homebanking-pwa-backend, homebanking-pwa-proxy, homebanking-pwa (no clonado — correr scripts/setup.sh)
<!-- DORA:END -->

## Estimado vs. real (alimenta a F2)
| Spec | Puntos estimados | Resultado | Aprendizaje |
|---|---|---|---|

## Uso real de features (alimenta a F1)
| Feature | Adopción / métrica | Insight |
|---|---|---|
