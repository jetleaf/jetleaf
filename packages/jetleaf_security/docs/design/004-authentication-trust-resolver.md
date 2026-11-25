# 004 — AuthenticationTrustResolver

## Design reference
An `AuthenticationTrustResolver` contract with a default `...Impl` that classifies tokens as anonymous, remember-me, or fully authenticated so access denials map to the correct HTTP status.

## Problem
`AnonymousAuthenticationToken.isAuthenticated` is `true`. Without distinguishing anonymous and remember-me principals from fully authenticated ones, `ExceptionTranslationFilter` returns 403 for unauthenticated users instead of 401, producing broken login redirects.

## Invariant
1. The resolver MUST expose `isAnonymous`, `isRememberMe`, and `isFullyAuthenticated`.
2. `ExceptionTranslationFilter` MUST use `isAnonymous`/`isRememberMe` to decide 401 vs 403 for an `AccessDeniedException`.
3. `isFullyAuthenticated` MUST be true only for a non-anonymous, non-remember-me, authenticated token.
4. A null authentication MUST be treated as anonymous for this decision.

## Extension seam
`AuthenticationTrustResolver` is a public interface supplied as a pod with `@ConditionalOnMissingPod`. Custom token types can be registered by replacing it.

## Edge cases
Anonymous token present but no `AnonymousAuthenticationFilter` configured (must not happen — filter creates it); remember-me token; `null` authentication; custom token implementing an interface rather than extending a base class.

## Jetleaf mapping
New interface and `...Impl` default. `AnonymousAuthenticationFilter` (record 011) is the only producer of `AnonymousAuthenticationToken`. No Jetleaf-specific complication.

## Gating tests
- `anonymous_denial_yields_401`
- `remember_me_denial_yields_401`
- `fully_authenticated_denial_yields_403`
- `null_authentication_is_anonymous`