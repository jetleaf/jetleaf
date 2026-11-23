/// 🛡️ **Jetleaf Security Subsystem**
///
/// A layered security toolkit covering authentication, authorization, token
/// verification, request filtering, and password hashing. Identities are
/// established by authentication providers — including JWT and OAuth2/OIDC
/// verifiers — stored in a security context, and then evaluated by
/// authorization managers and method-security interceptors before a request
/// reaches application code.
///
/// Trust decisions are explicit and fail-closed: signature verification and
/// claim validation precede authority extraction, the authenticated-state
/// setter can only revoke trust, and cryptographic comparisons use constant-time
/// equality where signature bytes are involved.
///
/// ---
///
/// ## 🧭 Subsystem Topology
///
/// ```text
///                    ┌─────────────────────────────────────┐
///                    │          Configuration layer        │
///                    │  HttpSecurity / auto-configuration  │
///                    └──────────────────┬──────────────────┘
///                                       │ builds
/// ┌────────────────────┐       ┌─────────▼──────────────────┐
/// │  Identity layer    │       │       Filter chain         │
/// │  Authentication    │◄─────►│  SecurityFilterChain       │
/// │  UserDetails       │       │  FilterChainProxy          │
/// └─────────┬──────────┘       └─────────┬──────────────────┘
///           │ principals                 │ per-request context
/// ┌─────────▼──────────┐       ┌─────────▼──────────────────┐
/// │   Token layer      │       │      Context layer         │
/// │  JWT / OAuth2/OIDC │       │  SecurityContextHolder     │
/// │  JWK / JWKS / JWA  │       │  context repositories      │
/// └─────────┬──────────┘       └─────────┬──────────────────┘
///           │ authorities                │
/// ┌─────────▼─────────────────────────────▼─────────────────┐
/// │                  Authorization layer                     │
/// │  AuthorizationManager / expressions / method security    │
/// └───────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🧱 Core Contracts & Context
/// - [Authentication] — request/principal token with revoke-only trust.
/// - [GrantedAuthority], [SimpleGrantedAuthority] — authority representation.
/// - [SecurityContext], [SecurityContextHolder] — per-request principal storage.
/// - [SecurityContextRepository], [HttpSessionSecurityContextRepository],
///   [NullSecurityContextRepository] — context persistence strategies.
/// - [UserDetails], [UserDetailsService], [InMemoryUserDetailsManager] — user sources.
/// - [AuthenticationTrustResolver], [AuthenticationTrustResolverImpl] — trust checks.
/// - [SecurityException], [AuthenticationException], [BadCredentialsException],
///   [AccessDeniedException] — security failure hierarchy.
///
/// ### 🔐 Password Hashing
/// - [PasswordEncoder] — hashing and matching contract.
/// - [BCryptPasswordEncoder], [Pbkdf2PasswordEncoder],
///   [Argon2idPasswordEncoder] — concrete hashing schemes.
/// - [DelegatingPasswordEncoder], [PasswordEncoderFactories] — scheme routing.
///
/// ### 🔑 Authentication
/// - [AuthenticationManager], [ProviderManager] — credential processing.
/// - [AuthenticationProvider], [DaoAuthenticationProvider] — provider contracts.
/// - [UsernamePasswordAuthenticationToken], [AnonymousAuthenticationToken] — request tokens.
/// - [AuthenticationEventPublisher], [AuthenticationEvent],
///   [AuthenticationSuccessEvent], [AuthenticationFailureEvent] — outcome events.
/// - [SessionRegistry], [SessionInformation],
///   [SessionAuthenticationStrategy], [SessionFixationProtectionStrategy] — session handling.
///
/// ### 🧾 JWT
/// - [JwtEncoder], [DartJwtEncoder], [JwtDecoder], [DartJwtDecoder] — signing and verification.
/// - [JwtClaimsSet], [JwtValidator], [JwtValidationException] — claims and policy.
/// - [JwtKey], [JwtSecretKey], [JwtRsaKey], [JwtEcKey], [JwsAlgorithms] — key material and algorithms.
/// - [Jwk], [JwkSetSource], [RemoteJwkSetSource], [StaticJwkSetSource] — JWK handling.
/// - [JwtAuthenticationToken], [JwtTokenProvider] — JWT authentication objects and service.
/// - [JwtCrypto], [JwtBase64Url] — cryptographic and encoding primitives.
///
/// ### 🌐 OAuth2 / OIDC
/// - [OAuth2User], [OidcIdToken], [OAuth2AuthenticationToken] — provider principals.
/// - [OAuth2ResourceServer] — bearer-token verification and scope mapping.
/// - [AppleOAuth2Provider], [GoogleOAuth2Provider], [GitHubOAuth2Provider] — provider verifiers.
///
/// ### ✅ Authorization
/// - [AuthorizationManager], [RequestAuthorizationContext],
///   [AuthorizationDecision] — decision contracts.
/// - [AuthorityAuthorizationManager], [AuthenticatedAuthorizationManager],
///   [ExpressionAuthorizationManager], [AuthorizationManagers],
///   [RequestMatcherDelegatingAuthorizationManager] — decision strategies.
/// - [SecurityExpressionParser], [SecurityExpressionHandler],
///   [RoleHierarchy] — expression evaluation.
/// - [PreAuthorize], [PostAuthorize], [Secured], [RolesAllowed],
///   [EnableMethodSecurity] — method-security annotations.
/// - [MethodSecurityInterceptor], [PreAuthorizeAuthorizationManager],
///   [PostAuthorizeAuthorizationManager] — method interception.
///
/// ### 🚿 Filters
/// - [SecurityFilter], [SecurityFilterChain], [FilterChainProxy],
///   [SecurityFilterOrders] — chain infrastructure.
/// - [AuthenticationFilter], [BearerTokenAuthenticationConverter],
///   [BasicAuthenticationConverter] — credential extraction.
/// - [AuthorizationFilter], [AnonymousAuthenticationFilter],
///   [SecurityContextHolderFilter] — identity and access filters.
/// - [CsrfFilter], [CorsFilter], [RateLimitingFilter],
///   [SecurityHeadersFilter], [ExceptionTranslationFilter] — request protection.
///
/// ### ⚙️ Configuration
/// - [HttpSecurity], [SecurityFilterChainBuilder], [EnableWebSecurity] — chain assembly.
/// - [CorsConfiguration], [CsrfConfiguration], [SessionCreationPolicy] — policy objects.
/// - [SecurityAutoConfiguration], [MethodSecurityAutoConfiguration] — wiring entry points.
///
/// ---
///
/// ## 🎯 Usage Example
///
/// ```dart
/// import 'package:jetleaf_security/jetleaf_security.dart';
///
/// void main() async {
///   // Issue and verify a signed access token.
///   final tokens = JwtTokenProvider.hmac(
///     secret: 'a-long-random-secret',
///     issuer: 'https://issuer.example.com',
///     audience: 'orders-api',
///   );
///   final jwt = tokens.generateAccessToken(
///     subject: 'alice',
///     roles: ['USER'],
///   );
///   final claims = await tokens.verifyToken(jwt);
///
///   // Establish an authenticated principal in the security context.
///   final authentication = JwtAuthenticationToken.authenticated(
///     claims: claims,
///     principal: claims.subject,
///     authorities: {SimpleGrantedAuthority('ROLE_USER')},
///   );
///   SecurityContextHolder.getContext().authentication = authentication;
/// }
/// ```
library;

// ============================================================================
// PUBLIC LIBRARY BARRELS
// Each barrel already exports its implementation files; re-exporting the
// barrels keeps this aggregate file to a single source of truth.
// ============================================================================

export 'core.dart';
export 'authentication.dart';
export 'authorization.dart';
export 'annotation.dart';
export 'crypto.dart';
export 'filter.dart';
export 'config.dart';
export 'jwt.dart';
export 'oauth2.dart';
