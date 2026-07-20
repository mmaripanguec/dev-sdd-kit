---
paths:
  - "src/api/**"
  - "**/openapi*.{yaml,yml,json}"
---
# API design
> Base: service domains (business capabilities) · Google AIP (aip.dev) · REST

- Every API belongs to ONE service domain: a business capability with clear
  boundaries, no overlap with other domains. Name it by the capability
  (e.g. `order-management`, `user-profile`), not by the table or the team.
- Contract first: versioned OpenAPI in the repo BEFORE implementing; the contract
  is part of the spec and changes via ADR if it breaks compatibility.
- Resources and verbs per Google AIP: plural nouns, standard HTTP verbs,
  errors with a single format (code, actionable message, correlation-id).
- Explicit versioning (`/v1/`); incompatible changes create a new version,
  never mutate the existing one.
- Idempotency mandatory (idempotency-key) on non-retryable operations
  with external effects; the domain profile may extend the list
  (see rules/domain-banking.md for repos with `domain: banking`).
