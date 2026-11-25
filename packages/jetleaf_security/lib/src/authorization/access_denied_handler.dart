import 'dart:convert';

import 'package:jetleaf_web/jetleaf_web.dart';

import '../core/exceptions.dart';

/// {@template access_denied_handler}
/// Contract for writing the response when an authenticated user lacks the
/// authority required by a resource.
///
/// An access-denied handler is the last step of the authorization failure path.
/// It runs for requests that *do* have an authenticated identity but fail an
/// authorization check, in contrast to an [AuthenticationEntryPoint], which
/// handles requests with no usable identity at all.
///
/// ### Contract
/// - [handle] must write a complete HTTP response, including status code and
///   body.
/// - Implementations should avoid leaking internal details such as stack
///   traces or stored credentials.
/// - Implementations must be safe to call concurrently for different requests.
///
/// ### Example
/// ```dart
/// final class LoggingAccessDeniedHandler implements AccessDeniedHandler {
///   const LoggingAccessDeniedHandler(this.delegate);
///
///   final AccessDeniedHandler delegate;
///
///   @override
///   Future<void> handle(
///     ServerHttpRequest request,
///     ServerHttpResponse response,
///     AccessDeniedException exception,
///   ) async {
///     print('denied ${request.getUri()}: ${exception.message}');
///     await delegate.handle(request, response, exception);
///   }
/// }
/// ```
///
/// ### See also
/// - [AuthenticationEntryPoint]
/// - [JsonAccessDeniedHandler]
/// - [AccessDeniedException]
/// {@endtemplate}
abstract interface class AccessDeniedHandler {
  /// Writes an HTTP response describing the access denial.
  ///
  /// ### Parameters
  /// - [request] — the request that was denied.
  /// - [response] — the response to populate with a status and body.
  /// - [exception] — the [AccessDeniedException] raised by the authorization
  ///   check.
  ///
  /// ### Returns
  /// A future completing once the response body has been written.
  Future<void> handle(ServerHttpRequest request, ServerHttpResponse response, AccessDeniedException exception);
}

/// {@template json_access_denied_handler}
/// An [AccessDeniedHandler] that writes an HTTP 403 response with a JSON body.
///
/// The body contains an `error` field set to `forbidden` and a `message` field
/// taken from the [AccessDeniedException].
///
/// ### Contract and invariants
/// - The status is always [HttpStatus.FORBIDDEN].
/// - The content type is always [MediaType.APPLICATION_JSON].
/// - The class is stateless and has a `const` constructor.
///
/// ### Example
/// ```dart
/// const handler = JsonAccessDeniedHandler();
/// await handler.handle(request, response, exception);
/// // 403, {"error":"forbidden","message":"Access denied"}
/// ```
///
/// ### See also
/// - [AccessDeniedHandler]
/// {@endtemplate}
class JsonAccessDeniedHandler implements AccessDeniedHandler {
  /// {@macro json_access_denied_handler}
  const JsonAccessDeniedHandler();

  /// Sets a 403 status and writes the JSON error payload.
  ///
  /// ### Parameters
  /// - [request] — the denied request; accepted for interface conformance.
  /// - [response] — the response to write.
  /// - [exception] — the source of the error message in the payload.
  ///
  /// ### Returns
  /// A future completing after the body is written.
  @override
  Future<void> handle(ServerHttpRequest request, ServerHttpResponse response, AccessDeniedException exception) async {
    response.setStatus(HttpStatus.FORBIDDEN);
    response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
    final body = jsonEncode({
      'error': 'forbidden',
      'message': exception.message,
    });
    final output = response.getBody();
    await output.writeString(body);
    await output.close();
  }
}