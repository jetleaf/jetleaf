import 'package:jetleaf_web/jetleaf_web.dart';

import 'package:jetleaf_security/authentication.dart';
import 'package:jetleaf_security/core.dart';
import 'package:jetleaf_security/filter.dart';

import '../auth/api_key_authentication_token.dart';

/// Demonstrates `addFilterBefore`: extracts a custom credential and lets the
/// configured [AuthenticationManager] decide whether it is valid.
final class ApiKeyAuthenticationFilter extends SecurityFilter {
  ApiKeyAuthenticationFilter(this.authenticationManager);

  final AuthenticationManager authenticationManager;

  @override
  int get order => -55;

  @override
  Future<void> doFilter(
    ServerHttpRequest request,
    ServerHttpResponse response,
    FilterChain chain,
  ) async {
    final key = request.getHeaders().getFirst('X-Api-Key');
    if (key != null && key.isNotEmpty) {
      final result = await authenticationManager.authenticate(
        ApiKeyAuthenticationToken.unauthenticated(key, details: request.getOrigin()),
      );
      SecurityContextHolder.getContext().authentication = result;
    }
    await chain.next(request, response);
  }
}
