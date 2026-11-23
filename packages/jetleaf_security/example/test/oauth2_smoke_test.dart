import 'package:jetleaf_security/core.dart';
import 'package:jetleaf_security/jwt.dart';
import 'package:jetleaf_security/oauth2.dart';
import 'package:test/test.dart';

import 'package:jetleaf_security_example/config/oauth2_config.dart';

void main() {
  test('resource server verifies a locally signed token', () async {
    const secret = OAuth2Config.IDP_SECRET;
    final encoder = DartJwtEncoder(
      signingKey: JwtSecretKey.fromString(secret),
      algorithm: JwsAlgorithms.hs256,
      issuer: OAuth2Config.IDP_ISSUER,
    );
    
    final jwks = StaticJwkSetSource({
      OAuth2Config.KEY_ID: Jwk.fromJson({
        'kty': 'oct',
        'kid': OAuth2Config.KEY_ID,
        'use': 'sig',
        'alg': 'HS256',
        'k': JwtBase64Url.encode(JwtSecretKey.fromString(secret).bytes),
      }),
    });
    final server = OAuth2ResourceServer(
      jwtDecoder: DartJwtDecoder.withJwkSet(
        jwks,
        validator: JwtValidator(
          expectedIssuer: OAuth2Config.IDP_ISSUER,
          expectedAudience: SecurityAudience.resourceApi,
        ),
      ),
    );
    final token = encoder.encode(
      JwtClaimsSet({
        'sub': 'alice',
        'aud': SecurityAudience.resourceApi,
        'exp': DateTime.now().toUtc().add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000,
      }),
      keyId: OAuth2Config.KEY_ID,
    );
    final result = await server.authenticateBearer(token);
    expect(result.name, 'alice');
    expect(SecurityContextHolder, isNotNull);
  });
}
