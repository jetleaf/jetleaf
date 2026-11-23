import '../../core/exceptions.dart';
import '../../core/simple_granted_authority.dart';
import '../../jwt/jwk_set_source.dart';
import '../../jwt/jwt_decoder.dart';
import '../../jwt/jwt_validator.dart';
import '../oauth2_authentication_token.dart';
import '../oauth2_user.dart';
import '../oidc_id_token.dart';

/// {@template apple_oauth2_provider}
/// OIDC ID-token verifier and [OAuth2AuthenticationToken] builder for Apple's
/// identity provider (`https://appleid.apple.com`).
///
/// The provider configures a [DartJwtDecoder] with Apple's public JWKS and a
/// [JwtValidator] that requires the fixed issuer and the configured [clientId]
/// as audience. Signature, algorithm, key filtering, issuer, audience, and
/// timestamp checks therefore all run before a user is constructed.
///
/// - **Nonce:** pass [authenticateIdToken]'s `expectedNonce` to reject replayed
///   authentication responses.
/// - **Email verification:** `email_verified` is accepted from a boolean or the
///   string `'true'`; any other shape is treated as not verified.
/// - **Fail-closed:** a missing subject becomes an empty id, and every token
///   check failure surfaces as an [AuthenticationException].
///
/// ### See also
/// - [RemoteJwkSetSource] — the default key source.
/// - [OidcIdToken] — the verified token exposed on the result.
///
/// ### Example
/// ```dart
/// final provider = AppleOAuth2Provider(clientId: 'com.example.services.id');
/// final authentication = await provider.authenticateIdToken(
///   idTokenString,
///   expectedNonce: storedNonce,
/// );
/// ```
/// {@endtemplate}
class AppleOAuth2Provider {
  /// Apple's public JWKS URI.
  static final Uri defaultJwksUri = Uri.parse('https://appleid.apple.com/auth/keys');

  /// Apple Services ID or Bundle ID, verified against the `aud` claim.
  final String clientId;

  final JwtDecoder _decoder;

  /// {@macro apple_oauth2_provider}
  ///
  /// ### Parameters
  /// - [clientId] — the expected audience for incoming ID tokens.
  /// - [jwkSetSource] — optional custom key source; defaults to Apple's public
  ///   JWKS endpoint.
  AppleOAuth2Provider({
    required this.clientId,
    JwkSetSource? jwkSetSource,
  }) : _decoder = DartJwtDecoder.withJwkSet(
        jwkSetSource ?? RemoteJwkSetSource(defaultJwksUri),
        validator: JwtValidator(
          expectedIssuer: 'https://appleid.apple.com',
          expectedAudience: clientId,
        ),
      );

  /// {@template apple_oauth2_provider.authenticate_id_token}
  /// Verifies an Apple OIDC ID token and builds an authenticated principal.
  ///
  /// After the decoder validates the token, a nonce comparison is performed
  /// when [expectedNonce] is supplied. An email-verified claim expressed as
  /// `true` or `'true'` is honored; all other values leave the user unverified.
  /// The resulting user receives `ROLE_USER`.
  ///
  /// ### Parameters
  /// - [idTokenString] — the compact ID token from the client.
  /// - [details] — optional request context.
  /// - [expectedNonce] — nonce stored at authorization-request time; when
  ///   supplied, a mismatch rejects the token.
  ///
  /// ### Returns
  /// An authenticated [OAuth2AuthenticationToken] for provider `'apple'`.
  ///
  /// ### Throws
  /// [BadCredentialsException] on nonce mismatch; [AuthenticationException]
  /// for signature, claim, or validation failures.
  /// {@endtemplate}
  Future<OAuth2AuthenticationToken> authenticateIdToken(String idTokenString, {
    Object? details,
    String? expectedNonce,
  }) async {
    final claims = await _decoder.decode(idTokenString);
    final idToken = OidcIdToken(tokenValue: idTokenString, claims: claims);
    if (expectedNonce != null && idToken.nonce != expectedNonce) {
      throw BadCredentialsException('OIDC nonce mismatch');
    }
    final emailVerifiedRaw = claims.claims['email_verified'];
    final emailVerified = emailVerifiedRaw == true || emailVerifiedRaw == 'true';
    final user = OAuth2User(
      id: claims.subject ?? '',
      name: idToken.email ?? claims.subject ?? '',
      email: idToken.email,
      emailVerified: emailVerified,
      attributes: claims.claims,
      authorities: {SimpleGrantedAuthority('ROLE_USER')},
    );
    return OAuth2AuthenticationToken(
      user: user,
      authorizedClientRegistrationId: 'apple',
      idToken: idToken,
      details: details,
    );
  }
}
