import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

/// {@template security_filter}
/// Base class for all filters participating in a `SecurityFilterChain`.
///
/// It implements the web [Filter] contract while adding an explicit [order] so
/// execution follows the canonical security filter sequence regardless of
/// configuration order. Equality is derived from the runtime type and order,
/// which keeps filter sets stable when chains are compared.
///
/// ### Contract and ordering guarantees
/// - Subclasses supply [order], normally from `SecurityFilterOrders`, and
///   implement [doFilter].
/// - Lower [order] values run earlier; a chain sorts its filters by this value
///   when constructed.
/// - Implementations should call `chain.next(request, response)` unless they
///   deliberately terminate the request.
/// - Two filters of the same runtime type and order are considered equal.
///
/// ### Who implements this
/// Built-in implementations include the CORS, rate-limiting, headers, CSRF,
/// exception-translation, context-holder, authentication, anonymous,
/// authorization and chain-proxy filters. Applications can add their own by
/// subclassing and registering it through the lambda DSL.
///
/// ### See also
/// - [Filter]
/// - `SecurityFilterChain`
/// - `SecurityFilterOrders`
/// {@endtemplate}
abstract class SecurityFilter with EqualsAndHashCode implements Filter {
  /// Execution priority in the `SecurityFilterChain` (lower runs earlier).
  ///
  /// Implementations should return one of the canonical values from
  /// `SecurityFilterOrders`, or an offset from one when inserting a custom
  /// filter relative to a built-in one.
  int get order;

  /// Contributes the runtime type and [order] to equality and hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, order];
}
