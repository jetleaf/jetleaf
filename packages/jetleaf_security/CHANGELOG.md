# Changelog

## 1.0.0

**Breaking rewrite.** This release replaces the earlier untracked implementation.
The public class names keep their familiar shape, but the internals,
API surface and runtime behaviour changed substantially.

### Added
- Zero third-party JWT dependency: in-house base64url, JWK, HMAC/RSA/ECDSA JWS
  engine and validator chain on `pointycastle` and `crypto`.
- Typed `AuthorizationManager<T>` model for request and method security.
- Real `AuthorizationManagerBeforeMethodInterceptor` /
  `AuthorizationManagerAfterMethodInterceptor` registered as Jetleaf pods.
- `SecurityAutoConfiguration` and `MethodSecurityAutoConfiguration` with
  `@ConditionalOnMissingPod` defaults.
- `FilterChainProxy` with ordered multi-chain selection.
- `SecurityContextRepository` family, `AuthenticationTrustResolver`,
  `SessionAuthenticationStrategy` family, `SessionRegistry`.
- `DelegatingPasswordEncoder` with `{id}` prefixes and async hashing APIs.
- Ten `lib/` barrels for selective imports.
- Published cryptographic vectors and adversarial tests.

### Changed
- `Authentication.authorities` is an immutable `Set`; the trust setter is
  revoke-only.
- Authorization expressions are no longer used for request matchers.
- `SessionCreationPolicy` now selects real repository and session behaviour.
- CSRF denials render a JSON 403 directly.
- OIDC providers validate `nonce` (and Google `azp`); GitHub no longer asserts
  unverified emails.
- `dart_jsonwebtoken` removed from dependencies.

### Migration
See the API conventions in `README.md` and the rewrite
specification at `roadmap/jetleaf_security_rewrite.md`. Secured classes require
`jl build` generated proxies and must not be final.
