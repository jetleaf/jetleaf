# 026 — OAuth2ResourceServer

## Design reference
An `OAuth2ResourceServer` configurer that wires a `JwtAuthenticationConverter` and an `OAuth2AuthoritiesConverter` into the filter chain for bearer-token authentication.

## Problem
`OAuth2ResourceServer` is currently a standalone helper with an `authenticateBearer()` method, never wired into `HttpSecurity` or `ProviderManager`. Configuring it in the DSL has no effect.

## Invariant
1. The resource server MUST be implemented as an `AuthenticationProvider` + `AuthenticationFilter` wired by `http.oauth2ResourceServer(...)`.
2. A bearer token from an inbound request MUST be decoded, validated, and converted into an authenticated token with authorities.
3. Authority extraction MUST support `scope`/`scp` with a configurable prefix and `roles` without one.
4. The decoder MUST enforce issuer and audience from configuration; missing values MUST fail closed.
5. The resource server MUST be selectable when multiple filter chains exist.

## Extension seam
`JwtDecoder`, `OAuth2AuthoritiesConverter`, and `AuthenticationConverter` are public pods with `@ConditionalOnMissingPod`.

## Edge cases
Malformed `Authorization` header; non-Bearer scheme; token from the wrong issuer; empty scope; duplicate authorities; multiple chains with different issuers.

## Jetleaf mapping
Public name retained. Uses in-house JWT engine (records 022–025). `OpaqueTokenIntrospector` is reserved for Pass B.

## Gating tests
- `oauth2_resource_server_wired_into_chain`
- `bearer_token_becomes_authenticated_token`
- `scope_maps_to_scope_prefixed_authority`
- `roles_map_without_prefix`
- `wrong_issuer_is_rejected`