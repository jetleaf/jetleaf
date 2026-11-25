import '../../core/exceptions.dart';
import '../../core/simple_granted_authority.dart';
import '../../jwt/jwk_set_source.dart';
import '../../jwt/jwt_decoder.dart';
import '../../jwt/jwt_validator.dart';
import '../oauth2_authentication_token.dart';
import '../oauth2_user.dart';
import '../oidc_id_token.dart';

/// {@template google_oauth2_provider}
/// OIDC ID-token verifier and [OAuth2AuthenticationToken] builder for Google's
/// identity provider (`https://accounts.google.com`).
///
/// The provider configures a [DartJwtDecoder] with Google's public JWKS. The
/// audience is checked against [clientId], and the issuer is enforced by a
/// custom validator that compares the full OIDC issuer URI rather than a bare
/// hostname. Signature, algorithm, key filtering, issuer, audience, and
/// timestamp checks therefore all run before a user is constructed.
///
/// - **Client checks:** when present, `azp` must equal [clientId], and a nonce
///   supplied to [authenticateIdToken] must match the token's `nonce`.
/// - **Fail-closed:** a missing subject becomes an empty id, and any token
///   check failure surfaces as an [AuthenticationException].
///
/// ### See also
/// - [RemoteJwkSetSource] — the default key source.
/// - [OidcIdToken] — the verified token exposed on the result.
///
/// ### Example
/// ```dart
/// final provider = GoogleOAuth2Provider(clientId: 'my-client.apps.googleusercontent.com');
/// final authentication = await provider.authenticateIdToken(
///   idTokenString,
///   expectedNonce: storedNonce,
/// );
/// ```
/// {@endtemplate}
class GoogleOAuth2Provider {
  /// Google's public JWKS URI.
  static final Uri defaultJwksUri = Uri.parse('https://www.googleapis.com/oauth2/v3/certs');

  /// Expected OAuth2 client ID, verified against `aud` and `azp`.
  final String clientId;

  final JwtDecoder _decoder;

  /// {@macro google_oauth2_provider}
  ///
  /// ### Parameters
  /// - [clientId] — the expected audience for incoming ID tokens.
  /// - [jwkSetSource] — optional custom key source; defaults to Google's public
  ///   JWKS endpoint.
  GoogleOAuth2Provider({
    required this.clientId,
    JwkSetSource? jwkSetSource,
  }) : _decoder = DartJwtDecoder.withJwkSet(
        jwkSetSource ?? RemoteJwkSetSource(defaultJwksUri),
        validator: JwtValidator(
          expectedAudience: clientId,
          // Bare hostnames are not valid OIDC issuers.
          customValidator: (claims) => claims.issuer == 'https://accounts.google.com',
        ),
      );

  /// {@template google_oauth2_provider.authenticate_id_token}
  /// Verifies a Google OIDC ID token and builds an authenticated principal.
  ///
  /// After the decoder validates the token, the optional nonce and the `azp`
  /// claim (when present) are compared with [clientId]. The user's display name
  /// prefers the `name` claim, then `email`, then the subject. A successful
  /// result carries `ROLE_USER`.
  ///
  /// ### Parameters
  /// - [idTokenString] — the compact ID token from the client.
  /// - [details] — optional request context.
  /// - [expectedNonce] — nonce stored at authorization-request time; a
  ///   mismatch rejects the token.
  ///
  /// ### Returns
  /// An authenticated [OAuth2AuthenticationToken] for provider `'google'`.
  ///
  /// ### Throws
  /// [BadCredentialsException] on nonce or `azp` mismatch;
  /// [AuthenticationException] for signature, claim, or validation failures.
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
    final azp = claims.getClaim<String>('azp');
    if (azp != null && azp != clientId) {
      throw BadCredentialsException('OIDC azp does not match client id');
    }
    final user = OAuth2User(
      id: claims.subject ?? '',
      name: idToken.fullName ?? idToken.email ?? claims.subject ?? '',
      email: idToken.email,
      emailVerified: idToken.emailVerified,
      attributes: claims.claims,
      authorities: {SimpleGrantedAuthority('ROLE_USER')},
    );
    return OAuth2AuthenticationToken(
      user: user,
      authorizedClientRegistrationId: 'google',
      idToken: idToken,
      details: details,
    );
  }
}