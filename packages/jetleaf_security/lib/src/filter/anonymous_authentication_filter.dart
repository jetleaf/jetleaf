import 'package:jetleaf_web/jetleaf_web.dart';

import '../authentication/anonymous_authentication_token.dart';
import '../core/granted_authority.dart';
import '../core/simple_granted_authority.dart';
import '../core/security_context_holder.dart';
import 'security_filter.dart';

/// {@template anonymous_authentication_filter}
/// Establishes a synthetic anonymous principal for requests that carry no
/// credentials, so downstream components can rely on a non-null authentication.
///
/// When the current [SecurityContextHolder] context has no authentication, this
/// filter installs an [AnonymousAuthenticationToken] assembled from [principal],
/// [authorities] and [key]. Because it runs before authorization, access checks
/// can treat anonymous callers as ordinary principals and decide explicitly
/// whether to grant or deny them.
///
/// ### Contract and invariants
/// - An existing authentication is never replaced; the anonymous token is only
///   installed when the current value is `null`.
/// - The token is not marked as authenticated, so trust checks can distinguish
///   it from a genuinely authenticated user.
/// - The chain is always advanced; this filter never terminates a request.
/// - It occupies the `SecurityFilterOrders.anonymous` slot so a real
///   authentication established by an earlier filter always takes precedence.
///
/// ### Example
/// ```dart
/// final filter = AnonymousAuthenticationFilter(
///   principal: 'guest',
///   authorities: {const SimpleGrantedAuthority('ROLE_GUEST')},
/// );
/// ```
/// {@endtemplate}
final class AnonymousAuthenticationFilter extends SecurityFilter {
  /// Key identifying the anonymous authentication.
  ///
  /// Stored as the token's details so callers can recognize the synthetic
  /// principal without depending on the principal's runtime type.
  final String key;

  /// Principal name used for anonymous requests.
  final Object principal;

  /// Authorities granted to anonymous requests.
  ///
  /// Defaults to a single `ROLE_ANONYMOUS` authority when none is supplied.
  final Set<GrantedAuthority> authorities;

  /// Execution priority: anonymous authentication is installed after real
  /// authentication but before the authorization gate.
  @override
  int get order => -40;

  /// {@macro anonymous_authentication_filter}
  AnonymousAuthenticationFilter({
    this.key = 'jetleafAnonymousAuthenticationToken',
    this.principal = 'anonymousUser',
    Set<GrantedAuthority>? authorities,
  }) : authorities = authorities ?? {const SimpleGrantedAuthority('ROLE_ANONYMOUS')};

  /// Installs an anonymous [AnonymousAuthenticationToken] when needed, then
  /// continues the chain.
  ///
  /// [request] is the incoming request being processed and is not modified by
  /// this filter. [response] is the outgoing response and is likewise untouched.
  /// [chain] represents the remaining filters: `chain.next(request, response)`
  /// is always called so downstream authorization sees a non-null principal.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The outgoing [ServerHttpResponse].
  /// - [chain]: The remaining filter chain to delegate to.
  ///
  /// ### Returns
  /// A [Future] that completes after the downstream chain has finished.
  ///
  /// ### Throws
  /// Propagates any error raised by filters further down the chain.
  ///
  /// ### Example
  /// ```dart
  /// await filter.doFilter(request, response, chain);
  /// // SecurityContextHolder.getContext().authentication is now non-null.
  /// ```
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    final context = SecurityContextHolder.getContext();
    context.authentication ??= AnonymousAuthenticationToken(
      principal: principal,
      authorities: authorities,
      details: key,
    );
    await chain.next(request, response);
  }
}
