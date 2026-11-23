import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

final class _StubClient extends http.BaseClient {
  int calls = 0;
  int statusCode = 200;
  String body = '{"keys":[]}';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
      request: request,
    );
  }
}

void main() {
  group('JWK hardening', () {
    test('oct keys cannot verify asymmetric algorithms', () {
      final jwk = Jwk.fromJson({'kty': 'oct', 'k': 'AQID'});
      expect(jwk.canVerify(JwsAlgorithms.hs256), isTrue);
      expect(jwk.canVerify(JwsAlgorithms.rs256), isFalse);
      expect(jwk.canVerify(JwsAlgorithms.es256), isFalse);
    });

    test('keys marked for encryption are rejected for signatures', () {
      final jwk = Jwk.fromJson({'kty': 'RSA', 'n': 'AQAB', 'e': 'AQAB', 'use': 'enc'});
      expect(jwk.canVerify(JwsAlgorithms.rs256), isFalse);
    });

    test('an alg-restricted key cannot verify another algorithm', () {
      final jwk = Jwk.fromJson({
        'kty': 'EC',
        'crv': 'P-256',
        'x': 'AQAB',
        'y': 'AQAB',
        'alg': 'ES384',
      });
      expect(jwk.canVerify(JwsAlgorithms.es256), isFalse);
    });

    test('a key with the wrong curve is rejected', () {
      final jwk = Jwk.fromJson({
        'kty': 'EC',
        'crv': 'P-384',
        'x': 'AQAB',
        'y': 'AQAB',
      });
      expect(jwk.canVerify(JwsAlgorithms.es256), isFalse);
      expect(jwk.canVerify(JwsAlgorithms.es384), isTrue);
    });

    test('remote JWKS failures fail closed', () async {
      final client = _StubClient()..statusCode = 500;
      final source = RemoteJwkSetSource(
        Uri.parse('https://example.com/.well-known/jwks.json'),
        httpClient: client,
      );

      await expectLater(
        source.resolveKey('unknown'),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('an unknown kid triggers at most one refresh per cooldown', () async {
      final client = _StubClient()
        ..body = jsonEncode({
          'keys': [
            {
              'kty': 'oct',
              'kid': 'known',
              'k': 'AyM1SysPpbyDfgZld3umj1qzKObwVMkoqQ-EstJQLr_T-1qS0gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr1Z9CAow',
            }
          ]
        });
      final source = RemoteJwkSetSource(
        Uri.parse('https://example.com/.well-known/jwks.json'),
        httpClient: client,
        unknownKidCooldown: const Duration(minutes: 5),
      );

      await source.resolveKey('known');
      await source.resolveKey('missing-1');
      await source.resolveKey('missing-2');

      expect(client.calls, 2);
    });
  });
}
