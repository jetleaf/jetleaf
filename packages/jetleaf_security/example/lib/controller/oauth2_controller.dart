import 'package:jetleaf_core/annotation.dart';

import 'package:jetleaf_security/core.dart';
import 'package:jetleaf_security/jwt.dart';
import 'package:jetleaf_security/oauth2.dart';
import 'package:jetleaf_web/annotation.dart';

import '../config/oauth2_config.dart';

/// Demonstrates resource-server verification and OIDC provider validation with
/// a local identity provider.
@RestController()
class OAuth2Controller {
  @Autowired()
  late final OAuth2ResourceServer resourceServer;

  @Autowired()
  late final GoogleOAuth2Provider googleProvider;

  @Autowired()
  late final AppleOAuth2Provider appleProvider;

  @Autowired()
  late final JwtEncoder idTokenEncoder;

  @GetMapping(path: '/api/oauth2/token')
  Future<Map<String, Object?>> token(
    @RequestParam(value: 'subject') String subject,
    @RequestParam(value: 'provider') String provider,
    @RequestParam(value: 'nonce') String nonce,
  ) async {
    final issuer = switch (provider) {
      'google' => 'https://accounts.google.com',
      'apple' => 'https://appleid.apple.com',
      _ => OAuth2Config.IDP_ISSUER,
    };
    final audience = switch (provider) {
      'google' => OAuth2Config.GOOGLE_CLIENT,
      'apple' => OAuth2Config.APPLE_CLIENT,
      _ => SecurityAudience.resourceApi,
    };
    final now = DateTime.now().toUtc();
    final compact = idTokenEncoder.encode(
      JwtClaimsSet({
        'sub': subject,
        'iss': issuer,
        'aud': audience,
        'azp': audience,
        'nonce': nonce,
        'email': '$subject@example.com',
        'email_verified': true,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': now.add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000,
      }),
      keyId: OAuth2Config.KEY_ID,
    );
    return {'id_token': compact, 'issuer': issuer, 'audience': audience};
  }

  @GetMapping(path: '/api/oauth2/google')
  Future<Map<String, Object?>> google(
    @RequestParam(value: 'idToken') String idToken,
    @RequestParam(value: 'nonce') String nonce,
  ) async {
    final authentication = await googleProvider.authenticateIdToken(
      idToken,
      expectedNonce: nonce,
    );
    return _describe(authentication);
  }

  @GetMapping(path: '/api/oauth2/apple')
  Future<Map<String, Object?>> apple(
    @RequestParam(value: 'idToken') String idToken,
    @RequestParam(value: 'nonce') String nonce,
  ) async {
    final authentication = await appleProvider.authenticateIdToken(
      idToken,
      expectedNonce: nonce,
    );
    return _describe(authentication);
  }

  @GetMapping(path: '/api/oauth2/resource')
  Future<Map<String, Object?>> resource(
    @RequestHeader(value: 'Authorization') String authorization,
  ) async {
    final token = authorization.startsWith('Bearer ')
        ? authorization.substring(7)
        : authorization;
    final authentication = await resourceServer.authenticateBearer(token);
    return _describe(authentication);
  }

  Map<String, Object?> _describe(Authentication authentication) => {
        'name': authentication.name,
        'provider': authentication is OAuth2AuthenticationToken
            ? authentication.authorizedClientRegistrationId
            : 'jwt',
        'authorities': authentication.authorities
            .map((authority) => authority.authority)
            .toList(),
      };
}
