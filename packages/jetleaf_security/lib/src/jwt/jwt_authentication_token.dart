import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import '../core/authentication.dart';
import '../core/granted_authority.dart';
import 'jwt_claims_set.dart';

/// {@template jwt_authentication_token}
/// An [Authentication] representing either a bearer JWT awaiting verification
/// or an authenticated JWT principal carrying decoded [claims].
///
/// Trust is granted only by [JwtAuthenticationToken.authenticated]. The
/// unauthenticated constructor holds the raw compact token and no claims; a
/// provider verifies the signature and claims before issuing an authenticated
/// instance with the same token (or with the token omitted).
///
/// - **Revocation-only setter:** `isAuthenticated` cannot grant trust. Setting
///   it to `true` throws through [checkAuthenticationRevocation], and setting
///   it to `false` always revokes.
/// - **Authority safety:** authenticated instances take an unmodifiable copy of
///   the granted authorities.
/// - **Credential erasure:** [eraseCredentials] clears the raw token; decoded
///   claims and authorities remain available for authorization decisions.
///
/// ### See also
/// - `JwtTokenProvider` — creates and verifies these tokens.
/// - `OAuth2ResourceServer` — converts bearer JWT scopes into authorities.
///
/// ### Example
/// ```dart
/// final bearer = JwtAuthenticationToken.unauthenticated(compactJwt);
/// final verified = JwtAuthenticationToken.authenticated(
///   claims: claims,
///   principal: claims.subject,
///   authorities: {SimpleGrantedAuthority('ROLE_USER')},
/// );
/// ```
/// {@endtemplate}
class JwtAuthenticationToken with EqualsAndHashCode implements Authentication {
  /// The raw compact JWT string, or `null` after [eraseCredentials].
  String? token;

  /// Decoded and verified claims; `null` until verification succeeds.
  final JwtClaimsSet? claims;

  @override
  final Object? principal;

  @override
  Object? get credentials => token;

  @override
  final Set<GrantedAuthority> authorities;

  @override
  final Object? details;

  bool _isAuthenticated;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  set isAuthenticated(bool value) {
    checkAuthenticationRevocation(value);
    _isAuthenticated = false;
  }

  /// {@template jwt_authentication_token.unauthenticated}
  /// Creates a bearer JWT request that has not been verified yet.
  ///
  /// ### Parameters
  /// - [token] — the raw compact JWT string from the request.
  /// - [details] — optional request context such as an IP address or session ID.
  ///
  /// ### Returns
  /// An instance with no principal, no claims, no authorities, and
  /// `isAuthenticated == false`.
  /// {@endtemplate}
  /// {@macro jwt_authentication_token}
  JwtAuthenticationToken.unauthenticated(
    this.token, {
    this.details,
  })  : claims = null,
        principal = null,
        authorities = const {},
        _isAuthenticated = false;

  /// {@template jwt_authentication_token.authenticated}
  /// Creates a verified, authenticated JWT principal.
  ///
  /// Only this factory can grant trust; the [isAuthenticated] setter is
  /// revoke-only.
  ///
  /// ### Parameters
  /// - [claims] — the validated claims set from the verified token.
  /// - [principal] — the authenticated identity, typically the `sub` claim.
  /// - [token] — optional raw token kept for credential reporting; it is
  ///   cleared by [eraseCredentials].
  /// - [authorities] — granted authorities, copied into an unmodifiable set.
  /// - [details] — optional request context.
  ///
  /// ### Returns
  /// An instance with `isAuthenticated == true`.
  /// {@endtemplate}
  /// {@macro jwt_authentication_token}
  JwtAuthenticationToken.authenticated({
    required this.claims,
    required this.principal,
    this.token,
    Set<GrantedAuthority> authorities = const {},
    this.details,
  })  : authorities = Set.unmodifiable(authorities),
        _isAuthenticated = true;

  /// The subject from [claims], the string form of [principal], or `''`.
  @override
  String get name => claims?.subject ?? principal?.toString() ?? '';

  /// {@template jwt_authentication_token.erase_credentials}
  /// Clears the raw JWT from memory after authentication completes.
  ///
  /// Verified [claims], [principal], and [authorities] are retained so
  /// authorization can still evaluate the request.
  /// {@endtemplate}
  @override
  void eraseCredentials() {
    token = null;
  }

  @override
  String toString() => 'JwtAuthenticationToken(subject: $name, authenticated: $isAuthenticated, authorities: $authorities)';

  /// Contributes the verified token identity to equality and hashing.
  ///
  /// [token] is excluded because it is a mutable secret.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [
    runtimeType,
    principal,
    claims,
    authorities,
    isAuthenticated,
    details,
  ];
}
