import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

/// Red-phase tests for defects 2, 3, 4 and 5 in the rewrite specification.
/// These compile against the current API and MUST fail until Phase 5.
void main() {
  const secret = 'adversarial-test-secret-key-at-least-32-bytes!';

  group('JWT defects (red phase)', () {
    test('configured audience is emitted on issued access tokens', () async {
      final provider = JwtTokenProvider.hmac(
        secret: secret,
        audience: 'jetleaf-api',
      );

      final token = provider.generateAccessToken(subject: 'alice');
      final claims = await provider.verifyToken(token);

      expect(claims.audience, contains('jetleaf-api'));
    });

    test('a refresh token cannot be used as an authentication credential',
        () async {
      final provider = JwtTokenProvider.hmac(secret: secret);
      final refreshToken = provider.generateRefreshToken(subject: 'alice');

      expect(
        () => provider.authenticate(
          JwtAuthenticationToken.unauthenticated(refreshToken),
        ),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('a token with a future iat is rejected', () {
      final validator = JwtValidator();
      final futureIat =
          DateTime.now().toUtc().add(const Duration(hours: 1));
      final claims = JwtClaimsSet({
        'sub': 'alice',
        'iat': futureIat.millisecondsSinceEpoch ~/ 1000,
      });

      expect(
        () => validator.validate(claims),
        throwsA(isA<JwtValidationException>()),
      );
    });

    test('a token without exp is rejected when expiration is required', () {
      // Spec 022 makes this configurable. Until then, encode the expectation
      // as a direct validator contract so the gap is visible.
      final claims = JwtClaimsSet({'sub': 'alice'});
      final validator = JwtValidator();

      expect(
        () => validator.validate(claims),
        throwsA(isA<JwtValidationException>()),
        reason: 'A token that never expires must not be accepted by default',
      );
    });
  });
}