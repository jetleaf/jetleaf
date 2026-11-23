// ignore_for_file: use_super_parameters

import 'package:jetleaf_core/lang.dart' show RuntimeException;

/// {@template jetleaf_security_exceptions}
/// Base exception for all security-related errors raised by Jetleaf Security.
///
/// Every security failure carries a human-readable [message] and may wrap the
/// underlying [cause] that led to it. Subclasses narrow the meaning of the
/// failure so callers can react without matching on message strings.
///
/// The hierarchy extends [RuntimeException], so every security failure is an
/// unchecked Jetleaf failure and can be handled with `on RuntimeException` or
/// `on Error`.
///
/// - Exceptions are immutable and safe to pass across zone boundaries.
/// - [toString] includes the runtime type and, when present, the cause.
///
/// ### Example
/// ```dart
/// try {
///   await authenticate(token);
/// } on SecurityException catch (error) {
///   logger.severe(error.toString(), error.cause);
/// }
/// ```
/// {@endtemplate}
class SecurityException extends RuntimeException {
  /// {@macro jetleaf_security_exceptions}
  SecurityException(String message, [Object? cause]) : super(message, cause: cause);

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// {@template authentication_exception}
/// Base exception for failures raised while processing an authentication
/// request.
///
/// Authentication exceptions signal that credentials could not be established
/// or that the account is not eligible for authentication. They are distinct
/// from [AccessDeniedException], which reports an authorization failure.
///
/// ### See also
/// - [SecurityException] — the common base type.
/// - [BadCredentialsException] — invalid credentials.
/// - [AccountStatusException] — account state failures.
/// {@endtemplate}
class AuthenticationException extends SecurityException {
  /// {@macro authentication_exception}
  AuthenticationException(String message, [Object? cause]) : super(message, cause);
}

/// {@template bad_credentials_exception}
/// Thrown when an authentication request is rejected because the supplied
/// credentials are invalid, such as an incorrect password or an expired token.
///
/// The default message is deliberately generic so callers cannot enumerate
/// valid principals from the error text.
///
/// ### Example
/// ```dart
/// if (!encoder.matches(raw, stored)) {
///   throw BadCredentialsException();
/// }
/// ```
/// {@endtemplate}
class BadCredentialsException extends AuthenticationException {
  /// {@macro bad_credentials_exception}
  BadCredentialsException([String message = 'Bad credentials', Object? cause])
      : super(message, cause);
}

/// {@template username_not_found_exception}
/// Thrown when a user cannot be located by the supplied username.
///
/// Some authentication flows deliberately translate this into
/// [BadCredentialsException] at the boundary to avoid revealing whether an
/// account exists.
///
/// ### See also
/// - [AuthenticationException] — the parent category.
/// {@endtemplate}
class UsernameNotFoundException extends AuthenticationException {
  /// {@macro username_not_found_exception}
  UsernameNotFoundException(String message, [Object? cause]) : super(message, cause);
}

/// {@template account_status_exception}
/// Base exception for failures caused by the state of a user account.
///
/// Subclasses identify a specific reason — disabled, locked, expired, or
/// expired credentials — so callers can present an appropriate response.
///
/// ### See also
/// - [AuthenticationException] — the parent category.
/// {@endtemplate}
class AccountStatusException extends AuthenticationException {
  /// {@macro account_status_exception}
  AccountStatusException(String message, [Object? cause]) : super(message, cause);
}

/// {@template disabled_exception}
/// Thrown when authentication is rejected because the account is disabled.
/// {@endtemplate}
class DisabledException extends AccountStatusException {
  /// {@macro disabled_exception}
  DisabledException([String message = 'User account is disabled', Object? cause])
      : super(message, cause);
}

/// {@template locked_exception}
/// Thrown when authentication is rejected because the account is locked.
/// {@endtemplate}
class LockedException extends AccountStatusException {
  /// {@macro locked_exception}
  LockedException([String message = 'User account is locked', Object? cause])
      : super(message, cause);
}

/// {@template account_expired_exception}
/// Thrown when authentication is rejected because the account has expired.
/// {@endtemplate}
class AccountExpiredException extends AccountStatusException {
  /// {@macro account_expired_exception}
  AccountExpiredException([String message = 'User account has expired', Object? cause])
      : super(message, cause);
}

/// {@template credentials_expired_exception}
/// Thrown when authentication is rejected because the credentials themselves
/// have expired, even though the account is still valid.
/// {@endtemplate}
class CredentialsExpiredException extends AccountStatusException {
  /// {@macro credentials_expired_exception}
  CredentialsExpiredException(
      [String message = 'User credentials have expired', Object? cause])
      : super(message, cause);
}

/// {@template access_denied_exception}
/// Thrown when an authenticated principal does not hold a required authority
/// or otherwise fails an authorization check.
///
/// This is an authorization failure, not an authentication failure: the caller
/// has an identity, but that identity is not permitted to perform the action.
///
/// ### See also
/// - [SecurityException] — the common base type.
/// - [InvalidCsrfTokenException] — a more specific denial caused by CSRF validation.
/// {@endtemplate}
class AccessDeniedException extends SecurityException {
  /// {@macro access_denied_exception}
  AccessDeniedException([String message = 'Access is denied', Object? cause])
      : super(message, cause);
}

/// {@template insufficient_authentication_exception}
/// Thrown when an operation requires a stronger identity than the current
/// authentication provides, for example when an anonymous token is presented
/// to a protected endpoint.
///
/// ### See also
/// - [AccessDeniedException] — the related authorization failure category.
/// {@endtemplate}
class InsufficientAuthenticationException extends AuthenticationException {
  /// {@macro insufficient_authentication_exception}
  InsufficientAuthenticationException([
    String message = 'Full authentication is required to access this resource',
    Object? cause,
  ]) : super(message, cause);
}

/// {@template invalid_csrf_token_exception}
/// Thrown when a state-changing request is missing a valid CSRF token.
///
/// The failure is reported as an access denial so a single handler can map all
/// authorization rejections to the same HTTP response.
/// {@endtemplate}
class InvalidCsrfTokenException extends AccessDeniedException {
  /// {@macro invalid_csrf_token_exception}
  InvalidCsrfTokenException(
      [String message = 'Invalid or missing CSRF token', Object? cause])
      : super(message, cause);
}
