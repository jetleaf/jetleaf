import 'package:jetleaf_web/jetleaf_web.dart';

import '../core/security_context_holder.dart';
import 'security_filter.dart';
import 'security_filter_chain.dart';

/// {@template filter_chain_proxy}
/// Single web [Filter] that selects the first matching [SecurityFilterChain]
/// and runs it.
///
/// Register this filter as a pod; `FilterManager` discovers it automatically.
/// Chains are sorted by their `order` when the proxy is constructed, so the
/// most specific or highest-priority chain is considered first. If no chain
/// matches, the request passes through untouched.
///
/// ### Contract and invariants
/// - Exactly one matching chain is executed per request; the rest are skipped.
/// - The [SecurityContextHolder] context is cleared in a `finally` block after
///   the selected chain runs, including when it throws.
/// - Non-matching requests are forwarded with
///   `chain.next(request, response)` and are not modified.
/// - The proxy's [order] determines its position among ordinary web filters.
///
/// ### Example
/// ```dart
/// final proxy = FilterChainProxy([
///   HttpSecurity()
///     ..securityMatcher(PathPatternMatcher('/api/**'))
///     // ... configuration ...
///     ..build(),
/// ]);
/// ```
/// {@endtemplate}
final class FilterChainProxy extends SecurityFilter {
  /// Ordered chains considered in sequence.
  final List<SecurityFilterChain> chains;

  /// Position relative to other web filters.
  @override
  final int order;

  /// {@macro filter_chain_proxy}
  FilterChainProxy(
    List<SecurityFilterChain> chains, {
    this.order = -50,
  }) : chains = List.unmodifiable([...chains]..sort((a, b) => a.order.compareTo(b.order)));

  /// Runs the first matching security chain, or passes the request through.
  ///
  /// [request] is offered to each chain's matcher in priority order. [response]
  /// is handed to the selected chain, which may write headers or a status.
  /// [chain] is invoked with `chain.next(request, response)` only when no
  /// security chain matches; a selected chain is responsible for invoking the
  /// downstream web filter chain itself.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The outgoing [ServerHttpResponse].
  /// - [chain]: The downstream web filter chain used on a pass-through.
  ///
  /// ### Returns
  /// A [Future] that completes after the selected chain or pass-through
  /// finishes.
  ///
  /// ### Throws
  /// Propagates errors from the selected chain after clearing the security
  /// context.
  ///
  /// ### Example
  /// ```dart
  /// await proxy.doFilter(request, response, webFilterChain);
  /// ```
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    for (final securityChain in chains) {
      if (!securityChain.matches(request)) continue;
      try {
        await securityChain.doFilter(request, response, chain);
      } finally {
        SecurityContextHolder.clearContext();
      }
      return;
    }

    // No chain matched: pass through untouched rather than inventing a
    // security decision for a request this proxy does not govern.
    await chain.next(request, response);
  }
}
