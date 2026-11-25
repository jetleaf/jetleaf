import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import '../core/authentication.dart';
import '../core/granted_authority.dart';
import '../core/simple_granted_authority.dart';

/// {@template anonymous_authentication_token}
/// An [Authentication] token representing a principal that has not supplied any
/// credentials.
///
/// The token exists so that downstream code always has an [Authentication]
/// object to inspect, even for public endpoints. Its authorities are limited to
/// a single anonymous role, and it is considered "authenticated" only in the
/// narrow sense that the anonymous state has been established — it is never
/// treated as a fully trusted identity by trust-resolving code.
///
/// ### Contract and invariants
/// - The default principal is the literal `'anonymousUser'`.
/// - The default authority set is `ROLE_ANONYMOUS`; a supplied set replaces it.
/// - The authority set is unmodifiable, so callers cannot widen an anonymous
///   identity's privileges after construction.
/// - The token starts out authenticated, but the [isAuthenticated] setter is
///   revoke-only: passing `true` throws an [ArgumentError], while passing
///   `false` permanently revokes trust.
/// - Credentials are always an empty string and cannot be erased any further.
///
/// ### Example
/// ```dart
/// final anonymous = AnonymousAuthenticationToken();
/// print(anonymous.name);            // anonymousUser
/// print(anonymous.isAuthenticated); // true
///
/// final custom = AnonymousAuthenticationToken(
///   principal: 'guest',
///   authorities: {const SimpleGrantedAuthority('ROLE_GUEST')},
/// );
/// print(custom.name); // guest
/// ```
/// {@endtemplate}
class AnonymousAuthenticationToken with EqualsAndHashCode implements Authentication {
  @override
  final Object? principal;

  @override
  Object? get credentials => '';

  @override
  final Set<GrantedAuthority> authorities;

  @override
  final Object? details;

  /// {@template anonymous_authentication_token._is_authenticated}
  /// Backing field for the token's authentication flag.
  ///
  /// It begins as `true` because the anonymous identity is a valid established
  /// state; only an explicit revocation can flip it to `false`.
  /// {@endtemplate}
  bool _isAuthenticated = true;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  set isAuthenticated(bool value) {
    checkAuthenticationRevocation(value);
    _isAuthenticated = false;
  }

  /// {@macro anonymous_authentication_token}
  AnonymousAuthenticationToken({
    this.principal = 'anonymousUser',
    Set<GrantedAuthority>? authorities,
    this.details,
  }) : authorities = Set.unmodifiable(authorities ?? {const SimpleGrantedAuthority('ROLE_ANONYMOUS')});

  @override
  String get name => principal?.toString() ?? 'anonymousUser';

  @override
  void eraseCredentials() {}

  @override
  String toString() => 'AnonymousAuthenticationToken(principal: $name)';

  /// Contributes the stable token identity to equality and hashing.
  ///
  /// The constant [credentials] value is excluded as a secret placeholder.
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