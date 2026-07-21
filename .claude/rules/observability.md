---
paths:
  - "src/**"
---
# Observability and reliability
> Base: Google SRE (SLOs, error budgets, golden signals) · DORA

- Every API exposes the 4 golden signals: latency, traffic, errors, saturation.
- Every service defines SLOs (e.g. availability 99.9%, p99 < 300ms) in its spec;
  the error budget governs the pace: exhausted budget = feature work freezes
  and reliability is prioritized.
- Structured logs (JSON) with end-to-end correlation-id; no personal data
  or secrets in logs.
- The team's DORA metrics are recorded in knowledge/usage.md: deployment
  frequency, lead time, change failure rate, MTTR.
- Actionable alerts: every alert links to its runbook; an alert without a runbook is not created.
