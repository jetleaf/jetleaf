# 002 — SecurityContextRepository

## Design reference
A `SecurityContextRepository` abstraction for loading and saving security context, with a null implementation for stateless flows, a session-backed implementation for stateful flows, and a request-attribute implementation for per-request storage.

## Problem
Stateless JWT and stateful session authentication need different persistence. The current package has no repository at all, so `SessionCreationPolicy` is dead configuration and "stateless" is only an intention expressed in a builder.

## Invariant
1. `SecurityContextHolderFilter` MUST load via the configured repository and save via the same repository at completion (see record 012).
2. `NullSecurityContextRepository` MUST never read or write a session, even if one exists.
3. `HttpSessionSecurityContextRepository` MUST honour `allowSessionCreation`; with `false` it may read an existing session but MUST NOT create one.
4. The repository MUST be selected by `SessionCreationPolicy` (record 031).
5. Saving an empty context MUST remove the stored attribute rather than store an empty object.

## Extension seam
`SecurityContextRepository` is a public interface supplied as a pod, guarded by `@ConditionalOnMissingPod`. Users may provide a Redis-backed or custom repository without touching the filter.

## Edge cases
Context loaded lazily (deferred) when the filter chain never reads it; response committed before save; session invalidated mid-request; concurrent modification of the same session; `stateless` policy but an inbound session cookie present (must be ignored).

## Jetleaf mapping
Use `jetleaf_web`'s `HttpSession`/`ServerHttpRequest.getSession(create:)` from `packages/jetleaf_web/lib/src/http/http_session.dart`. Introduce `DeferredSecurityContext` so loading is lazy. The public name `HttpSessionSecurityContextRepository` is retained.

## Gating tests
- `null_repository_never_touches_session`
- `http_session_repository_respects_allow_session_creation_false`
- `empty_context_removes_session_attribute`
- `deferred_context_not_loaded_when_unused`
- `custom_repository_pod_overrides_default`