# 012 — SecurityContextHolderFilter / OncePerRequestFilter

## Design reference
A `SecurityContextHolderFilter` built on `OncePerRequestFilter` that loads, binds, saves, and clears security context for exactly one request.

## Problem
The context must be bound for exactly one request and cleared on every exit path, including exceptions and async/error dispatch. Without a once-per-request guard, a filter can run twice on the same request and rebind or prematurely clear the context.

## Invariant
1. The filter MUST load the deferred context from the repository, bind it via `runWithContext`, run the chain, save via the repository, and clear in `finally`.
2. The filter MUST NOT run twice for one request; a request attribute marker enforces this.
3. On error dispatch, the filter MUST NOT re-load a context that is already bound.
4. The zone binding MUST be restored to the outer context after completion.
5. Saving MUST happen before clearing.

## Extension seam
Repository is pluggable (record 002). Users may extend `OncePerRequestFilter` for their own filters.

## Edge cases
Exception thrown by downstream filter; async dispatch; `Future` spawned inside the zone; response already committed at save time; nested filters that also use zones.

## Jetleaf mapping
The existing `SecurityContextHolderFilter` has correct bracketing on the happy path; preserve it and add save-through-repository plus once-per-request semantics. The once-per-request marker uses `ServerHttpRequest.setAttribute`, a request-attribute approach. No container-specific APIs.

## Gating tests
- `context_bound_and_cleared_on_success`
- `context_cleared_on_exception`
- `filter_does_not_run_twice_via_marker`
- `save_happens_before_clear`
- `async_dispatch_does_not_rebind_context`
