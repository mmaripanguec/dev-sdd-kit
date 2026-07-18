---
paths:
  - "src/**"
---
# Observabilidad y confiabilidad
> Base: Google SRE (SLOs, error budgets, golden signals) · DORA

- Toda API expone las 4 señales doradas: latencia, tráfico, errores, saturación.
- Cada servicio define SLOs (p.ej. disponibilidad 99.9%, p99 < 300ms) en su spec;
  el error budget gobierna el ritmo: presupuesto agotado = se congela feature work
  y se prioriza confiabilidad.
- Logs estructurados (JSON) con correlation-id de punta a punta; sin datos
  personales ni secretos en logs.
- Métricas DORA del equipo se registran en knowledge/uso.md: frecuencia de
  despliegue, lead time, change failure rate, MTTR.
- Alertas accionables: cada alerta enlaza a su runbook; alerta sin runbook no se crea.
