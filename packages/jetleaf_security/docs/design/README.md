# Design ledger

This directory is the authoritative specification for the `jetleaf_security` rewrite. The package-level roadmap at `roadmap/jetleaf_security_rewrite.md` explains the process; these records explain *why* each abstraction exists and *how* completion is proven.

## Rule

If implementation reveals a need to deviate from the rewrite specification, **update the relevant ledger record first, then the code.** A change without a ledger entry is a design error.

## Record format

See `000-template.md`. Seven required fields: Design reference, Problem, Invariant, Extension seam, Edge cases, Jetleaf mapping, Gating tests.

## Index

| # | Record | Phase |
|---|---|---|
| 000 | Template | — |
| 001 | SecurityContextHolder | 1 |
| 002 | SecurityContextRepository | 1 |
| 003 | Authentication token invariants | 1 |
| 004 | AuthenticationTrustResolver | 1 |
| 005 | ProviderManager | 2 |
| 006 | AuthenticationEventPublisher | 2 |
| 007 | DaoAuthenticationProvider | 2 |
| 008 | PasswordEncoder family | 2 |
| 009 | SecurityFilterChain / FilterChainProxy | 3 |
| 010 | Filter ordering | 3 |
| 011 | AnonymousAuthenticationFilter | 3 |
| 012 | SecurityContextHolderFilter / OncePerRequestFilter | 3 |
| 013 | CsrfFilter | 3 |
| 014 | ExceptionTranslationFilter | 3 |
| 015 | AuthorizationFilter | 3 |
| 016 | AuthorizationManager family | 3 |
| 017 | SecurityExpressionHandler | 4 |
| 018 | MethodSecurityMetadataSource | 4 |
| 019 | Method interceptors | 4 |
| 020 | HttpSecurity and configurers | 3 / 6 |
| 021 | ObjectPostProcessor | 3 / 6 |
| 022 | JwtDecoder and validator chain | 5 |
| 023 | JWS algorithm allowlist | 5 |
| 024 | JwkSource / RemoteJwkSetSource | 5 |
| 025 | JwtTokenProvider | 5 |
| 026 | OAuth2ResourceServer | 5 |
| 027 | OIDC ID token validation | 5 |
| 028 | RateLimitingFilter | 3 |
| 029 | HeaderWriter / security headers | 3 |
| 030 | Multiple filter chains | 3 |
| 031 | Session management | 1 / 3 |