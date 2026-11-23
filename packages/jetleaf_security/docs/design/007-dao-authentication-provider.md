# 007 — DaoAuthenticationProvider

## Design reference
A `DaoAuthenticationProvider` built on a `UserDetails`-based abstract provider model for username-and-password authentication.

## Problem
Username/password authentication must load a user, check all account-status flags, verify the password, and avoid leaking whether a username exists — without leaking the plaintext password onward.

## Invariant
1. A missing username MUST be masked as `BadCredentialsException` when `hideUserNotFoundExceptions` is true.
2. All four account-status checks MUST run in the canonical order: locked → disabled → account expired → credentials expired.
3. The raw password MUST be erased from the returned token before it leaves the provider (or the provider MUST require `ProviderManager`), and MUST never be stored in a loggable field.
4. `supports(Authentication)` MUST use Dart's `is` operator so token subclasses work.
5. An empty password MUST be rejected before any user lookup.
6. A `PasswordEncoder` MUST be required; a missing one MUST fail at construction, not at authentication time.

## Extension seam
`UserDetailsService`, `PasswordEncoder`, `UserDetailsChecker`s, and an authorities mapper are all injectable. Defaults are pods with `@ConditionalOnMissingPod`.

## Edge cases
Race between user load and account status change; `UserDetails` implementation with null authorities; hidden not-found vs hidden bad password being distinguishable by timing; password encoded with a legacy `{id}` prefix; null principal.

## Jetleaf mapping
Existing provider is sound; harden credential erasure and `supports`. Keep the public names. `UserDetailsService` is the database seam users override with a pod.

## Gating tests
- `account_status_checks_run_in_order`
- `username_not_found_is_masked`
- `returned_token_has_no_raw_password` (fails today when provider used directly)
- `empty_password_rejected_before_lookup`
- `missing_password_encoder_fails_at_construction`
