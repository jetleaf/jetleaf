import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import 'typedefs.dart';
import '../core/typedefs.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

import '../core/authentication.dart';
import 'authorization_decision.dart';
import 'authorization_manager.dart';

/// {@template request_authorization_entry}
/// A request matcher paired with the manager that governs matching requests.
///
/// Entries are consumed by [RequestMatcherDelegatingAuthorizationManager],
/// which evaluates [matches] in order and delegates the first match to
/// [manager].
///
/// ### Contract and invariants
/// - [matches] is a pure predicate over a [ServerHttpRequest]; it should not
///   mutate the request.
/// - [manager] receives a [RequestAuthorizationContext] wrapping the request.
/// - Order matters: an entry placed earlier shadows later overlapping entries.
///
/// ### Example
/// ```dart
/// final entry = RequestAuthorizationEntry(
///   matches: (request) => request.getUri().path.startsWith('/admin'),
///   manager: AuthorityAuthorizationManager.hasRole('ADMIN'),
/// );
/// ```
/// {@endtemplate}
final class RequestAuthorizationEntry with EqualsAndHashCode {
  /// Predicate selecting requests governed by [manager].
  final RequestPredicate matches;

  /// Manager evaluated for matching requests.
  final AuthorizationManager<RequestAuthorizationContext> manager;

  /// {@macro request_authorization_entry}
  ///
  /// Creates an entry pairing a predicate with a manager.
  ///
  /// ### Parameters
  /// - [matches]: predicate that selects requests governed by this entry.
  /// - [manager]: manager evaluated when the predicate returns `true`.
  const RequestAuthorizationEntry({
    required this.matches,
    required this.manager,
  });

  /// Contributes the runtime type, [matches] and [manager] to equality and
  /// hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, matches, manager];
}

/// {@template request_matcher_delegating_authorization_manager}
/// Selects the first matching entry and delegates the decision to its manager.
///
/// The manager walks [entries] in declaration order, calling each entry's
/// [RequestAuthorizationEntry.matches] predicate against the incoming
/// [ServerHttpRequest]. The first matching entry wins and its
/// [RequestAuthorizationEntry.manager] decides the outcome; the caller's
/// authentication supplier is passed through unchanged.
///
/// When no entry matches, the manager fails closed and returns a denied
/// [AuthorizationDecision]. This makes the default behavior safe: adding a new
/// route never silently grants access.
///
/// ### Contract and invariants
/// - [entries] is ordered; first match wins and later entries are not evaluated.
/// - A `null` or unauthenticated principal is handled by the delegated manager,
///   not by this class.
/// - No match always yields [AuthorizationDecision.denied].
///
/// ### Example
/// ```dart
/// final manager = RequestMatcherDelegatingAuthorizationManager([
///   RequestAuthorizationEntry(
///     matches: (request) => request.getUri().path.startsWith('/public'),
///     manager: const PermitAllAuthorizationManager(),
///   ),
///   RequestAuthorizationEntry(
///     matches: (request) => request.getUri().path.startsWith('/admin'),
///     manager: AuthorityAuthorizationManager.hasRole('ADMIN'),
///   ),
/// ]);
/// ```
/// {@endtemplate}
final class RequestMatcherDelegatingAuthorizationManager implements AuthorizationManager<ServerHttpRequest> {
  /// Ordered entries; first match wins.
  final List<RequestAuthorizationEntry> entries;

  /// {@macro request_matcher_delegating_authorization_manager}
  ///
  /// Creates a manager over an ordered list of [entries].
  ///
  /// ### Parameters
  /// - [entries]: rules to evaluate in order; place specific rules first.
  const RequestMatcherDelegatingAuthorizationManager(this.entries);

  /// {@template request_matcher_delegating_authorization_manager_check}
  /// Delegates to the first entry whose predicate matches [request].
  ///
  /// The authentication supplier is forwarded to the selected manager, which
  /// receives a [RequestAuthorizationContext] carrying the request. When
  /// nothing matches, a denied decision is returned.
  ///
  /// ### Parameters
  /// - [authentication]: supplier for the current [Authentication], or `null`
  ///   when no authentication is present.
  /// - [request]: the incoming [ServerHttpRequest] to authorize.
  ///
  /// ### Returns
  /// The selected manager's [AuthorizationDecision], or
  /// [AuthorizationDecision.denied] when no entry matches.
  ///
  /// ### Example
  /// ```dart
  /// final decision = manager.check(() => currentAuthentication, request);
  /// ```
  /// {@endtemplate}
  @override
  AuthorizationDecision check(AuthenticationSupplier authentication, ServerHttpRequest request) {
    for (final entry in entries) {
      if (entry.matches(request)) {
        return entry.manager.check(
          authentication,
          RequestAuthorizationContext(request),
        );
      }
    }
    // Fail closed.
    return AuthorizationDecision.denied;
  }
}