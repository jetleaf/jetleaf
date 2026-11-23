/// ⚙️ **Jetleaf Security Configuration & Auto-Configuration**
///
/// This library provides the lambda DSL used to describe web security and the
/// auto-configuration that supplies overridable defaults. [HttpSecurity]
/// collects settings through fluent callbacks and produces a security filter
/// chain; the builder turns CORS, CSRF, rate limiting, session, authentication
/// and authorization settings into concrete filters.
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🧩 The lambda DSL
/// - [HttpSecurity] — entry point for configuring and building a security chain.
/// - [SecurityFilterChainBuilder] — assembles configured components into an ordered chain.
/// - [AuthorizeHttpRequestsConfigurer] — registry mapping request patterns to authorization managers.
/// - [AuthorizedUrl] — terminal builder choosing the policy for matched patterns.
/// - [CsrfConfigurer] — fluent CSRF settings.
/// - [CorsConfigurer] — fluent CORS settings.
/// - [ExceptionHandlingConfigurer] — authentication entry point and denial handler settings.
///
/// ### 📋 Configuration values
/// - [CorsConfiguration] — immutable cross-origin policy.
/// - [CsrfConfiguration] — immutable CSRF policy, with a disabled preset.
/// - [SessionCreationPolicy] — how sessions are created and used.
/// - [SessionManagementConfigurer] — sets the session policy inside the DSL.
///
/// ### 🚀 Auto-configuration
/// - [SecurityAutoConfiguration] — default web security beans guarded by pod conditions.
/// - [MethodSecurityAutoConfiguration] — method interceptor beans for annotation-driven checks.
///
/// ---
///
/// ## 🎯 Usage Example
///
/// ```dart
/// import 'package:jetleaf_security/config.dart';
///
/// final chain = HttpSecurity()
///   ..securityMatcher(PathPatternMatcher('/api/**'))
///   ..csrf((csrf) => csrf.disable())
///   ..cors((cors) => cors.configuration(const CorsConfiguration(
///         allowedOrigins: ['https://app.example.com'],
///       )))
///   ..rateLimit(const RateLimitConfig(capacity: 100, refillTokens: 100))
///   ..sessionManagement((session) {
///     session.sessionCreationPolicy(SessionCreationPolicy.stateless);
///   })
///   ..authorizeHttpRequests((auth) {
///     auth.requestMatchers(['/api/auth/**']).permitAll();
///     auth.requestMatcher('/api/admin/**').hasRole('ADMIN');
///     auth.anyRequest().authenticated();
///   })
///   ..build();
/// ```
library;

export 'src/config/cors_configuration.dart';
export 'src/config/csrf_configuration.dart';
export 'src/config/http_security.dart';
export 'src/config/method_security_auto_configuration.dart';
export 'src/config/method_security_enablement_post_processor.dart';
export 'src/config/security_auto_configuration.dart';
export 'src/config/security_filter_chain_builder.dart';
export 'src/config/session_creation_policy.dart';
export 'src/config/typedefs.dart';
