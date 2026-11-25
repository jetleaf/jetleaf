# 🔐 Jetleaf Security — Authentication, Authorization & JWT

[![pub package](https://img.shields.io/badge/version-1.0.0-blue)](https://pub.dev/packages/jetleaf_security)
[![License: Jetleaf](https://img.shields.io/badge/license-Jetleaf-green)](#license)
[![Dart SDK](https://img.shields.io/badge/sdk-%3E%3D3.9.0-blue)](https://dart.dev)

Enterprise authentication, authorization and security infrastructure for Dart,
built on Jetleaf's IoC, AOP and web filter pipeline.

## 📋 Overview

`jetleaf_security` gives a Jetleaf application a complete security layer:

- **Authentication** — `ProviderManager`, providers for username/password, JWT bearer tokens and API keys
- **Authorization** — URL rules with `HttpSecurity`, plus `@PreAuthorize` / `@PostAuthorize` method guards
- **Filter chain** — an ordered chain of CORS, CSRF, headers, rate limiting, context, authentication and authorization filters
- **JWT & JWK** — HS256 / RS256 / ES256 tokens, signature verification, claim validation and JWKS key lookup
- **Password hashing** — Argon2id, BCrypt and PBKDF2 with `{id}`-prefixed hashes for algorithm migration
- **Sessions** — four creation policies, context repositories, and session-fixation protection
- **Events** — authentication successes and failures published on Jetleaf's application event bus
- **OAuth2 / OIDC** — resource-server bearer verification and Google/Apple/GitHub provider verifiers

If you already know `HttpSecurity`, `ProviderManager`, `SecurityFilterChain` and
`@PreAuthorize`, the API will feel familiar. Everything runs on Jetleaf-native
`@Pod`s and `Filter` contracts, with the current principal carried in a forked
Dart zone instead of a thread-local.

## 🚀 Quick Start

### Installation

```yaml
dependencies:
  jetleaf: ^2.1.0
  jetleaf_web: ^2.1.0
  jetleaf_security: ^1.0.0

dev_dependencies:
  jetleaf_tools: ^1.1.0
```

Import only the barrels you need:

```dart
import 'package:jetleaf_security/config.dart';        // HttpSecurity, auto-configuration
import 'package:jetleaf_security/authentication.dart'; // managers, providers, tokens
import 'package:jetleaf_security/authorization.dart';  // authorization managers, expressions
import 'package:jetleaf_security/annotation.dart';     // @PreAuthorize, @EnableMethodSecurity
import 'package:jetleaf_security/core.dart';           // context, user details, exceptions
import 'package:jetleaf_security/crypto.dart';         // password encoders
import 'package:jetleaf_security/filter.dart';         // filters, matchers, chains
import 'package:jetleaf_security/jwt.dart';            // JWT/JWK API
import 'package:jetleaf_security/oauth2.dart';         // OAuth2/OIDC support
```

`package:jetleaf_security/jetleaf_security.dart` is the unified barrel.

### 1. Wire the security pods

`SecurityAutoConfiguration` installs overridable defaults (trust resolver,
password encoder, context repository, entry point, access-denied handler, filter
chain and proxy). Declare your own pod of any of those types to replace the
default.

```dart
import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_security/annotation.dart';
import 'package:jetleaf_security/authentication.dart';
import 'package:jetleaf_security/config.dart';
import 'package:jetleaf_security/core.dart';
import 'package:jetleaf_security/crypto.dart';
import 'package:jetleaf_security/filter.dart';
import 'package:jetleaf_security/jwt.dart';

@Configuration()
@EnableMethodSecurity()
final class SecurityConfig {
  @Pod()
  PasswordEncoder passwordEncoder() =>
      PasswordEncoderFactories.createDelegatingPasswordEncoder();

  @Pod()
  UserDetailsService userDetailsService(PasswordEncoder encoder) =>
      InMemoryUserDetailsManager([
        SecurityUser.withRoles(
          username: 'alice',
          password: encoder.encode('s3cret'),
          roles: ['ADMIN'],
        ),
        SecurityUser.withRoles(
          username: 'bob',
          password: encoder.encode('hunter2'),
          roles: ['USER'],
        ),
      ]);

  @Pod()
  JwtTokenProvider jwtProvider() => JwtTokenProvider.hmac(
        secret: 'a-long-random-signing-secret-change-me',
        issuer: 'https://auth.example.com',
        audience: 'orders-api',
      );

  @Pod()
  AuthenticationManager authenticationManager(
    UserDetailsService users,
    PasswordEncoder encoder,
    JwtTokenProvider jwt,
    AuthenticationEventPublisher events,
  ) =>
      ProviderManager([
        DaoAuthenticationProvider(
          userDetailsService: users,
          passwordEncoder: encoder,
        ),
        jwt,
      ], eventPublisher: events);

  @Pod()
  SecurityFilterChain apiChain(AuthenticationManager manager) =>
      (HttpSecurity()
            ..securityMatcher(PathPatternMatcher('/api/**'))
            ..csrf((csrf) => csrf.disable())
            ..cors((cors) => cors.configuration(const CorsConfiguration(
                  allowedOrigins: ['https://app.example.com'],
                )))
            ..sessionManagement((session) => session
                .sessionCreationPolicy(SessionCreationPolicy.stateless))
            ..authenticationManager(manager)
            ..authorizeHttpRequests((auth) {
              auth.requestMatchers(['/api/auth/**']).permitAll();
              auth.requestMatcher('/api/admin/**').hasRole('ADMIN');
              auth.anyRequest().authenticated();
            }))
        .build();
}
```

Contribute one or more `SecurityFilterChain` pods. The default `FilterChainProxy`
discovers all of them and dispatches to the first matching chain. Set `order()`
when more than one chain can match.

### 2. Protect controller methods

```dart
@RestController('/api/reports')
class ReportController {
  @PreAuthorize("hasRole('ADMIN') or #orgId == principal.organizationId")
  Future<Report> getReport(String orgId) async { ... }

  @PostAuthorize('returnObject.ownerId == authentication.name')
  Future<AuditLog> getAuditLog(String orgId) async { ... }
}
```

Method security is implemented with generated proxies:

- add `jetleaf_tools` as a dev dependency and run `jl build` (or `jl proxy`);
- secured classes must have a stereotype (`@RestController`, `@Service`,
  `@Component`, `@Configuration`, `@Pod`, …) and must **not** be `final`,
  `sealed` or `mixin class`;
- `@PreAuthorize` / `@PostAuthorize` are enabled by `@EnableMethodSecurity()`;
  `@Secured` and `@RolesAllowed` are enabled with `securedEnabled: true` and
  `jsr250Enabled: true`.

Without proxies, annotations on method calls are inert.

### 3. Issue and verify a JWT

```dart
import 'package:jetleaf_security/jwt.dart';

final provider = JwtTokenProvider.hmac(
  secret: 'a-long-random-signing-secret',
  issuer: 'https://auth.example.com',
  audience: 'orders-api',
);

final token = provider.generateAccessToken(
  subject: 'alice',
  roles: ['ADMIN'],
);

final claims = await provider.verifyToken(token);
print(claims.subject); // alice
```

`JwtTokenProvider` also issues refresh tokens (`generateRefreshToken`) and is an
`AuthenticationProvider`, so adding it to `ProviderManager` lets
`Authorization: Bearer <token>` requests authenticate automatically.

### 4. Hash and upgrade passwords

```dart
import 'package:jetleaf_security/crypto.dart';

final encoder = PasswordEncoderFactories.createDelegatingPasswordEncoder();

final hash = encoder.encode('correct horse battery staple');
// {argon2id}$argon2id$...

print(encoder.matches('correct horse battery staple', hash)); // true

if (encoder.upgradeEncoding(storedHash)) {
  final upgraded = encoder.encode(rawPassword);
  // Persist the new hash, replacing the old one.
}
```

Hashes carry their algorithm id, so stored passwords can be migrated without a
flag day. Argon2id, BCrypt and PBKDF2 also provide `encodeAsync` /
`matchesAsync`, which run the expensive derivation on a separate isolate.

## 📚 Key Features

### 1. Request authorization

Rules are registered with a fluent DSL and evaluated first-match-wins:

```dart
..authorizeHttpRequests((auth) {
  auth.requestMatchers(['/health', '/api/auth/**']).permitAll();
  auth.requestMatcher('/api/admin/**', method: 'GET').hasRole('ADMIN');
  auth.requestMatchers(['/api/manager/**']).hasAnyRole(['ADMIN', 'MANAGER']);
  auth.requestMatcher('/api/reports/**').hasAuthority('REPORT_READ');
  auth.anyRequest().authenticated();
})
```

Terminals include `permitAll()`, `denyAll()`, `authenticated()`, `hasRole()`,
`hasAnyRole()`, `hasAuthority()`, `hasAnyAuthority()` and `access(...)`.
`hasRole` adds the `ROLE_` prefix; `hasAuthority` uses the value verbatim.
Configure role expansion with `..roleHierarchy(hierarchy)` on the chain.

### 2. Multiple filter chains

Chain order and matcher scope keep APIs and browser sessions separate:

```dart
@Pod()
SecurityFilterChain healthChain() => (HttpSecurity()
      ..securityMatcher(PathPatternMatcher('/health/**'))
      ..order(-1)
      ..authorizeHttpRequests((auth) => auth.anyRequest().permitAll()))
    .build();

@Pod()
SecurityFilterChain apiChain(AuthenticationManager manager) => (HttpSecurity()
      ..securityMatcher(PathPatternMatcher('/api/**'))
      ..order(0)
      ..csrf((csrf) => csrf.disable())
      ..authenticationManager(manager)
      ..authorizeHttpRequests((auth) => auth.anyRequest().authenticated()))
    .build();
```

Place custom filters relative to built-ins:

```dart
..addFilterBefore(RequestIdFilter(), AuthenticationFilter)
..addFilterAfter(AuditFilter(), AuthorizationFilter)
```

### 3. JWT, JWK and OAuth2

```dart
// Verify tokens issued by an external identity provider.
final server = OAuth2ResourceServer.withJwkSetUri(
  Uri.parse('https://issuer.example.com/jwks'),
  expectedIssuer: 'https://issuer.example.com',
  expectedAudience: 'orders-api',
);
final principal = await server.authenticateBearer(compactJwt);

// Verify with a locally configured key and algorithm allowlist.
final decoder = DartJwtDecoder.withKey(
  key,
  validator: JwtValidator(
    expectedIssuer: 'https://issuer.example.com',
    expectedAudience: 'orders-api',
    clockSkew: const Duration(seconds: 30),
  ),
);
final claims = decoder.decode(compactJwt);
```

Signatures are verified before claims; algorithms come from a closed allowlist
and keys are filtered by use and type.

### 4. Method security expressions

```dart
@PreAuthorize("hasRole('ADMIN')")
Future<void> deleteUser(String id) async { ... }

@PreAuthorize("hasAuthority('REPORT_READ') and #id.startsWith('rep_')")
Future<Report> load(String id) async { ... }

@RolesAllowed(['ADMIN', 'AUDITOR'])
Report readAuditReport() => ...;
```

The expression grammar supports `hasRole`, `hasAnyRole`, `hasAuthority`,
`isAuthenticated`, `#methodParameter`, `principal.*`, `authentication.*` and
`returnObject.*`. It is deliberately narrow — not a general-purpose language.

### 5. Protection filters

```dart
(HttpSecurity()
  ..csrf((csrf) => csrf.disable()) // or configure double-submit cookie/header
  ..cors((cors) => cors.configuration(const CorsConfiguration(
        allowedOrigins: ['https://app.example.com'],
        allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        allowedHeaders: ['Authorization', 'Content-Type'],
        allowCredentials: true,
        maxAgeSeconds: 3600,
      )))
  ..headers(const SecurityHeadersConfig(
    strictTransportSecurity: 'max-age=31536000; includeSubDomains',
    contentSecurityPolicy: "default-src 'self'",
  ))
  ..rateLimit(const RateLimitConfig(
    capacity: 120,
    refillTokens: 120,
    refillPeriod: Duration(minutes: 1),
    trustedProxies: {'127.0.0.1'},
  )))
  ..build();
```

CSRF, exception translation, context binding and the final authorization gate
are always present. CORS, headers and rate limiting are added only when
configured.

### 6. Session policies

```dart
..sessionManagement((session) =>
    session.sessionCreationPolicy(SessionCreationPolicy.ifRequired))
```

| Policy | Context storage | Behaviour |
| :--- | :--- | :--- |
| `stateless` | `NullSecurityContextRepository` | Never reads or writes a session |
| `never` | `HttpSessionSecurityContextRepository` (no creation) | Reads an existing session only |
| `ifRequired` | `HttpSessionSecurityContextRepository` | Creates a session when the context changes |
| `always` | `HttpSessionSecurityContextRepository` | Always creates a session |

Stateful policies add session-fixation protection: a successful login migrates
attributes into a fresh session, invalidates the old one and emits a new
`JSESSIONID` cookie.

### 7. Security context

The active identity lives in a forked zone, not a thread-local:

```dart
import 'package:jetleaf_security/core.dart';

await SecurityContextHolder.runWithContext(() async {
  SecurityContextHolder.setContext(context);
  final auth = SecurityContextHolder.getContext().authentication;
  if (auth == null || !auth.isAuthenticated) {
    throw InsufficientAuthenticationException();
  }
  print('Welcome, ${auth.name}');
});
```

`SecurityContextHolderFilter` loads, binds, saves and clears the context for
each request.

### 8. Authentication events

`BusAuthenticationEventPublisher` publishes outcomes to the application event
bus. Pass it to `ProviderManager` and observe it from any pod:

```dart
@Component()
class LoginAudit {
  @EventListener()
  void onSuccess(AuthenticationSuccessEvent event) {
    print('login: ${event.authentication.name}');
  }

  @EventListener()
  void onFailure(AuthenticationFailureEvent event) {
    print('failed login: ${event.exception.message}');
  }
}
```

## 🎯 Common Patterns

### Pattern 1: Stateless REST API

Disable CSRF, use a stateless session policy, and register both the password and
JWT providers on the manager. Clients send `Authorization: Bearer <token>`;
401 responses come from `BearerAuthenticationEntryPoint`, 403 responses from
`JsonAccessDeniedHandler`.

### Pattern 2: Browser sessions with Basic authentication

Use `SessionCreationPolicy.ifRequired`, keep CSRF enabled, and let the
`BasicAuthenticationConverter` read credentials from the `Authorization` header.
`ChangeSessionIdAuthenticationStrategy` protects against fixation on login.

### Pattern 3: Role hierarchy

```dart
@Pod()
RoleHierarchy roleHierarchy() =>
    RoleHierarchy('ROLE_ADMIN > ROLE_MODERATOR > ROLE_USER');

// ...and in the chain:
..roleHierarchy(hierarchy)
```

An `ADMIN` then satisfies rules that require `MODERATOR` or `USER`.

### Pattern 4: Load users from your own database

Implement `UserDetailsService` and hand it to `DaoAuthenticationProvider`:

```dart
class DatabaseUserDetailsService implements UserDetailsService {
  DatabaseUserDetailsService(this._users);

  final UserRepository _users;

  @override
  Future<UserDetails> loadUserByUsername(String username) async {
    final row = await _users.findByUsername(username);
    if (row == null) throw UsernameNotFoundException(username);

    return SecurityUser.withRoles(
      username: row.username,
      password: row.passwordHash,
      roles: row.roles,
    );
  }
}
```

For a custom credential shape, implement `AuthenticationProvider`, define
`supports(Authentication)`, and add it to `ProviderManager`. Providers are tried
in order; the first one returning a trusted token wins.

## ⚠️ Common Issues

| Issue | Cause | Solution |
| :--- | :--- | :--- |
| `@PreAuthorize` has no effect | No generated proxy for the target class | Run `jl build` / `jl proxy`; remove `final` / `sealed` / `mixin class`; add a stereotype |
| Every request returns 401 | No authentication filter or no supporting provider | Pass an `AuthenticationManager` to the chain and include a provider for your token type |
| Every request returns 403 | Missing role or authority | Check `hasRole` adds `ROLE_`; use `hasAuthority` for exact strings |
| No port is bound when using `dart run` | AOT registrar missing | Use `jl dev` + `jl run`, or pass `registerGeneratedArtifacts` in the entrypoint |
| Session context is lost | `stateless` policy uses the null repository | Switch to `ifRequired` or `always` for session-backed auth |
| CSRF rejects a valid client request | Missing double-submit cookie/header | Send the CSRF cookie value in the configured header, or disable CSRF for a pure bearer-token API |
| JWT verification fails | Issuer/audience/clock-skew mismatch | Match `JwtValidator` settings to the issuing provider |
| Password check always fails | Stored hash produced by a different algorithm | Use `PasswordEncoderFactories.createDelegatingPasswordEncoder()` and keep `{id}` prefixes |

## 📋 Best Practices

### ✅ DO

- Use one chain per application surface (API vs. browser), ordered explicitly
- Prefer `hasRole` for roles and `hasAuthority` for exact permission strings
- Store `{id}`-prefixed password hashes and re-encode when `upgradeEncoding` reports true
- Keep signing secrets out of source control; use environment configuration
- Use `stateless` for bearer-token APIs and a stateful policy only when you need sessions
- Register authentication event listeners for audit trails
- Run `jl build` after changing security annotations

### ❌ DON'T

- Disable CSRF on a cookie-authenticated browser application
- Put `@PreAuthorize` on `final`, `sealed` or non-pod classes and expect interception
- Trust a JWT before verifying signature, issuer, audience and expiry
- Log raw passwords or credentials from authentication events
- Use `denyAll()` as the fallback for a public API by accident — check `anyRequest()`
- Reuse a signing secret across environments

## 🧪 Testing

```bash
dart analyze
dart test
```

The suite includes known-answer vectors (Argon2id, BCrypt, PBKDF2 and RFC 7515
JWS), JWT clock-skew/algorithm-confusion/JWKS tests, and filter-chain and
proxy-generation gates.

## 📦 Dependencies

- **`jetleaf_core`** — IoC container, annotations, events and exceptions
- **`jetleaf_web`** — HTTP filters, sessions and request/response types
- **`crypto`** and **`pointycastle`** — hashing and signing primitives
- **`jetleaf_tools`** (dev) — `jl build` / `jl proxy` for generated proxies

## 📄 License

This package is part of the Jetleaf Framework. See LICENSE in the root directory.

## 🔗 Related Packages

- **`jetleaf`** — Framework bootstrap and lifecycle
- **`jetleaf_web`** — HTTP server and MVC
- **`jetleaf_validation`** — Request data validation
- **`jetson`** — JSON serialization

## 📞 Support

For issues, questions, or contributions, visit:

- [GitHub Issues](https://github.com/jetleaf/jetleaf/issues)
- [Documentation](https://jetleaf.hapnium.com/docs/security)
- [Community Forum](https://forum.jetleaf.hapnium.com)

---

**Created with ❤️ by [Hapnium](https://hapnium.com)**