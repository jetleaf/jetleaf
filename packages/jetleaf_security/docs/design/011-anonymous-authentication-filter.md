# 011 — AnonymousAuthenticationFilter

## Design reference
An `AnonymousAuthenticationFilter` that installs an anonymous authentication when no real authentication is present, so downstream code never has to special-case a null principal.

## Problem
`AnonymousAuthenticationToken` exists in the current package but no filter ever creates one, so downstream code must special-case `null` authentication. That leads to inconsistent 401/403 decisions.

## Invariant
1. The filter MUST install an anonymous `Authentication` into the context only when no authentication is already present.
2. It MUST be positioned after all real authentication mechanisms have had a chance to authenticate.
3. The anonymous token MUST carry a key and a principal string so `AuthenticationTrustResolver` can identify it.
4. It MUST be disabled by `http.anonymous((a) => a.disable())` and by `stateless` configurations where appropriate.
5. It MUST NOT make anonymous requests appear "fully authenticated" to authorization managers.

## Extension seam
Configurable key and principal via `AnonymousConfigurer`; the filter is a pod with `@ConditionalOnMissingPod`.

## Edge cases
A real authentication installed by an earlier filter; a provider that deliberately returns an anonymous token; disabled anonymous support combined with `anyRequest().authenticated()`.

## Jetleaf mapping
New filter implementing `SecurityFilter`. Writes through `SecurityContextHolder` (record 001) inside the zone bound by the context holder filter (record 012).

## Gating tests
- `anonymous_filter_installs_token_only_when_empty`
- `anonymous_filter_does_not_overwrite_real_authentication`
- `anonymous_request_is_not_fully_authenticated`
- `anonymous_can_be_disabled`