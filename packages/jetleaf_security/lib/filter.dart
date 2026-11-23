/// 🛡️ **Jetleaf Security Filters & Filter Chains**
///
/// This library exposes the filter pipeline that enforces web security in
/// Jetleaf. A [FilterChainProxy] selects a [SecurityFilterChain] for each
/// request, and that chain runs its ordered [SecurityFilter]s before handing
/// control to the application. Filters cover cross-origin handling, rate
/// limiting, response headers, CSRF, exception translation, context binding,
/// authentication, anonymous principals and final authorization.
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🔗 Core contracts & chain assembly
/// - [SecurityFilter] — base type adding an execution order to the web filter contract.
/// - [SecurityFilterChain] — ordered collection of filters guarded by a matcher.
/// - [FilterChainProxy] — web filter that selects and runs the first matching chain.
/// - [SecurityFilterOrders] — canonical order constants for built-in filters.
///
/// ### 🎯 Request matching
/// - [RequestMatcher] — strategy deciding whether a chain governs a request.
/// - [AnyRequestMatcher] — matcher accepting every request.
/// - [PathPatternMatcher] — Ant-style path and optional method matcher.
///
/// ### 🔐 Authentication filters
/// - [AuthenticationFilter] — extracts credentials and authenticates them.
/// - [AuthenticationConverter] — strategy turning a request into a token.
/// - [BearerTokenAuthenticationConverter] — reads `Authorization: Bearer`.
/// - [BasicAuthenticationConverter] — reads `Authorization: Basic`.
/// - [AnonymousAuthenticationFilter] — installs a synthetic principal when none exists.
///
/// ### 🧱 Protection filters
/// - [CorsFilter] — applies cross-origin policy and answers preflight requests.
/// - [RateLimitingFilter] — token-bucket quota enforcement with standard headers.
/// - [RateLimitConfig] — capacity, refill and client-key settings.
/// - [CsrfFilter] — double-submit cookie/header CSRF validation.
/// - [SecurityHeadersFilter] — writes a composed set of response headers.
/// - [SecurityHeadersConfig] — values for the default security headers.
/// - [HeaderWriter] — strategy for writing one header or header group.
/// - [StaticHeaderWriter] — writer for a fixed header value.
///
/// ### 🧭 Context, errors & decisions
/// - [SecurityContextHolderFilter] — loads, binds, saves and clears the context.
/// - [ExceptionTranslationFilter] — converts security exceptions into 401/403 responses.
/// - [AuthorizationFilter] — final URL-level access gate.
/// - [AuthorizationRule] — matcher plus typed authorization manager pair.
///
/// ---
///
/// ## 🎯 Usage Example
///
/// ```dart
/// import 'package:jetleaf_security/filter.dart';
///
/// final chain = SecurityFilterChain(
///   requestMatcher: PathPatternMatcher('/api/**'),
///   filters: [
///     CorsFilter(const CorsConfiguration(allowedOrigins: ['https://app.example.com'])),
///     SecurityContextHolderFilter(),
///     AuthenticationFilter(authenticationManager: manager),
///     AuthorizationFilter(rules: rules),
///   ],
/// );
///
/// final proxy = FilterChainProxy([chain]);
/// ```
library;

export 'src/filter/anonymous_authentication_filter.dart';
export 'src/filter/authentication_filter.dart';
export 'src/filter/authorization_filter.dart';
export 'src/filter/cors_filter.dart';
export 'src/filter/csrf_filter.dart';
export 'src/filter/exception_translation_filter.dart';
export 'src/filter/filter_chain_proxy.dart';
export 'src/filter/filter_orders.dart';
export 'src/filter/header_writer.dart';
export 'src/filter/rate_limiting_filter.dart';
export 'src/filter/security_context_holder_filter.dart';
export 'src/filter/security_exception_resolver.dart';
export 'src/filter/security_filter.dart';
export 'src/filter/security_filter_chain.dart';
export 'src/filter/security_headers_filter.dart';
export 'src/filter/typedefs.dart';
