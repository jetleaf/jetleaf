import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import '../core/authentication.dart';
import '../core/exceptions.dart';

/// {@template authentication_event}
/// Base type for events describing an authentication outcome.
///
/// AuthenticationEvent is sealed, so all event varieties are known at compile
/// time and can be handled exhaustively with a `switch`. Each event carries the
/// [Authentication] object that produced it, giving observers access to the
/// principal, authorities, and request details without re-running the
/// authentication pipeline.
///
/// ### Contract and invariants
/// - Instances are immutable; the carried [authentication] reference is fixed
///   at construction.
/// - Subclasses exist only within this library, so consumers pattern-match on
///   [AuthenticationSuccessEvent] and [AuthenticationFailureEvent].
///
/// ### Example
/// ```dart
/// void describe(AuthenticationEvent event) {
///   switch (event) {
///     case AuthenticationSuccessEvent():
///       print('welcome ${event.authentication.name}');
///     case AuthenticationFailureEvent(:final exception):
///       print('denied: ${exception.message}');
///   }
/// }
/// ```
///
/// ### See also
/// - [AuthenticationEventPublisher]
/// - [AuthenticationSuccessEvent]
/// - [AuthenticationFailureEvent]
/// {@endtemplate}
sealed class AuthenticationEvent {
  /// The authentication object whose processing produced this event.
  final Authentication authentication;

  /// {@macro authentication_event}
  const AuthenticationEvent(this.authentication);
}

/// {@template authentication_success_event}
/// An [AuthenticationEvent] published after credentials were successfully
/// verified and a trusted [Authentication] object was produced.
///
/// ### Contract and invariants
/// - The embedded [authentication] is the successful result, including its
///   granted authorities; it is safe to audit or log.
/// - No password or other sensitive credential is retained by the event.
///
/// ### Example
/// ```dart
/// final event = AuthenticationSuccessEvent(authenticated);
/// publisher.publishAuthenticationSuccess(event.authentication);
/// ```
///
/// ### See also
/// - [AuthenticationEventPublisher.publishAuthenticationSuccess]
/// {@endtemplate}
final class AuthenticationSuccessEvent extends AuthenticationEvent with EqualsAndHashCode {
  /// {@macro authentication_success_event}
  const AuthenticationSuccessEvent(super.authentication);

  /// Contributes the runtime type and [authentication] to equality and hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, authentication];
}

/// {@template authentication_failure_event}
/// An [AuthenticationEvent] published when authentication could not be
/// completed.
///
/// ### Contract and invariants
/// - It carries both the attempted [authentication] and the [exception] that
///   caused the failure, so audit logs can explain *why* access was denied.
/// - The credentials on the attempted token may still be populated; treat
///   instances as sensitive and never serialize the credentials field.
///
/// ### Example
/// ```dart
/// final event = AuthenticationFailureEvent(attempt, exception);
/// print(event.exception.message);
/// ```
///
/// ### See also
/// - [AuthenticationEventPublisher.publishAuthenticationFailure]
/// {@endtemplate}
final class AuthenticationFailureEvent extends AuthenticationEvent with EqualsAndHashCode {
  /// The exception that caused the authentication to fail.
  final AuthenticationException exception;

  /// {@macro authentication_failure_event}
  const AuthenticationFailureEvent(super.authentication, this.exception);

  /// Contributes the runtime type, [authentication] and [exception] to equality
  /// and hashing.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, authentication, exception];
}

/// {@template authentication_event_publisher}
/// An observability seam for reporting authentication successes and failures.
///
/// Implementations forward outcomes to an application event bus, an audit
/// trail, or a metrics backend. Publishing is a side channel: a failure in the
/// publisher must never change whether an authentication attempt succeeds.
///
/// ### Contract
/// - [publishAuthenticationSuccess] is called once with the trusted result after
///   authentication completes.
/// - [publishAuthenticationFailure] is called with the attempted token and the
///   [AuthenticationException] that rejected it.
/// - Implementations should be safe to call from concurrent requests and
///   should swallow their own delivery errors, or guarantee delivery cannot
///   fail, so callers never need to guard the call.
///
/// ### Example
/// ```dart
/// final class AuditPublisher implements AuthenticationEventPublisher {
///   const AuditPublisher(this.auditLog);
///
///   final void Function(String message) auditLog;
///
///   @override
///   void publishAuthenticationSuccess(Authentication authentication) {
///     auditLog('login: ${authentication.name}');
///   }
///
///   @override
///   void publishAuthenticationFailure(
///     Authentication authentication,
///     AuthenticationException exception,
///   ) {
///     auditLog('rejected: ${exception.message}');
///   }
/// }
/// ```
///
/// ### See also
/// - [AuthenticationSuccessEvent]
/// - [AuthenticationFailureEvent]
/// - [NoOpAuthenticationEventPublisher]
/// {@endtemplate}
abstract interface class AuthenticationEventPublisher {
  /// Publishes a successful authentication.
  ///
  /// Called with the fully populated [Authentication] returned by an
  /// authentication manager, after authorities have been resolved and
  /// credentials (optionally) erased.
  ///
  /// ### Parameters
  /// - [authentication] — the trusted result of a successful authentication.
  ///
  /// ### Returns
  /// Nothing; delivery failures must be handled by the implementation.
  void publishAuthenticationSuccess(Authentication authentication);

  /// Publishes a failed authentication.
  ///
  /// Called with the token that was attempted and the exception that rejected
  /// it. The token may still hold credentials, so implementations must not
  /// persist the credentials field.
  ///
  /// ### Parameters
  /// - [authentication] — the untrusted token that failed authentication.
  /// - [exception] — the [AuthenticationException] describing the failure.
  ///
  /// ### Returns
  /// Nothing; delivery failures must be handled by the implementation.
  void publishAuthenticationFailure(Authentication authentication, AuthenticationException exception);
}

/// {@template no_op_authentication_event_publisher}
/// An [AuthenticationEventPublisher] that intentionally discards every event.
///
/// It is the default used when no publisher is configured, keeping publishing
/// free of side effects for applications that do not need observability.
///
/// ### Contract and invariants
/// - Both publishing methods are no-ops and always return normally.
/// - The class is stateless and has a `const` constructor, so a single instance
///   can be shared safely.
///
/// ### Example
/// ```dart
/// const publisher = NoOpAuthenticationEventPublisher();
/// publisher.publishAuthenticationSuccess(token); // nothing happens
/// ```
///
/// ### See also
/// - [AuthenticationEventPublisher]
/// {@endtemplate}
final class NoOpAuthenticationEventPublisher implements AuthenticationEventPublisher {
  /// {@macro no_op_authentication_event_publisher}
  const NoOpAuthenticationEventPublisher();

  @override
  void publishAuthenticationSuccess(Authentication authentication) {}

  @override
  void publishAuthenticationFailure(Authentication authentication, AuthenticationException exception) {}
}
