# 016 — AuthorizationManager family

## Design reference
An `AuthorizationManager<T>` contract with `AuthorizationDecision`, `AuthorityAuthorizationManager`, `AuthenticatedAuthorizationManager`, `RequestMatcherDelegatingAuthorizationManager`, and `AuthorizationManagers` combinators for shared, composable request and method authorization.

## Problem
Authorization logic is duplicated between request and method security in the current package, with two different context-construction paths. There is no shared, composable contract.

## Invariant
1. `AuthorizationManager<T>` MUST expose a single `AuthorizationDecision check(Supplier<Authentication> authentication, T context)`.
2. `AuthorizationDecision` MUST expose `isGranted()` and be immutable.
3. `AuthorityAuthorizationManager` and `AuthenticatedAuthorizationManager` MUST work for both request and method contexts.
4. `AuthorizationManagers.anyOf`/`allOf` MUST short-circuit correctly.
5. A null `Authentication` supplier MUST be handled as unauthenticated, never as a crash.
6. Method-security managers MUST receive the reflective `MethodInvocation` as context; request managers receive `RequestAuthorizationContext`.

## Extension seam
The interface is public; any user implementation can be supplied as a pod. Built-in managers are defaults with `@ConditionalOnMissingPod`.

## Edge cases
Combinator with an empty list; combinator whose first manager throws; role-prefix mismatch between `hasRole` and token authorities; `ROLE_` double-prefixing.

## Jetleaf mapping
New package surface with familiar names. No container-specific types. `Supplier<Authentication>` is a plain `Authentication Function()`; Dart's `Future` is not needed because context is zone-bound synchronously.

## Gating tests
- `authority_manager_grants_matching_role`
- `authenticated_manager_denies_anonymous`
- `any_of_short_circuits`
- `all_of_denies_on_first_failure`
- `null_authentication_is_handled`
