# 028 — RateLimitingFilter

## Design reference
There is no built-in rate limiter in the reference model — this package supplies its own filter. Document this addition and keep the familiar filter name.

## Problem
The current filter trusts a client-controlled `X-Forwarded-For` header, collapses all clients without it into one bucket, and keeps an unbounded in-memory map — a trivially bypassable limiter and a memory-exhaustion vector.

## Invariant
1. The client key MUST come from a configured list of trusted proxies: only honour `X-Forwarded-For` when the direct peer is trusted.
2. Otherwise the key MUST be the direct peer address; there MUST be no shared `'default'` bucket.
3. The store MUST be bounded with eviction of idle buckets.
4. `Retry-After` and rate-limit headers MUST be emitted on 429.
5. Rejected requests MUST be terminated before the security context is loaded.
6. A distributed store MUST be pluggable via an interface (implementation is Pass B).

## Extension seam
`RateLimitStore` and the trusted-proxy configuration are public pods.

## Edge cases
Spoofed `X-Forwarded-For`; a chain of proxies; IPv4/IPv6; burst vs sustained rate; clock injection for deterministic tests.

## Jetleaf mapping
Keep the familiar filter API (`maxRequestsPerMinute`, `byIp`). Use `ServerHttpRequest.getOrigin()` or the equivalent remote-address accessor from `jetleaf_web` rather than trusting headers by default.

## Gating tests
- `spoofed_forwarded_for_does_not_bypass_limit` (fails today)
- `clients_without_forwarded_for_have_separate_buckets` (fails today)
- `idle_buckets_are_evicted`
- `retry_after_header_emitted`