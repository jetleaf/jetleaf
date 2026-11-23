import 'package:jetleaf_core/annotation.dart';

import 'package:jetleaf_security/jwt.dart';
import 'package:jetleaf_security/oauth2.dart';

/// Local identity-provider setup for the OAuth2/OIDC endpoints.
@Configuration()
final class OAuth2Config {
  static const String GOOGLE_CLIENT = 'demo-client.apps.googleusercontent.com';
  static const String APPLE_CLIENT = 'com.example.demo';
  static const String IDP_ISSUER = 'https://idp.example.com';
  static const String IDP_SECRET = 'local-idp-secret-at-least-32-bytes-long!';
  static const String KEY_ID = 'demo-signing-key';

  static const String JWKS = 'example.jwks';
  static const String TOKEN_ENCODER = 'example.idTokenEncoder';
  static const String GOOGLE = 'example.googleProvider';
  static const String APPLE = 'example.appleProvider';
  static const String GITHUB = 'example.githubProvider';
  static const String RESOURCE_SERVER = 'example.oauth2ResourceServer';

  const OAuth2Config();

  /// A static JWKS holding the demo HMAC key, so no network is needed.
  @Pod(value: JWKS)
  JwkSetSource jwkSetSource() => StaticJwkSetSource({
        KEY_ID: Jwk.fromJson({
          'kty': 'oct',
          'kid': KEY_ID,
          'use': 'sig',
          'alg': 'HS256',
          'k': JwtBase64Url.encode(JwtSecretKey.fromString(IDP_SECRET).bytes),
        }),
      });

  /// Emits locally-signed ID tokens and resource-server tokens.
  @Pod(value: TOKEN_ENCODER)
  JwtEncoder idTokenEncoder() => DartJwtEncoder(
        signingKey: JwtSecretKey.fromString(IDP_SECRET),
        algorithm: JwsAlgorithms.hs256,
        issuer: IDP_ISSUER,
      );

  @Pod(value: GOOGLE)
  GoogleOAuth2Provider googleProvider(JwkSetSource jwks) => GoogleOAuth2Provider(
        clientId: GOOGLE_CLIENT,
        jwkSetSource: jwks,
      );

  @Pod(value: APPLE)
  AppleOAuth2Provider appleProvider(JwkSetSource jwks) => AppleOAuth2Provider(
        clientId: APPLE_CLIENT,
        jwkSetSource: jwks,
      );

  @Pod(value: GITHUB)
  GitHubOAuth2Provider githubProvider() => GitHubOAuth2Provider();

  @Pod(value: RESOURCE_SERVER)
  OAuth2ResourceServer resourceServer(JwkSetSource jwks) => OAuth2ResourceServer(
        jwtDecoder: DartJwtDecoder.withJwkSet(
          jwks,
          validator: JwtValidator(
            expectedIssuer: IDP_ISSUER,
            expectedAudience: SecurityAudience.resourceApi,
          ),
        ),
      );
}

/// Audience used by the resource-server demo endpoint.
abstract final class SecurityAudience {
  static const String resourceApi = 'jetleaf-resource-api';

  const SecurityAudience._();
}
