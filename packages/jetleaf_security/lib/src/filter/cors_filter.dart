import 'package:jetleaf_web/jetleaf_web.dart';

import '../config/cors_configuration.dart' as sec;
import 'security_filter.dart';

/// {@template jetleaf_security_cors_filter}
/// Applies Cross-Origin Resource Sharing (CORS) rules from a
/// `CorsConfiguration` and short-circuits valid cross-origin preflight
/// (`OPTIONS`) requests.
///
/// Requests without an `Origin` header, or whose origin is not permitted, pass
/// through unchanged. For permitted origins the filter writes the appropriate
/// `Access-Control-*` headers and, for a preflight carrying
/// `Access-Control-Request-Method`, validates the requested method and headers
/// before responding with `204 No Content` or `403 Forbidden`.
///
/// ### Contract and invariants
/// - A wildcard origin never emits `Vary: Origin`; an echoed origin does.
/// - Credentialed responses always carry
///   `Access-Control-Allow-Credentials: true`.
/// - Disallowed preflight methods or headers terminate the request with 403;
///   allowed ones never reach the downstream handler.
/// - Simple (non-preflight) requests always advance the chain.
/// - It occupies the `SecurityFilterOrders.cors` slot so cross-origin handling
///   happens before any authentication decision.
///
/// ### See also
/// - `CorsConfiguration`
/// - `SecurityFilterChain`
/// {@endtemplate}
class CorsFilter extends SecurityFilter {
  /// CORS policy configuration.
  final sec.CorsConfiguration configuration;

  /// Execution priority: first in the chain, so preflight and CORS headers are
  /// handled before any other security decision.
  @override
  int get order => -100;

  /// {@macro jetleaf_security_cors_filter}
  CorsFilter(this.configuration);

  /// Applies CORS headers to [response] and conditionally continues the chain.
  ///
  /// [request] supplies the `Origin`, `Access-Control-Request-Method` and
  /// `Access-Control-Request-Headers` headers used for validation. [response]
  /// receives `Access-Control-*` headers and may be terminated with 204 for an
  /// accepted preflight or 403 for a rejected one. [chain] is called with
  /// `chain.next(request, response)` only for non-CORS or simple cross-origin
  /// requests; accepted preflights return without delegating.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The outgoing [ServerHttpResponse].
  /// - [chain]: The remaining filter chain to delegate to for non-preflight
  ///   requests.
  ///
  /// ### Returns
  /// A [Future] that completes either after the chain finishes or immediately
  /// after a preflight response is written.
  ///
  /// ### Throws
  /// Propagates errors raised by filters further down the chain.
  ///
  /// ### Example
  /// ```dart
  /// final filter = CorsFilter(
  ///   CorsConfiguration(allowedOrigins: ['https://app.example.com']),
  /// );
  /// await filter.doFilter(request, response, chain);
  /// ```
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    final origin = request.getHeaders().getFirst('Origin');
    if (origin == null || origin.isEmpty) {
      await chain.next(request, response);
      return;
    }

    final allowedOrigin = configuration.resolveAllowedOrigin(origin);
    if (allowedOrigin == null) {
      await chain.next(request, response);
      return;
    }

    final resHeaders = response.getHeaders();
    resHeaders.set('Access-Control-Allow-Origin', allowedOrigin);
    if (allowedOrigin != '*') {
      resHeaders.set('Vary', 'Origin');
    }
    if (configuration.allowCredentials) {
      resHeaders.set('Access-Control-Allow-Credentials', 'true');
    }
    if (configuration.exposedHeaders.isNotEmpty) {
      resHeaders.set(
        'Access-Control-Expose-Headers',
        configuration.exposedHeaders.join(', '),
      );
    }

    final isPreflight = request.getMethod().toString().toUpperCase() == 'OPTIONS' && request.getHeaders().getFirst('Access-Control-Request-Method') != null;

    if (isPreflight) {
      final requestedMethod = request
        .getHeaders()
        .getFirst('Access-Control-Request-Method')
        ?.toUpperCase();
      if (requestedMethod == null || !configuration.allowedMethods.map((m) => m.toUpperCase()).contains(requestedMethod)) {
        response.setStatus(HttpStatus.FORBIDDEN);
        await response.getBody().close();
        return;
      }

      final requestedHeaders = request.getHeaders().getFirst('Access-Control-Request-Headers');
      if (requestedHeaders != null) {
        final allowed = configuration.allowedHeaders
          .map((h) => h.toLowerCase())
          .toSet();
        final requested = requestedHeaders
          .split(',')
          .map((h) => h.trim().toLowerCase())
          .where((h) => h.isNotEmpty);
        if (requested.any((h) => !allowed.contains(h))) {
          response.setStatus(HttpStatus.FORBIDDEN);
          await response.getBody().close();
          return;
        }
      }

      if (configuration.allowedMethods.isNotEmpty) {
        resHeaders.set(
          'Access-Control-Allow-Methods',
          configuration.allowedMethods.join(', '),
        );
      }
      if (configuration.allowedHeaders.isNotEmpty) {
        resHeaders.set(
          'Access-Control-Allow-Headers',
          configuration.allowedHeaders.join(', '),
        );
      }
      if (configuration.maxAgeSeconds != null) {
        resHeaders.set(
          'Access-Control-Max-Age',
          configuration.maxAgeSeconds.toString(),
        );
      }
      response.setStatus(HttpStatus.NO_CONTENT);
      await response.getBody().close();
      return;
    }

    await chain.next(request, response);
  }
}