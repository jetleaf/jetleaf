import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

/// {@template jetleaf_security_cors_configuration}
/// Configures Cross-Origin Resource Sharing (CORS) policies for a `CorsFilter`.
///
/// The configuration is immutable and safe to share across chains. It describes
/// which origins, methods and headers are permitted, which response headers are
/// exposed to browser clients, whether credentials are allowed, and how long a
/// preflight result may be cached.
///
/// ### Contract and invariants
/// - A wildcard in [allowedOrigins] grants access to any origin; when
///   [allowCredentials] is true the concrete origin is echoed instead of `*`,
///   because browsers reject wildcard origins on credentialed requests.
/// - [allowedMethods] and [allowedHeaders] are compared case-insensitively by
///   the filter.
/// - An empty [exposedHeaders] list emits no `Access-Control-Expose-Headers`
///   header.
/// - [maxAgeSeconds] controls the `Access-Control-Max-Age` preflight cache.
///
/// ### Example
/// ```dart
/// const config = CorsConfiguration(
///   allowedOrigins: ['https://app.example.com'],
///   allowedMethods: ['GET', 'POST'],
///   allowCredentials: true,
/// );
/// ```
/// {@endtemplate}
class CorsConfiguration with EqualsAndHashCode {
  /// Allowed request origins (for example `['https://app.example.com']` or
  /// `['*']`).
  final List<String> allowedOrigins;

  /// Allowed HTTP methods (for example `['GET', 'POST', 'PUT', 'DELETE',
  /// 'OPTIONS']`).
  final List<String> allowedMethods;

  /// Allowed request headers (for example `['Authorization', 'Content-Type']`).
  final List<String> allowedHeaders;

  /// Response headers exposed to browser clients.
  final List<String> exposedHeaders;

  /// Whether credentials (cookies, authorization headers) are supported.
  final bool allowCredentials;

  /// Preflight cache duration in seconds.
  final int? maxAgeSeconds;

  /// {@macro jetleaf_security_cors_configuration}
  const CorsConfiguration({
    this.allowedOrigins = const ['*'],
    this.allowedMethods = const ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    this.allowedHeaders = const ['Authorization', 'Content-Type', 'X-XSRF-TOKEN'],
    this.exposedHeaders = const [],
    this.allowCredentials = false,
    this.maxAgeSeconds = 3600,
  });

  /// Resolves the `Access-Control-Allow-Origin` value for [origin].
  ///
  /// When [allowedOrigins] contains `*`, the result is `*` unless credentials
  /// are allowed, in which case [origin] itself is echoed. Otherwise the
  /// origin is returned only when it appears in [allowedOrigins].
  ///
  /// ### Parameters
  /// - [origin]: The value of the request's `Origin` header.
  ///
  /// ### Returns
  /// The header value to emit, or `null` when the origin is not permitted.
  ///
  /// ### Example
  /// ```dart
  /// const config = CorsConfiguration(allowedOrigins: ['https://app.example.com']);
  /// print(config.resolveAllowedOrigin('https://app.example.com'));
  /// // https://app.example.com
  /// print(config.resolveAllowedOrigin('https://evil.example.com')); // null
  /// ```
  String? resolveAllowedOrigin(String origin) {
    if (allowedOrigins.contains('*')) {
      return allowCredentials ? origin : '*';
    }
    if (allowedOrigins.contains(origin)) {
      return origin;
    }
    return null;
  }

  /// Contributes the runtime type and every policy field to equality and
  /// hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [
    runtimeType,
    allowedOrigins,
    allowedMethods,
    allowedHeaders,
    exposedHeaders,
    allowCredentials,
    maxAgeSeconds,
  ];
}