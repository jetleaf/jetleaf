# 023 — JWS algorithm allowlist

## Design reference
A `JwsAlgorithm` allowlist applied per decoder so accepted algorithms come from configuration, never from the untrusted token header.

## Problem
`alg: none`, RS256→HS256 algorithm confusion, and accepting an algorithm chosen by the untrusted token header are classic critical JWT vulnerabilities. The current decoder trusts the header.

## Invariant
1. Each decoder MUST have an explicit allowlist of accepted JWS algorithms.
2. The algorithm MUST be resolved from configuration, never from the token header alone.
3. When a key type is known, only algorithms compatible with that key type may be accepted (`oct` → HMAC only; RSA → RS/PS; EC → ES).
4. `alg: none` MUST always be rejected.
5. An incompatible `alg`/`kty` pair MUST be rejected before any cryptographic operation.

## Extension seam
The allowlist is a constructor/builder argument on the decoder. Users may narrow it; they may not widen it beyond supported algorithms.

## Edge cases
Token header with an unknown `alg`; header with `alg` case variation; JWK marked `use: enc` used for signature verification; `crit` header parameters; `kid` absent.

## Jetleaf mapping
Define `JwsAlgorithms` with constants `HS256/384/512`, `RS256/384/512`, `ES256/384/512`. Enforce in the in-house `JwtVerifier` before decoding the signature. Part of the in-house JWT engine (record 022).

## Gating tests
- `alg_none_rejected`
- `rs256_to_hs256_confusion_rejected`
- `unknown_alg_rejected`
- `enc_use_key_rejected_for_signature`
- `hmac_key_cannot_verify_rsa_token`