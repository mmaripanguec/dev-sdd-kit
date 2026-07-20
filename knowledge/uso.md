# Factory usage and performance
> DORA metrics (Google/DORA) + learnings. F9 writes; F1/F2 read to
> prioritize and estimate. Updated: at the close of each feature and incident.

## DORA metrics (per quarter)
Derived by `scripts/dora.sh` (git history of the repos + postmortems); never
edit by hand inside the markers. CI verification: `dora.sh --check`.
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

## Estimated vs. actual (feeds F2)
| Spec | Estimated points | Outcome | Learning |
|---|---|---|---|

## Real feature usage (feeds F1)
| Feature | Adoption / metric | Insight |
|---|---|---|
