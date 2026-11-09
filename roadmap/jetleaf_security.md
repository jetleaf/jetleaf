# `jetleaf_security`: Architectural Specification & Implementation Roadmap

> **Enterprise Authentication, Authorization & Security Infrastructure for Dart**  
> Status: Canonical Production Specification  
> Package: `packages/jetleaf_security`  
> Author: Evaristus Adimonyemma & Jetleaf Architecture Team  
> Architectural Benchmark: Spring Security (Spring Security 6+ Lambda DSL)

---

## 1. Executive Summary & Core Philosophy

### 1.1 The Objective
`jetleaf_security` provides the Dart backend ecosystem with an enterprise-grade, defense-in-depth security framework modeled after **Spring Security 6+**.

It delivers:
- **Filter-Chain Pipeline**: Declarative request processing for CORS, CSRF, rate-limiting, and headers.
- **Strict Separation of Concerns**: Uncompromising architectural boundary between **Authentication** (identity verification) and **Authorization** (access control).
- **Stateless-First Token Architecture**: Native JWT (HMAC, RSA, ECDSA) and OAuth2 / OpenID Connect (OIDC) Resource Server capabilities.
- **Fine-Grained Declarative Method Security**: SpEL-style method security annotations (`@PreAuthorize`, `@PostAuthorize`, `@Secured`, `@RolesAllowed`).
- **Cryptographic Rigor**: Default Argon2id and BCrypt password hashing conforming to current OWASP guidelines.
- **100% Inversion of Control**: Every component — from password encoders to authentication providers and filter positions — can be overridden by user implementations without touching framework internals.

### 1.2 Separation of Concerns & DRY Principles
```
┌────────────────────────────────────────────────────────────────────────┐
│                        INCOMING HTTP REQUEST                           │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      SECURITY FILTER CHAIN PIPELINE                    │
│   CorsFilter ➔ RateLimitingFilter ➔ SecurityHeadersFilter ➔ CsrfFilter │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     AUTHENTICATION SUBSYSTEM                           │
│   AuthenticationFilter ➔ AuthenticationManager ➔ AuthenticationProvider│
│   (JWT / OAuth2 / OIDC / Username-Password / API Key)                  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼ Populates SecurityContext
┌────────────────────────────────────────────────────────────────────────┐
│                  SECURITY CONTEXT & ZONE PROPAGATION                   │
│   SecurityContextHolder (Zone-local Principal & Granted Authorities)   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      AUTHORIZATION SUBSYSTEM                           │
│   AuthorizationFilter (Route Matchers) ➔ MethodSecurityInterceptor     │
│   (@PreAuthorize / @Secured / Role Hierarchy Validation)               │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      DESTINATION @RestController                       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Package File Structure (`packages/jetleaf_security`)

```text
packages/jetleaf_security/
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
├── lib/
│   ├── jetleaf_security.dart             # Unified root export
│   └── src/
│       ├── core/                         # Core security domain abstractions
│       │   ├── authentication.dart
│       │   ├── granted_authority.dart
│       │   ├── simple_granted_authority.dart
│       │   ├── security_context.dart
│       │   ├── security_context_holder.dart
│       │   ├── user_details.dart
│       │   ├── user_details_service.dart
│       │   └── in_memory_user_details_manager.dart
│       ├── crypto/                       # Cryptographic password encoders
│       │   ├── password_encoder.dart
│       │   ├── argon2id_password_encoder.dart
│       │   ├── bcrypt_password_encoder.dart
│       │   └── pbkdf2_password_encoder.dart
│       ├── filter/                       # Security filter chain implementations
│       │   ├── security_filter.dart
│       │   ├── security_filter_chain.dart
│       │   ├── cors_filter.dart
│       │   ├── csrf_filter.dart
│       │   ├── rate_limiting_filter.dart
│       │   ├── security_headers_filter.dart
│       │   ├── authentication_filter.dart
│       │   ├── authorization_filter.dart
│       │   └── exception_translation_filter.dart
│       ├── config/                       # Fluent DSL configuration builder
│       │   ├── http_security.dart
│       │   ├── security_filter_chain_builder.dart
│       │   ├── cors_configuration.dart
│       │   ├── csrf_configuration.dart
│       │   ├── session_creation_policy.dart
│       │   └── enable_web_security.dart
│       ├── auth/                         # Authentication managers & providers
│       │   ├── authentication_manager.dart
│       │   ├── provider_manager.dart
│       │   ├── authentication_provider.dart
│       │   ├── dao_authentication_provider.dart
│       │   ├── username_password_authentication_token.dart
│       │   └── anonymous_authentication_token.dart
│       ├── jwt/                          # Stateless JSON Web Token engine
│       │   ├── jwt_token_provider.dart
│       │   ├── jwt_authentication_token.dart
│       │   ├── jwt_decoder.dart
│       │   ├── jwt_encoder.dart
│       │   ├── jwt_claims_set.dart
│       │   ├── jwt_validator.dart
│       │   └── jwk_set_source.dart       # JSON Web Key Set (remote JWKS)
│       ├── oauth2/                       # OAuth2 & OpenID Connect support
│       │   ├── oauth2_resource_server.dart
│       │   ├── oidc_id_token.dart
│       │   ├── oauth2_authentication_token.dart
│       │   ├── oauth2_user.dart
│       │   └── providers/
│       │       ├── google_oauth2_provider.dart
│       │       ├── apple_oauth2_provider.dart
│       │       └── github_oauth2_provider.dart
│       └── authorization/                # Declarative RBAC & method security
│           ├── annotations.dart          # @PreAuthorize, @PostAuthorize, @Secured, @RolesAllowed
│           ├── expression_parser.dart    # Security expression parser (hasRole, hasAuthority)
│           ├── method_security_interceptor.dart
│           ├── role_hierarchy.dart
│           ├── access_denied_handler.dart
│           └── authentication_entry_point.dart
└── test/
    ├── crypto/
    │   ├── argon2id_test.dart
    │   └── bcrypt_test.dart
    ├── jwt/
    │   └── jwt_token_provider_test.dart
    ├── filter/
    │   ├── security_filter_chain_test.dart
    │   └── rate_limiting_filter_test.dart
    └── authorization/
        └── method_security_test.dart
```

---

## 3. Core Security Abstractions & Domain Model

### 3.1 Authentication & Principal Contract
An immutable representation of a verified or in-flight security identity:

```dart
abstract interface class Authentication {
  /// The principal identity (e.g. `UserDetails` object, user ID, or username).
  Object get principal;

  /// The proof of identity (password, JWT string, bearer token).
  Object? get credentials;

  /// The granted permissions and roles (e.g. `ROLE_ADMIN`, `READ_DOCS`).
  Set<GrantedAuthority> get authorities;

  /// Whether the credentials have been verified by an AuthenticationManager.
  bool get isAuthenticated;

  /// Details of the request (IP address, user agent, session ID).
  Object? get details;
}

abstract interface class GrantedAuthority {
  String get authority;
}

final class SimpleGrantedAuthority implements GrantedAuthority {
  @override
  final String authority;
  const SimpleGrantedAuthority(this.authority);
}
```

### 3.2 SecurityContext & Isolate Zone Holder
Because Dart isolates run on an asynchronous event loop without thread-local storage, `jetleaf_security` manages the `SecurityContext` through Dart's **`Zone`**:

```dart
final class SecurityContext {
  Authentication? authentication;
  SecurityContext([this.authentication]);
}

abstract final class SecurityContextHolder {
  static const Symbol _contextKey = #_jetleafSecurityContext;

  static SecurityContext get context {
    final ctx = Zone.current[_contextKey] as SecurityContext?;
    return ctx ?? SecurityContext();
  }

  static R runWithContext<R>(SecurityContext context, R Function() computation) {
    return runZoned(
      computation,
      zoneValues: {_contextKey: context},
    );
  }
}
```

---

## 4. The Security Filter Chain Pipeline

Every incoming HTTP request traverses an ordered chain of `SecurityFilter` instances before reaching the `@RestController`:

| Order | Filter | Responsibility |
| :---: | :--- | :--- |
| **1** | `CorsFilter` | Validates `Origin`, handles `OPTIONS` pre-flight, sets `Access-Control-*` headers. |
| **2** | `RateLimitingFilter` | Enforces client IP/token rate limits (Token Bucket / Redis) to mitigate DoS. |
| **3** | `SecurityHeadersFilter` | Emits `Strict-Transport-Security` (HSTS), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`. |
| **4** | `CsrfFilter` | Validates anti-CSRF token on state-changing requests (`POST`, `PUT`, `DELETE`). |
| **5** | `AuthenticationFilter` | Extracts credentials (Bearer JWT, Basic Auth, API Key) and authenticates. |
| **6** | `SecurityContextHolderFilter` | Binds the authenticated `SecurityContext` to the active Dart Zone. |
| **7** | `AuthorizationFilter` | Validates request against route pattern authorization rules (`requestMatchers`). |
| **8** | `ExceptionTranslationFilter` | Catches security exceptions, emitting HTTP 401 Unauthorized or 403 Forbidden. |

---

## 5. Fluent Configuration DSL (Spring Security 6+ Style)

Developers configure the entire security architecture using an expressive, type-safe builder:

```dart
@Configuration()
final class SecurityConfig {

  @Pod()
  SecurityFilterChain filterChain(HttpSecurity http) {
    return http
      // 1. CORS Configuration
      .cors((cors) => cors.configuration(CorsConfiguration(
        allowedOrigins: ['https://myapp.com', 'http://localhost:3000'],
        allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
        allowedHeaders: ['Authorization', 'Content-Type', 'X-Requested-With'],
        allowCredentials: true,
        maxAgeSeconds: 3600,
      )))
      
      // 2. CSRF (Disabled for stateless REST APIs)
      .csrf((csrf) => csrf.disable())

      // 3. Rate Limiting
      .rateLimiting((rate) => rate
        .maxRequestsPerMinute(120)
        .byIp()
      )

      // 4. Stateless Session Policy
      .sessionManagement((session) => session
        .sessionCreationPolicy(SessionCreationPolicy.stateless)
      )

      // 5. Request Authorization Matchers
      .authorizeHttpRequests((auth) => auth
        .requestMatchers(['/api/v1/auth/**', '/actuator/health']).permitAll()
        .requestMatchers(['/api/v1/admin/**']).hasRole('ADMIN')
        .requestMatchers(['/api/v1/billing/**']).hasAnyAuthority(['ROLE_ADMIN', 'READ_BILLING'])
        .anyRequest().authenticated()
      )

      // 6. JWT Token Filter Integration
      .jwt((jwt) => jwt
        .tokenProvider(CustomJwtTokenProvider())
      )

      .build();
  }

  @Pod()
  PasswordEncoder passwordEncoder() {
    // OWASP Recommended Default: Argon2id
    return Argon2idPasswordEncoder(
      memoryCostKb: 65536,
      iterations: 3,
      parallelism: 4,
    );
  }
}
```

---

## 6. Stateless JWT Engine & OAuth2 Resource Server

### 6.1 JWT Engine Architecture
`jetleaf_security` provides native JWT issuance and validation without external native dependencies:
- **Algorithms Supported**:
  - Symmetric HMAC: `HS256`, `HS384`, `HS512`.
  - Asymmetric RSA: `RS256`, `RS384`, `RS512` (with automated JWKS retrieval).
  - Asymmetric ECDSA: `ES256`, `ES384`, `ES512`.
- **Claims Verification**:
  - Validates `exp` (expiration with configurable clock skew, e.g. 60 seconds).
  - Validates `nbf` (not before) and `iat` (issued at).
  - Validates `iss` (issuer) and `aud` (audience).

### 6.2 OAuth2 & OpenID Connect (OIDC) Resource Server
To integrate with external identity providers (Auth0, Supabase, Firebase Auth, Keycloak, AWS Cognito):

```dart
@Pod()
SecurityFilterChain oauth2Security(HttpSecurity http) {
  return http
    .oauth2ResourceServer((oauth2) => oauth2
      .jwt((jwt) => jwt
        .jwkSetUri('https://auth.company.com/.well-known/jwks.json')
        .issuerUri('https://auth.company.com/')
        .jwtAuthenticationConverter(CustomJwtAuthorityConverter())
      )
    )
    .build();
}
```

---

## 7. Declarative Method Security (`@PreAuthorize`)

Fine-grained authorization can be declared directly on controller handlers or business service methods:

```dart
@RestController()
@RequestMapping('/api/v1/organizations')
final class OrganizationController {

  // Role-based authorization
  @PostMapping('/')
  @Secured(['ROLE_SUPER_ADMIN'])
  Future<Organization> createOrg(@RequestBody CreateOrgRequest request) async { ... }

  // SpEL-style expression with runtime parameter binding
  @GetMapping('/{orgId}/reports')
  @PreAuthorize("hasRole('ADMIN') or (hasRole('MEMBER') and #orgId == principal.organizationId)")
  Future<Report> getReports(@PathVariable('orgId') String orgId) async { ... }

  // Post-invocation validation on return value
  @GetMapping('/{orgId}/audit')
  @PostAuthorize("returnObject.ownerId == principal.id")
  Future<AuditLog> getAuditLog(@PathVariable('orgId') String orgId) async { ... }
}
```

### Expression Evaluation Language (SpEL-Equivalent)
The built-in expression parser supports:
- `hasRole('NAME')` (automatically checks for `ROLE_NAME`)
- `hasAnyRole(['A', 'B'])`
- `hasAuthority('PERMISSION')`
- `hasAnyAuthority(['PERM_1', 'PERM_2'])`
- `isAuthenticated()` / `isAnonymous()`
- Method parameter access via `#paramName`
- Principal properties access via `principal.property`

---

## 8. Extensibility: Overriding Built-In Implementations

### 8.1 Custom `UserDetailsService` (Database Integration)
Integrating with `jetleaf_data`:

```dart
@Pod()
final class DatabaseUserDetailsService implements UserDetailsService {
  final UserRepository _userRepo;

  DatabaseUserDetailsService(this._userRepo);

  @override
  Future<UserDetails> loadUserByUsername(String username) async {
    final user = await _userRepo.findByEmail(username);
    if (user == null) {
      throw UsernameNotFoundException("User not found: $username");
    }

    return UserDetails(
      username: user.email,
      password: user.passwordHash,
      enabled: user.isActive,
      authorities: user.roles.map((r) => SimpleGrantedAuthority('ROLE_$r')).toSet(),
    );
  }
}
```

### 8.2 Adding Custom Security Filters
Users can insert custom filters at any point in the pipeline:

```dart
@Pod()
SecurityFilterChain customFilterPipeline(HttpSecurity http) {
  return http
    .addFilterBefore(CustomApiKeyFilter(), AuthenticationFilter)
    .addFilterAfter(AuditLoggingFilter(), AuthorizationFilter)
    .build();
}
```

---

## 9. Verification & Testing Strategy

1. **Cryptographic Tests**: Verify Argon2id and BCrypt against standard known vector test suites.
2. **JWT Signature & Clock Skew Tests**: Validate expired tokens, tampered signatures, and boundary clock skew tests.
3. **Filter Chain Integration Tests**: Use mock HTTP requests to verify complete pipeline execution, CORS pre-flight assertions, and rate-limiting throttling.
4. **Method Security Proxy Tests**: Verify that `@PreAuthorize` prevents method execution when authorities do not match, throwing an `AccessDeniedException`.
