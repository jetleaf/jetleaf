# 024 — JwkSource / RemoteJwkSetSource

## Design reference
A `JwkSource` abstraction for supplying verification keys, with a remote JWKS implementation that filters keys and refreshes them safely.

## Problem
The current remote JWKS source accepts any JWK including `oct` keys, ignores `use`/`alg`/`kty`, refreshes on every unknown `kid`, is not concurrency-safe, and silently keeps stale keys when a fetch fails.

## Invariant
1. A JWK MUST be filtered by `kty`, `use` (must be `sig` or absent), and `alg` (if present) before it is used for verification.
2. An `oct` key MUST NOT be accepted by an asymmetric decoder.
3. An unknown `kid` MUST trigger at most one refresh per cooldown window; repeated unknown kids MUST NOT cause repeated HTTP calls.
4. Refresh MUST be concurrency-safe; simultaneous callers share one in-flight fetch.
5. A failed refresh MUST fail closed once stale keys are unusable, and MUST NOT silently serve verified tokens with a stale key set indefinitely.
6. A cached key set MUST honour a configurable TTL and `Cache-Control` max-age where present.

## Extension seam
`JwkSource` is a public pod; users may supply a static, remote, or custom source.

## Edge cases
`kid` missing from token header; key rotation with overlapping kid sets; JWKS endpoint returns 500; malformed JWK; `n`/`e` with leading-zero bytes; EC point validation failure.

## Jetleaf mapping
The public name `JwkSource` is introduced; `JwkSetSource` is retained as a compatibility facade if needed. In-house JWK parsing (record 022) using `pointycastle`. `http` dependency may be dropped in favour of `dart:io` `HttpClient` for JWKS fetch (server-only framework) — confirm during implementation.

## Gating tests
- `oct_key_rejected_by_asymmetric_decoder`
- `enc_use_key_rejected`
- `unknown_kid_throttled`
- `concurrent_refresh_performs_one_fetch`
- `fetch_failure_fails_closed`
- `key_rotation_succeeds`