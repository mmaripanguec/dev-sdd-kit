# Testing
> Base: test pyramid (Google Testing Blog) · TDD (Beck) · ISO/IEC 25010

- TDD for all business logic: failing test → commit the test → implement
  → green → refactor. NEVER modify the test to make it pass.
- Pyramid: mostly unit (fast, isolated), integration for contracts between
  modules, E2E only for critical user flows.
- Minimum coverage on new code: 80% lines / 100% on auth and on the critical
  paths declared by the domain profile (e.g. money in domain-banking).
  Coverage is a floor, not a goal: every edge case in the spec has its test.
- Deterministic tests: no sleeps, no external network dependency, no implicit ordering.
- Synthetic test data; FORBIDDEN to use real customer data in tests.
- Every fixed bug first adds the test that reproduces it (regression).
