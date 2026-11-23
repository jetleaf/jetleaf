import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

/// Cross-checks the package's PBKDF2 implementation against an independent
/// derivation built from `package:crypto`'s HMAC-SHA256.
Uint8List _independentPbkdf2(
  String password,
  Uint8List salt, {
  required int iterations,
  required int length,
}) {
  final output = BytesBuilder(copy: false);
  var block = 1;
  while (output.length < length) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var u = hmac.convert([...salt, ..._int32BE(block)]).bytes;
    final t = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    output.add(t);
    block++;
  }
  return output.takeBytes().sublist(0, length);
}

List<int> _int32BE(int value) => [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];

void main() {
  group('PBKDF2 cross-check', () {
    test('matches an independent HMAC-SHA256 derivation', () {
      final encoder = Pbkdf2PasswordEncoder(
        iterations: 1000,
        hashLength: 32,
        saltLength: 16,
      );
      const password = 'password';

      final encoded = encoder.encode(password);
      final parts = encoded.split(r'$');
      final iterations = int.parse(parts[2]);
      final salt = base64.decode(parts[3].padRight(
          parts[3].length + (4 - parts[3].length % 4) % 4, '='));
      final expected = _independentPbkdf2(
        password,
        salt,
        iterations: iterations,
        length: 32,
      );

      expect(encoder.matches(password, encoded), isTrue);
      expect(
        base64.decode(parts[4].padRight(
            parts[4].length + (4 - parts[4].length % 4) % 4, '=')),
        equals(expected),
      );
    });
  });
}
