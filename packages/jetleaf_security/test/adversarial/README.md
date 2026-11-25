# Adversarial / red-phase tests

These tests encode **known defects** in the current implementation. They compile against the current API and are expected to **fail**. They are the executable half of the rewrite specification in `roadmap/jetleaf_security_rewrite.md`.

Current baseline (before implementation starts):

- `dart analyze` — clean
- `dart test` — 19 original tests pass, 14 adversarial tests fail

Each test file maps to a defect number in §1.4 of the rewrite specification:

| File | Defects |
|---|---|
| `jwt_defects_test.dart` | 2 (audience never emitted), 3 (refresh token authenticates), 4 (`iat` unchecked), 5 (no `exp`) |
| `authentication_defects_test.dart` | 1 (public trust escalation), 13 (raw password leak), 14 (`supports` exact type) |
| `expression_defects_test.dart` | 12 (list syntax, Dart object property paths) |
| `filter_defects_test.dart` | 7 (CSRF denial escapes translation), 8 (preflight method not validated) |
| `crypto_defects_test.dart` | 17 (unbounded bcrypt strength) |

## Rules

1. Do not delete or weaken these tests to make the suite green.
2. When a phase fixes a defect, the corresponding test should turn green without modification. If it needs modification, the test was wrong — fix the ledger first.
3. New-API contract tests (typed `AuthorizationManager`, real proxies, session matrix, RFC vectors) are added at the start of their respective phases; their names are listed in each ledger record under `docs/design/`.
4. Mock HTTP helpers in `test/helpers/` are acceptable for unit tests but **not** for the integration gates in §8.2 of the rewrite specification.