# 022 — JwtDecoder and validator chain

## Design reference
A `JwtDecoder` that verifies signatures and then runs a composable validator chain (`OAuth2TokenValidator`, `JwtValidators`, `JwtTimestampValidator`) over the token's claims.

## Problem
Claim validation is duplicated (`JwtClaimsSet.isExpired` vs `JwtValidator`), `iat` is never checked, audiences are single-valued, and there is no composable validator pipeline. Tokens with no `exp` are accepted indefinitely.

## Invariant
1. Signature verification and claim validation MUST be separate stages; a decoder verifies the signature then runs the validator chain.
2. The chain MUST include timestamp (`exp`, `nbf`, `iat`), issuer, and audience validators, plus an optional custom validator.
3. `exp`, `nbf`, and `iat` MUST use one shared clock-skew implementation.
4. `requireExp`, `requireIss`, `requireAud` MUST be configurable; missing required claims MUST fail closed.
5. Multiple audiences MUST be supported.
6. No token may be accepted solely because its signature is valid.

## Extension seam
`OAuth2TokenValidator` is a public interface; `JwtValidators` composes defaults; users add validators via `JwtDecoderBuilder`.

## Edge cases
Clock skew boundary (exactly `now - skew`); a token with `nbf` in the future; `iat` in the future; `aud` as a list; issuer with a trailing slash; token with no `exp`; custom validator that throws.

## Jetleaf mapping
In-house implementation on `pointycastle` (owner decision). `dart_jsonwebtoken` is a temporary test oracle only and MUST be deleted once RFC 7515 vectors pass. No third-party JWT dependency in the final package.

## Gating tests
- `expired_token_rejected`
- `not_before_token_rejected`
- `future_iat_rejected` (fails today)
- `wrong_issuer_rejected`
- `wrong_audience_rejected`
- `multiple_audiences_supported`
- `missing_exp_rejected_when_required`
- `clock_skew_boundaries`