import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

void main() {
  group('JwtTokenProvider', () {
    const secret = 'super-secret-signing-key-at-least-32-bytes!';

    test('generates, verifies, and extracts roles from access tokens', () async {
      final provider = JwtTokenProvider.hmac(
        secret: secret,
        issuer: 'https://auth.jetleaf.dev',
        audience: 'jetleaf-api',
      );

      final token = provider.generateAccessToken(
        subject: 'user-42',
        roles: ['ROLE_USER', 'ROLE_ADMIN'],
        additionalClaims: {'aud': 'jetleaf-api', 'tenant': 'acme'},
      );

      final claims = await provider.verifyToken(token);
      expect(claims.subject, equals('user-42'));
      expect(claims.issuer, equals('https://auth.jetleaf.dev'));
      expect(claims.getClaim<String>('tenant'), equals('acme'));

      final auth = await provider.authenticate(
        JwtAuthenticationToken.unauthenticated(token),
      );
      expect(auth, isNotNull);
      expect(auth!.isAuthenticated, isTrue);
      expect(auth.name, equals('user-42'));
      expect(
        auth.authorities.map((a) => a.authority),
        containsAll(['ROLE_USER', 'ROLE_ADMIN']),
      );
    });

    test('rejects expired tokens', () async {
      final provider = JwtTokenProvider.hmac(
        secret: secret,
        clockSkew: Duration.zero,
      );

      final expiredToken = provider.generateAccessToken(
        subject: 'user-42',
        expiresIn: const Duration(seconds: -10),
      );

      expect(
        () => provider.verifyToken(expiredToken),
        throwsA(isA<JwtValidationException>()),
      );
    });

    test('rejects tokens signed with wrong secret', () async {
      final issuer = JwtTokenProvider.hmac(secret: secret);
      final verifier = JwtTokenProvider.hmac(secret: 'different-secret-key-32-bytes-long!');

      final token = issuer.generateAccessToken(subject: 'alice');
      expect(
        () => verifier.verifyToken(token),
        throwsA(isA<BadCredentialsException>()),
      );
    });
  });
}