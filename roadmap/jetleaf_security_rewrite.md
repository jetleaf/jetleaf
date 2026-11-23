# `jetleaf_security` — Rewrite Specification

> **Status:** Canonical execution specification. Supersedes the _implementation_ guidance in `roadmap/jetleaf_security.md` (the feature inventory in that document remains the scope target). **Package:** `packages/jetleaf_security` **Audience:** Any engineer or agent assigned to implement, review, or verify this package. **Architectural benchmark:** a conventional security filter-chain model with a lambda DSL, implemented on Jetleaf's own IoC/AOP/filter infrastructure. **Governing value:** Correctness first. Duration is not a constraint; an incorrect implementation is.

---

## 0. How to read this document

This document is a **directive**, not a suggestion list. It states what must be built, why, in what order, and how completion is proven.

- **MUST** — required. Absence is a defect, not a scope decision.
- **SHOULD** — strongly preferred; deviation requires a written note in the design ledger.
- **DO NOT** — prohibited. These are the mistakes that produced the current rejected implementation.
- **Deliverable / Exit criteria** — the phase is not complete until these exist and pass.

All design decisions are recorded in `docs/design/` inside the package (see §6). If implementation reveals a need to deviate from this document, **update the ledger first, then the code.**

---

## 1. Why we are rewriting

### 1.1 Current state

`packages/jetleaf_security/` is untracked and unreleased. It contains 57 Dart files (~4,700 lines) and 7 test files (19 tests). `dart analyze` is clean and all tests pass. **This is the problem, not a mitigating fact** — the suite validates the library's own API surface while its headline features do not function.

### 1.2 Root-cause diagnosis

The current package is **framework-shaped but framework-detached**. It reproduces a familiar _class list_ without binding to Jetleaf's runtime:

1. Zero `@Pod`, `@Configuration`, `@AutoConfiguration`, `@ConditionalOnMissingPod` annotations in `lib/`. Nothing is registered with the IoC container.
2. `@PreAuthorize`, `@PostAuthorize`, `@Secured`, `@RolesAllowed`, `@EnableWebSecurity`, `@EnableMethodSecurity` are plain Dart classes. They are not `ReflectableAnnotation`s and have no `@Target`, so Jetleaf's reflection registry cannot read them.
3. `MethodSecurityInterceptor` is a plain helper with no `canIntercept(Method)` and is never registered with `DefaultMethodInterceptor`. The example calls it by hand at `example/lib/main.dart:88-102`.
4. `SecurityFilterChain` implements `jetleaf_web`'s `Filter` but is never registered with `FilterManager`. The example drives it with a hand-made `_ExampleRequest`/`_ExampleResponse` and a fake chain, so it has never run through the real dispatcher.
5. The DSL compiles typed calls into strings (`"hasRole('ADMIN')"`) and re-parses them at request time with a 372-line homegrown parser.
6. `SessionCreationPolicy` is stored and never read. `EnableWebSecurity.debug` is dead.
7. CORS/CSRF are reimplemented despite `jetleaf_web` shipping DI-integrated versions.
8. Two JWT stacks coexist: hand-rolled encoder/decoder/validator plus a `dart_jsonwebtoken` dependency.

### 1.3 What is genuinely reusable — DO NOT rewrite these

Preserve and harden (with the tests specified in §9):

- `crypto/bcrypt_password_encoder.dart` — complete Eksblowfish port, correct radix64, 72-byte truncation.
- `crypto/argon2id_password_encoder.dart` and `crypto/pbkdf2_password_encoder.dart` — correct pointycastle usage and PHC parsing.
- `core/exceptions.dart` — clean const exception hierarchy.
- `auth/provider_manager.dart` — provider iteration, parent delegation, account-status rethrow, credential erasure.
- `auth/dao_authentication_provider.dart` — four account-status checks and masked not-found.
- `authorization/role_hierarchy.dart` — correct BFS expansion.
- `filter/security_context_holder_filter.dart` — correct zone bracketing pattern.
- `filter/security_filter_chain.dart` `_VirtualFilterChain` — correct chain mechanics.
- `authorization/authentication_entry_point.dart`, `authorization/access_denied_handler.dart` — sensible 401/403 output.
- `test/helpers/mock_http.dart` — reusable for unit tests (but NOT sufficient as the only integration mechanism).

Everything else in `lib/` is to be replaced or substantially rewritten.

### 1.4 Known defects to eliminate

The implementing agent must treat each of these as a regression test to add:

| # | Defect |
| --- | --- |
| 1 | `Authentication` exposes a public `set isAuthenticated(bool)` — any token holder can self-escalate. The canonical `AbstractAuthenticationToken.setAuthenticated(true)` **throws**; only revocation is allowed. |
| 2 | `JwtTokenProvider.hmac(audience:)` configures the validator but never emits `aud` on issued tokens. The existing test manually injects `aud`, hiding this. |
| 3 | `JwtTokenProvider.authenticate()` accepts refresh tokens as authentication credentials. |
| 4 | `iat` is never validated; tokens with no `exp` are accepted indefinitely. |
| 5 | `JwtValidator.expectedAudience` is a single `String` while `JwtClaimsSet.audience` supports lists. |
| 6 | JWKS accepts any JWK including `kty: 'oct'`; no `alg`/`use` allowlist; unknown `kid` triggers an HTTP fetch per request; refresh is not concurrency-safe; non-200 responses silently keep stale keys. |
| 7 | `CsrfFilter` (order −70) throws `InvalidCsrfTokenException` outside `ExceptionTranslationFilter` (−65), so CSRF denials are never translated to JSON 403. |
| 8 | `CorsFilter` short-circuits preflight without validating `Access-Control-Request-Method`/`Headers` against the allow-list. |
| 9 | `RateLimitingFilter` trusts client-supplied `X-Forwarded-For`, collapses all clients without it into one bucket, and grows its map without bound. |
| 10 | `PathPatternMatcher._compileAnt` over-matches `/api/**`-style patterns. |
| 11 | `AuthorizedUrl` terminals return `void`, so the roadmap's own chained DSL example does not compile. Expression strings are built by naive quote concatenation (expression injection). |
| 12 | `SecurityExpressionParser` cannot parse `hasAnyRole(['A','B'])`; `principal.property`/`returnObject.property` resolve only on `Map`, so the roadmap's §7 examples evaluate to `null`. |
| 13 | `DaoAuthenticationProvider` returns a token with the raw password in `credentials`; safety depends on the caller using `ProviderManager`. |
| 14 | Provider support checks used exact `runtimeType` equality, so token subclasses were unsupported. |
| 15 | Anonymous token has `isAuthenticated == true`; without an `AuthenticationTrustResolver`, unauthenticated denials become 403 instead of 401. |
| 16 | No `AnonymousAuthenticationFilter` exists to ever create an anonymous token. |
| 17 | Argon2/PBKDF2 parse unbounded `m`/`t`/`p`/iterations from stored hashes (CPU/memory DoS); bcrypt accepts strength 31 (`1 << 31` rounds) and its base64 decoder ignores an invalid 4th character. |
| 18 | All password hashing is synchronous; 64 MiB Argon2id blocks the isolate event loop. |
| 19 | OIDC `nonce` is exposed but never validated; Google accepts a bare `accounts.google.com` issuer and does not check `azp`. |
| 20 | `GitHubOAuth2Provider` sets `emailVerified: email != null` — factually incorrect. |
| 21 | `pointycastle` is pinned to a two-major range (`>=3.9.0 <5.0.0`) for a security primitive. |
| 22 | README (12 lines), CHANGELOG (5 lines), and the console-only example are stubs. |

---

## 2. Goals and scope

### 2.1 Goals

1. **Production correctness.** Every security invariant established by hard-won industry experience is present and tested.
2. **Familiar developer experience.** Keep conventional public names, a lambda DSL, and established vocabulary so developers can adopt the package without relearning concepts.
3. **Native Jetleaf integration.** Every component is an overridable pod; method security runs through Jetleaf's proxy/`MethodInterceptor` infrastructure; request security runs through `FilterManager` and `GlobalServerDispatcher`.
4. **Extensibility by default.** No sealed internals. Users can replace any default without modifying framework code.
5. **Layering.** Dependencies point inward. Core domain has no web dependency.

### 2.2 Pass A and Pass B — what the split means

"Pass A" and "Pass B" are **sequencing, not permanent exclusion**. Pass A is the first delivery: it builds the entire architecture and every core capability, proves it with the full §8 gate suite, and ships it. Pass B then extends the same architecture with the remaining integrations. Nothing in Pass B requires re-architecting Pass A — the names and extension seams are reserved now so Pass B is additive.

**Pass A (this rewrite) includes:** all of §1's scope, including the complete session story (all four `SessionCreationPolicy` states, session-backed `SecurityContextRepository`, session-fixation protection), method security, JWT, and OAuth2/OIDC **resource-server** verification.

**Pass B (additive, after Pass A is green):**

- Full OAuth2 **client** flow — i.e. *your app* redirecting users to Google/GitHub/etc. to log in, handling the authorization-code callback, exchanging the code for tokens, storing authorized clients, and federated logout. This is distinct from what Pass A does, which is **validating incoming bearer tokens** issued by an identity provider. Resource-server verification is a filter; client login is a whole set of redirect/callback filters and repositories.
- SAML, LDAP, remember-me, X.509, JAAS, CAS.
- Distributed rate limiting (Redis) — design the interface so it can be added; the in-memory implementation must be hardened now.
- A general-purpose expression language — the parser supports a narrow security grammar only.

Names for every Pass B item are reserved in §4.3 now. Do not implement them in Pass A, but do not paint the architecture into a corner that would require renaming later.

---

## 3. Governing principles

1. **Familiar names at the boundary, Jetleaf primitives underneath.** A developer writes `HttpSecurity`, `ProviderManager`, `@PreAuthorize`. The implementation uses `@Pod`, `Filter`, `MethodInterceptor`, Zones.
2. **Invariants over class lists.** Every abstraction must encode a rule that prevents a real failure; if it cannot name the failure it prevents, do not add it.
3. **Ledger-first.** For each component, write its design record (§6) before its code.
4. **No string round-trips for configuration.** Request authorization is built from typed objects. Expression strings exist only for annotation-based authorization and are compiled to an AST once at startup and cached.
5. **No mutable process-global security state.** Context lives in a forked Zone with an immutable binding, following `ZoneTransactionHolder`.
6. **Overridable by default.** Every framework default is a `@Pod` guarded by `@ConditionalOnMissingPod`; ordering via `@Order`/`Ordered`; disambiguation via `@Primary`/`@Qualifier`.
7. **Tests are the contract.** Each ledger invariant maps to at least one test. Integration tests use the real dispatcher and real proxies.
8. **Crypto is never trusted without external vectors.** No crypto internals change without published known-answer tests.

---

## 4. Target architecture

### 4.1 Layering (dependency direction is inward only)

```text
┌─────────────────────────────────────────────────────────────────┐
│ config/   HttpSecurity, SecurityConfigurer, AutoConfiguration   │
│           two-phase init/configure, ObjectPostProcessor         │
├─────────────────────────────────────────────────────────────────┤
│ filter/   FilterChainProxy, ordered filters, HeaderWriters      │
├─────────────────────────────────────────────────────────────────┤
│ authorization/  AuthorizationManager, method managers, AST      │
│ auth/           AuthenticationManager, providers, tokens       │
│ jwt/ oauth2/    provider adapters built on core contracts       │
├─────────────────────────────────────────────────────────────────┤
│ crypto/   PasswordEncoder family (no web/core-IoC dependency)   │
├─────────────────────────────────────────────────────────────────┤
│ core/     Domain, invariants, context strategy, repositories    │
└─────────────────────────────────────────────────────────────────┘
```

`core/` may depend on `jetleaf_core` only (for `EqualsAndHashCode`, reflection types, Zone patterns). `filter/` depends on `jetleaf_web`. No lower layer imports a higher one.

### 4.2 Required file layout

Keep the roadmap's directory names and the established type names. New files are marked **NEW**; rewritten files **REWRITE**; preserved-and-hardened files **KEEP**.

```text
packages/jetleaf_security/
├── pubspec.yaml
├── README.md                                  # API conventions and migration notes
├── CHANGELOG.md
├── docs/design/                               # the design ledger (§6)
│   ├── 000-template.md
│   └── 001-security-context.md ...
├── lib/
│   ├── jetleaf_security.dart                  # unified barrel (keep)
│   ├── authentication.dart                    # NEW secondary barrel (optional)
│   ├── config.dart                            # NEW secondary barrel (optional)
│   └── src/
│       ├── core/
│       │   ├── authentication.dart                       REWRITE (revoke-only)
│       │   ├── authentication_trust_resolver.dart        NEW
│       │   ├── granted_authority.dart                    KEEP
│       │   ├── simple_granted_authority.dart             KEEP
│       │   ├── security_context.dart                     KEEP
│       │   ├── security_context_holder.dart              REWRITE (forked Zone)
│       │   ├── security_context_repository.dart          NEW
│       │   ├── null_security_context_repository.dart     NEW
│       │   ├── http_session_security_context_repository.dart NEW (familiar name)
│       │   ├── deferred_security_context.dart            NEW
│       │   ├── user_details.dart                         KEEP (immutable)
│       │   ├── user_details_service.dart                 KEEP
│       │   ├── in_memory_user_details_manager.dart       KEEP
│       │   └── exceptions.dart                           KEEP
│       ├── crypto/
│       │   ├── password_encoder.dart                     KEEP
│       │   ├── delegating_password_encoder.dart          NEW
│       │   ├── password_encoder_factories.dart           NEW
│       │   ├── argon2id_password_encoder.dart            KEEP + harden
│       │   ├── bcrypt_password_encoder.dart              KEEP + harden
│       │   └── pbkdf2_password_encoder.dart              KEEP + harden
│       ├── auth/
│       │   ├── authentication_manager.dart               KEEP
│       │   ├── authentication_provider.dart              KEEP (isAssignableFrom)
│       │   ├── provider_manager.dart                     KEEP + harden
│       │   ├── dao_authentication_provider.dart          KEEP + harden
│       │   ├── username_password_authentication_token.dart KEEP
│       │   ├── anonymous_authentication_token.dart       KEEP
│       │   ├── authentication_event_publisher.dart       NEW
│       │   ├── session_authentication_strategy.dart      NEW (familiar name)
│       │   ├── session_fixation_protection_strategy.dart NEW
│       │   ├── change_session_id_authentication_strategy.dart NEW
│       │   ├── composite_session_authentication_strategy.dart NEW
│       │   ├── session_information.dart                  NEW
│       │   └── session_registry.dart                     NEW
│       ├── authorization/
│       │   ├── annotations.dart                          REWRITE (ReflectableAnnotation)
│       │   ├── authorization_manager.dart                NEW
│       │   ├── authorization_decision.dart               NEW
│       │   ├── authority_authorization_manager.dart      NEW
│       │   ├── authenticated_authorization_manager.dart  NEW
│       │   ├── request_matcher_delegating_authorization_manager.dart NEW
│       │   ├── authorization_managers.dart               NEW (anyOf/allOf)
│       │   ├── expression/
│       │   │   ├── security_expression_handler.dart      NEW
│       │   │   ├── security_expression_parser.dart       NEW (moved, AST)
│       │   │   ├── security_expression_root.dart         NEW
│       │   │   └── method_security_evaluation_context.dart NEW
│       │   ├── method/
│       │   │   ├── method_security_metadata_source.dart  NEW
│       │   │   ├── pre_post_annotation_security_metadata_source.dart NEW
│       │   │   ├── pre_authorize_authorization_manager.dart NEW
│       │   │   ├── post_authorize_authorization_manager.dart NEW
│       │   │   ├── secured_authorization_manager.dart    NEW
│       │   │   ├── jsr250_authorization_manager.dart     NEW
│       │   │   ├── authorization_manager_before_method_interceptor.dart NEW
│       │   │   ├── authorization_manager_after_method_interceptor.dart NEW
│       │   │   └── method_security_interceptor.dart      KEEP as facade
│       │   ├── role_hierarchy.dart                       KEEP
│       │   ├── access_denied_handler.dart                KEEP
│       │   └── authentication_entry_point.dart           KEEP
│       ├── filter/
│       │   ├── security_filter.dart                      KEEP
│       │   ├── security_filter_chain.dart                REWRITE
│       │   ├── filter_chain_proxy.dart                   NEW
│       │   ├── virtual_filter_chain.dart                 NEW (extracted)
│       │   ├── once_per_request_filter.dart              NEW
│       │   ├── cors_filter.dart                          REMOVE — delegate to jetleaf_web
│       │   ├── csrf_filter.dart                          REWRITE (own AccessDeniedHandler)
│       │   ├── security_headers_filter.dart              REWRITE
│       │   ├── header_writer.dart                        NEW
│       │   ├── rate_limiting_filter.dart                 REWRITE
│       │   ├── authentication_filter.dart                REWRITE
│       │   ├── bearer_token_authentication_filter.dart   NEW (familiar name)
│       │   ├── anonymous_authentication_filter.dart      NEW
│       │   ├── session_management_filter.dart            NEW (familiar name)
│       │   ├── authorization_filter.dart                 REWRITE
│       │   ├── exception_translation_filter.dart         REWRITE
│       │   └── security_context_holder_filter.dart       KEEP + harden
│       ├── config/
│       │   ├── security_builder.dart                     NEW
│       │   ├── security_configurer.dart                  NEW
│       │   ├── shared_objects.dart                       NEW
│       │   ├── object_post_processor.dart                NEW
│       │   ├── http_security.dart                        REWRITE
│       │   ├── security_filter_chain_builder.dart        KEEP as concrete builder
│       │   ├── configurers/
│       │   │   ├── csrf_configurer.dart                  NEW
│       │   │   ├── cors_configurer.dart                  NEW
│       │   │   ├── session_management_configurer.dart    NEW
│       │   │   ├── exception_handling_configurer.dart    NEW
│       │   │   ├── authorize_http_requests_configurer.dart NEW
│       │   │   ├── headers_configurer.dart               NEW
│       │   │   ├── anonymous_configurer.dart             NEW
│       │   │   ├── logout_configurer.dart                NEW (reserve name)
│       │   │   ├── jwt_configurer.dart                   NEW
│       │   │   ├── oauth2_resource_server_configurer.dart NEW
│       │   │   └── rate_limiting_configurer.dart         NEW
│       │   ├── cors_configuration.dart                   KEEP
│       │   ├── csrf_configuration.dart                   KEEP
│       │   ├── session_creation_policy.dart              KEEP (now consumed)
│       │   ├── enable_web_security.dart                  REWRITE (ReflectableAnnotation)
│       │   ├── enable_method_security.dart               NEW
│       │   ├── security_auto_configuration.dart          NEW
│       │   └── method_security_auto_configuration.dart   NEW
│       ├── jwt/
│       │   ├── jwt_encoder.dart                          KEEP
│       │   ├── jwt_decoder.dart                          REWRITE
│       │   ├── jwt_claims_set.dart                       KEEP
│       │   ├── jwt_validator.dart                        REWRITE
│       │   ├── jwt_validators.dart                       NEW
│       │   ├── oauth2_token_validator.dart               NEW
│       │   ├── jwt_timestamp_validator.dart              NEW
│       │   ├── jwt_issuer_validator.dart                 NEW
│       │   ├── jwt_audience_validator.dart               NEW
│       │   ├── jws_algorithms.dart                       NEW (allowlist)
│       │   ├── jwt_signer.dart                           NEW (in-house, pointycastle)
│       │   │   # HMAC + RSA PKCS#1 v1.5 + ECDSA; one entry per algorithm family
│       │   ├── jwt_verifier.dart                         NEW (in-house)
│       │   ├── jwt_base64_url.dart                       NEW (no third-party)
│       │   ├── jwk.dart                                  NEW (JWK/JWKSet model)
│       │   ├── p1363_signature_codec.dart                NEW (DER ↔ raw R‖S)
│       │   ├── jwt_authentication_token.dart             KEEP
│       │   ├── jwt_token_provider.dart                   KEEP as convenience
│       │   └── jwk_set_source.dart                       REWRITE
│       └── oauth2/
│           ├── oauth2_resource_server.dart               REWRITE (as AuthenticationProvider)
│           ├── oidc_id_token.dart                        KEEP + nonce validation
│           ├── oauth2_authentication_token.dart          KEEP
│           ├── oauth2_user.dart                          KEEP
│           ├── oauth2_authorities_converter.dart         NEW (familiar name)
│           └── providers/{google,apple,github}_oauth2_provider.dart KEEP + harden
└── test/
    ├── unit/...                       # follows the lib/ structure
    ├── integration/
    │   ├── dispatcher_security_test.dart
    │   ├── method_security_proxy_test.dart
    │   └── multiple_filter_chains_test.dart
    ├── vectors/...                    # external crypto vectors
    └── adversarial/...                # attack & edge-case suite
```

### 4.3 Public naming contract

**Public names that MUST be preserved** (existing or newly added):

- Core: `Authentication`, `GrantedAuthority`, `SimpleGrantedAuthority`, `SecurityContext`, `SecurityContextHolder`, `SecurityContextRepository`, `NullSecurityContextRepository`, `HttpSessionSecurityContextRepository`, `AuthenticationTrustResolver`, `UserDetails`, `UserDetailsService`, `InMemoryUserDetailsManager`.
- Auth: `AuthenticationManager`, `AuthenticationProvider`, `ProviderManager`, `DaoAuthenticationProvider`, `UsernamePasswordAuthenticationToken`, `AnonymousAuthenticationToken`, `AuthenticationEventPublisher`, `SessionAuthenticationStrategy`, `SessionFixationProtectionStrategy`, `ChangeSessionIdAuthenticationStrategy`, `CompositeSessionAuthenticationStrategy`, `SessionRegistry`, `SessionInformation`.
- Session filter: `SessionManagementFilter`.
- Authorization: `AuthorizationManager`, `AuthorizationDecision`, `AuthorityAuthorizationManager`, `AuthenticatedAuthorizationManager`, `RequestMatcherDelegatingAuthorizationManager`, `AuthorizationManagers`, `AuthorizationFilter`, `MethodSecurityInterceptor` (facade), `AuthorizationManagerBeforeMethodInterceptor`, `AuthorizationManagerAfterMethodInterceptor`, `PreAuthorizeAuthorizationManager`, `PostAuthorizeAuthorizationManager`, `SecuredAuthorizationManager`, `Jsr250AuthorizationManager`, `MethodSecurityMetadataSource`, `SecurityExpressionHandler`, `RoleHierarchy`, `AuthenticationEntryPoint`, `AccessDeniedHandler`.
- Filter: `SecurityFilterChain`, `FilterChainProxy`, `OncePerRequestFilter`, `BearerTokenAuthenticationFilter`, `CsrfFilter`, `HeaderWriterFilter`, `SecurityContextHolderFilter`, `AnonymousAuthenticationFilter`, `ExceptionTranslationFilter`.
- Config: `HttpSecurity`, `SecurityConfigurer`, `SecurityBuilder`, `SharedObjects`, `ObjectPostProcessor`, `AuthorizeHttpRequestsConfigurer`, `CsrfConfigurer`, `CorsConfigurer`, `SessionManagementConfigurer`, `ExceptionHandlingConfigurer`, `HeadersConfigurer`, `OAuth2ResourceServerConfigurer`, `EnableWebSecurity`, `EnableMethodSecurity`, `SessionCreationPolicy`.
- Crypto: `PasswordEncoder`, `DelegatingPasswordEncoder`, `PasswordEncoderFactories`, `BCryptPasswordEncoder`, `Pbkdf2PasswordEncoder`.
- JWT/OAuth2: `JwtEncoder`, `JwtDecoder`, `JwtClaimsSet`, `JwtValidators`, `OAuth2TokenValidator`, `JwtTimestampValidator`, `JwtIssuerValidator`, `JwtAuthenticationToken`, `JwtTokenProvider`, `JwkSource`, `OAuth2ResourceServer`, `OAuth2AuthenticationToken`, `OAuth2User`, `OidcIdToken`, `OAuth2AuthoritiesConverter`.

**Decisions already taken by the project owner:**

- Keep **both** `MethodSecurityInterceptor` (public facade, legacy name) **and** the real `AuthorizationManagerBeforeMethodInterceptor` / `AuthorizationManagerAfterMethodInterceptor` classes.
- Keep **`Argon2idPasswordEncoder`** as the class name (roadmap); document that it names the exact algorithm in the README. Do not add an alias class.

**Deliberate deviations — document each in README's API conventions table:**

`SecurityContextHolder` uses Zone, not `ThreadLocal`; `Filter` is `jetleaf_web.Filter`; `SecurityFilterChain` is contributed via `FilterManager`; `@Pod`/`@AutoConfiguration` replace bean declarations; `RateLimitingFilter` and `JwtTokenProvider` are package-specific additions; `SecurityHeadersFilter` remains the public name but composes `HeaderWriter`s.

**Vocabulary rule:** DO NOT rename familiar security concepts into Jetleaf-flavoured ones. No `Identity` for `Authentication`, no `Permission` for `GrantedAuthority`, no `SecurityHttp` for `HttpSecurity`. Code, docs, tests, and examples use the established security vocabulary.

### 4.4 Extensibility mechanisms

- **Container:** every default is a `@Pod` in an `@AutoConfiguration` class, guarded by `@ConditionalOnMissingPod`. Use `@Primary` for defaults that should win when users add their own, `@Qualifier`/`@Order` for disambiguation.
- **`ObjectPostProcessor<T>`:** define the fluent interface in `config/object_post_processor.dart` and apply it to every object `HttpSecurity` builds. Bridge to Jetleaf `PodPostProcessor` for container-created pods.
- **`SecurityConfigurer<O, B>`:** use a two-phase `init(B builder)` / `configure(O object)` model. Configurers are ordered via `@Order`. Shared state lives in `SharedObjects` backed by `ApplicationContext`.
- **Events:** if Jetleaf exposes an application event publisher, publish named events (`AuthenticationSuccessEvent`, `AuthenticationFailureEvent`, `InteractiveAuthenticationSuccessEvent`, `AuthorizationEventPublisher` equivalent). Otherwise define `AuthenticationEventPublisher` with a no-op default pod.
- **Annotations:** all annotations extend `ReflectableAnnotation`, declare `@Target`, override `annotationType` and `equalizedProperties`, and are read with `getDirectAnnotation<T>()` / `getAnnotations<T>()` from `jetleaf_core/lang.dart`.

### 4.5 Public export policy (mandatory)

**`export` directives exist only in files directly under `lib/`. No file under `lib/src/` may contain `export`.** Internal files use `import` only. This keeps the public surface auditable in one place and lets developers import only what they need.

Required barrels, all at `lib/` root:

| Barrel | Exports |
|---|---|
| `jetleaf_security.dart` | everything — the full unified surface (existing barrel, keep) |
| `core.dart` | domain, context, repositories, trust resolver, exceptions |
| `authentication.dart` | manager, providers, tokens, `UserDetails*`, session strategies |
| `authorization.dart` | authorization managers, expression API, method security, role hierarchy, handlers |
| `annotation.dart` | `@PreAuthorize`, `@PostAuthorize`, `@Secured`, `@RolesAllowed`, `@EnableWebSecurity`, `@EnableMethodSecurity` |
| `crypto.dart` | all password encoders and factories |
| `filter.dart` | `Filter`, `FilterChain`, `SecurityFilterChain`, concrete filters |
| `config.dart` | `HttpSecurity`, configurers, builder, `SecurityConfigurer`, `ObjectPostProcessor`, `SessionCreationPolicy`, auto-configuration |
| `jwt.dart` | JWT and JWK API |
| `oauth2.dart` | OAuth2/OIDC resource-server API and provider verifiers |

Each barrel MUST have a library-level Dartdoc comment and a grouped, ordered `export` list, following the convention of `libraries/jetleaf_core/lib/annotation.dart` and `packages/jetleaf_web/lib/server.dart`. Avoid overlapping exports where possible; where an overlap is unavoidable (e.g. `jetleaf_security.dart`), it must be intentional and documented.

---

## 5. Jetleaf infrastructure the implementation MUST use

These are real APIs in this repository; the implementing agent must read them before writing code.

| Concern | Jetleaf primitive | Location |
| --- | --- | --- |
| Bean registration | `@Pod` (factory method), `@Configuration`, `@AutoConfiguration`, `@ConditionalOnMissingPod`, `@Primary`, `@Order`, `@Qualifier` | `libraries/jetleaf_core/lib/src/core/annotations/` (barrel `annotation.dart`) |
| Container lifecycle | `InitializingPod`, `SmartInitializingSingleton`, `PodPostProcessor`, `PodFactoryAware` | `libraries/jetleaf_core/lib/src/pod/`, `.../context/` |
| Request/response | `ServerHttpRequest`, `ServerHttpResponse`, `HttpHeaders`, `HttpCookie`, `HttpSession` | `packages/jetleaf_web/lib/src/server/`, `.../http/` |
| Filters | `Filter`, `FilterChain`, `OncePerRequestFilter`, `FilterManager` | `packages/jetleaf_web/lib/src/server/filter/` |
| Dispatch | `GlobalServerDispatcher.doDispatch()` drives `FilterManager.getFilters()` | `packages/jetleaf_web/lib/src/server/dispatcher/global_server_dispatcher.dart:194-212` |
| AOP contracts | `Interceptable.when()`, `MethodInterceptor`, `AroundMethodInterceptor`, `MethodBeforeInterceptor`, `AfterReturningInterceptor`, `MethodInvocation.proceed()/hijack()`, `MethodInterceptorRegistry` | `libraries/jetleaf_core/lib/src/core/intercept/` (barrel `intercept.dart`) |
| AOP registration | `DefaultMethodInterceptor.processAfterInitialization()` injects `support` into `$$JLInterfaced$$` proxies | `.../intercept/default_method_interceptor.dart:205-221` |
| Proxy generation | `jetleaf_tools` AOT generator; `Constant.PROXY_IDENTIFIER == '$$JLInterfaced$$'` | `libraries/jetleaf_tools/`, `libraries/jetleaf_core/lib/src/lang/utils/constant.dart:161` |
| Reflection | `Class`, `Method`, `Field`, `Parameter`, `getDirectAnnotation<A>()` | `package:jetleaf_core/lang.dart` |
| Zone pattern | `ZoneTransactionHolder` (fork-based, `const Symbol` key) | `packages/jetleaf_data/lib/src/transaction/zone_transaction_holder.dart` |
| Existing CORS/CSRF | DI-registered `CorsFilter`, `CsrfFilter` \+ token repositories | `packages/jetleaf_web/lib/src/cors/`, `.../csrf/`, `.../config/*_auto_configuration.dart` |
| Ordering | `AnnotationAwareOrderComparator` | `libraries/jetleaf_core/lib/src/core/annotation_aware_order_comparator.dart` |
| Style | snake\_case files, `{@template}`/`{@macro}` docs, `with EqualsAndHashCode`, uppercase static constants | root `analysis_options.yaml` |

**DO NOT** reimplement CORS/CSRF filters, filter sorting, annotation reflection, or proxy creation. Delegate or extend.

### 5.1 Verified framework constraints (Phase 0 research)

These are confirmed facts, not assumptions. Ledger records 009, 010, 013, 017, 019 and 031 have been updated accordingly.

1. **Proxy generation is CLI-driven, not `build_runner`.** There is no `build.yaml`. Users run `jl build` or `jl proxy` from `jetleaf_tools`. Eligible stereotypes include `RestController`, `Controller`, `Service`, `Component`, `Configuration`, `Pod`. Output goes to `lib/_jetleaf/proxies/`. **`final`, `sealed` and `mixin class` targets are skipped.**
2. **No proxy ⇒ no interception, silently.** `DefaultMethodInterceptor.processAfterInitialization()` returns the plain pod when no `$$JLInterfaced$$` subclass exists. There is no runtime fallback. This must be a documented hard requirement and a build-level integration test.
3. **Parameter names survive AOT generation.** `Parameter.getName()` returns the source lexeme; `ExecutableArgument` carries values only, so map `#param` via `Method.getParameters()` + `getPositionalArguments()`. No `@P` annotation is needed.
4. **Filter registration is automatic for `Filter` pods.** `FilterManager.onReady()` discovers all `Filter` beans and subtypes. Multiple chains need no manual registry call. Ordering is `AnnotationAwareOrderComparator` (lower = earlier); web's CORS filter is `HIGHEST_PRECEDENCE` and its CSRF filter is `HIGHEST_PRECEDENCE + 1`.
5. **`HttpSession` ids cannot be changed in place.** Fixation protection must create a new session, copy attributes, invalidate the old one, and emit a fresh `JSESSIONID` cookie. `IoRequest.getSession(create:)` ignores the `create` flag.

---

## 6. The design ledger

### 6.1 Purpose

The old roadmap specified _filenames_. That is how a package can look complete while being inert. The ledger specifies _invariants_. It is the real specification and is authoritative for review.

Location: `packages/jetleaf_security/docs/design/`. One file per component, numbered. Template: `000-template.md`.

### 6.2 Required fields for every record

1. **Design reference** — the abstraction this component provides and the problem it solves; where possible, the underlying contract it implements.
2. **Problem** — the production failure the abstraction exists to prevent.
3. **Invariant** — what must always be true (testable, imperative).
4. **Extension seam** — what users may replace; which pod/interface/order governs it.
5. **Edge cases** — the CVEs, regressions, and boundary conditions that motivated it.
6. **Jetleaf mapping** — concrete types, Jetleaf primitives used, and deviations with rationale.
7. **Gating tests** — named tests that prove the invariant, including at least one adversarial case.

### 6.3 Required ledger records

Write records for at least: `SecurityContextHolder` \+ `SecurityContextRepository`; `Authentication` token invariants; `AuthenticationTrustResolver`; `ProviderManager`; `DaoAuthenticationProvider`; `PasswordEncoder` family; `SecurityFilterChain`/`FilterChainProxy`; `FilterComparator`/ordering; `OncePerRequestFilter`; `CsrfFilter`; `CorsFilter` delegation; `ExceptionTranslationFilter`; `AuthorizationFilter`; `AuthorizationManager` family; `SecurityExpressionHandler`; method-security metadata sources; before/after method interceptors; `HttpSecurity` \+ configurers; `ObjectPostProcessor`; `JwtDecoder`/validator chain; `JWSAlgorithm` allowlist; `JwkSource`; `JwtTokenProvider`; `OAuth2ResourceServer`; OIDC nonce validation; rate limiting; headers; multiple chains.

### 6.4 Worked example (format to follow exactly)

```markdown
# 014 — ExceptionTranslationFilter

## Design reference
An `ExceptionTranslationFilter` that turns security exceptions raised inside the chain into correct HTTP responses at a single boundary.

## Problem
Translate security exceptions raised inside the chain into correct HTTP responses
at a single boundary, without swallowing programming errors.

## Invariant
1. The filter MUST sit outside `AuthorizationFilter`.
2. It MUST translate `AuthenticationException` via `AuthenticationEntryPoint`
   and `AccessDeniedException` via `AccessDeniedHandler`.
3. For an anonymous or remember-me principal, an `AccessDeniedException` MUST
   be treated as unauthenticated (401), decided through `AuthenticationTrustResolver`.
4. It MUST NOT write a response if the response is already committed.
5. Any filter that throws a security exception from OUTSIDE this filter MUST
   handle its own denial. `CsrfFilter` is the canonical case: the design injects an
   `AccessDeniedHandler` into `CsrfFilter` itself rather than reordering it.

## Extension seam
`AuthenticationEntryPoint`, `AccessDeniedHandler`, `AuthenticationTrustResolver`,
`RequestCache` are all overridable pods (`@ConditionalOnMissingPod`).

## Edge cases
CSRF denial thrown upstream; anonymous denial; committed response; async/error
dispatch; exception thrown by the controller (must NOT be translated).

## Jetleaf mapping
`ExceptionTranslationFilter implements SecurityFilter`, order -10. Delegates
to `jetleaf_web` `ServerHttpResponse.setStatus`. Uses `HttpHeaders` for
`WWW-Authenticate`. `RequestCache` deferred to Pass B.

## Gating tests
- `exception_translation_authentication_exception_yields_401`
- `exception_translation_access_denied_yields_403`
- `exception_translation_anonymous_denial_yields_401`
- `csrf_failure_yields_json_403` (regression for defect #7)
- `controller_runtime_exception_is_not_translated`
- `committed_response_is_not_rewritten`
```

---

## 7. Subsystem specifications

### 7.1 Core domain and context

- **MUST** make `Authentication` revoke-only: remove public grant; `setAuthenticated(true)` throws `IllegalArgumentException` equivalent; factory constructors (`unauthenticated`, `authenticated`) are the only way to grant. Keep the `isAuthenticated` getter.
- **MUST** use `Set<GrantedAuthority>` (roadmap contract) and immutable authorities.
- **MUST** implement `SecurityContextHolder` with a `const Symbol` zone key and `Zone.fork(zoneValues: ...)`; remove the mutable static `_fallbackContext`. `getContext()` returns a fresh empty context when outside a zone; never shared mutable state.
- **MUST** introduce `SecurityContextRepository` with two implementations, both in Pass A:
  - `NullSecurityContextRepository` — never reads or writes a session; used for `stateless`.
  - `HttpSessionSecurityContextRepository` — backed by `jetleaf_web`'s `HttpSession`; reads lazily via `DeferredSecurityContext`, writes on completion, and honours `allowSessionCreation`.
- **MUST** make `SessionCreationPolicy` fully behavioural in Pass A (it is currently dead config):

  | Policy | Repository | Session creation |
  |---|---|---|
  | `stateless` | `NullSecurityContextRepository` | never; no session read or write |
  | `never` | `HttpSessionSecurityContextRepository(allowSessionCreation: false)` | never creates, but uses an existing session |
  | `ifRequired` | `HttpSessionSecurityContextRepository` | creates only when the context changes / authentication occurs |
  | `always` | `HttpSessionSecurityContextRepository` | always creates a session |

- **MUST** implement `SessionAuthenticationStrategy` and the fixations-protection family (`ChangeSessionIdAuthenticationStrategy`, `SessionFixationProtectionStrategy`, `CompositeSessionAuthenticationStrategy`) plus `SessionRegistry`/`SessionInformation` for concurrency control hooks. Wire them into `SessionManagementFilter` for stateful policies.
- **MUST** ensure `SecurityContextHolderFilter` loads the deferred context, binds the zone, saves through the repository at completion, and clears in `finally` on every path including errors and async dispatch.
- **MUST** implement `AuthenticationTrustResolver` with `isAnonymous`, `isRememberMe`, `isFullyAuthenticated`; wire it into `ExceptionTranslationFilter`.
- **MUST** add `AnonymousAuthenticationFilter` and make `AnonymousAuthenticationToken` construction internal to it (via config).
- Exit criteria: concurrent-request isolation test, context-cleared-on-error test, 401-vs-403 trust-resolver matrix, and a four-policy session matrix test proving each `SessionCreationPolicy` state creates/uses sessions exactly as tabled above, plus a session-fixation test asserting the session id changes on authentication.

### 7.2 Crypto

- **MUST** keep the three encoders and add `DelegatingPasswordEncoder` with `{id}` prefixes plus `PasswordEncoderFactories.createDelegatingPasswordEncoder()`.
- **MUST** add published known-answer vectors: RFC 9106 Argon2id, published bcrypt vectors (including 72-byte boundary and Unicode), NIST SP 800-132 PBKDF2.
- **MUST** bound parsed parameters: Argon2 memory/iterations/parallelism and PBKDF2 iterations get configurable maxima; reject out-of-range stored hashes with a clear exception. Cap bcrypt strength at a safe maximum. Fix bcrypt base64's missing 4th-character validation.
- **MUST** provide an async API (`Future<String> encodeAsync`, `Future<bool> matchesAsync`) so 64 MiB Argon2id does not block the isolate; keep sync API for compatibility.
- **MUST** pin `pointycastle` to a single major version.
- **DO NOT** alter the Eksblowfish/PHC internals without a vector proving the change is correct.
- Exit criteria: vector tests pass; DoS-bound tests pass; async tests pass.

### 7.3 Authentication

- **MUST** keep `ProviderManager` and `DaoAuthenticationProvider` with their hardening: `supports` uses assignability, not exact `runtimeType`; DAO provider erases credentials before returning or documents that `ProviderManager` is mandatory.
- **MUST** add `AuthenticationEventPublisher` (named events) with a no-op default if Jetleaf has no event bus.
- **MUST** keep `UserDetailsService` as the database seam; `InMemoryUserDetailsManager` remains the default only via `@ConditionalOnMissingPod`.
- Exit criteria: provider delegation, parent fallback, last-exception semantics, credential erasure, account-status matrix, `UserDetailsService` override via a custom pod.

### 7.4 Request authorization and the filter chain

- **MUST** replace expression-string rules with `AuthorizationManager<RequestAuthorizationContext>` implementations. `AuthorizeHttpRequestsConfigurer` terminals return `AuthorizedUrl`/the configurer for chaining and produce typed rules.
- **MUST** provide `AuthorityAuthorizationManager`, `AuthenticatedAuthorizationManager`, `RequestMatcherDelegatingAuthorizationManager`, and `AuthorizationManagers.anyOf/allOf`.
- **MUST** build a `FilterChainProxy`-equivalent `Filter` bean registered with `FilterManager` via `@Pod`, supporting multiple `SecurityFilterChain`s selected by `securityMatcher` and ordered by `@Order`. It clears the security context in `finally`.
- **MUST** establish this order; relative placement is exposed through `addFilterBefore`/`addFilterAfter`, not raw numbers alone:
  | order | filter | invariant |
  | --- | --- | --- |
  | −100 | web `CorsFilter` (delegated) | preflight handled before auth |
  | −95 | `RateLimitingFilter` | reject before allocating context; trusted proxies only |
  | −90 | `SecurityContextHolderFilter` | load/defer, bind, clear in finally |
  | −80 | `HeaderWriterFilter` | composed `HeaderWriter`s |
  | −70 | `CsrfFilter` | **owns its `AccessDeniedHandler`** — see ledger 014 |
  | −60 | `LogoutFilter` (reserved) |  |
  | −50 | `BearerTokenAuthenticationFilter` / `AuthenticationFilter` | populate context |
  | −40 | `AnonymousAuthenticationFilter` | only after real auth attempted |
  | −30 | `SessionManagementFilter` (stateful only) | session fixation protection |
  | −10 | `ExceptionTranslationFilter` | outside `AuthorizationFilter` only |
  | 0 | `AuthorizationFilter` | terminal decision |
- **DO NOT** fix defect #7 by moving `ExceptionTranslationFilter` outside `CsrfFilter`. Follow the handler-injection approach: inject an `AccessDeniedHandler` into `CsrfFilter`. Document this in the ledger.
- **DO NOT** reimplement CORS. Remove the local `CorsFilter`; delegate to `jetleaf_web` and extend it only where the roadmap requires.
- **MUST** harden `RateLimitingFilter`: trusted-proxy configuration for `X-Forwarded-For`, direct peer address as default key, bounded/evicting store, `Retry-After`.
- **MUST** replace the hand-rolled Ant regex with Jetleaf's `PathPattern` machinery if available; otherwise add tests for `**`, trailing slashes, case sensitivity, and method matching.
- Exit criteria: real-dispatcher integration test, CSRF→403 regression, multiple-chain test, rate-limit spoofing test, header composition test.

### 7.5 Method security

- **MUST** convert all four annotations to `ReflectableAnnotation` with `@Target({TargetKind.method, TargetKind.classType})` (and appropriate targets), `annotationType`, `equalizedProperties`.
- **MUST** implement `MethodSecurityMetadataSource` and `PrePostAnnotationSecurityMetadataSource` reading annotations from both `Method` and declaring class via `getDirectAnnotation<A>()`.
- **MUST** implement `AuthorizationManager<MethodInvocation>` managers: `PreAuthorizeAuthorizationManager`, `SecuredAuthorizationManager`, `Jsr250AuthorizationManager`; and `AuthorizationManager<MethodInvocationResult>`: `PostAuthorizeAuthorizationManager`.
- **MUST** implement `AuthorizationManagerBeforeMethodInterceptor` and `AuthorizationManagerAfterMethodInterceptor` as real Jetleaf `MethodInterceptor`/`AroundMethodInterceptor` classes with `canIntercept(Method)`, registered as pods via `MethodInterceptorAutoConfiguration`, ordered by `@Order`.
- **MUST** keep `MethodSecurityInterceptor` as a public facade that preserves the existing `intercept<T>({annotations, invocation, arguments})` convenience API and delegates to the same managers — no duplicate policy logic.
- **MUST** parse annotation expressions into an AST **once**, cached by expression string; evaluate with `SecurityExpressionHandler`, `SecurityExpressionRoot`, `MethodSecurityEvaluationContext`.
- **MUST** support: `hasRole`, `hasAnyRole(['A','B'])`, `hasAuthority`, `hasAnyAuthority([...])`, `isAuthenticated`, `isAnonymous`, `isFullyAuthenticated`, `#param`, `principal.*`, `authentication.*`, `returnObject.*`, `&&`/`||`/`!`, `==`/`!=`, relational operators. Property paths MUST use Jetleaf reflection on Dart objects, not `Map`-only lookup.
- **MUST** escape/bind user values; no string concatenation into expressions.
- **MUST** verify Dart parameter-name retention via Jetleaf reflection in Phase 0. If names are unavailable, require explicit `@P('name')` annotations or positional binding, and document the constraint.
- **MUST** verify that the `jetleaf_tools` build generates `$$JLInterfaced$$` proxies for user classes. Without proxies, `@PreAuthorize` cannot fire. Document this as a hard framework requirement in the README and add a proxy-generation integration test.
- Exit criteria: a real proxied controller method is denied before its body executes; class-level annotations work; `Future`-returning methods work; `#param` and object property paths work; no manual `interceptor.intercept()` calls in integration tests.

### 7.6 Configuration DSL

- **MUST** implement `SecurityBuilder`, `SecurityConfigurer<O, B>` (two-phase `init`/`configure`), `SharedObjects`, `ObjectPostProcessor<T>` as described in §4.4.
- **MUST** make `HttpSecurity` an ordered configurer host with `SecurityFilterChainBuilder` as the concrete builder.
- **MUST** make all terminal DSL methods chainable. The roadmap's canonical example in §5 must compile verbatim (after translating imports to Dart).
- **MUST** add the missing DSL methods listed in §4.3, including `addFilterBefore`/`addFilterAfter` with relative positioning.
- **MUST** consume `SessionCreationPolicy`: `stateless` selects `NullSecurityContextRepository` and disables session-based context; `never`/`ifRequired`/`always` behave accordingly.
- **MUST** provide `@AutoConfiguration` classes registering all defaults with `@ConditionalOnMissingPod`; `EnableWebSecurity`/`EnableMethodSecurity` become real annotations.
- Exit criteria: the roadmap's `SecurityConfig` example compiles and runs against a real server; overriding any default pod changes behaviour; two ordered chains work.

### 7.7 JWT

- **Decision (owner-approved):** implement JWT signing, verification, JWK parsing and base64url handling **in-house on `pointycastle` + `crypto`**; there will be **no third-party JWT dependency** in the final package. `pointycastle` is already required for Argon2id/PBKDF2, so this adds no new dependency.
- **Migration gate:** during implementation, `dart_jsonwebtoken` may remain in `dev_dependencies` purely as a test oracle to cross-check our implementation. It MUST be removed from `pubspec.yaml` entirely once the RFC vectors in §8.1 pass. Do not ship it, even transitively.
- **MUST** implement correctly, with explicit tests for each:
  - base64url without padding, including unsigned big-endian integer encoding for RSA `n`/`e` and EC `x`/`y` (leading-zero handling);
  - HMAC SHA-256/384/512;
  - RSA PKCS#1 v1.5 signatures RS256/384/512 from JWK `n`/`e` and X.509 `SubjectPublicKeyInfo`;
  - ECDSA ES256/384/512 on P-256/P-384/P-521, including conversion between pointycastle's DER output and JWT's **raw fixed-width R‖S** format (66-byte components for P-521) — this is the highest-risk part of the implementation;
  - a strict `JWSAlgorithm` allowlist per decoder; never derive the accepted algorithm from the untrusted token header.
- **MUST** inject `aud` on issuance from the provider's configured audience; support multiple audiences.
- **MUST** reject refresh tokens as authentication credentials via an explicit token-type claim check.
- **MUST** validate `exp`, `nbf`, `iat`, `iss`, `aud` with configurable clock skew and `require*` flags; consolidate the duplicated `isExpired` logic.
- **MUST** build a validator chain: `OAuth2TokenValidator` \+ `JwtValidators.createDefaultWithIssuer(...)` \+ `JwtTimestampValidator` \+ `JwtIssuerValidator` \+ `JwtAudienceValidator` \+ `customValidator`.
- **MUST** enforce a `JWSAlgorithm` allowlist per decoder; filter JWKS by `kty`, `use`, `alg`; reject `oct` keys for asymmetric decoders; handle `kid` misses with a throttled single refresh and concurrency safety; fail closed on fetch errors.
- **MUST** add RSA/ECDSA factories and tests (HS256/384/512, RS256/384/512, ES256/384/512).
- Exit criteria: all JWT adversarial tests (§9.3) pass; no duplicate validation logic remains.

### 7.8 OAuth2 / OIDC

- **MUST** make `OAuth2ResourceServer` an `AuthenticationProvider` wired into `HttpSecurity.oauth2ResourceServer(...)`, not a standalone helper.
- **MUST** add `OAuth2AuthoritiesConverter` for `scope`/`scp` (`SCOPE_` prefix) and `roles`.
- **MUST** validate OIDC `nonce`; enforce issuer allowlists (no bare `accounts.google.com`); check Google `azp`.
- **MUST** remove the incorrect GitHub `emailVerified` assertion; mark unverifiable emails as unverified.
- Exit criteria: provider verification tests with recorded JWKS fixtures; scope/role mapping tests; replay/nonce test.

### 7.9 Documentation and example

- README MUST include: an API conventions section, a getting-started example using the roadmap's DSL, the proxy-generation requirement, and all deliberate deviations.
- The example MUST be a real Jetleaf web application with a real `SecurityFilterChain` pod and a proxied controller demonstrating `@PreAuthorize` — not a `print`-based simulator.
- CHANGELOG MUST describe the rewrite as a breaking change.

---

## 8. Correctness gates

A phase is complete only when all of the following are true:

1. `dart analyze` reports no issues in the package.
2. `dart test` passes with the new tests added by that phase.
3. Every ledger record for the phase has its gating tests present and passing.
4. Integration tests exercise the **real** `IoWebServer` → `GlobalServerDispatcher` → `FilterManager` path and **real** generated proxies. Mock-only coverage does not satisfy this gate.
5. No public type deviates from the public naming contract without a ledger entry.

### 8.1 External vectors (mandatory)

- RFC 9106 Argon2id known-answer vectors.
- Published bcrypt vectors for `$2a$`, `$2b$`, `$2y$`, plus 72-byte boundary and Unicode.
- NIST SP 800-132 PBKDF2 vectors.
- RFC 7515/7519 JWT vectors for HS/RS/ES families, **including RFC 7515 Appendix A.1/A.2/A.3 signatures**. These prove the in-house JWT implementation before `dart_jsonwebtoken` is deleted.
- Every vector test must run against fixed inputs, not self-generated tokens. A test that signs and then verifies with the same code is not a vector test.

### 8.2 Integration tests (mandatory)

- `dispatcher_security_test.dart` — real request through the dispatcher; 200/401/403 outcomes; multiple ordered chains.
- `method_security_proxy_test.dart` — proxied controller, denial before body execution, class-level annotations, async methods.
- `csrf_failure_yields_json_403.dart` — regression for defect #7.
- `context_isolated_across_concurrent_requests.dart`.
- `custom_pod_overrides_default.dart`.
- `session_creation_policy_matrix.dart` — all four states against a real `HttpSession`.
- `session_fixation_protection.dart` — session id changes on authentication.

### 8.3 Adversarial suite (mandatory)

- `alg_none_rejected`, `rs256_to_hs256_confusion_rejected`, `tampered_payload_rejected`.
- `refresh_token_cannot_authenticate`, `missing_aud_rejected`, `iat_future_rejected`, `clock_skew_boundaries`.
- `jwks_unknown_kid_throttled`, `jwks_oct_key_rejected`, `jwks_fetch_failure_fails_closed`, `jwks_rotation`.
- `argon2_hostile_parameters_rejected`, `bcrypt_strength_capped`.
- `x_forwarded_for_spoofing_does_not_bypass_rate_limit`.
- `expression_injection_via_role_name_rejected`, `has_any_role_list_syntax`, `object_property_path_resolution`.
- `anonymous_denial_yields_401`, `committed_response_not_rewritten`.
- `oidc_nonce_missing_rejected`, `github_email_not_marked_verified`.

---

## 9. Execution plan

| Phase | Deliverable | Exit criteria |
| --- | --- | --- |
| **0 — Ledger and failing suite** | `docs/design/` records; conformance \+ adversarial tests written against the desired API; verify Jetleaf APIs, proxy generation, and parameter-name retention | Tests fail against the current package; no implementation code written yet |
| **1 — Core invariants** | Rewritten `core/`, both context repositories, trust resolver, session strategies/fixation protection, hardened exceptions | Context isolation, trust matrix, four-policy session matrix, fixation test pass |
| **2 — Crypto \+ auth** | Delegating encoder, vectors, hardened encoders, events | Vector \+ DoS \+ async \+ provider tests pass |
| **3 — Request security** | Typed authorization managers, filter chain proxy, ordering, CORS/CSRF delegation, rate limiting hardening | Real-dispatcher integration passes; CSRF regression passes |
| **4 — Method security** | Reflectable annotations, metadata sources, managers, real interceptors, facade, AST | Proxied-controller integration passes |
| **5 — JWT / OAuth2 / OIDC** | In-house JWT engine (HMAC/RSA/ECDSA + JWK), validator chain, JWKS hardening, resource-server provider, then delete `dart_jsonwebtoken` | RFC vectors + JWT adversarial + provider tests pass; no JWT dependency remains |
| **6 — Docs and hardening pass** | README migration table, real example app, CHANGELOG, final review | Full §8 gate suite green |

Pass A ends at Phase 6. Pass B adds the §2.2 additive integrations only after the owner reviews Pass A.

---

## 10. Risk register

| Risk | Mitigation |
| --- | --- |
| In-house JWT crypto has subtle format bugs, especially ECDSA DER ↔ raw R‖S and JWK integer encoding | RFC 7515 vectors for every algorithm family; cross-check against `dart_jsonwebtoken` as a temporary test oracle; delete the oracle only after all vectors pass |
| No proxy is generated for a secured class, so annotations silently never fire (verified: no runtime fallback) | Hard requirement in README: non-final stereotyped classes + `jl build`. Build-level test asserts a `$$JLInterfaced$$` proxy exists and is wrapped by `DefaultMethodInterceptor` |
| `final`/`sealed`/`mixin class` secured targets are skipped by the proxy generator | Document the restriction; integration test uses a non-final `@RestController` |
| Parameter name mapping wrong | Resolved in Phase 0: `Parameter.getName()` is reliable; bind via `getParameters()` + `getPositionalArguments()` (§5.1) |
| Jetleaf has no application event bus | Define `AuthenticationEventPublisher` with no-op default |
| Reference source is unavailable offline | Fetch authoritative specifications for the components in §6.3; cite in ledger |
| Scope creep into OAuth2 client flows | §2.2 is a hard boundary for Pass A |
| Naming drift toward "Jetleaf-flavoured" terms | §4.3 parity contract is a review gate |
| Reusing old crypto without vectors | §8.1 is mandatory before any crypto change |

---

## 11. Definition of done

- [ ] Every ledger record in §6.3 exists with all seven fields.
- [ ] Every §4.2 file exists (or is explicitly documented as removed/deferred with rationale).
- [ ] Every §4.3 mandated public name exists with the expected semantics.
- [ ] Every defect in §1.4 has a passing regression test.
- [ ] Every §8 gate passes, including real-dispatcher and real-proxy integration.
- [ ] The roadmap's canonical configuration example compiles and runs unchanged.
- [ ] README contains the API conventions section and the proxy requirement.
- [ ] The example is a real web application, not a simulator.
- [ ] `dart_jsonwebtoken` is absent from `pubspec.yaml`; JWT is implemented in-house and passes §8.1 vectors.
- [ ] No `export` directive exists anywhere under `lib/src/`; all ten §4.5 barrels exist.
- [ ] All four `SessionCreationPolicy` states pass the §7.1 matrix test.
- [ ] `dart analyze` clean; all tests green.

---

## 12. Owner decisions

| # | Decision | Status |
|---|---|---|
| 1 | Pass A delivers the full architecture and all core capabilities; Pass B is additive (§2.2). | **Confirmed by owner** |
| 2 | No third-party JWT dependency. Implement JWT/JWK/base64url in-house on `pointycastle`; use `dart_jsonwebtoken` only as a temporary test oracle, then delete it (§7.7). Owner prefers the smallest possible dependency surface. | **Decided** |
| 3 | Secondary barrels under `lib/` for selective imports; `export` only in `lib/*.dart`, never in `src/` (§4.5). | **Decided** |
| 4 | Session-backed `SecurityContextRepository` is required in Pass A; all four `SessionCreationPolicy` states must work (§7.1). | **Decided** |
| 5 | Keep both `MethodSecurityInterceptor` facade and the real `AuthorizationManager*` method interceptors. | **Decided** |
| 6 | Keep `Argon2idPasswordEncoder` name with a documented rationale; no alias class. | **Decided** |

All six items are decided. The implementing agent may proceed.

---

## 13. Progress

### Phase 0 — ledger and red suite: **delivered**

- `packages/jetleaf_security/docs/design/` contains 32 ledger records plus `README.md` index and `000-template.md`. Every record has all seven required fields.
- `packages/jetleaf_security/test/adversarial/` contains five red-phase test files plus a `README.md` mapping each test to a defect number.
- Baseline after Phase 0: `dart analyze` clean; `dart test` → 19 original tests pass, **14 adversarial tests fail for the intended reasons**. No implementation code in `lib/` was modified.
- Framework verification is **complete** (§5.1). Records 009, 010, 013, 017, 019 and 031 have been updated with verified facts: CLI-driven proxy generation with silent no-proxy failure, reliable `Parameter.getName()`, automatic `Filter` pod discovery, and no in-place session-id change.

### Phase 1 — core invariants: **substantially complete**

- `Authentication` tokens are now revoke-only (`setAuthenticated(true)` throws) and carry immutable `Set<GrantedAuthority>` authorities across all token types.
- `SecurityContextHolder` is fork-based with a `const Symbol` key and no mutable fallback; `setContext` outside a zone throws.
- Added `SecurityContextRepository`, `DeferredSecurityContext`, `NullSecurityContextRepository`, `HttpSessionSecurityContextRepository`.
- Added `AuthenticationTrustResolverImpl`, `SessionAuthenticationStrategy` family, `SessionRegistry`/`SessionInformation`, and `AnonymousAuthenticationFilter`.
- `SecurityContextHolderFilter` now loads/saves through the repository and clears in `finally`.
- Added 14 new unit tests under `test/core/` and `test/auth/`.
- Baseline: `dart analyze` clean; `dart test` → 37 pass, 13 adversarial tests still failing (all owned by later phases). Ledger 001 and 003 were updated to match the implemented API shape.

### Next

### Phase 2 — crypto and authentication hardening: **complete**

- Added `DelegatingPasswordEncoder` (`{id}` prefixes) and `PasswordEncoderFactories`.
- Added published crypto vectors: RFC 9106 Argon2id PHC vectors, Favre OpenBSD bcrypt vectors (including non-ASCII and the 72-byte boundary), and an independent PBKDF2-HMAC-SHA256 cross-check built on `package:crypto`.
- Hardened parameter bounds: Argon2 memory/iterations/parallelism, PBKDF2 iterations, bcrypt strength capped at 16, bcrypt base64 4th-character validation.
- Added `Isolate.run`-backed `encodeAsync`/`matchesAsync` for all three encoders.
- Pinned `pointycastle` to `^3.9.0`.
- Added `AuthenticationEventPublisher` with named events and a no-op default; `ProviderManager` publishes success/failure and cannot be broken by a failing publisher.
- Collapsed provider support checks into a single instance-based `supports(Authentication)`; `DaoAuthenticationProvider` no longer returns the raw password in credentials.
- Ledgers 005 and 007 updated to document the `Type`-assignability adaptation required by Dart.
- Baseline: `dart analyze` clean; `dart test` → **63 pass, 10 adversarial still red** (expression parser, JWT, filter defects, OAuth2 and rate-limit items owned by later phases).

### Next

### Phase 3 — request security: **substantially complete**

- Typed authorization model added: `AuthorizationManager<T>`, `AuthorizationDecision`, `AuthorityAuthorizationManager`, `AuthenticatedAuthorizationManager`, `RequestMatcherDelegatingAuthorizationManager`, `AuthorizationManagers.anyOf/allOf`, permit/deny managers, and `ExpressionAuthorizationManager` for the DSL's `access(...)`.
- `AuthorizationFilter` and `AuthorizeHttpRequestsConfigurer` no longer build or parse expression strings; DSL terminals build typed managers and return chainable values. Role hierarchy is applied to authority managers at build time.
- `ExceptionTranslationFilter` 401/403 decisions go through `AuthenticationTrustResolver`.
- `FilterChainProxy` added: ordered multi-chain selection, pass-through when no chain matches, context cleanup in `finally`. `SecurityFilterChain` gained a chain `order`.
- Canonical order table in `filter_orders.dart`; `addFilterBefore`/`addFilterAfter` implemented with explicit relative placement.
- `SecurityAutoConfiguration` added with `@AutoConfiguration` + `@ConditionalOnMissingPod` defaults for trust resolver, context repository, password encoder, chain, and proxy.
- CSRF denial now renders a JSON 403 through an injected `AccessDeniedHandler` (the handler-injection fix, not filter reordering); CORS preflight validates requested method and headers.
- `HeaderWriter` composition, trusted-proxy-aware and bounded rate limiting, and full `SessionCreationPolicy` wiring (repository + `SessionAuthenticationStrategy`, including fixation protection) added.
- Ledger 013 updated to record the deliberate choice to retain a hardened local CSRF filter rather than fully delegate to `jetleaf_web`.
- Baseline: `dart analyze` clean; `dart test` → **80 pass, 8 adversarial still red** (4 expression-parser, 4 JWT — Phases 4 and 5).

### Next

### Phase 4 — method security: **substantially complete**

- All six annotations are now `ReflectableAnnotation`s with `@Target`, `annotationType` and `equalizedProperties`.
- Added `MethodSecurityMetadataSource` / `PrePostAnnotationSecurityMetadataSource` reading annotations from methods and declaring classes.
- Added method `AuthorizationManager`s (`PreAuthorize`, `PostAuthorize`, `Secured`, `Jsr250`) over a `MethodAuthorizationContext`, with parameter binding via `Parameter.getName()` + `ExecutableArgument.getPositionalArguments()`.
- Added real `AuthorizationManagerBeforeMethodInterceptor` (`MethodBeforeInterceptor`) and `AuthorizationManagerAfterMethodInterceptor` (`AfterReturningInterceptor`), registered by `MethodSecurityAutoConfiguration` with `@ConditionalOnMissingPod`.
- `MethodSecurityInterceptor` retained as the public facade and now delegates to the same managers — no duplicate policy logic.
- Expression parser now supports `hasAnyRole([...])` / `hasAnyAuthority([...])`, caches tokenisation, and resolves property paths on objects via `SecurityExpressionPropertyResolvers` (reflection default + pluggable resolvers for non-AOT objects). Ledger 017 records the token-cache vs full-AST refinement and the reflection constraint.
- Baseline: `dart analyze` clean; `dart test` → **89 pass, 4 adversarial still red** (all JWT — Phase 5).

### Next

### Phase 5 — JWT / OAuth2 / OIDC: **substantially complete**

- `dart_jsonwebtoken` is **removed** from `pubspec.yaml`. All JWS work is in-house on `pointycastle`: `JwtBase64Url`, `JwsAlgorithms`, `JwtCrypto` (HMAC, RSA PKCS#1 v1.5, ECDSA with raw R‖S), `Jwk`, `JwtKey`, and rewritten encoder/decoder/JWKS source.
- RFC 7515 Appendix A.1 (HS256), A.2 (RS256) and A.3 (ES256) known-answer vectors pass, plus `alg: none` rejection.
- Validator chain now enforces single shared clock skew, `exp` (required by default), `nbf`, `iat`, issuer and multiple audiences.
- Fixed all four JWT defects: `aud` injected on issuance, refresh tokens rejected as credentials, future `iat` rejected, missing `exp` rejected.
- JWKS source filters keys by `kty`/`use`/`alg`/curve, uses one in-flight refresh, throttles unknown-kid refreshes, and fails closed on non-200/malformed responses.
- `OAuth2ResourceServer` now implements `AuthenticationProvider`. OIDC providers accept `expectedNonce`, Google checks `azp` and rejects bare issuers, and GitHub no longer asserts unverified emails.
- Baseline: `dart analyze` clean; `dart test` → **103 pass, 0 fail** (all adversarial tests green).

### Next

### Phase 6 — docs, barrels and review: **complete**

- Ten `lib/` barrels exist (`jetleaf_security`, `core`, `authentication`, `authorization`, `annotation`, `crypto`, `filter`, `config`, `jwt`, `oauth2`). `grep` confirms zero `export` directives under `lib/src/`.
- README rewritten with an API conventions section, deliberate deviations, session-policy table, proxy-generation requirement, source-layout guide, selective-import guide and a working `HttpSecurity` example. CHANGELOG records the breaking rewrite.
- `example/` is now a real Jetleaf application (`JetleafApplication.run`) with an `@AutoConfiguration`-backed security config and a non-final `@RestController` using `@PreAuthorize`/`@PostAuthorize`. `dart analyze` clean.
- `jl build` verified: it emitted `$$JLInterfaced$$OrganizationController` proxy and registered all default pods (`jetleaf.security.authenticationTrustResolver`, `passwordEncoder`, `securityFilterChain`, `filterChainProxy`, `methodSecurityMetadataSource`, both method interceptors) in the AOT pod registry.
- `dart_jsonwebtoken` is gone from this package's `pubspec.yaml`. It remains in the workspace lockfile only as a transitive dependency of `gotrue`, which is unrelated to this package.
- Final suite: `dart analyze` clean; `dart test` → **103 pass, 0 fail**.

### Gates completed after Phase 6

- **End-to-end HTTP**: `packages/jetleaf_security/example/test/web_security_e2e_test.dart` boots a real `IoWebServer` on an ephemeral port with generated AOT registries and sends real requests. It asserts a 401 for anonymous access, a 200 through the interceptable controller, and a 403 when `@PreAuthorize` denies a principal from another organization. Handler-level security exceptions are mapped by `SecurityExceptionResolver`.
- **Conditional enablement**: `MethodSecurityEnablementPodFactoryPostProcessor` reads `@EnableMethodSecurity` from the application class and prunes interceptor definitions before instantiation; `EnablementAwareMethodSecurityMetadataSource` honours the three enablement flags. It also removes the default filter chain when the application supplies its own.
- **Comprehensive example application**: `packages/jetleaf_security/example` now covers three filter chains, JWT access/refresh, DAO/JWT/custom API-key providers, delegating password hashing, `@PreAuthorize`/`@PostAuthorize`/`@Secured`/`@RolesAllowed`, role hierarchy, OAuth2 resource server and OIDC nonce validation with a local JWKS, CORS, headers, rate limiting, and a custom authentication event publisher. `dart test` in the example passes **19 tests** (18 real HTTP tests plus an OAuth2 smoke test).
- **AOT generator fix**: `libraries/jetleaf_tools/lib/src/aot/aot_field_registry_writer.dart` now emits field setters for `late final` fields, so `@Autowired late final` injections work in AOT builds. The example controllers use real field injection after this fix.
- **`SecurityContext.setAuthentication`** was added alongside direct assignment.
- Remaining scope boundary: Pass B items from §2.2 (OAuth2 client flows, SAML, LDAP, remember-me, distributed rate limiting) remain out of scope by design.

