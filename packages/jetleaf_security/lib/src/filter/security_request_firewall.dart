import 'package:jetleaf_web/jetleaf_web.dart';

import 'security_filter.dart';

/// {@template security_request_firewall}
/// Rejects ambiguous request targets before any matcher or router sees them.
///
/// Path matchers and downstream routers may normalise encoded or relative path
/// segments differently, allowing a request to bypass a security rule while
/// still reaching a protected handler. This filter applies the conservative
/// rule: reject rather than interpret.
///
/// ### Contract and invariants
/// - Requests containing `//`, `.`/`..` segments, `;`, `%2e`, or `%00` are
///   answered with `400 Bad Request` and never reach the chain.
/// - Rejected responses are closed immediately so clients do not hang.
/// - It runs before every other security filter.
/// {@endtemplate}
final class SecurityRequestFirewall extends SecurityFilter {
  /// {@macro security_request_firewall}
  SecurityRequestFirewall();

  @override
  int get order => -110;

  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    final path = request.getRequestURI().path;
    final full = request.getUri().toString();
    final lowered = full.toLowerCase();

    final unsafe = path.contains('//') ||
        path.split('/').any((segment) => segment == '.' || segment == '..') ||
        path.contains(';') ||
        lowered.contains('%2e') ||
        lowered.contains('%00');

    if (unsafe) {
      response.setStatus(HttpStatus.BAD_REQUEST);
      await response.getBody().close();
      return;
    }

    await chain.next(request, response);
  }
}
