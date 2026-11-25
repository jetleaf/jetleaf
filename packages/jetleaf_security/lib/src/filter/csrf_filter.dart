import 'dart:convert';
import 'dart:math';

import 'package:jetleaf_web/jetleaf_web.dart';

import '../authorization/access_denied_handler.dart';
import '../config/csrf_configuration.dart';
import '../core/exceptions.dart';
import '../crypto/password_encoder.dart';
import 'security_filter.dart';

/// {@template jetleaf_security_csrf_filter}
/// Protects state-changing HTTP methods (`POST`, `PUT`, `PATCH`, `DELETE`)
/// against Cross-Site Request Forgery using the double-submit cookie/header
/// pattern.
///
/// A safe request that has no token yet receives a newly generated token in a
/// `Set-Cookie` header. Unsafe requests must echo that token in a request
/// header; the two values are compared in constant time. A mismatch is written
/// directly to the response through [accessDeniedHandler] because this filter
/// runs before the exception-translation filter.
///
/// ### Contract and invariants
/// - `GET`, `HEAD`, `OPTIONS` and `TRACE` are always safe and never rejected.
/// - Requests to a configured ignored path prefix bypass validation entirely.
/// - When protection is disabled the filter is a pure pass-through.
/// - Cookie and header tokens are compared with
///   `constantTimeEquals` to avoid leaking information through timing.
/// - Generated tokens are 32 random bytes encoded as unpadded base64url.
/// - It occupies the `SecurityFilterOrders.csrf` slot, ahead of authentication
///   and authorization.
///
/// ### Example
/// ```dart
/// final filter = CsrfFilter(
///   configuration: const CsrfConfiguration(),
///   accessDeniedHandler: const JsonAccessDeniedHandler(),
/// );
/// ```
/// {@endtemplate}
class CsrfFilter extends SecurityFilter {
  /// {@template csrf_filter.safe_methods}
  /// HTTP methods that never require a CSRF token.
  ///
  /// These methods are defined as read-only by the HTTP specification, so a
  /// cross-site request cannot mutate application state through them.
  /// {@endtemplate}
  static const Set<String> _safeMethods = {'GET', 'HEAD', 'OPTIONS', 'TRACE'};

  /// CSRF configuration.
  final CsrfConfiguration configuration;

  /// Handler that renders the 403 response directly. `CsrfFilter` sits outside
  /// the exception-translation filter, so it must handle its own denial.
  final AccessDeniedHandler accessDeniedHandler;

  /// {@template csrf_filter.random}
  /// Cryptographically secure source used to generate new CSRF token bytes.
  /// {@endtemplate}
  final Random _random = Random.secure();

  /// Execution priority: before authentication and authorization so unsafe
  /// requests are rejected before credentials are processed.
  @override
  int get order => -70;

  /// {@macro jetleaf_security_csrf_filter}
  CsrfFilter({
    CsrfConfiguration? configuration,
    AccessDeniedHandler? accessDeniedHandler,
  })  : configuration = configuration ?? const CsrfConfiguration(),
        accessDeniedHandler = accessDeniedHandler ?? const JsonAccessDeniedHandler();

  /// Validates CSRF tokens for unsafe methods, then continues the chain.
  ///
  /// [request] supplies the method, URI and CSRF cookie/header. [response]
  /// receives a `Set-Cookie` header for new tokens or a denial status and body
  /// for invalid ones. [chain] is called with `chain.next(request, response)`
  /// on every allowed path; denied unsafe requests return without delegating.
  ///
  /// ### Parameters
  /// - [request]: The incoming [ServerHttpRequest].
  /// - [response]: The outgoing [ServerHttpResponse].
  /// - [chain]: The remaining filter chain to delegate to on success.
  ///
  /// ### Returns
  /// A [Future] that completes after the chain finishes or after the denial
  /// response is written.
  ///
  /// ### Throws
  /// Does not throw for a token mismatch; [accessDeniedHandler] renders the
  /// response. Errors from downstream filters propagate normally.
  ///
  /// ### Example
  /// ```dart
  /// // GET issues XSRF-TOKEN; POST must echo it in X-XSRF-TOKEN.
  /// await filter.doFilter(request, response, chain);
  /// ```
  @override
  Future<void> doFilter(ServerHttpRequest request, ServerHttpResponse response, FilterChain chain) async {
    if (!configuration.enabled) {
      await chain.next(request, response);
      return;
    }

    final path = request.getRequestURI().path;
    if (configuration.ignoringRequestPaths.any((prefix) => _pathMatchesPrefix(path, prefix))) {
      await chain.next(request, response);
      return;
    }

    final cookieToken = request.getCookies().get(configuration.cookieName)?.getValue();
    final method = request.getMethod().toString().toUpperCase();

    if (_safeMethods.contains(method)) {
      if (cookieToken == null || cookieToken.isEmpty) {
        final token = _generateToken();
        final secure = configuration.secure || request.getUri().scheme == 'https';
        response.getHeaders().add(
          'Set-Cookie',
          '${configuration.cookieName}=$token; Path=/; SameSite=Lax'
          '${secure ? '; Secure' : ''}',
        );
      }
      await chain.next(request, response);
      return;
    }

    final headerToken = request.getHeaders().getFirst(configuration.headerName);
    if (cookieToken == null ||
        cookieToken.isEmpty ||
        headerToken == null ||
        headerToken.isEmpty ||
        !constantTimeEquals(utf8.encode(cookieToken), utf8.encode(headerToken))) {
      await accessDeniedHandler.handle(
        request,
        response,
        InvalidCsrfTokenException(),
      );
      return;
    }

    await chain.next(request, response);
  }

  /// {@template csrf_filter.generate_token}
  /// Generates an unpadded base64url CSRF token from 32 secure random bytes.
  ///
  /// ### Returns
  /// A URL-safe token string suitable for a cookie value or request header.
  /// {@endtemplate}
  /// Matches a configured ignore prefix on path-segment boundaries so that
  /// `/api/webhook` never accidentally exempts `/api/webhook_secret`.
  static bool _pathMatchesPrefix(String path, String prefix) {
    final normalized = prefix.endsWith('/') ? prefix.substring(0, prefix.length - 1) : prefix;
    if (normalized.isEmpty) return true;
    return path == normalized || path == '$normalized/' || path.startsWith('$normalized/');
  }

  String _generateToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}