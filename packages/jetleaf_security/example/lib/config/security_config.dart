import 'package:jetleaf_core/annotation.dart';

import 'package:jetleaf_security/authentication.dart';
import 'package:jetleaf_security/authorization.dart';
import 'package:jetleaf_security/config.dart';
import 'package:jetleaf_security/core.dart';
import 'package:jetleaf_security/crypto.dart';
import 'package:jetleaf_security/filter.dart';
import 'package:jetleaf_security/jwt.dart';

import '../auth/api_key_authentication_provider.dart';
import '../auth/demo_users.dart';
import '../auth/token_service.dart';
import '../filter/api_key_authentication_filter.dart';
import '../filter/request_id_filter.dart';

/// Central security wiring for the demo application.
///
/// The three filter chains are separate pods. The framework's default
/// `FilterChainProxy` Pod discovers all of them and selects the first match,
/// so no custom proxy Pod or override post-processor is needed.
@Configuration()
final class SecurityConfig {
  static const String USER_DETAILS = 'example.userDetailsService';
  static const String JWT_PROVIDER = 'example.jwtProvider';
  static const String AUTH_MANAGER = 'example.authenticationManager';
  static const String TOKEN_SERVICE = 'example.tokenService';
  static const String ROLE_HIERARCHY = 'example.roleHierarchy';
  static const String OAUTH2_CHAIN = 'example.oauth2Chain';
  static const String API_CHAIN = 'example.apiChain';
  static const String SESSION_CHAIN = 'example.sessionChain';

  /// Shared signing settings used by the token endpoints and the filter chain.
  static const signingSecret = 'example-signing-secret-change-me-in-production!';
  static const issuer = 'https://auth.example.com';
  static const audience = 'jetleaf-api';

  const SecurityConfig();

  @Pod(value: USER_DETAILS)
  UserDetailsService userDetailsService(PasswordEncoder encoder) =>
      InMemoryUserDetailsManager(DemoUsers.create(encoder));

  @Pod(value: JWT_PROVIDER)
  JwtTokenProvider jwtProvider() => JwtTokenProvider.hmac(
        secret: signingSecret,
        issuer: issuer,
        audience: audience,
      );

  @Pod(value: ROLE_HIERARCHY)
  RoleHierarchy roleHierarchy() =>
      RoleHierarchy('ROLE_ADMIN > ROLE_MODERATOR > ROLE_USER');

  @Pod(value: TOKEN_SERVICE)
  TokenService tokenService(JwtTokenProvider provider) => TokenService(provider);

  @Pod(value: AUTH_MANAGER)
  AuthenticationManager authenticationManager(
    UserDetailsService users,
    PasswordEncoder encoder,
    JwtTokenProvider jwt,
    AuthenticationEventPublisher eventPublisher,
  ) =>
      ProviderManager(
        [
          DaoAuthenticationProvider(userDetailsService: users, passwordEncoder: encoder),
          jwt,
          ApiKeyAuthenticationProvider({
            'demo-service-key': 'billing-service',
          }),
        ],
        eventPublisher: eventPublisher,
      );

  /// OIDC/resource-server endpoints verify their own tokens, so this chain has
  /// no authentication filter that would try the application's JWT key first.
  @Pod(value: OAUTH2_CHAIN)
  SecurityFilterChain oauth2Chain() => (HttpSecurity()
        ..securityMatcher(PathPatternMatcher('/api/oauth2/**'))
        ..order(-1)
        ..csrf((csrf) => csrf.disable())
        ..authorizeHttpRequests(
          (auth) => auth.anyRequest().permitAll(),
        ))
      .build();

  /// Stateless JWT chain for the REST API.
  @Pod(value: API_CHAIN)
  SecurityFilterChain apiChain(
    AuthenticationManager manager,
    RoleHierarchy hierarchy,
  ) =>
      (HttpSecurity()
            ..securityMatcher(PathPatternMatcher('/api/**'))
            ..order(0)
            ..csrf((csrf) => csrf.disable())
            ..cors((cors) => cors.configuration(const CorsConfiguration(
                  allowedOrigins: ['https://app.example.com'],
                  allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
                  allowedHeaders: [
                    'Authorization',
                    'Content-Type',
                    'X-Api-Key',
                    'X-XSRF-TOKEN'
                  ],
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
            ))
            ..sessionManagement(
              (session) =>
                  session.sessionCreationPolicy(SessionCreationPolicy.stateless),
            )
            ..roleHierarchy(hierarchy)
            ..authenticationManager(manager)
            ..addFilterBefore(RequestIdFilter(), AuthenticationFilter)
            ..addFilterBefore(ApiKeyAuthenticationFilter(manager), AuthenticationFilter)
            ..exceptionHandling((exceptions) {
              exceptions.authenticationEntryPoint(
                const BearerAuthenticationEntryPoint(realm: 'demo-api'),
              );
              exceptions.accessDeniedHandler(const JsonAccessDeniedHandler());
            })
            ..authorizeHttpRequests((auth) => auth
                .requestMatchers([
                  '/api/public/**',
                  '/api/auth/login',
                  '/api/auth/refresh'
                ]).permitAll()
                .requestMatchers(['/api/admin/**']).hasRole('ADMIN')
                .requestMatchers(['/api/service/**']).hasRole('SERVICE')
                .requestMatchers(['/api/oauth2/**']).permitAll()
                .anyRequest().authenticated()))
          .build();

  /// Session-backed chain demonstrating Basic authentication.
  @Pod(value: SESSION_CHAIN)
  SecurityFilterChain sessionChain(AuthenticationManager manager) =>
      (HttpSecurity()
            ..securityMatcher(PathPatternMatcher('/session/**'))
            ..order(1)
            ..csrf((csrf) => csrf.disable())
            ..sessionManagement(
              (session) => session
                  .sessionCreationPolicy(SessionCreationPolicy.ifRequired),
            )
            ..authenticationManager(manager)
            ..authorizeHttpRequests(
              (auth) => auth.anyRequest().authenticated(),
            ))
          .build();
}