import 'anonymous_authentication_filter.dart';
import 'authentication_filter.dart';
import 'cors_filter.dart';
import 'authorization_filter.dart';
import 'csrf_filter.dart';
import 'exception_translation_filter.dart';
import 'rate_limiting_filter.dart';
import 'security_context_holder_filter.dart';
import 'security_headers_filter.dart';

/// {@template security_filter_orders}
/// The single canonical order table for filters inside a `SecurityFilterChain`.
///
/// Lower values run earlier. Filters are sorted by these values when a chain is
/// built, so the ordering is independent of the order in which components were
/// configured. The constants leave gaps so custom filters can be inserted with
/// `addFilterBefore` and `addFilterAfter` without colliding with built-in ones.
///
/// ### Contract and invariants
/// - Every built-in filter reads its position from this table rather than
///   declaring an independent literal where possible.
/// - A filter that produces data needed by later filters must have a lower
///   value than its consumers (for example context before authentication).
/// - A filter that translates exceptions must run before the filters that
///   raise them.
/// - Keep this in sync with the design ledger (010).
///
/// ### Example
/// ```dart
/// const position = SecurityFilterOrders.authentication; // -50
/// final filter = MyFilter(order: position - 1);
/// ```
/// {@endtemplate}
abstract final class SecurityFilterOrders {
  /// {@macro security_filter_orders}
  const SecurityFilterOrders._();

  /// Cross-origin handling runs first: a rejected preflight must never be
  /// gated by authentication, and CORS headers must decorate all later
  /// responses.
  static const int cors = -100;

  /// Rate limiting follows CORS so legitimate preflight traffic is not charged
  /// against a quota, but precedes all credentials work so abusive traffic is
  /// shed before expensive processing.
  static const int rateLimiting = -95;

  /// Security headers are written early so they are present on every response,
  /// including errors produced by filters further down the chain.
  static const int headers = -80;

  /// CSRF validation precedes authentication and authorization so a forged
  /// state-changing request is rejected before credentials are examined.
  static const int csrf = -70;

  /// Exception translation sits just before authentication and authorization,
  /// whose security exceptions it converts into 401 and 403 responses. It runs
  /// after CSRF because that filter renders its own denial.
  static const int exceptionTranslation = -65;

  /// The per-request security context must be loaded and bound before any
  /// filter reads or writes the current authentication.
  static const int securityContextHolder = -60;

  /// Authentication consumes the established context and must therefore run
  /// after it, but before anonymous authentication and authorization so a real
  /// principal takes precedence.
  static const int authentication = -50;

  /// Anonymous authentication runs only after real authentication has had a
  /// chance to populate the context, and before authorization so a principal
  /// always exists.
  static const int anonymous = -40;

  /// Reserved slot for session-policy handling: after a principal is
  /// established and before the final authorization decision.
  static const int sessionManagement = -30;

  /// Authorization is the final gate. It runs once identity and context are
  /// fully established, and sits at zero so custom filters can be placed on
  /// either side with small offsets.
  static const int authorization = 0;

  /// Lookup table used by `addFilterBefore` / `addFilterAfter`.
  ///
  /// Each built-in filter type maps to the constant above that defines its
  /// position. Unknown types are rejected with an [ArgumentError] by the
  /// builder rather than silently receiving an arbitrary order.
  static const Map<Type, int> byType = {
    CorsFilter: cors,
    RateLimitingFilter: rateLimiting,
    SecurityHeadersFilter: headers,
    CsrfFilter: csrf,
    ExceptionTranslationFilter: exceptionTranslation,
    SecurityContextHolderFilter: securityContextHolder,
    AuthenticationFilter: authentication,
    AnonymousAuthenticationFilter: anonymous,
    AuthorizationFilter: authorization,
  };
}
