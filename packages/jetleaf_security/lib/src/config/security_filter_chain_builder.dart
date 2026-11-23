import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import 'package:jetleaf_web/jetleaf_web.dart' hide CorsConfiguration, CorsFilter, CsrfFilter;

import '../authentication/authentication_manager.dart';
import '../authentication/session_authentication_strategy.dart';
import '../authentication/session_fixation_protection_strategy.dart';
import '../authorization/access_denied_handler.dart';
import '../authorization/authority_authorization_manager.dart';
import '../authorization/authorization_manager.dart';
import '../core/http_session_security_context_repository.dart';
import '../core/null_security_context_repository.dart';
import '../authorization/authentication_entry_point.dart';
import '../authorization/role_hierarchy.dart';
import '../filter/authentication_filter.dart';
import '../filter/authorization_filter.dart';
import '../filter/cors_filter.dart';
import '../filter/csrf_filter.dart';
import '../filter/exception_translation_filter.dart';
import '../filter/filter_orders.dart';
import '../filter/rate_limiting_filter.dart';
import '../filter/security_context_holder_filter.dart';
import '../filter/security_filter.dart';
import '../filter/security_filter_chain.dart';
import '../filter/security_headers_filter.dart';
import 'cors_configuration.dart';
import 'csrf_configuration.dart';
import 'session_creation_policy.dart';

/// {@template security_filter_chain_builder}
/// Assembles a canonical ordered `SecurityFilterChain` from configured security
/// components.
///
/// The builder holds the configuration supplied by the lambda DSL and turns it
/// into concrete filter instances in [build]. Filters are placed according to
/// `SecurityFilterOrders`, with role hierarchy rules rewritten before they are
/// handed to the authorization filter.
///
/// ### Contract and invariants
/// - Optional filters (CORS, rate limiting, headers) are included only when
///   their configuration has been set; headers are enabled by default.
/// - CSRF, exception translation, context holding and authorization are always
///   included.
/// - The authentication filter is included only when an [AuthenticationManager]
///   is configured.
/// - Custom filters are spliced in before the final authorization gate.
/// - The session policy selects both the context repository and the session
///   authentication strategy.
///
/// ### Example
/// ```dart
/// final builder = SecurityFilterChainBuilder()
///   ..rateLimit(const RateLimitConfig(capacity: 30))
///   ..sessionPolicy(SessionCreationPolicy.stateless);
/// final chain = builder.build();
/// ```
/// {@endtemplate}
class SecurityFilterChainBuilder {
  /// {@template security_filter_chain_builder.request_matcher}
  /// Matcher restricting the resulting chain to a subset of requests.
  /// {@endtemplate}
  RequestMatcher _requestMatcher = const AnyRequestMatcher();

  /// {@template security_filter_chain_builder.cors_config}
  /// CORS policy, or null when CORS support is disabled.
  /// {@endtemplate}
  CorsConfiguration? _corsConfig;

  /// {@template security_filter_chain_builder.rate_limit_config}
  /// Rate limiting settings, or null when rate limiting is disabled.
  /// {@endtemplate}
  RateLimitConfig? _rateLimitConfig;

  /// {@template security_filter_chain_builder.headers_config}
  /// Security header values, or null to omit the headers filter.
  /// {@endtemplate}
  SecurityHeadersConfig? _headersConfig = const SecurityHeadersConfig();

  /// {@template security_filter_chain_builder.csrf_config}
  /// CSRF policy used to construct the CSRF filter.
  /// {@endtemplate}
  CsrfConfiguration _csrfConfig = const CsrfConfiguration();

  /// {@template security_filter_chain_builder.authentication_manager}
  /// Manager used to verify extracted credentials.
  /// {@endtemplate}
  AuthenticationManager? _authenticationManager;

  /// {@template security_filter_chain_builder.authentication_converters}
  /// Optional override for the credential converters of the auth filter.
  /// {@endtemplate}
  List<AuthenticationConverter>? _authenticationConverters;

  /// {@template security_filter_chain_builder.authorization_rules}
  /// Ordered URL authorization rules collected from the DSL.
  /// {@endtemplate}
  final List<AuthorizationRule> _authorizationRules = [];

  /// {@template security_filter_chain_builder.role_hierarchy}
  /// Role hierarchy applied to authority-based rules.
  /// {@endtemplate}
  RoleHierarchy? _roleHierarchy;

  /// {@template security_filter_chain_builder.entry_point}
  /// Entry point used for unauthenticated failures.
  /// {@endtemplate}
  AuthenticationEntryPoint _entryPoint = const BearerAuthenticationEntryPoint();

  /// {@template security_filter_chain_builder.access_denied_handler}
  /// Handler used for access-denied failures.
  /// {@endtemplate}
  AccessDeniedHandler _accessDeniedHandler = const JsonAccessDeniedHandler();

  /// {@template security_filter_chain_builder.custom_filters}
  /// User-supplied filters, including positioned wrappers.
  /// {@endtemplate}
  final List<SecurityFilter> _customFilters = [];

  /// {@template security_filter_chain_builder.session_policy}
  /// Policy governing session creation and use.
  /// {@endtemplate}
  SessionCreationPolicy _sessionPolicy = SessionCreationPolicy.ifRequired;

  /// {@template security_filter_chain_builder.chain_order}
  /// Selection order of the resulting chain among multiple chains.
  /// {@endtemplate}
  int _chainOrder = 0;

  /// Restricts this chain to requests matching [matcher].
  ///
  /// ### Parameters
  /// - [matcher]: Predicate deciding whether the chain applies.
  ///
  /// ### Returns
  /// This builder for chaining.
  SecurityFilterChainBuilder securityMatcher(RequestMatcher matcher) {
    _requestMatcher = matcher;
    return this;
  }

  /// Configures CORS policy.
  ///
  /// ### Parameters
  /// - [configuration]: The CORS policy to apply.
  ///
  /// ### Returns
  /// This builder for chaining.
  SecurityFilterChainBuilder cors(CorsConfiguration configuration) {
    _corsConfig = configuration;
    return this;
  }

  /// Configures token-bucket rate limiting.
  ///
  /// ### Parameters
  /// - [config]: Bucket capacity, refill and key settings.
  ///
  /// ### Returns
  /// This builder for chaining.
  SecurityFilterChainBuilder rateLimit(RateLimitConfig config) {
    _rateLimitConfig = config;
    return this;
  }

  /// Configures security headers (pass `null` to disable).
  ///
  /// ### Parameters
  /// - [config]: Header values, or `null` to omit the filter.
  ///
  /// ### Returns
  /// This builder for chaining.
  SecurityFilterChainBuilder headers(SecurityHeadersConfig? config) {
    _headersConfig = config;
    return this;
  }

  /// Configures CSRF protection.
  ///
  /// ### Parameters
  /// - [config]: CSRF settings for the generated filter.
  ///
  /// ### Returns
  /// This builder for chaining.
  SecurityFilterChainBuilder csrf(CsrfConfiguration config) {
    _csrfConfig = config;
    return this;
  }

  /// Configures the [AuthenticationManager] and optional [converters].
  ///
  /// ### Parameters
  /// - [manager]: Manager verifying credentials.
  /// - [converters]: Optional credential extractor override.
  ///
  /// ### Returns
  /// This builder for chaining.
  SecurityFilterChainBuilder authenticationManager(AuthenticationManager manager, {
    List<AuthenticationConverter>? converters,
  }) {
    _authenticationManager = manager;
    _authenticationConverters = converters;
    return this;
  }

  /// Appends an [AuthorizationRule].
  ///
  /// ### Parameters
  /// - [rule]: The matcher/manager pair to append.
  ///
  /// ### Returns
  /// This builder for chaining.
  SecurityFilterChainBuilder addAuthorizationRule(AuthorizationRule rule) {
    _authorizationRules.add(rule);
    return this;
  }

  /// Configures [RoleHierarchy] for authorization checks.
  ///
  /// ### Parameters
  /// - [hierarchy]: Role implication rules applied at build time.
  ///
  /// ### Returns
  /// This builder for chaining.
  SecurityFilterChainBuilder roleHierarchy(RoleHierarchy hierarchy) {
    _roleHierarchy = hierarchy;
    return this;
  }

  /// Configures custom [AuthenticationEntryPoint] and [AccessDeniedHandler].
  ///
  /// ### Parameters
  /// - [entryPoint]: Overrides the 401 renderer when non-null.
  /// - [accessDeniedHandler]: Overrides the 403 renderer when non-null.
  ///
  /// ### Returns
  /// This builder for chaining.
  SecurityFilterChainBuilder exceptionHandling({
    AuthenticationEntryPoint? entryPoint,
    AccessDeniedHandler? accessDeniedHandler,
  }) {
    if (entryPoint != null) _entryPoint = entryPoint;
    if (accessDeniedHandler != null) _accessDeniedHandler = accessDeniedHandler;
    return this;
  }

  /// Configures session creation policy.
  ///
  /// ### Parameters
  /// - [policy]: The desired session behavior.
  ///
  /// ### Returns
  /// This builder for chaining.
  SecurityFilterChainBuilder sessionPolicy(SessionCreationPolicy policy) {
    _sessionPolicy = policy;
    return this;
  }

  /// Registers a custom [SecurityFilter].
  ///
  /// ### Parameters
  /// - [filter]: The filter to include; its own order determines placement.
  ///
  /// ### Returns
  /// This builder for chaining.
  SecurityFilterChainBuilder addFilter(SecurityFilter filter) {
    _customFilters.add(filter);
    return this;
  }

  /// Places [filter] immediately before the filter of type [anchor].
  ///
  /// ### Parameters
  /// - [filter]: The custom filter to insert.
  /// - [anchor]: A built-in type from `SecurityFilterOrders.byType`.
  ///
  /// ### Returns
  /// This builder for chaining.
  ///
  /// ### Throws
  /// An [ArgumentError] when [anchor] is not a known built-in filter type.
  SecurityFilterChainBuilder addFilterBefore(SecurityFilter filter, Type anchor) {
    final base = SecurityFilterOrders.byType[anchor];
    if (base == null) {
      throw IllegalArgumentException('anchor: Unknown security filter type (got )');
    }
    _customFilters.add(_PositionedFilter(filter, base - 1));
    return this;
  }

  /// Places [filter] immediately after the filter of type [anchor].
  ///
  /// ### Parameters
  /// - [filter]: The custom filter to insert.
  /// - [anchor]: A built-in type from `SecurityFilterOrders.byType`.
  ///
  /// ### Returns
  /// This builder for chaining.
  ///
  /// ### Throws
  /// An [ArgumentError] when [anchor] is not a known built-in filter type.
  SecurityFilterChainBuilder addFilterAfter(SecurityFilter filter, Type anchor) {
    final base = SecurityFilterOrders.byType[anchor];
    if (base == null) {
      throw IllegalArgumentException('anchor: Unknown security filter type (got )');
    }
    _customFilters.add(_PositionedFilter(filter, base + 1));
    return this;
  }

  /// Sets the selection order of this chain when several chains are registered.
  ///
  /// ### Parameters
  /// - [order]: Lower values are considered first.
  ///
  /// ### Returns
  /// This builder for chaining.
  SecurityFilterChainBuilder chainOrder(int order) {
    _chainOrder = order;
    return this;
  }

  /// Returns the configured [SessionCreationPolicy].
  ///
  /// ### Returns
  /// The policy currently held by this builder.
  SessionCreationPolicy get sessionCreationPolicy => _sessionPolicy;

  /// Builds the ordered `SecurityFilterChain`.
  ///
  /// Role hierarchy rules are rewritten to hierarchy-aware managers when a
  /// hierarchy is configured. The resulting list is sorted by filter order when
  /// the chain is constructed.
  ///
  /// ### Returns
  /// A new [SecurityFilterChain] snapshot of the current configuration.
  ///
  /// ### Example
  /// ```dart
  /// final chain = builder.build();
  /// print(chain.filters.map((f) => f.order));
  /// ```
  SecurityFilterChain build() {
    final effectiveRules = _roleHierarchy == null
        ? _authorizationRules
        : _authorizationRules
          .map((rule) => AuthorizationRule(
            matcher: rule.matcher,
            manager: rule.manager is AuthorityAuthorizationManager
                ? (rule.manager as AuthorityAuthorizationManager<RequestAuthorizationContext>).withHierarchy(_roleHierarchy!)
                : rule.manager,
          ))
          .toList();

    final filters = <SecurityFilter>[
      if (_corsConfig != null) CorsFilter(_corsConfig!),
      if (_rateLimitConfig != null) RateLimitingFilter(config: _rateLimitConfig!),
      if (_headersConfig != null) SecurityHeadersFilter(_headersConfig!),
      CsrfFilter(
        configuration: _csrfConfig,
        accessDeniedHandler: _accessDeniedHandler,
      ),
      ExceptionTranslationFilter(
        authenticationEntryPoint: _entryPoint,
        accessDeniedHandler: _accessDeniedHandler,
      ),
      SecurityContextHolderFilter(
        contextRepository: _sessionPolicy == SessionCreationPolicy.stateless
          ? const NullSecurityContextRepository()
          : HttpSessionSecurityContextRepository(allowSessionCreation: _sessionPolicy != SessionCreationPolicy.never),
      ),
      if (_authenticationManager != null)
        AuthenticationFilter(
          authenticationManager: _authenticationManager!,
          sessionAuthenticationStrategy: _sessionPolicy == SessionCreationPolicy.stateless
            ? const NullAuthenticatedSessionStrategy()
            : const ChangeSessionIdAuthenticationStrategy(),
          converters: _authenticationConverters ?? const [
            BearerTokenAuthenticationConverter(),
            BasicAuthenticationConverter(),
          ],
        ),
      ..._customFilters,
      AuthorizationFilter(rules: effectiveRules),
    ];

    return SecurityFilterChain(
      requestMatcher: _requestMatcher,
      filters: filters,
      order: _chainOrder,
    );
  }
}

/// {@template security_filter_chain_builder.positioned_filter}
/// Wraps a filter with an explicit order for relative placement.
///
/// Used by `addFilterBefore` and `addFilterAfter` to give a custom filter a
/// synthetic order derived from a built-in anchor. The wrapper delegates all
/// request processing to [delegate].
///
/// ### Contract
/// - [positionedOrder] is the value used for sorting in the chain.
/// - Delegation is transparent: no headers or state are added by the wrapper.
/// {@endtemplate}
final class _PositionedFilter extends SecurityFilter {
  /// {@template security_filter_chain_builder.positioned_filter.delegate}
  /// The wrapped filter that performs the actual work.
  /// {@endtemplate}
  final SecurityFilter delegate;

  /// {@template security_filter_chain_builder.positioned_filter.positioned_order}
  /// Synthetic order computed from the anchor filter's position.
  /// {@endtemplate}
  final int positionedOrder;

  /// {@macro security_filter_chain_builder.positioned_filter}
  _PositionedFilter(this.delegate, this.positionedOrder);

  /// {@template security_filter_chain_builder.positioned_filter.order}
  /// Returns the synthetic order used to place the wrapped filter.
  /// {@endtemplate}
  @override
  int get order => positionedOrder;

  /// Forwards [request], [response] and [chain] to [delegate] unchanged.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The outgoing [ServerHttpResponse].
  /// - [chain]: The remaining filter chain, passed through to the delegate.
  ///
  /// ### Returns
  /// The delegate's [Future].
  @override
  Future<void> doFilter(
    ServerHttpRequest request,
    ServerHttpResponse response,
    FilterChain chain,
  ) => delegate.doFilter(request, response, chain);
}
