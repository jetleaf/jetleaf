# 001 — SecurityContextHolder

## Design reference
A `SecurityContextHolder` and its pluggable `SecurityContextHolderStrategy`: a holder that binds security state to a request-scoped execution context so concurrent requests stay isolated.

## Problem
Dart has no thread-local storage. A naive static holder leaks one request's authentication into another on the shared isolate event loop, or falls back to process-global mutable state when called outside a deliberately entered zone.

## Invariant
1. Security state MUST be bound to a forked `Zone`, never to a mutable static field.
2. Outside any bound zone, `getContext()` MUST return a fresh empty context; it MUST NOT return shared mutable state.
3. There MUST be no public API that mutates a context which is not the current zone's context.
4. A context bound for a request MUST be cleared in `finally` on success, error, and async dispatch.
5. Nested `runWithContext` calls MUST restore the outer context, not overwrite it.

## Extension seam
`SecurityContextHolderStrategy` equivalent is internal; users do not replace the holder. Users replace the *repository* (record 002) and the filter (record 011). The zone key is private.

## Edge cases
Concurrent requests on one isolate; exception thrown mid-request; `Future` spawned inside a zone outliving the request; code calling `getContext()` from a `Timer` callback with no zone; tests running in parallel.

## Jetleaf mapping
Follow `packages/jetleaf_data/lib/src/transaction/zone_transaction_holder.dart`: `static const Symbol _key`, forked zone values, immutable binding. Delete the `_fallbackContext` static entirely. Keep the existing `runWithContext(R Function() fn, [SecurityContext? context])` signature — the roadmap's argument order is not a security invariant and changing it would ripple through the example and tests without benefit. `setContext` outside a zone now throws `StateError` instead of mutating global state.

## Gating tests
- `context_is_isolated_across_concurrent_requests`
- `get_context_outside_zone_returns_fresh_empty_context`
- `context_cleared_when_downstream_throws`
- `nested_runWithContext_restores_outer_context`