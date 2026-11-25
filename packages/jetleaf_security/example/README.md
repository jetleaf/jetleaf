# Jetleaf Security example application

A runnable Jetleaf web application that exercises `jetleaf_security` end to end.
It starts a real `IoWebServer` with generated AOT registries, configures three
security filter chains, and verifies behaviour with real HTTP requests.

## Run

```bash
cd packages/jetleaf_security/example
dart run jetleaf_tools build   # regenerate AOT registries and proxies
dart run jetleaf:jetleaf       # or: dart run bin/... (see package:jetleaf)
dart test                      # 18 E2E tests + OAuth2 smoke test
```

## What it demonstrates

| Area | Where |
|---|---|
| Three `SecurityFilterChain` pods + default proxy auto-discovery | `lib/config/security_config.dart` |
| Lambda DSL: CORS, CSRF, headers, rate limiting, exception handling | `lib/config/security_config.dart` |
| Stateless JWT chain (`/api/**`) | `apiChain` in `security_config.dart` |
| Session-backed Basic-auth chain (`/session/**`) | `sessionChain` in `security_config.dart` |
| Chain with no bearer filter for OIDC endpoints (`/api/oauth2/**`) | `oauth2Chain` in `security_config.dart` |
| Custom `Authentication`, provider and `addFilterBefore` filter | `lib/auth/api_key_*`, `lib/filter/api_key_authentication_filter.dart` |
| `ProviderManager` with DAO, JWT and custom providers | `authenticationManager()` in `security_config.dart` |
| Password hashing via delegating encoder with `{id}` prefixes | `lib/auth/demo_users.dart` |
| JWT access/refresh issuance and refresh-token type checks | `lib/auth/token_service.dart`, `/api/auth/*` |
| `@PreAuthorize` with `#param` and `principal.organizationId` | `OrganizationController.reports` |
| `@PostAuthorize` with `returnObject` | `OrganizationController.audit` |
| `@Secured`, `@RolesAllowed`, role hierarchy | `AdminController` |
| `hasAuthority` | `OrganizationController.allReports` |
| OAuth2 resource server with a local JWKS | `/api/oauth2/resource`, `lib/config/oauth2_config.dart` |
| OIDC ID-token validation with nonce and `azp` | `/api/oauth2/google`, `/api/oauth2/apple` |
| Authentication event publisher | `lib/auth/audit_event_publisher.dart` |
| `setAuthentication` / direct setter | `SecurityContext` (covered by package tests) |

## Endpoints

- `GET /api/public/health`, `GET /api/public/echo?message=…`
- `POST /api/auth/login?username=…&password=…`, `POST /api/auth/refresh?token=…`, `GET /api/auth/me`
- `GET /api/admin/stats`, `GET /api/admin/audit`, `GET /api/admin/user-access` (role hierarchy)
- `GET /api/orgs/{orgId}/reports`, `GET /api/orgs/{orgId}/audit`, `GET /api/orgs/reports`
- `GET /api/service/status` with `X-Api-Key: demo-service-key`
- `GET /session/profile` with Basic auth
- `GET /api/oauth2/token?subject=…&provider=google|apple|resource&nonce=…`
- `GET /api/oauth2/google?idToken=…&nonce=…`, `/api/oauth2/apple`, `/api/oauth2/resource`

Demo passwords are `password` for `alice`, `bob`, `admin`, `locked` and `disabled`.