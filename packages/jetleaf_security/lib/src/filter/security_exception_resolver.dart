import 'package:jetleaf_core/lang.dart' show Ordered, PriorityOrdered;
import 'package:jetleaf_web/jetleaf_web.dart';

import '../authorization/access_denied_handler.dart';
import '../authorization/authentication_entry_point.dart';
import '../core/exceptions.dart';

/// {@template security_exception_resolver}
/// Maps security failures raised while invoking a handler to HTTP responses.
///
/// Filter-level failures are handled by `ExceptionTranslationFilter`, but a
/// method-security interceptor throws from inside the controller invocation,
/// where the filter chain can no longer translate it. This resolver closes that
/// gap so an authorization denial is always a 403 rather than a generic 500.
/// {@endtemplate}
final class SecurityExceptionResolver implements ExceptionResolver, PriorityOrdered {
  const SecurityExceptionResolver();

  @override
  int getOrder() => Ordered.HIGHEST_PRECEDENCE - 1;

  @override
  List<MediaType> getSupportedMediaTypes() => const [MediaType.APPLICATION_JSON];

  @override
  Future<bool> resolve(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod? handler, Object ex, StackTrace stackTrace) async {
    if (ex is! SecurityException) return false;

    response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
    if (ex is AuthenticationException) {
      await const BearerAuthenticationEntryPoint().commence(request, response, ex);
    } else if (ex is AccessDeniedException) {
      await const JsonAccessDeniedHandler().handle(request, response, ex);
    } else {
      return false;
    }
    return true;
  }
}
