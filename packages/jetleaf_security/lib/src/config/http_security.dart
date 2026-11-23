import 'typedefs.dart';
import '../authentication/authentication_manager.dart';
import '../authorization/access_denied_handler.dart';
import '../authorization/authorization_manager.dart';
import '../authorization/authorization_managers.dart';
import '../authorization/authority_authorization_manager.dart';
import '../authorization/authenticated_authorization_manager.dart';
import '../authorization/expression_authorization_manager.dart';
import '../authorization/authentication_entry_point.dart';
import '../authorization/role_hierarchy.dart';
import '../filter/authentication_filter.dart';
import '../filter/authorization_filter.dart';
import '../filter/rate_limiting_filter.dart';
import '../filter/security_filter.dart';
import '../filter/security_filter_chain.dart';
import '../filter/security_headers_filter.dart';
import 'cors_configuration.dart';
import 'csrf_configuration.dart';
import 'security_filter_chain_builder.dart';
import 'session_creation_policy.dart';

/// {@template authorize_http_requests_configurer}
/// Fluent registry that maps request patterns to typed authorization managers.
///
/// Each call to [requestMatchers], [requestMatcher] or [anyRequest] returns an
/// [AuthorizedUrl] whose terminal method records one or more
/// [AuthorizationRule]s. Rules accumulate in call order and are later consumed
/// by [AuthorizationFilter], which applies first-match-wins semantics.
///
/// ### Contract and invariants
/// - Patterns are Ant-style and are compiled into [PathPatternMatcher]
///   instances at registration time.
/// - Multiple patterns registered in one call produce one rule per pattern.
/// - The accumulated rule list is unmodifiable when exposed through [rules].
///
/// ### Example
/// ```dart
/// auth.requestMatchers(['/api/public/**']).permitAll();
/// auth.requestMatcher('/api/admin/**').hasRole('ADMIN');
/// auth.anyRequest().authenticated();
/// ```
/// {@endtemplate}
class AuthorizeHttpRequestsConfigurer {
  /// {@template authorize_http_requests_configurer.rules}
  /// Ordered rules accumulated by the fluent calls on this configurer.
  /// {@endtemplate}
  final List<AuthorizationRule> _rules = [];

  /// Registers rules for one or more Ant-style [patterns].
  ///
  /// ### Parameters
  /// - [patterns]: Path patterns to match; one rule is created per pattern.
  /// - [method]: Optional HTTP method restricting the match; null matches any
  ///   method.
  ///
  /// ### Returns
  /// An [AuthorizedUrl] used to choose the terminal authorization policy.
  ///
  /// ### Example
  /// ```dart
  /// configurer.requestMatchers(['/api/**', '/health'], method: 'GET').permitAll();
  /// ```
  AuthorizedUrl requestMatchers(List<String> patterns, {String? method}) => AuthorizedUrl(
    patterns.map((p) => PathPatternMatcher(p, method: method)).toList(),
    _rules,
    this,
  );

  /// Registers rules for a single Ant-style [pattern].
  ///
  /// ### Parameters
  /// - [pattern]: The Ant-style path pattern to match.
  /// - [method]: Optional HTTP method restricting the match.
  ///
  /// ### Returns
  /// An [AuthorizedUrl] used to choose the terminal authorization policy.
  AuthorizedUrl requestMatcher(String pattern, {String? method}) => AuthorizedUrl([PathPatternMatcher(pattern, method: method)], _rules, this);

  /// Registers a fallback rule matching any remaining request.
  ///
  /// ### Returns
  /// An [AuthorizedUrl] for the catch-all matcher.
  ///
  /// ### Example
  /// ```dart
  /// configurer.anyRequest().authenticated();
  /// ```
  AuthorizedUrl anyRequest() => AuthorizedUrl([const AnyRequestMatcher()], _rules, this);

  /// Returns the accumulated ordered [AuthorizationRule] list.
  ///
  /// ### Returns
  /// An unmodifiable view of the registered rules, in declaration order.
  List<AuthorizationRule> get rules => List.unmodifiable(_rules);
}

/// {@template authorized_url}
/// Fluent terminal builder specifying the required authorization policy for
/// matched request patterns.
///
/// Every terminal method appends a rule for each stored matcher and returns the
/// owning [AuthorizeHttpRequestsConfigurer] so calls can be chained in the
/// lambda DSL without re-declaring the matcher.
///
/// ### Contract
/// - A terminal method may be called once per [AuthorizedUrl] in typical use;
///   calling it more than once appends additional rules.
/// - `hasRole` prefixes the supplied name with `ROLE_`; `hasAuthority` uses the
///   value verbatim.
/// - [access] parses its expression once, at configuration time.
///
/// ### Example
/// ```dart
/// auth.requestMatcher('/admin/**').hasAnyRole(['ADMIN', 'STAFF']);
/// auth.anyRequest().denyAll();
/// ```
/// {@endtemplate}
class AuthorizedUrl {
  /// {@template authorized_url.matchers}
  /// Matchers selected by the preceding registry call.
  /// {@endtemplate}
  final List<RequestMatcher> _matchers;

  /// {@template authorized_url.rules}
  /// Shared list into which terminal methods append their rules.
  /// {@endtemplate}
  final List<AuthorizationRule> _rules;

  /// {@template authorized_url.configurer}
  /// Registry returned by every terminal method.
  /// {@endtemplate}
  final AuthorizeHttpRequestsConfigurer _configurer;

  /// {@macro authorized_url}
  AuthorizedUrl(this._matchers, this._rules, this._configurer);

  /// {@template authorized_url.add}
  /// Appends a rule for every stored matcher using [manager].
  ///
  /// ### Parameters
  /// - [manager]: The typed manager that will decide access.
  ///
  /// ### Returns
  /// The owning [AuthorizeHttpRequestsConfigurer].
  /// {@endtemplate}
  AuthorizeHttpRequestsConfigurer _add(AuthorizationManager<RequestAuthorizationContext> manager) {
    for (final matcher in _matchers) {
      _rules.add(AuthorizationRule(matcher: matcher, manager: manager));
    }
    return _configurer;
  }

  /// Allows all requests, including unauthenticated ones.
  ///
  /// ### Returns
  /// The owning [AuthorizeHttpRequestsConfigurer].
  AuthorizeHttpRequestsConfigurer permitAll() => _add(const PermitAllAuthorizationManager());

  /// Denies all requests.
  ///
  /// ### Returns
  /// The owning [AuthorizeHttpRequestsConfigurer].
  AuthorizeHttpRequestsConfigurer denyAll() => _add(const DenyAllAuthorizationManager());

  /// Requires an authenticated, non-anonymous principal.
  ///
  /// ### Returns
  /// The owning [AuthorizeHttpRequestsConfigurer].
  AuthorizeHttpRequestsConfigurer authenticated() => _add(AuthenticatedAuthorizationManager<RequestAuthorizationContext>.authenticated());

  /// Requires the principal to hold [role], automatically prefixed with
  /// `ROLE_`.
  ///
  /// ### Parameters
  /// - [role]: Role name without the `ROLE_` prefix.
  ///
  /// ### Returns
  /// The owning [AuthorizeHttpRequestsConfigurer].
  AuthorizeHttpRequestsConfigurer hasRole(String role) => _add(AuthorityAuthorizationManager.hasRole(role));

  /// Requires the principal to hold at least one of [roles].
  ///
  /// ### Parameters
  /// - [roles]: Role names without the `ROLE_` prefix.
  ///
  /// ### Returns
  /// The owning [AuthorizeHttpRequestsConfigurer].
  AuthorizeHttpRequestsConfigurer hasAnyRole(List<String> roles) => _add(
    AuthorizationManagers.anyOf([
      for (final role in roles) ...[
        AuthorityAuthorizationManager<RequestAuthorizationContext>.hasRole(role)
      ],
    ]),
  );

  /// Requires the principal to hold [authority].
  ///
  /// ### Parameters
  /// - [authority]: The exact authority string to require.
  ///
  /// ### Returns
  /// The owning [AuthorizeHttpRequestsConfigurer].
  AuthorizeHttpRequestsConfigurer hasAuthority(String authority) => _add(AuthorityAuthorizationManager<RequestAuthorizationContext>(authority));

  /// Requires the principal to hold at least one of [authorities].
  ///
  /// ### Parameters
  /// - [authorities]: Exact authority strings; any one suffices.
  ///
  /// ### Returns
  /// The owning [AuthorizeHttpRequestsConfigurer].
  AuthorizeHttpRequestsConfigurer hasAnyAuthority(List<String> authorities) => _add(
    AuthorizationManagers.anyOf([
      for (final authority in authorities) ...[
        AuthorityAuthorizationManager<RequestAuthorizationContext>(authority)
      ],
    ]),
  );

  /// Evaluates a custom expression, parsed once at configuration time.
  ///
  /// ### Parameters
  /// - [expression]: The authorization expression to evaluate per request.
  ///
  /// ### Returns
  /// The owning [AuthorizeHttpRequestsConfigurer].
  AuthorizeHttpRequestsConfigurer access(String expression) => _add(ExpressionAuthorizationManager<RequestAuthorizationContext>(expression));
}

/// {@template csrf_configurer}
/// Fluent configurer for CSRF settings inside `HttpSecurity.csrf`.
///
/// Values are collected on the configurer and converted into an immutable
/// [CsrfConfiguration] by [build] when the callback completes.
///
/// ### Example
/// ```dart
/// HttpSecurity()
///   ..csrf((c) {
///     c.disable();
///     c.ignoringRequestMatchers(['/webhooks/']);
///   });
/// ```
/// {@endtemplate}
class CsrfConfigurer {
  /// {@template csrf_configurer.enabled}
  /// Whether CSRF protection should remain active.
  /// {@endtemplate}
  bool _enabled = true;

  /// {@template csrf_configurer.cookie_name}
  /// Name of the cookie carrying the CSRF token.
  /// {@endtemplate}
  String _cookieName = 'XSRF-TOKEN';

  /// {@template csrf_configurer.header_name}
  /// Name of the request header echoing the CSRF token.
  /// {@endtemplate}
  String _headerName = 'X-XSRF-TOKEN';

  /// {@template csrf_configurer.ignoring_paths}
  /// Path prefixes exempt from CSRF validation.
  /// {@endtemplate}
  final List<String> _ignoringPaths = [];

  /// Disables CSRF protection (recommended for stateless APIs).
  ///
  /// ### Returns
  /// Nothing; the receiver is mutated in place.
  void disable() {
    _enabled = false;
  }

  /// Configures the CSRF cookie name.
  ///
  /// ### Parameters
  /// - [name]: Name of the cookie that stores the token.
  ///
  /// ### Returns
  /// Nothing; the receiver is mutated in place.
  void cookieName(String name) {
    _cookieName = name;
  }

  /// Configures the CSRF header name.
  ///
  /// ### Parameters
  /// - [name]: Name of the request header that must carry the token.
  ///
  /// ### Returns
  /// Nothing; the receiver is mutated in place.
  void headerName(String name) {
    _headerName = name;
  }

  /// Exempts path prefixes from CSRF validation.
  ///
  /// ### Parameters
  /// - [pathPrefixes]: Prefixes matched against the beginning of the request
  ///   path.
  ///
  /// ### Returns
  /// Nothing; the receiver is mutated in place.
  void ignoringRequestMatchers(List<String> pathPrefixes) {
    _ignoringPaths.addAll(pathPrefixes);
  }

  /// Builds the [CsrfConfiguration].
  ///
  /// ### Returns
  /// An immutable configuration snapshot of the current settings.
  CsrfConfiguration build() => CsrfConfiguration(
    enabled: _enabled,
    cookieName: _cookieName,
    headerName: _headerName,
    ignoringRequestPaths: List.unmodifiable(_ignoringPaths),
  );
}

/// {@template cors_configurer}
/// Fluent configurer for CORS settings inside `HttpSecurity.cors`.
///
/// It accepts a complete [CorsConfiguration] rather than individual fields, so
/// callers can reuse a policy object across chains.
///
/// ### Example
/// ```dart
/// HttpSecurity()
///   ..cors((c) => c.configuration(const CorsConfiguration(
///         allowedOrigins: ['https://app.example.com'],
///       )));
/// ```
/// {@endtemplate}
class CorsConfigurer {
  /// {@template cors_configurer.configuration}
  /// Currently selected CORS policy.
  /// {@endtemplate}
  CorsConfiguration _configuration = const CorsConfiguration();

  /// Replaces the [CorsConfiguration].
  ///
  /// ### Parameters
  /// - [config]: The policy to use for this chain.
  ///
  /// ### Returns
  /// Nothing; the receiver is mutated in place.
  void configuration(CorsConfiguration config) {
    _configuration = config;
  }

  /// Builds the [CorsConfiguration].
  ///
  /// ### Returns
  /// The currently selected configuration.
  CorsConfiguration build() => _configuration;
}

/// {@template exception_handling_configurer}
/// Fluent configurer for authentication and authorization error handling inside
/// [HttpSecurity].
///
/// Values set here are passed to `ExceptionTranslationFilter`, which converts
/// security exceptions into HTTP responses.
///
/// ### Example
/// ```dart
/// HttpSecurity()
///   ..exceptionHandling((exceptions) {
///     exceptions.authenticationEntryPoint(const BearerAuthenticationEntryPoint());
///     exceptions.accessDeniedHandler(const JsonAccessDeniedHandler());
///   });
/// ```
/// {@endtemplate}
class ExceptionHandlingConfigurer {
  /// {@template exception_handling_configurer.entry_point}
  /// Entry point used for unauthenticated requests; null keeps the default.
  /// {@endtemplate}
  AuthenticationEntryPoint? _entryPoint;

  /// {@template exception_handling_configurer.access_denied_handler}
  /// Handler used for denied requests; null keeps the default.
  /// {@endtemplate}
  AccessDeniedHandler? _accessDeniedHandler;

  /// Sets the [AuthenticationEntryPoint].
  ///
  /// ### Parameters
  /// - [entryPoint]: The component that renders 401 responses.
  ///
  /// ### Returns
  /// Nothing; the receiver is mutated in place.
  void authenticationEntryPoint(AuthenticationEntryPoint entryPoint) {
    _entryPoint = entryPoint;
  }

  /// Sets the [AccessDeniedHandler].
  ///
  /// ### Parameters
  /// - [handler]: The component that renders 403 responses.
  ///
  /// ### Returns
  /// Nothing; the receiver is mutated in place.
  void accessDeniedHandler(AccessDeniedHandler handler) {
    _accessDeniedHandler = handler;
  }
}

/// {@template http_security}
/// Fluent lambda DSL for configuring web security and constructing a
/// [SecurityFilterChain].
///
/// Each configuration method updates an internal
/// [SecurityFilterChainBuilder] and returns the receiver, so calls can be
/// chained. [build] materializes the ordered chain once configuration is
/// complete.
///
/// ### Contract and invariants
/// - [csrf], [sessionManagement], [authorizeHttpRequests] and
///   [exceptionHandling] receive a fresh configurer for each callback.
/// - Optional features such as [cors], [rateLimit] and [headers] are enabled
///   only when their configuration method is called.
/// - Calling [securityMatcher] scopes the resulting chain; otherwise it
///   matches every request.
/// - Custom filters can be appended or positioned relative to built-in types
///   with [addFilter], [addFilterBefore] and [addFilterAfter].
///
/// ### Example
/// ```dart
/// final chain = HttpSecurity()
///   ..csrf((c) => c.disable())
///   ..cors((c) => c.configuration(CorsConfiguration(
///         allowedOrigins: ['https://app.example.com'],
///       )))
///   ..sessionManagement((s) => s.sessionCreationPolicy(SessionCreationPolicy.stateless))
///   ..authorizeHttpRequests((auth) {
///     auth.requestMatchers(['/api/auth/**', '/health']).permitAll();
///     auth.requestMatcher('/api/admin/**').hasRole('ADMIN');
///     auth.anyRequest().authenticated();
///   });
/// ```
/// {@endtemplate}
class HttpSecurity {
  /// {@template http_security.builder}
  /// Builder accumulating the configuration applied by the DSL methods.
  /// {@endtemplate}
  final SecurityFilterChainBuilder _builder = SecurityFilterChainBuilder();

  /// Scopes this security filter chain to requests matching [matcher].
  ///
  /// ### Parameters
  /// - [matcher]: The predicate deciding which requests this chain governs.
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  HttpSecurity securityMatcher(RequestMatcher matcher) {
    _builder.securityMatcher(matcher);
    return this;
  }

  /// Configures CORS support.
  ///
  /// ### Parameters
  /// - [configure]: Optional callback receiving a fresh [CorsConfigurer].
  ///   Omitting it enables CORS with the default policy.
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  ///
  /// ### Example
  /// ```dart
  /// http.cors((c) => c.configuration(config));
  /// ```
  HttpSecurity cors([Configurer<CorsConfigurer>? configure]) {
    final configurer = CorsConfigurer();
    configure?.call(configurer);
    _builder.cors(configurer.build());
    return this;
  }

  /// Configures CSRF protection.
  ///
  /// ### Parameters
  /// - [configure]: Callback receiving a fresh [CsrfConfigurer].
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  HttpSecurity csrf(Configurer<CsrfConfigurer> configure) {
    final configurer = CsrfConfigurer();
    configure(configurer);
    _builder.csrf(configurer.build());
    return this;
  }

  /// Configures token-bucket rate limiting.
  ///
  /// ### Parameters
  /// - [config]: Capacity, refill and client-key settings.
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  HttpSecurity rateLimit(RateLimitConfig config) {
    _builder.rateLimit(config);
    return this;
  }

  /// Configures security response headers (pass `null` to disable).
  ///
  /// ### Parameters
  /// - [config]: Header values, or `null` to omit the headers filter.
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  HttpSecurity headers(SecurityHeadersConfig? config) {
    _builder.headers(config);
    return this;
  }

  /// Configures session management policy.
  ///
  /// ### Parameters
  /// - [configure]: Callback receiving a fresh [SessionManagementConfigurer].
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  HttpSecurity sessionManagement(Configurer<SessionManagementConfigurer> configure) {
    final configurer = SessionManagementConfigurer();
    configure(configurer);
    _builder.sessionPolicy(configurer.policy);
    return this;
  }

  /// Configures the [AuthenticationManager] and optional [converters].
  ///
  /// ### Parameters
  /// - [manager]: The component that verifies credentials.
  /// - [converters]: Optional credential extractors; defaults to bearer token
  ///   and HTTP Basic converters.
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  HttpSecurity authenticationManager(AuthenticationManager manager, {
    List<AuthenticationConverter>? converters,
  }) {
    _builder.authenticationManager(manager, converters: converters);
    return this;
  }

  /// Configures URL-level authorization rules.
  ///
  /// ### Parameters
  /// - [configure]: Callback receiving a fresh
  ///   [AuthorizeHttpRequestsConfigurer].
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  HttpSecurity authorizeHttpRequests(Configurer<AuthorizeHttpRequestsConfigurer> configure) {
    final configurer = AuthorizeHttpRequestsConfigurer();
    configure(configurer);
    for (final rule in configurer.rules) {
      _builder.addAuthorizationRule(rule);
    }
    return this;
  }

  /// Configures [RoleHierarchy] for authorization checks.
  ///
  /// ### Parameters
  /// - [hierarchy]: The role implication rules applied to authority checks.
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  HttpSecurity roleHierarchy(RoleHierarchy hierarchy) {
    _builder.roleHierarchy(hierarchy);
    return this;
  }

  /// Configures authentication entry point and access denied handler.
  ///
  /// ### Parameters
  /// - [configure]: Callback receiving a fresh [ExceptionHandlingConfigurer].
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  HttpSecurity exceptionHandling(Configurer<ExceptionHandlingConfigurer> configure) {
    final configurer = ExceptionHandlingConfigurer();
    configure(configurer);
    _builder.exceptionHandling(
      entryPoint: configurer._entryPoint,
      accessDeniedHandler: configurer._accessDeniedHandler,
    );
    return this;
  }

  /// Registers a custom [SecurityFilter].
  ///
  /// ### Parameters
  /// - [filter]: The filter to add; it is sorted into the chain by its order.
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  HttpSecurity addFilter(SecurityFilter filter) {
    _builder.addFilter(filter);
    return this;
  }

  /// Places [filter] immediately before the filter of type [anchor].
  ///
  /// ### Parameters
  /// - [filter]: The custom filter to insert.
  /// - [anchor]: A built-in filter type used as the positional reference.
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  ///
  /// ### Throws
  /// An [ArgumentError] when [anchor] is not a known built-in filter type.
  HttpSecurity addFilterBefore(SecurityFilter filter, Type anchor) {
    _builder.addFilterBefore(filter, anchor);
    return this;
  }

  /// Places [filter] immediately after the filter of type [anchor].
  ///
  /// ### Parameters
  /// - [filter]: The custom filter to insert.
  /// - [anchor]: A built-in filter type used as the positional reference.
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  ///
  /// ### Throws
  /// An [ArgumentError] when [anchor] is not a known built-in filter type.
  HttpSecurity addFilterAfter(SecurityFilter filter, Type anchor) {
    _builder.addFilterAfter(filter, anchor);
    return this;
  }

  /// Sets the selection order of this chain when multiple chains are registered.
  ///
  /// ### Parameters
  /// - [order]: Lower values are considered first.
  ///
  /// ### Returns
  /// This [HttpSecurity] instance for chaining.
  HttpSecurity order(int order) {
    _builder.chainOrder(order);
    return this;
  }

  /// Builds and returns the configured [SecurityFilterChain].
  ///
  /// ### Returns
  /// A chain whose filters are sorted into canonical security order.
  SecurityFilterChain build() => _builder.build();
}