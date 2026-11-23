# 027 — OIDC ID token validation

## Design reference
`OidcIdToken` validation with an `OidcIdTokenValidator` and nonce handling for login flows.

## Problem
`OidcIdToken.nonce` exists in the current package but is never validated. Provider-specific verification also accepts a bare `accounts.google.com` issuer and does not check `azp`, and GitHub's provider asserts `emailVerified` from mere email presence.

## Invariant
1. When an OIDC ID token carries a `nonce`, it MUST be compared to the nonce associated with the authentication request; a missing or mismatched nonce MUST be rejected.
2. Issuer MUST be matched against an explicit allowlist; bare hostnames MUST NOT be accepted as valid issuers.
3. Google `azp` MUST be checked when present.
4. Email verification MUST reflect the provider's actual claim; where the provider does not expose one, the value MUST be `false`.
5. All providers MUST share the in-house JWT validator chain (record 022).

## Extension seam
Provider verifiers are pods with `@ConditionalOnMissingPod`; users add custom providers.

## Edge cases
Replayed ID token; nonce claim missing because the provider does not issue one; `email_verified` as string `"true"` vs boolean; JWKS rotation; `aud` as a list.

## Jetleaf mapping
Keep provider class names. Use `OidcIdToken` and the shared validator. No third-party JWT dependency.

## Gating tests
- `missing_nonce_rejected_when_expected`
- `mismatched_nonce_rejected`
- `bare_issuer_rejected`
- `google_azp_mismatch_rejected`
- `github_email_not_marked_verified` (fails today)
