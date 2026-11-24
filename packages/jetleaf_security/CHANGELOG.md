# Changelog

## 1.0.0

Initial stable release of **Jetleaf Security**—bringing Spring-inspired authentication, authorization, session management, and cryptographic security primitives to the Jetleaf framework.

### Features
- **In-House JWT & JWS Engine:** Zero third-party JWT dependencies, powered by a built-in base64url, JWK, and HMAC/RSA/ECDSA JWS engine and validator chain built on `pointycastle` and `crypto`.
- **Typed Authorization Model:** `AuthorizationManager<T>` for fine-grained request and method-level access control.
- **Method Security Interceptors:** `AuthorizationManagerBeforeMethodInterceptor` and `AuthorizationManagerAfterMethodInterceptor` registered automatically as Jetleaf pods (requires `jl build` generated proxies on non-final secured classes).
- **Auto-Configuration:** `SecurityAutoConfiguration` and `MethodSecurityAutoConfiguration` with `@ConditionalOnMissingPod` defaults for out-of-the-box setup and seamless overrides.
- **Multi-Chain Request Filtering:** `FilterChainProxy` supporting ordered multi-chain security selection.
- **Session & Context Management:** Complete `SecurityContextRepository` family, `SessionCreationPolicy` enforcement, `SessionAuthenticationStrategy` implementations, `SessionRegistry`, and `AuthenticationTrustResolver`.
- **Password Encoding:** `DelegatingPasswordEncoder` supporting `{id}` prefix routing and asynchronous hashing APIs.
- **OAuth2 & OIDC Hardening:** Built-in OIDC `nonce` validation (including Google `azp` verification) and strict verified-email checks for GitHub authentication.
- **CSRF & Immutable Auth Primitives:** JSON `403` responses on CSRF denials, immutable `Authentication.authorities` sets, and revoke-only trust semantics.
- **Modular Exports & Test Suite:** Ten focused `lib/` barrel files for selective imports, backed by published cryptographic test vectors and adversarial security tests.

See `README.md` for configuration examples and API conventions.