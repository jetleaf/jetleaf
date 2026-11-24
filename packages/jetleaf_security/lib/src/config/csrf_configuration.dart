import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

/// {@template jetleaf_security_csrf_configuration}
/// Configures Cross-Site Request Forgery (CSRF) protection for a `CsrfFilter`.
///
/// The configuration is immutable and selects the cookie/header pair used for
/// the double-submit token pattern, whether protection is active at all, and
/// which path prefixes are exempt.
///
/// ### Contract and invariants
/// - [enabled] is true by default; disabled configurations bypass the filter
///   entirely.
/// - [cookieName] identifies the cookie holding the token issued on safe
///   requests.
/// - [headerName] identifies the request header that must echo that token on
///   unsafe requests.
/// - [ignoringRequestPaths] contains path prefixes, matched against the start
///   of the request URI (for webhook endpoints, for example).
///
/// ### Example
/// ```dart
/// const config = CsrfConfiguration(
///   cookieName: 'XSRF-TOKEN',
///   headerName: 'X-XSRF-TOKEN',
///   ignoringRequestPaths: ['/webhooks/'],
/// );
/// ```
/// {@endtemplate}
class CsrfConfiguration with EqualsAndHashCode {
  /// Whether CSRF protection is enabled.
  final bool enabled;

  /// Cookie name storing the CSRF token. Defaults to `'XSRF-TOKEN'`.
  final String cookieName;

  /// Request header name carrying the CSRF token. Defaults to `'X-XSRF-TOKEN'`.
  final String headerName;

  /// Path prefixes exempt from CSRF validation (for example webhook endpoints).
  /// Matching is segment-aware, so `/api/webhook` does not exempt
  /// `/api/webhook_secret`.
  final List<String> ignoringRequestPaths;

  /// Whether the CSRF cookie carries the `Secure` attribute.
  final bool secure;

  /// {@macro jetleaf_security_csrf_configuration}
  const CsrfConfiguration({
    this.enabled = true,
    this.cookieName = 'XSRF-TOKEN',
    this.headerName = 'X-XSRF-TOKEN',
    this.ignoringRequestPaths = const [],
    this.secure = false,
  });

  /// Disabled CSRF configuration (commonly used for stateless JWT APIs).
  ///
  /// Use this for stateless APIs that authenticate with tokens and do not rely
  /// on ambient credentials such as cookies.
  const CsrfConfiguration.disabled()
    : enabled = false,
      cookieName = 'XSRF-TOKEN',
      headerName = 'X-XSRF-TOKEN',
      ignoringRequestPaths = const [],
      secure = false;

  /// Contributes the runtime type and every policy field to equality and
  /// hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [
    runtimeType,
    enabled,
    cookieName,
    headerName,
    ignoringRequestPaths,
    secure,
  ];
}
