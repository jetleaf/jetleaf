# 013 — CsrfFilter

## Design reference
A `CsrfFilter` with `CsrfTokenRepository`, `CsrfTokenRequestHandler`, and `MissingCsrfTokenException` for token generation and validation.

## Problem
CSRF denial must be rendered as a JSON 403, but `CsrfFilter` sits outside `ExceptionTranslationFilter` in the canonical order. The current implementation throws `InvalidCsrfTokenException` with no handler, so the exception escapes the chain and the client receives no response.

## Invariant
1. `CsrfFilter` MUST own an `AccessDeniedHandler` and call it directly on token mismatch — do NOT fix this by reordering the chain.
2. Comparison MUST be constant-time.
3. A token MUST be generated and exposed on safe requests via the configured repository/request handler.
4. State-changing methods MUST be rejected when the token is missing or mismatched.
5. The filter MUST be disabled for stateless REST configurations via `http.csrf((c) => c.disable())`.
6. Deferred token handling MUST avoid leaking the token in a way vulnerable to compression side channels.

## Extension seam
`CsrfTokenRepository` and `CsrfTokenRequestHandler` are public pods. The local `CsrfFilter` may be replaced entirely by `jetleaf_web`'s DI-registered version.

## Edge cases
Preflight `OPTIONS` (safe method); a request with a valid cookie but missing header; `X-Requested-With` exemptions; path exemptions; token rotation; multiple simultaneous tabs.

## Jetleaf mapping (verified)
`jetleaf_web` already ships `CsrfTokenRepository`, `CsrfTokenRepositoryManager`, `CsrfFilter` (order `Ordered.HIGHEST_PRECEDENCE + 1`) and an `@AutoConfiguration`-registered filter bean. **Do not register a second CSRF bean with the same role.**

**Implementation choice recorded in Phase 3:** option 2 — the local `CsrfFilter` is retained but hardened with an injected `AccessDeniedHandler`, using the same handler-injection approach. It is the only CSRF filter contributed by this package; applications using the security chain must not also register the web CSRF bean. Full delegation to the web token repository is deferred to Pass B because that filter does not expose the handler-injection seam this design requires. The duplicate `config/csrf_configuration.dart` is likewise deferred to Pass B.

## Gating tests
- `csrf_failure_yields_json_403` (fails today)
- `csrf_missing_token_is_rejected`
- `csrf_valid_token_passes`
- `csrf_disabled_allows_state_change`
- `csrf_token_compared_in_constant_time`
