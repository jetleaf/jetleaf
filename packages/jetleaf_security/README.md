# jetleaf_security

Enterprise authentication, authorization and security infrastructure for Dart,
built on Jetleaf's IoC/AOP/filter infrastructure with a familiar security API.

The public API uses familiar names and a fluent configuration shape. A developer
who knows `HttpSecurity`, `ProviderManager`, `@PreAuthorize` and
`SecurityFilterChain` will recognize the conventions. The internals are
Jetleaf-native: `@Pod` beans, `Filter`/`MethodInterceptor` contracts, and
Zone-based context.

> **Status:** This is a rewrite of the package. See
> `roadmap/jetleaf_security_rewrite.md` for the specification and
> `docs/design/` for the per-component design ledger.

---

## Installation

```yaml
dependencies:
  jetleaf_security: ^1.0.0
```

Runtime cryptographic dependencies are limited to `pointycastle` and `crypto`;
JWT/JWS, JWK parsing and base64url are implemented in this package.

## Selective imports

Import only what you use. All public exports live in the `lib/` barrels; no file
under `lib/src/` exports anything.

```dart
import 'package:jetleaf_security/config.dart';        // HttpSecurity, auto-config
import 'package:jetleaf_security/authentication.dart'; // managers, providers, tokens
import 'package:jetleaf_security/authorization.dart';  // authorization managers
import 'package:jetleaf_security/annotation.dart';     // @PreAuthorize, @Enable...
import 'package:jetleaf_security/crypto.dart';
import 'package:jetleaf_security/filter.dart';
import 'package:jetleaf_security/jwt.dart';
import 'package:jetleaf_security/oauth2.dart';
import 'package:jetleaf_security/core.dart';
```

`package:jetleaf_security/jetleaf_security.dart` remains the unified barrel.

The ten `lib/` barrels map to the folders under `lib/src/`:

| Folder | Responsibility |
|---|---|
| `lib/src/annotation/` | Security annotations and their enable switches |
| `lib/src/authentication/` | Managers, providers, tokens, user details and session strategies |
| `lib/src/core/` | Domain types, context, repositories, trust resolver and exceptions |
| `lib/src/crypto/` | Password encoders and factories |
| `lib/src/authorization/` | Authorization managers, expression API, method security and role hierarchy |
| `lib/src/filter/` | Filter-chain proxy and concrete filters |
| `lib/src/config/` | `HttpSecurity`, configurers, builder and auto-configuration |
| `lib/src/jwt/` | JWT and JWK API |
| `lib/src/oauth2/` | OAuth2/OIDC resource-server API and provider verifiers |

`lib/src/` holds implementation files only; no file under it exports anything.

---

## Getting started

### 1. Register the defaults

`SecurityAutoConfiguration` and `MethodSecurityAutoConfiguration` are
`@AutoConfiguration` classes. Every default is guarded by
`@ConditionalOnMissingPod`, so declaring your own pod replaces it.

### 2. Define a filter chain

```dart
import 'package:jetleaf_security/config.dart';
import 'package:jetleaf_security/authentication.dart';
import 'package:jetleaf_security/jwt.dart';

final jwt = JwtTokenProvider.hmac(
  secret: 'a-long-random-signing-secret',
  issuer: 'https://auth.example.com',
  audience: 'jetleaf-api',
);

final chain = HttpSecurity()
  ..csrf((csrf) => csrf.disable())
  ..cors((cors) => cors.configuration(const CorsConfiguration(
        allowedOrigins: ['https://app.example.com'],
        allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      )))
  ..sessionManagement(
    (session) => session.sessionCreationPolicy(SessionCreationPolicy.stateless),
  )
  ..authenticationManager(ProviderManager([jwt]))
  ..authorizeHttpRequests((auth) => auth
      .requestMatchers(['/health', '/api/auth/**']).permitAll()
      .requestMatcher('/api/admin/**').hasRole('ADMIN')
      .anyRequest().authenticated())
  .build();
```

`SecurityFilterChain` is a `jetleaf_web` `Filter`. Contribute it as a `@Pod`, or
wrap several chains in `FilterChainProxy`; `FilterManager` discovers them
automatically. Use `addFilterBefore` / `addFilterAfter` for custom filters.

### 3. Method security

```dart
@RestController()
class OrganizationController {
  @PreAuthorize("hasRole('ADMIN') or #orgId == principal.organizationId")
  Future<Report> getReports(String orgId) async { ... }

  @PostAuthorize('returnObject.ownerId == authentication.name')
  Future<AuditLog> getAuditLog(String orgId) async { ... }
}
```

**Hard requirement:** Jetleaf generated proxies are required for method
security. `DefaultMethodInterceptor` wraps only `$$JLInterfaced$$` proxy
classes; without one, annotations silently do nothing. Therefore:

- add `jetleaf_tools` as a dev dependency and run `jl build` (or `jl proxy`);
- secured classes must **not** be `final`, `sealed` or `mixin class`;
- secured classes must carry a stereotype (`@RestController`, `@Service`,
  `@Component`, `@Configuration`, `@Pod`, …).

This is CLI-driven — there is no `build.yaml`/`build_runner` generator.

### 4. Password hashing

```dart
final encoder = PasswordEncoderFactories.createDelegatingPasswordEncoder();
final hash = encoder.encode('correct horse battery staple'); // {argon2id}$argon2id$...
encoder.matches('...', hash);
```

`DelegatingPasswordEncoder` prefixes hashes with `{id}` so algorithms can be
migrated without a flag day. Argon2id, BCrypt and PBKDF2 encoders also expose
`encodeAsync`/`matchesAsync`, which run on a separate isolate.

---

## API conventions

The package follows a consistent naming and semantic scheme. The table below
records those conventions and the reasons behind them.

| Area | Convention | Notes |
|---|---|---|
| Wiring | `@Configuration` + `@Pod` | Factory-method pods replace bean declarations |
| Filter chain | `SecurityFilterChain` / `FilterChainProxy` `@Pod` | Discovered by `FilterManager` |
| Builder | `HttpSecurity` | Chained terminals; no expression strings for request rules |
| Authentication | `ProviderManager` / `DaoAuthenticationProvider` | `supports(Authentication)` inspects the token instance, so subclasses are supported |
| Trust | `Authentication.setAuthenticated(true)` throws | Only revocation is allowed; trust comes from factories |
| Trust decisions | `AuthenticationTrustResolver` | Drives 401 vs 403 |
| Context | `SecurityContextHolder`, forked Zone | No thread-local storage in Dart |
| Context persistence | `SecurityContextRepository` / `HttpSessionSecurityContextRepository` | `NullSecurityContextRepository` for `stateless` |
| Authorization | `AuthorizationManager<T>` / `AuthorizationDecision` | Typed request and method authorization |
| Filter placement | `FilterChainProxy` / `filter_orders.dart` | Explicit relative placement via `addFilterBefore`/`addFilterAfter` |
| CSRF denial | `AccessDeniedHandler` in `CsrfFilter` | CSRF handles its own denial because it sits outside exception translation |
| Headers | `HeaderWriter` / `SecurityHeadersFilter` | Public filter name kept; writers compose it |
| Password migration | `DelegatingPasswordEncoder` | `{id}` prefixes |
| Algorithm naming | `Argon2idPasswordEncoder` | Names the exact algorithm |
| JWT decoding | `JwtDecoder` / `DartJwtDecoder` | In-house JWS engine on pointycastle; no third-party JWT package |
| Token validation | `JwtValidator` | Shared clock skew, required claims |
| Method interception | `MethodSecurityInterceptor` (facade) | Plus real `AuthorizationManagerBefore/AfterMethodInterceptor` |
| Annotation metadata | `PrePostAnnotationSecurityMetadataSource` | Reads `ReflectableAnnotation`s |
| Role annotations | `Jsr250AuthorizationManager` | `@RolesAllowed` |
| Expressions | narrow security expression grammar | `hasRole`, `hasAnyRole([...])`, `#param`, `principal.*`, `returnObject.*` |
| Session fixation | fresh session + attribute migration | Jetleaf `HttpSession` ids are immutable |

### Deliberate deviations

- Zone-based context instead of `ThreadLocal`.
- `jetleaf_web`'s own `Filter` contract instead of a container-specific filter API.
- `SecurityFilterChain` contributed to `FilterManager`, not a web container.
- `@Pod`/`@AutoConfiguration` instead of bean declarations.
- No general-purpose expression language — the parser understands a narrow
  security grammar only.
- Tokenisation is cached but the per-call parser state is not yet materialised
  as a persistent AST (tracked refinement in ledger 017).
- Plain Dart objects need either `jl build` metadata or a registered
  `SecurityExpressionPropertyResolver`; ad-hoc classes are not reflectable.

---

## Session policies

| Policy | Context repository | Session creation |
|---|---|---|
| `stateless` | `NullSecurityContextRepository` | never reads or writes a session |
| `never` | `HttpSessionSecurityContextRepository(allowSessionCreation: false)` | reads existing only |
| `ifRequired` | `HttpSessionSecurityContextRepository` | creates when the context changes |
| `always` | `HttpSessionSecurityContextRepository` | always creates |

Stateful policies install `ChangeSessionIdAuthenticationStrategy` on successful
authentication to prevent session fixation. Since Jetleaf cannot change a
session id in place, the strategy creates a new session, migrates attributes,
invalidates the old one and emits a fresh `JSESSIONID` cookie.

---

## Verification

The package ships with published known-answer vectors and adversarial tests:

- RFC 9106 Argon2id PHC vectors
- Favre OpenBSD BCrypt vectors (including non-ASCII and the 72-byte boundary)
- NIST-style PBKDF2 cross-check against `package:crypto`
- RFC 7515 Appendix A.1/A.2/A.3 JWS vectors (HS256, RS256, ES256)
- JWT clock-skew, token-type, audience, algorithm-confusion and JWKS tests
- real-dispatcher and proxy-generation gates (see the rewrite specification)

Run `dart analyze` and `dart test` from the package root.
