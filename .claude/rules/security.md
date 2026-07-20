# Security
> Base: NIST SP 800-218 (SSDF) and 800-218A (GenAI) · Microsoft SDL · OWASP Top 10 / ASVS

## Produce well-secured software (SSDF group PW)
- Validate ALL external input at the edge; sanitize outputs (XSS, SQL/NoSQL/OS injection).
- Secrets only via a secrets manager/environment variables; FORBIDDEN in code,
  logs, specs or commits. `.env` and keys are off-limits to the agents (settings.json).
- Authentication and authorization on every endpoint; deny by default.
- Encryption in transit (TLS) and at rest for personal and sensitive data
  (domain profiles extend the list, e.g. financial data in banking).
- Dependencies: pinned versions only; run vulnerability analysis (SCA)
  before certifying; generate an SBOM at the move to production (SSDF group PS).

## Lifecycle (Microsoft SDL)
- Threat modeling (STRIDE) mandatory in the Design phase for features that touch
  auth, personal data or the critical paths of the domain profile (e.g. money
  in banking); the result goes into the ADR.
- Static analysis (SAST) in CI; critical/high findings block the merge.

## Response (SSDF group RV)
- Every vulnerability detected in operation generates an incident + postmortem +
  regression test + root-cause review of the process.

## AI agents (SSDF 800-218A / NIST AI RMF)
- Agents do not receive production credentials; human gates backed by
  permissions, not just by instructions.
- AI-generated code goes through the same controls as human code: review,
  SAST, tests. Authorship does not exempt from control.
