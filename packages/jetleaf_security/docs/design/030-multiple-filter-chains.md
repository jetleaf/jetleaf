# 030 — Multiple SecurityFilterChains

## Design reference
Multiple `SecurityFilterChain` Pods selected by `securityMatcher` and ordered via `@Order`.

## Problem
One global chain cannot express "public endpoints have permissive rules, admin endpoints have strict rules, actuator has its own rules." The current builder produces exactly one chain with one rule set.

## Invariant
1. More than one `SecurityFilterChain` pod MUST be supported.
2. Each chain MUST declare a `securityMatcher`; chains without one are the fallback and MUST be ordered last.
3. The first matching chain MUST handle the request exclusively.
4. Chains MUST be ordered by `@Order` / `Ordered`, using `AnnotationAwareOrderComparator`.
5. A chain MUST NOT leak its security context into the next chain or the dispatcher.

## Extension seam
Users add chains as pods with `@Order`; no change to the entry point required.

## Edge cases
Two chains with the same order and overlapping matchers (deterministic tie-break required); a chain whose matcher throws; no fallback chain (must deny closed); a request matched by a chain that then calls `chain.next()` — the remaining filters of that chain still run.

## Jetleaf mapping
`FilterChainProxy` (record 009) performs selection. Registration via multiple `@Pod` methods in auto-configuration or user `@Configuration` classes. Reuse `AnnotationAwareOrderComparator`.

## Gating tests
- `two_chains_with_different_matchers`
- `first_matching_chain_wins`
- `fallback_chain_ordered_last`
- `no_fallback_denies_closed`
- `chain_context_does_not_leak`
