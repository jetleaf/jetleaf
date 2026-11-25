# 009 — SecurityFilterChain and FilterChainProxy

## Design reference
A `FilterChainProxy` entry point, a concrete `DefaultSecurityFilterChain`, and a `SecurityFilterChain` contract for running an ordered set of request filters.

## Problem
The current `SecurityFilterChain` implements `jetleaf_web`'s `Filter` but is never registered with `FilterManager`, so it has never run through the real dispatcher. The example drives it with hand-made request/response objects and a fake chain.

## Invariant
1. A `SecurityFilterChain` MUST be contributed as a `Filter` pod discovered by `FilterManager`, or via `WebConfigurer.addFilters`.
2. A single `FilterChainProxy`-equivalent entry point MUST select the first matching chain, run it, and clear the security context in `finally`.
3. A chain that does not match its `securityMatcher` MUST pass the request through untouched.
4. The chain MUST delegate the remainder of the request to the real `FilterChain` supplied by `GlobalServerDispatcher.doDispatch()` — never to a synthetic terminal.
5. Multiple chains MUST be ordered deterministically.

## Extension seam
Users contribute additional `SecurityFilterChain` pods with `@Order`; the entry point is overridable via `@ConditionalOnMissingPod`.

## Edge cases
No matching chain (must deny closed or pass through per explicit policy); two chains matching the same request (first wins); exception thrown inside a chain; async dispatch; context already bound when the proxy runs.

## Jetleaf mapping (verified)
`FilterManager.onReady()` auto-discovers **every** `Filter` Pod via `getPodsOf(Class<Filter>(null, PackageNames.WEB), allowEagerInit: true)` and matches subtypes, so multiple filters need no manual registration. Follow the exact pattern in `jetleaf_web/lib/src/config/cors_auto_configuration.dart`:

```dart
@AutoConfiguration()
@Role(DesignRole.INFRASTRUCTURE)
@Named(SecurityAutoConfiguration.NAME)
final class SecurityAutoConfiguration {
  @Pod(value: SecurityAutoConfiguration.FILTER_CHAIN_PROXY)
  FilterChainProxy securityFilterChainProxy(/* injected dependencies */) => ...;
}
```

`GlobalServerDispatcher.doDispatch()` at `global_server_dispatcher.dart:193-212` drives the ordered list. `WebConfigurer.addFilters(List<Filter>)` is an alternative but `WebUtils.findWebConfigurer()` resolves only a single configurer, so the `@Pod` route is preferred. Ordering uses `AnnotationAwareOrderComparator.getOrderedItems` (lower value = earlier). Do **not** reimplement filter discovery. Keep the public name `SecurityFilterChain`; add `FilterChainProxy`.

## Gating tests
- `chain_is_registered_with_filter_manager`
- `request_traverses_real_dispatcher`
- `non_matching_chain_passes_through`
- `first_matching_chain_wins`
- `context_cleared_after_chain`