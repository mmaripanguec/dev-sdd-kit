## Spec

<!-- Every non-trivial PR is governed by a spec. Link it: -->
Spec: `specs/....md`

## What & why

## Checklist (the factory's gates)

- [ ] Failing tests were committed **before** the implementation (TDD); no
      test was modified to make it pass
- [ ] One commit per task, Conventional Commits, spec referenced
- [ ] All suites green: `test-repo-lib.sh` · `test-dora.sh` · `test-docs.sh`
- [ ] Derived docs regenerated if sources changed (`./scripts/docs.sh`;
      CI fails on drift)
- [ ] No secrets, credentials or real customer data
- [ ] Spec's certification section updated (convergence + verdict); human
      gate approval recorded in the spec
- [ ] New architecture decision → ADR in `knowledge/decisiones/`
