# 005 — ProviderManager

## Design reference
A `ProviderManager` that delegates authentication across an ordered list of providers with consistent failure semantics, while never leaking plaintext credentials.

## Problem
Authentication must delegate across multiple strategies (DAO, JWT, OAuth2, API key) with consistent failure semantics, while never leaking plaintext credentials.

## Invariant
1. Iterate providers in order; the first non-null result wins.
2. `AccountStatusException` MUST be rethrown immediately, not masked by a later provider.
3. Other `AuthenticationException`s MUST be accumulated and the last one rethrown if no provider succeeds.
4. If a parent `AuthenticationManager` exists, it MUST be tried before failing.
5. Credentials MUST be erased from the successful result after authentication.
6. `AuthenticationProvider.supports(Authentication)` inspects the token instance with Dart's `is` operator. `ProviderManager` MUST consult it so token subclasses work. There is a single support predicate — no type-based variant.
7. An empty provider list without a parent MUST be rejected at construction.

## Extension seam
Providers are an ordered list supplied as a pod; users add providers by contributing additional `AuthenticationProvider` pods with `@Order`. `eraseCredentialsAfterAuthentication` is configurable.

## Edge cases
Provider returns a token with `isAuthenticated == false` (must be treated as failure); provider throws an unexpected runtime exception (must propagate); provider list mutated after construction (must be immutable snapshot); subclassed token.

## Jetleaf mapping
Existing `ProviderManager` is sound; harden `supports` and add events (record 006). No Jetleaf-specific primitive needed; it is a plain class exposed as a pod by auto-configuration.

## Gating tests
- `provider_manager_delegates_in_order`
- `account_status_exception_is_not_masked`
- `credentials_erased_after_authentication`
- `parent_manager_fallback`
- `subclassed_token_is_supported` (fails today)