# Contributing

Thanks for your interest! This project practices what it preaches: **every
contribution follows the factory's own spec-driven process**. That is the
best way to understand the template — and the only way changes get merged.

> Working language note: public docs are in English; the factory's internal
> artifacts (skills, rules, specs, knowledge) are in Spanish by design.
> Contributions to those artifacts should keep Spanish; code identifiers,
> commit types and this kind of public doc stay in English.

## The process in short

1. **Non-trivial change? Start with a spec.** Copy `specs/_template.md`
   (12 sections). Ambiguities are resolved up front and recorded in the
   spec's *Clarificaciones* section — unresolved ones are marked
   `[NECESITA CLARIFICACIÓN]` and block readiness.
2. **Work on a feature branch**, never on `main`.
3. **Strict TDD**: write the failing tests first and commit them *red*
   (see `scripts/tests/*.sh` for the house style — bash 3.2, no new
   dependencies). Then implement until green. **Never modify a test to make
   it pass.**
4. **One commit per task**, Conventional Commits, referencing the spec:
   `feat(scope): what and why` + `Spec: specs/<file>.md`.
5. **Before opening a PR**, all three suites must pass:

   ```bash
   ./scripts/tests/test-repo-lib.sh
   ./scripts/tests/test-dora.sh
   ./scripts/tests/test-docs.sh
   ```

   If you touched documentation sources, regenerate the derived docs
   (`./scripts/docs.sh`) and commit them — CI will fail on drift otherwise.
6. **Human gates are real.** A PR is reviewed against its spec; the
   certification section must show the convergence check (code vs. spec)
   and the verdict. Approval is recorded in the spec (who, when, commit).

## Ground rules

- Derived artifacts (`knowledge/as-is/`, the DORA block in
  `knowledge/uso.md`, `docs/*.html`) are **never edited by hand** — fix the
  source or the generator and regenerate.
- Every published metric declares its source and period, or says "no data".
- No secrets, credentials or real customer data anywhere — including specs,
  tests and fixtures.
- New architecture decisions get an ADR in `knowledge/decisiones/`.
- Small, self-contained changes review best: one intention per commit.

## Reporting bugs / proposing features

Use the issue templates. For bugs, a failing reproduction (ideally as a
test in the house style) is worth more than a long description.
