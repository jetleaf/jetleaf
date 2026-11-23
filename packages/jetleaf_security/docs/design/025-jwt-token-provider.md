# 025 — JwtTokenProvider

## Design reference
There is no separate reference type for this role; this is a Jetleaf convenience facade over `JwtEncoder`, `JwtDecoder`, and `AuthenticationProvider`, and must be documented as such.

## Problem
The current provider configures an audience validator but never emits `aud` on issued tokens, and accepts refresh tokens as authentication credentials. Both defects are masked by the existing test, which manually injects `aud`.

## Invariant
1. `audience` configured on the provider MUST be injected into every issued token's `aud` claim.
2. A refresh token MUST NOT authenticate; the provider MUST reject it with `BadCredentialsException`.
3. Token type MUST be read from a reserved claim and checked against the expected type for the operation.
4. `extractAuthorities` MUST normalise role names consistently with `hasRole`'s `ROLE_` prefix, or the mismatch MUST be documented and configurable.
5. Issuance and verification MUST use the same issuer/audience configuration by construction, not by caller discipline.

## Extension seam
`JwtEncoder`/`JwtDecoder` are injectable; users may replace the provider via `@ConditionalOnMissingPod`.

## Edge cases
Caller supplies an `aud` in `additionalClaims` that conflicts with the configured one; token with no `type` claim; legacy tokens issued before the type claim existed; roles as a comma-separated string vs a list.

## Jetleaf mapping
Keep the class as a convenience facade over the in-house encoder/decoder (owner decision). It MUST NOT become the only supported path — raw `JwtEncoder`/`JwtDecoder` remain public.

## Gating tests
- `configured_audience_is_emitted` (fails today)
- `refresh_token_cannot_authenticate` (fails today)
- `token_type_missing_is_rejected`
- `issuer_and_audience_consistent_between_issuance_and_validation`
