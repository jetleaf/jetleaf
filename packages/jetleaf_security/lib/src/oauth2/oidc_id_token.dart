import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

import '../jwt/jwt_claims_set.dart';

/// {@template oidc_id_token}
/// A verified OpenID Connect ID token: its raw compact string plus decoded
/// [claims].
///
/// The claims have already passed signature verification and claim validation
/// by the time this object is built. Accessors expose the registered OIDC
/// claims and common profile fields; absent or wrongly typed values yield
/// `null`, and [emailVerified] defaults to `false` so a missing claim is never
/// interpreted as a verified email.
///
/// - [nonce] is exposed so a caller can compare it against the value stored at
///   authorization-request time for replay protection.
/// - [tokenValue] is a credential and should be erased when no longer needed.
///
/// ### See also
/// - [JwtClaimsSet] — the underlying verified claims.
/// - [OAuth2AuthenticationToken] — carries this token in an authentication.
///
/// ### Example
/// ```dart
/// final idToken = OidcIdToken(tokenValue: compactJwt, claims: claims);
/// if (idToken.nonce != storedNonce) {
///   throw BadCredentialsException('OIDC nonce mismatch');
/// }
/// print(idToken.subject);
/// ```
/// {@endtemplate}
class OidcIdToken with EqualsAndHashCode {
  /// The raw compact ID-token string.
  final String tokenValue;

  /// Verified claims extracted from the ID token.
  final JwtClaimsSet claims;

  /// {@macro oidc_id_token}
  ///
  /// ### Parameters
  /// - [tokenValue] — the original compact JWT string.
  /// - [claims] — claims from a token that has already been verified.
  const OidcIdToken({
    required this.tokenValue,
    required this.claims,
  });

  /// The `sub` (subject) claim.
  String? get subject => claims.subject;

  /// The `iss` (issuer) claim.
  String? get issuer => claims.issuer;

  /// The `email` claim, when present.
  String? get email => claims.getClaim<String>('email');

  /// The `email_verified` claim, defaulting to `false` when absent.
  bool get emailVerified => claims.getClaim<bool>('email_verified') ?? false;

  /// The `name` claim, when present.
  String? get fullName => claims.getClaim<String>('name');

  /// The `nonce` claim used for replay protection.
  String? get nonce => claims.getClaim<String>('nonce');

  /// Contributes the runtime type and [claims] to equality and hashing.
  ///
  /// [tokenValue] is excluded because it is a credential.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, claims];
}