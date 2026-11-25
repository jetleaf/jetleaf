import 'package:jetleaf_web/jetleaf_web.dart';

import 'package:jetleaf_security/filter.dart';

/// Adds a synthetic request id attribute, demonstrating `addFilterBefore`.
final class RequestIdFilter extends SecurityFilter {
  RequestIdFilter();

  @override
  int get order => SecurityFilterOrders.authentication - 1;

  @override
  Future<void> doFilter(
    ServerHttpRequest request,
    ServerHttpResponse response,
    FilterChain chain,
  ) async {
    request.setAttribute('requestId', DateTime.now().microsecondsSinceEpoch.toString());
    response.getHeaders().set('X-Request-Id', request.getAttribute('requestId')?.toString() ?? '');
    await chain.next(request, response);
  }
}