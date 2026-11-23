import 'dart:convert';

import 'package:jetleaf_web/jetleaf_web.dart';

import '../core/exceptions.dart';

/// {@template authentication_entry_point}
/// Contract for starting an authentication scheme when an unauthenticated
/// request tries to access a protected resource.
///
/// An entry point turns an authentication failure into a response that tells
/// the client how to proceed — for example, by issuing a challenge header or a
/// redirect. It is invoked for requests that have no usable authenticated
/// identity, while an [AccessDeniedHandler] handles requests that are
/// authenticated but insufficiently privileged.
///
/// ### Contract
/// - [commence] must write a complete response, including status and any
///   challenge headers the chosen scheme requires.
/// - Implementations must not attempt to authenticate the request themselves.
/// - Implementations must be safe to call concurrently for different requests.
///
/// ### Example
/// ```dart
/// final class WwwAuthenticateEntryPoint implements AuthenticationEntryPoint {
///   const WwwAuthenticateEntryPoint();
///
///   @override
///   Future<void> commence(ServerHttpRequest request, ServerHttpResponse response, AuthenticationException exception) async {
///     response.setStatus(HttpStatus.UNAUTHORIZED);
///     response.getHeaders().set('WWW-Authenticate', 'Bearer');
///   }
/// }
/// ```
///
/// ### See also
/// - [AccessDeniedHandler]
/// - [BearerAuthenticationEntryPoint]
/// - [AuthenticationException]
/// {@endtemplate}
abstract interface class AuthenticationEntryPoint {
  /// Writes the response that commences authentication.
  ///
  /// ### Parameters
  /// - [request] — the request that could not be authenticated.
  /// - [response] — the response to populate with a status and challenge.
  /// - [exception] — the [AuthenticationException] describing why the request
  ///   was not authenticated.
  ///
  /// ### Returns
  /// A future completing once the response has been written.
  Future<void> commence(ServerHttpRequest request, ServerHttpResponse response, AuthenticationException exception);
}

/// {@template bearer_authentication_entry_point}
/// An [AuthenticationEntryPoint] that writes an HTTP 401 response containing a
/// `WWW-Authenticate` challenge and a JSON error payload.
///
/// ### Contract and invariants
/// - The status is always [HttpStatus.UNAUTHORIZED].
/// - The challenge header has the form `Bearer realm="<realm>"`.
/// - The content type is [MediaType.APPLICATION_JSON] and the body contains
///   `error: unauthorized` plus the exception message.
/// - The class is stateless apart from its [realm] and has a `const` constructor.
///
/// ### Example
/// ```dart
/// const entryPoint = BearerAuthenticationEntryPoint(realm: 'admin');
/// await entryPoint.commence(request, response, exception);
/// ```
///
/// ### See also
/// - [AuthenticationEntryPoint]
/// {@endtemplate}
class BearerAuthenticationEntryPoint implements AuthenticationEntryPoint {
  /// Authentication realm included in the `WWW-Authenticate` header.
  final String realm;

  /// {@macro bearer_authentication_entry_point}
  const BearerAuthenticationEntryPoint({this.realm = 'Jetleaf'});

  /// Writes a 401 status, a bearer challenge, and the JSON error body.
  ///
  /// ### Parameters
  /// - [request] — the unauthenticated request; accepted for interface
  ///   conformance.
  /// - [response] — the response to write.
  /// - [exception] — the source of the error message in the payload.
  ///
  /// ### Returns
  /// A future completing after the body is written.
  @override
  Future<void> commence(ServerHttpRequest request, ServerHttpResponse response, AuthenticationException exception) async {
    response.setStatus(HttpStatus.UNAUTHORIZED);
    response.getHeaders().set('WWW-Authenticate', 'Bearer realm="$realm"');
    response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
    final body = jsonEncode({
      'error': 'unauthorized',
      'message': exception.message,
    });
    final output = response.getBody();
    await output.writeString(body);
    await output.close();
  }
}