import 'package:jetleaf_web/jetleaf_web.dart';

import '../core/authentication.dart';

/// {@template session_authentication_strategy}
/// A hook invoked after a successful authentication when the application uses a
/// stateful session policy.
///
/// Implementations can regenerate a session identifier, bind the authenticated
/// principal to a session, or record session metadata. The hook receives both
/// the HTTP request and response so it can read the current session and write
/// any required cookie or header changes.
///
/// ### Contract
/// - [onAuthentication] is called only after credentials have been verified.
/// - It must complete normally for the authentication to be considered fully
///   processed; a thrown error prevents the response from being finalised.
/// - Implementations must be safe to call concurrently for different requests.
/// - Stateless applications can use [NullAuthenticatedSessionStrategy].
///
/// ### Example
/// ```dart
/// final class BindPrincipalToSession implements SessionAuthenticationStrategy {
///   const BindPrincipalToSession();
///
///   @override
///   Future<void> onAuthentication(
///     Authentication authentication,
///     ServerHttpRequest request,
///     ServerHttpResponse response,
///   ) async {
///     request.getSession(true).setAttribute('principal', authentication.name);
///   }
/// }
/// ```
///
/// ### See also
/// - [ChangeSessionIdAuthenticationStrategy]
/// - [NullAuthenticatedSessionStrategy]
/// - [CompositeSessionAuthenticationStrategy]
/// {@endtemplate}
abstract interface class SessionAuthenticationStrategy {
  /// Runs the session policy for [authentication] after it succeeds.
  ///
  /// ### Parameters
  /// - [authentication] — the trusted authentication result.
  /// - [request] — the request that triggered authentication; use it to obtain
  ///   the current session.
  /// - [response] — the response to which session cookies or headers can be
  ///   written.
  ///
  /// ### Returns
  /// A future that completes when the session work is finished.
  ///
  /// ### Throws
  /// Implementations may throw if the session cannot be created or migrated;
  /// callers should treat that as a failed authentication flow.
  Future<void> onAuthentication(Authentication authentication, ServerHttpRequest request, ServerHttpResponse response);
}

/// {@template null_authenticated_session_strategy}
/// A [SessionAuthenticationStrategy] that performs no work.
///
/// Use it for stateless or token-based flows where authentication must not
/// create or modify an HTTP session.
///
/// ### Contract and invariants
/// - [onAuthentication] always completes normally without touching the request
///   or response.
/// - The class is stateless and has a `const` constructor.
///
/// ### Example
/// ```dart
/// const strategy = NullAuthenticatedSessionStrategy();
/// await strategy.onAuthentication(result, request, response);
/// ```
///
/// ### See also
/// - [SessionAuthenticationStrategy]
/// {@endtemplate}
final class NullAuthenticatedSessionStrategy implements SessionAuthenticationStrategy {
  /// {@macro null_authenticated_session_strategy}
  const NullAuthenticatedSessionStrategy();

  @override
  Future<void> onAuthentication(Authentication authentication, ServerHttpRequest request, ServerHttpResponse response) async {
    // Intentionally empty.
  }
}

/// {@template composite_session_authentication_strategy}
/// A [SessionAuthenticationStrategy] that runs a list of delegates in order.
///
/// Each delegate is awaited before the next begins, so strategies that depend
/// on an earlier strategy's session changes observe them reliably.
///
/// ### Contract and invariants
/// - Delegates execute in list order, one at a time.
/// - A thrown error stops the sequence and propagates to the caller.
/// - The delegates list is used as supplied; callers should avoid mutating it
///   while authentication is in progress.
///
/// ### Example
/// ```dart
/// const strategy = CompositeSessionAuthenticationStrategy([
///   ChangeSessionIdAuthenticationStrategy(),
///   BindPrincipalToSession(),
/// ]);
/// await strategy.onAuthentication(result, request, response);
/// ```
///
/// ### See also
/// - [SessionAuthenticationStrategy]
/// {@endtemplate}
final class CompositeSessionAuthenticationStrategy implements SessionAuthenticationStrategy {
  /// Strategies to run, in order.
  final List<SessionAuthenticationStrategy> delegates;

  /// {@macro composite_session_authentication_strategy}
  const CompositeSessionAuthenticationStrategy(this.delegates);

  /// Runs every delegate in order, awaiting each one.
  ///
  /// ### Parameters
  /// - [authentication] — the trusted authentication result passed through to
  ///   each delegate.
  /// - [request] — the current HTTP request.
  /// - [response] — the current HTTP response.
  ///
  /// ### Returns
  /// A future completing after the last delegate finishes.
  ///
  /// ### Throws
  /// Any exception thrown by a delegate; later delegates are then skipped.
  @override
  Future<void> onAuthentication(Authentication authentication, ServerHttpRequest request, ServerHttpResponse response) async {
    for (final strategy in delegates) {
      await strategy.onAuthentication(authentication, request, response);
    }
  }
}
