# Factory usage and performance
> DORA metrics (Google/DORA) + learnings. F9 writes; F1/F2 read to
> prioritize and estimate. Updated: at the close of each feature and incident.

## DORA metrics (per quarter)
Derived by `scripts/dora.sh` (git history of the repos + postmortems); never
edit by hand inside the markers. CI verification: `dora.sh --check`.
<!-- DORA:BEGIN -->
[GENERATED v1] 2026-07-20 · period: last 90 days · sources: ninguna · do not edit by hand (scripts/dora.sh)

| Metric | Current | Target | Source |
|---|---|---|---|
| Deployment frequency | no data (no repos cloned — run scripts/setup.sh) | ≥ 1/day | v* tags or merges to default branch |
| Lead time (commit→prod) | no data (no repos cloned — run scripts/setup.sh) | < 1 day | first branch commit → merge |
| Change failure rate | no data (no repos cloned — run scripts/setup.sh) | < 15% | knowledge/incidents vs deployments |
| MTTR | no data (no repos cloned — run scripts/setup.sh) | < 1 hour | MTTR field of the postmortems |

No data from: REGISTRY_MISSING (not cloned — run scripts/setup.sh)
<!-- DORA:END -->

## Estimated vs. actual (feeds F2)
| Spec | Estimated points | Outcome | Learning |
|---|---|---|---|

## Real feature usage (feeds F1)
| Feature | Adoption / metric | Insight |
|---|---|---|
