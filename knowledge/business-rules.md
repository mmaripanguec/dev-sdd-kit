# Business rules
> Single source of truth for the domain. F4 (analysis) extracts and consults
> them; human gates validate them. A new or changed rule enters via PR.

| ID | Rule | Service domain | Origin (spec/regulation) | Effective since |
|---|---|---|---|---|
| RN-01 | <e.g.: a payment order above $X requires a second factor> | payment-order | specs/____.md | |
| RN-F1 | Process weight is proportional to risk: the F0 triage decides whether /clarify applies and which controls are loaded | factory-process | factory core (see CHANGELOG v1.0.0) | 2026-07-19 |
| RN-F2 | No skill edits artifacts it does not own: /consistency and /spec-review are read-only; /converge only appends to its own spec's plan; the guarantee is enforced by allowed-tools, not by instructions | factory-process | factory core (see CHANGELOG v1.0.0) | 2026-07-19 |
| RN-F3 | A pending [NEEDS CLARIFICATION] marker blocks the DoR (maximum 3 alive per spec) | factory-process | factory core (see CHANGELOG v1.0.0) | 2026-07-19 |
| RN-F4 | Every metric published in knowledge/ declares source and period, or declares "no data"; values without provenance are forbidden (DORA is derived with scripts/dora.sh) | factory-process | factory core (see CHANGELOG v1.0.0) | 2026-07-19 |
