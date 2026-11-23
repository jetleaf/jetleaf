import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import '../core/authentication.dart';
import '../core/granted_authority.dart';
import '../core/user_details.dart';

/// {@template username_password_authentication_token}
/// An [Authentication] implementation for presenting a username and password.
///
/// A token begins life untrusted and carries the raw credentials supplied by a
/// client. Only the [UsernamePasswordAuthenticationToken.authenticated]
/// constructor grants trust by populating authorities; the [isAuthenticated]
/// setter is revoke-only and throws when asked to grant trust.
///
/// ### Contract and invariants
/// - [UsernamePasswordAuthenticationToken.unauthenticated] produces a token
///   with an empty authority set and `isAuthenticated == false`.
/// - [UsernamePasswordAuthenticationToken.authenticated] produces a token with
///   an unmodifiable authority set and `isAuthenticated == true`.
/// - Setting [isAuthenticated] to `true` throws an [ArgumentError]; setting it
///   to `false` revokes trust permanently.
/// - [eraseCredentials] clears the stored password but leaves the principal and
///   authorities intact.
/// - [name] prefers [UserDetails.username] when the principal is a
///   [UserDetails], falling back to the principal's string representation.
///
/// ### Example
/// ```dart
/// final attempt = UsernamePasswordAuthenticationToken.unauthenticated(
///   principal: 'alice',
///   credentials: 's3cret',
/// );
/// print(attempt.isAuthenticated); // false
///
/// final trusted = UsernamePasswordAuthenticationToken.authenticated(
///   principal: attempt.principal,
///   authorities: {const SimpleGrantedAuthority('ROLE_USER')},
/// );
/// print(trusted.isAuthenticated); // true
/// ```
/// {@endtemplate}
class UsernamePasswordAuthenticationToken with EqualsAndHashCode implements Authentication {
  /// The identity being authenticated, typically a username or [UserDetails].
  @override
  final Object? principal;

  /// The password or other secret proving the principal's identity.
  @override
  Object? credentials;

  /// The authorities granted to the principal.
  @override
  final Set<GrantedAuthority> authorities;

  /// Optional request-specific details such as an IP address or session id.
  @override
  final Object? details;

  /// {@template username_password_authentication_token._is_authenticated}
  /// Backing field for the token's authentication flag.
  ///
  /// Only a named constructor may set it to `true`; the setter can only clear
  /// it by delegating to [checkAuthenticationRevocation].
  /// {@endtemplate}
  bool _isAuthenticated;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  set isAuthenticated(bool value) {
    checkAuthenticationRevocation(value);
    _isAuthenticated = false;
  }

  /// Creates an unauthenticated token with [principal] and [credentials].
  ///
  /// The token carries no authorities until an authentication provider verifies
  /// the credentials and produces an authenticated token.
  ///
  /// ### Parameters
  /// - [principal] — the claimed identity, such as a username.
  /// - [credentials] — the raw secret to verify.
  /// - [details] — optional contextual information about the request.
  ///
  /// ### Returns
  /// A token whose [isAuthenticated] is `false` and whose authorities are empty.
  /// {@macro username_password_authentication_token}
  UsernamePasswordAuthenticationToken.unauthenticated({
    required this.principal,
    required this.credentials,
    this.details,
  })  : authorities = const {}, _isAuthenticated = false;

  /// Creates an authenticated token with granted [authorities].
  ///
  /// Use this constructor only after credentials have been verified. The
  /// supplied credential value is typically `null` so the raw password does not
  /// outlive verification.
  ///
  /// ### Parameters
  /// - [principal] — the verified identity, often the loaded [UserDetails].
  /// - [credentials] — optional credential value; pass `null` to avoid retaining
  ///   the raw password.
  /// - [authorities] — the granted authorities, copied into an unmodifiable set.
  /// - [details] — optional contextual information about the request.
  ///
  /// ### Returns
  /// A token whose [isAuthenticated] is `true`.
  /// {@macro username_password_authentication_token}
  UsernamePasswordAuthenticationToken.authenticated({
    required this.principal,
    this.credentials,
    Set<GrantedAuthority> authorities = const {},
    this.details,
  })  : authorities = Set.unmodifiable(authorities), _isAuthenticated = true;

  /// Returns the principal's username, or its string representation.
  ///
  /// ### Returns
  /// [UserDetails.username] when [principal] is a [UserDetails]; otherwise the
  /// principal's [Object.toString] result, or an empty string when there is no
  /// principal.
  @override
  String get name {
    final p = principal;
    if (p is UserDetails) {
      return p.username;
    }

    return p?.toString() ?? '';
  }

  /// Clears the stored credentials.
  ///
  /// The principal, authorities, details, and authentication state are left
  /// untouched. Calling this method more than once is harmless.
  @override
  void eraseCredentials() {
    credentials = null;
  }

  @override
  String toString() => 'UsernamePasswordAuthenticationToken(principal: $name, authenticated: $isAuthenticated, authorities: $authorities)';

  /// Contributes the stable token identity to equality and hashing.
  ///
  /// [credentials] is excluded because it is a mutable secret.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [
    runtimeType,
    principal,
    authorities,
    isAuthenticated,
    details,
  ];
}
