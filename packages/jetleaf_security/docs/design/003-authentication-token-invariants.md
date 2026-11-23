# 003 — Authentication token invariants

## Design reference
An `Authentication` contract and an `AbstractAuthenticationToken` base that model a principal's identity, authorities, and authenticated state.

## Problem
The current `Authentication` exposes `set isAuthenticated(bool)`, so any code holding an unauthenticated token can promote it to trusted. That is a direct privilege-escalation API.

## Invariant
1. `isAuthenticated` MUST have a getter; the setter is retained for API familiarity but is **revoke-only**.
2. Granting trust MUST be possible only through named factory constructors (`unauthenticated`, `authenticated`) or a constructor that takes authorities.
3. The setter MUST accept `false` but MUST throw `ArgumentError` when asked to set `true` — this matches the underlying token contract and closes the escalation hole without breaking the familiar API.
4. Authorities MUST be an immutable `Set<GrantedAuthority>` (roadmap contract), not a mutable `List`.
5. `eraseCredentials()` MUST null the credentials field on all token implementations.
6. Tokens MUST be value-equal by principal, authorities, and authenticated state.

## Extension seam
`Authentication` is an `abstract interface class`; users may implement custom tokens. `AuthenticationProvider.supports` MUST use assignability so subclasses work (record 005).

## Edge cases
Subclassed tokens; tokens constructed by third-party providers; `UserDetails` as principal; `name` resolution for a `UserDetails` principal; serialization into `details`; attempts to mutate the authorities collection after construction.

## Jetleaf mapping
Public names retained exactly. The current `List<GrantedAuthority>` is widened to `Set<GrantedAuthority>` per the roadmap; callers that need a list use `.toList()`. Value semantics via `with EqualsAndHashCode` and `equalizedProperties()`.

## Gating tests
- `unauthenticated_token_cannot_be_promoted` (fails today)
- `setAuthenticated_true_throws`
- `authorities_are_immutable`
- `erase_clears_credentials`
- `subclassed_token_is_supported_by_provider` (fails today)
