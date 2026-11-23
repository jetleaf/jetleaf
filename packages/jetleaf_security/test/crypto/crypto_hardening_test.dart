import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

void main() {
  group('Crypto hardening', () {
    test('hostile Argon2 memory parameters are rejected without derivation', () {
      final encoder = Argon2idPasswordEncoder();
      const hostile =
          r'$argon2id$v=19$m=999999999,t=3,p=1$c29tZXNhbHQ$nf65EOgLrQMR/uIPnA4rEsF5h7TKyQwu9U1bMCHGi/4';

      expect(encoder.matches('password', hostile), isFalse);
    });

    test('Argon2 configuration cannot exceed its own bounds', () {
      expect(
        () => Argon2idPasswordEncoder(
          memoryKiB: 65536,
          maxMemoryKiB: 1024,
        ),
        throwsA(isA<IllegalArgumentException>()),
      );
    });

    test('hostile PBKDF2 iteration counts are rejected', () {
      final encoder = Pbkdf2PasswordEncoder(
        iterations: 1000,
        maxIterations: 1000,
      );
      const hostile = r'$pbkdf2-sha256$999999999$c29tZXNhbHQ$YWJj';

      expect(encoder.matches('password', hostile), isFalse);
    });

    test('async hashing agrees with synchronous hashing', () async {
      final encoder = Argon2idPasswordEncoder(
        memoryKiB: 256,
        iterations: 2,
        parallelism: 1,
      );

      final asyncHash = await encoder.encodeAsync('password');
      expect(await encoder.matchesAsync('password', asyncHash), isTrue);
      expect(await encoder.matchesAsync('wrong', asyncHash), isFalse);
      expect(encoder.matches('password', asyncHash), isTrue);
    });

    test('async bcrypt agrees with synchronous bcrypt', () async {
      final encoder = BCryptPasswordEncoder(strength: 4);
      final hash = await encoder.encodeAsync('secret');

      expect(await encoder.matchesAsync('secret', hash), isTrue);
      expect(encoder.matches('secret', hash), isTrue);
    });
  });
}
