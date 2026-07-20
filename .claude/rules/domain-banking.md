# Domain profile: banking
> Applies to repos whose registry (`repos.yaml`) declares `domain: banking`.
> Complements the base rules; does not replace them.
> Base: BIAN Service Landscape · ISO 20022 · OWASP ASVS

- Domain landscape: capabilities are assigned to BIAN service domains
  (e.g. `payment-order`, `customer-offer`); one domain = one module with its
  own API and data, no overlap.
- Payload vocabulary aligned to ISO 20022 when the domain is payments.
- Critical paths of the domain = every MONEY path (transfers, payments,
  credits) and every AUTHENTICATION path: 100% test coverage and mandatory
  idempotency (idempotency-key) on money operations.
- Threat modeling (STRIDE) mandatory for features that touch money,
  in addition to the base triggers (auth, personal data).
- Transactional and personal data: encryption in transit and at rest;
  financial regulatory requirements identified in the spec ("Análisis"
  section) as non-negotiable.
- Amounts are handled with exact types (decimal/integer cents),
  never floating point; every operation records an explicit currency.
