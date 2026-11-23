import 'dart:convert';

import 'package:jetleaf_web/jetleaf_web.dart';

import '../authentication/authentication_manager.dart';
import '../authentication/session_authentication_strategy.dart';
import '../authentication/username_password_authentication_token.dart';
import '../core/authentication.dart';
import '../core/security_context_holder.dart';
import '../jwt/jwt_authentication_token.dart';
import 'filter_orders.dart';
import 'security_filter.dart';

/// {@template authentication_converter}
/// Strategy that extracts an unauthenticated [Authentication] token from an
/// incoming [ServerHttpRequest].
///
/// Implementations recognize one credential format (for example a bearer token
/// or an HTTP Basic header). A converter returns `null` when the request carries
/// no credentials in the format it understands, allowing the next converter to
/// be tried.
///
/// ### Contract
/// - Converters must not authenticate; they only translate request data into a
///   token whose `isAuthenticated` flag is false.
/// - Returning `null` means "not applicable", not "authentication failed".
/// - Implementations are expected to be side-effect free with respect to the
///   request and response.
/// - [AuthenticationFilter] tries converters in declaration order and stops at
///   the first non-null token.
///
/// ### Who implements this
/// [BearerTokenAuthenticationConverter] and [BasicAuthenticationConverter] are
/// the built-in implementations; applications may add others for custom
/// credential formats.
///
/// ### See also
/// - [BearerTokenAuthenticationConverter]
/// - [BasicAuthenticationConverter]
/// - [AuthenticationFilter]
/// {@endtemplate}
abstract interface class AuthenticationConverter {
  /// Converts [request] into an unauthenticated [Authentication] token.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest] whose headers or body may
  ///   carry credentials.
  ///
  /// ### Returns
  /// An unauthenticated token, or `null` when [request] has no credentials in
  /// the format this converter recognizes.
  ///
  /// ### Example
/// ```dart
  /// final token = await converter.convert(request);
  /// if (token != null) {
  ///   final authenticated = await manager.authenticate(token);
  /// }
  /// ```
  Future<Authentication?> convert(ServerHttpRequest request);
}

/// {@template bearer_token_authentication_converter}
/// Extracts an `Authorization: Bearer <token>` header into an unauthenticated
/// [JwtAuthenticationToken].
///
/// The scheme prefix is matched case-sensitively and must be followed by at
/// least one non-whitespace character. Malformed or absent headers yield
/// `null`, which lets another converter handle the request.
///
/// ### Example
/// ```dart
/// final converter = BearerTokenAuthenticationConverter();
/// final token = await converter.convert(request); // JwtAuthenticationToken
/// ```
/// {@endtemplate}
class BearerTokenAuthenticationConverter implements AuthenticationConverter {
  /// {@macro bearer_token_authentication_converter}
  const BearerTokenAuthenticationConverter();

  /// Reads the `Authorization` header and builds a bearer token when present.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest] to inspect.
  ///
  /// ### Returns
  /// An unauthenticated [JwtAuthenticationToken], or `null` when the header is
  /// missing, uses another scheme, or contains an empty token.
  ///
  /// ### Throws
  /// Never throws for malformed header values; such values produce `null`.
  @override
  Future<Authentication?> convert(ServerHttpRequest request) async {
    final header = request.getHeaders().getFirst('Authorization');
    if (header == null) return null;
    const prefix = 'Bearer ';
    if (!header.startsWith(prefix) || header.length <= prefix.length) {
      return null;
    }
    final token = header.substring(prefix.length).trim();
    if (token.isEmpty) return null;
    return JwtAuthenticationToken.unauthenticated(token);
  }
}

/// {@template basic_authentication_converter}
/// Extracts an `Authorization: Basic <base64>` header into an unauthenticated
/// [UsernamePasswordAuthenticationToken].
///
/// The decoded payload must contain a colon separating the username from the
/// password, and the username must be non-empty. Any decoding failure is
/// treated as "converter not applicable" by returning `null`.
///
/// ### Example
/// ```dart
/// final converter = BasicAuthenticationConverter();
/// final token = await converter.convert(request);
/// // UsernamePasswordAuthenticationToken with principal and credentials
/// ```
/// {@endtemplate}
class BasicAuthenticationConverter implements AuthenticationConverter {
  /// {@macro basic_authentication_converter}
  const BasicAuthenticationConverter();

  /// Reads the `Authorization` header and builds a username/password token.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest] to inspect.
  ///
  /// ### Returns
  /// An unauthenticated [UsernamePasswordAuthenticationToken], or `null` when
  /// the header is missing, malformed, or uses another scheme.
  ///
  /// ### Throws
  /// Never throws; invalid base64 or a missing colon results in `null`.
  @override
  Future<Authentication?> convert(ServerHttpRequest request) async {
    final header = request.getHeaders().getFirst('Authorization');
    if (header == null) return null;
    const prefix = 'Basic ';
    if (!header.startsWith(prefix) || header.length <= prefix.length) {
      return null;
    }
    final encoded = header.substring(prefix.length).trim();
    try {
      final decoded = utf8.decode(base64Decode(encoded));
      final colonIndex = decoded.indexOf(':');
      if (colonIndex <= 0) return null;
      final username = decoded.substring(0, colonIndex);
      final password = decoded.substring(colonIndex + 1);
      return UsernamePasswordAuthenticationToken.unauthenticated(
        principal: username,
        credentials: password,
      );
    } catch (_) {
      return null;
    }
  }
}

/// {@template authentication_filter}
/// Extracts credentials from incoming requests via [converters], authenticates
/// them through [authenticationManager], and stores the resulting
/// [Authentication] in [SecurityContextHolder].
///
/// The filter first checks whether the current context already holds an
/// authenticated principal. If not, converters are tried in declaration order
/// until one produces a token; the first token found is handed to the manager
/// and the remaining converters are skipped.
///
/// ### Contract and invariants
/// - An already authenticated context is left untouched, so earlier
///   authentication mechanisms are never downgraded.
/// - At most one converter's token is authenticated per request.
/// - On success the session strategy is notified before the chain advances.
/// - The chain is always advanced, whether or not credentials were found; a
///   failure is reported by [authenticationManager] throwing, which downstream
///   error handling translates into a response.
/// - It occupies the `SecurityFilterOrders.authentication` slot, after context
///   setup and before anonymous authentication and authorization.
///
/// ### Example
/// ```dart
/// final filter = AuthenticationFilter(
///   authenticationManager: manager,
///   converters: [BearerTokenAuthenticationConverter()],
/// );
/// ```
/// {@endtemplate}
class AuthenticationFilter extends SecurityFilter {
  /// Manager used to authenticate extracted tokens.
  final AuthenticationManager authenticationManager;

  /// Ordered list of converters tried on each request.
  final List<AuthenticationConverter> converters;

  /// Strategy invoked after successful authentication (session fixation
  /// protection for stateful policies, no-op for stateless).
  final SessionAuthenticationStrategy sessionAuthenticationStrategy;

  /// Execution priority: after the security context is established and before
  /// the anonymous principal is installed.
  @override
  int get order => SecurityFilterOrders.authentication;

  /// {@macro authentication_filter}
  AuthenticationFilter({
    required this.authenticationManager,
    List<AuthenticationConverter> converters = const [
      BearerTokenAuthenticationConverter(),
      BasicAuthenticationConverter(),
    ],
    SessionAuthenticationStrategy? sessionAuthenticationStrategy,
  })  : converters = List.unmodifiable(converters),
        sessionAuthenticationStrategy = sessionAuthenticationStrategy ?? const NullAuthenticatedSessionStrategy();

  /// Attempts to authenticate [request] and then continues the chain.
  ///
  /// [request] supplies the credentials through its headers. [response] is
  /// passed to the session strategy and may be changed by it (for example to
  /// rotate a session identifier). [chain] is always invoked once authentication
  /// has succeeded or been skipped, so authorization can run afterwards.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest] carrying credentials.
  /// - [response]: The outgoing [ServerHttpResponse] for session handling.
  /// - [chain]: The remaining filter chain to delegate to.
  ///
  /// ### Returns
  /// A [Future] that completes after the downstream chain has finished.
  ///
  /// ### Throws
  /// Propagates an `AuthenticationException` from [authenticationManager] when
  /// supplied credentials are rejected, plus any error from the chain.
  ///
  /// ### Example
/// ```dart
  /// await filter.doFilter(request, response, chain);
  /// final principal = SecurityContextHolder.getContext().authentication;
  /// ```
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    final existing = SecurityContextHolder.getContext().authentication;
    if (existing == null || !existing.isAuthenticated) {
      for (final converter in converters) {
        final token = await converter.convert(request);
        if (token != null) {
          final authenticated = await authenticationManager.authenticate(token);
          SecurityContextHolder.getContext().authentication = authenticated;
          await sessionAuthenticationStrategy.onAuthentication(
            authenticated,
            request,
            response,
          );
          break;
        }
      }
    }

    await chain.next(request, response);
  }
}
