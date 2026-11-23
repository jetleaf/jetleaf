import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import '../core/typedefs.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

import '../authorization/authorization_decision.dart';
import '../authorization/authorization_manager.dart';
import '../core/authentication_trust_resolver.dart';
import '../core/exceptions.dart';
import '../core/security_context_holder.dart';
import 'security_filter.dart';
import 'security_filter_chain.dart';

/// {@template authorization_rule}
/// Associates a `RequestMatcher` with a typed [AuthorizationManager].
///
/// Rules are evaluated in declaration order by [AuthorizationFilter]; the first
/// matcher that accepts a request determines the decision, so more specific
/// patterns must be registered before broader ones.
///
/// ### Contract
/// - [matcher] selects the requests governed by the rule.
/// - [manager] receives a lazy authentication supplier and a
///   `RequestAuthorizationContext`, and returns an [AuthorizationDecision].
///
/// ### Example
/// ```dart
/// const rule = AuthorizationRule(
///   matcher: PathPatternMatcher('/admin/**'),
///   manager: AuthenticatedAuthorizationManager.authenticated(),
/// );
/// ```
/// {@endtemplate}
final class AuthorizationRule with EqualsAndHashCode {
  /// Matcher selecting requests governed by this rule.
  final RequestMatcher matcher;

  /// Typed manager that makes the decision.
  final AuthorizationManager<RequestAuthorizationContext> manager;

  /// {@macro authorization_rule}
  const AuthorizationRule({required this.matcher, required this.manager});

  /// Contributes the runtime type, [matcher] and [manager] to equality and
  /// hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, matcher, manager];
}

/// {@template authorization_filter}
/// Enforces URL-level access control using typed authorization managers.
///
/// The filter evaluates either a delegating manager assembled by the lambda DSL
/// or, when that is absent, an ordered list of [AuthorizationRule]s. A denied
/// decision raises an authentication exception for anonymous or remembered
/// callers and an access-denied exception otherwise, allowing downstream error
/// handling to choose the appropriate HTTP status.
///
/// ### Contract and invariants
/// - Rules are first-match-wins; later rules are not consulted after a match.
/// - When no rule matches, [defaultPermit] decides the outcome (deny by
///   default).
/// - The authentication supplier is lazy, so reading the security context is
///   deferred until a manager actually needs it.
/// - A granted decision always advances the chain; a denied decision never
///   does.
/// - It occupies the `SecurityFilterOrders.authorization` slot and therefore
///   runs after identity has been established.
///
/// ### See also
/// - [AuthorizationRule]
/// - [AuthorizationManager]
/// - [AuthenticationTrustResolver]
/// - [SecurityFilterChain]
/// {@endtemplate}
class AuthorizationFilter extends SecurityFilter {
  /// Ordered rules (first match wins). Used when no delegating manager is set.
  final List<AuthorizationRule> rules;

  /// Optional delegating manager assembled by the DSL.
  final AuthorizationManager<ServerHttpRequest>? delegatingManager;

  /// Resolver used to decide between 401 and 403 on denial.
  final AuthenticationTrustResolver trustResolver;

  /// Decision when no rule matches; deny by default.
  final bool defaultPermit;

  /// Execution priority: the final gate, after authentication and context
  /// setup have completed.
  @override
  int get order => 0;

  /// {@macro authorization_filter}
  AuthorizationFilter({
    List<AuthorizationRule> rules = const [],
    this.delegatingManager,
    this.trustResolver = const AuthenticationTrustResolverImpl(),
    this.defaultPermit = false,
  }) : rules = List.unmodifiable(rules);

  /// Authorizes [request] before allowing the chain to continue.
  ///
  /// [request] is inspected by the configured matcher or delegating manager.
  /// [response] is not written directly by this filter; denial is signalled by
  /// throwing so that the exception-translation filter can render it. [chain]
  /// is called with `chain.next(request, response)` only when access is granted.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest] to authorize.
  /// - [response]: The outgoing [ServerHttpResponse], left untouched here.
  /// - [chain]: The remaining filter chain to delegate to on success.
  ///
  /// ### Returns
  /// A [Future] that completes after the downstream chain has finished when
  /// access is granted.
  ///
  /// ### Throws
  /// - `InsufficientAuthenticationException` when an anonymous or remembered
  ///   caller is denied.
  /// - `AccessDeniedException` when an authenticated caller is denied.
  ///
  /// ### Example
  /// ```dart
  /// final filter = AuthorizationFilter(
  ///   rules: [rule],
  ///   defaultPermit: false,
  /// );
  /// await filter.doFilter(request, response, chain);
  /// ```
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    AuthenticationSupplier supplier() => () => SecurityContextHolder.getContext().authentication;

    final decision = delegatingManager != null
        ? delegatingManager!.check(supplier(), request)
        : _checkRules(supplier(), request);

    if (!decision.isGranted) {
      final auth = supplier()();
      if (auth == null || trustResolver.isAnonymous(auth) || trustResolver.isRememberMe(auth)) {
        throw InsufficientAuthenticationException();
      }
      throw AccessDeniedException();
    }

    await chain.next(request, response);
  }

  /// {@template authorization_filter.check_rules}
  /// Evaluates the ordered [rules] against [request] using the supplied
  /// authentication.
  ///
  /// The first matching rule wins. If no rule matches, an
  /// [AuthorizationDecision] reflecting [defaultPermit] is returned.
  ///
  /// ### Parameters
  /// - [authentication]: Lazy supplier for the current authentication.
  /// - [request]: The incoming request to match.
  ///
  /// ### Returns
  /// The decision produced by the first matching rule, or the default decision.
  /// {@endtemplate}
  AuthorizationDecision _checkRules(AuthenticationSupplier authentication, ServerHttpRequest request) {
    for (final rule in rules) {
      if (rule.matcher.matches(request)) {
        return rule.manager.check(
          authentication,
          RequestAuthorizationContext(request),
        );
      }
    }
    return AuthorizationDecision(defaultPermit);
  }
}
