import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

void main() {
  group('Argon2idPasswordEncoder', () {
    test('encodes in PHC format and verifies matching passwords', () {
      // Reduced memory cost for fast unit testing while exercising full Argon2id.
      final encoder = Argon2idPasswordEncoder(
        memoryKiB: 1024,
        iterations: 2,
        parallelism: 1,
      );

      final hash = encoder.encode('S3cureP@ssword!');
      expect(hash, startsWith(r'$argon2id$v=19$m=1024,t=2,p=1$'));
      expect(encoder.matches('S3cureP@ssword!', hash), isTrue);
      expect(encoder.matches('WrongPassword', hash), isFalse);
    });

    test('produces distinct hashes for identical passwords due to random salt', () {
      final encoder = Argon2idPasswordEncoder(
        memoryKiB: 512,
        iterations: 1,
        parallelism: 1,
      );

      final hash1 = encoder.encode('password123');
      final hash2 = encoder.encode('password123');
      expect(hash1, isNot(equals(hash2)));
      expect(encoder.matches('password123', hash1), isTrue);
      expect(encoder.matches('password123', hash2), isTrue);
    });

    test('flags hashes with weaker parameters for upgradeEncoding', () {
      final weak = Argon2idPasswordEncoder(memoryKiB: 512, iterations: 1);
      final strong = Argon2idPasswordEncoder(memoryKiB: 2048, iterations: 2);

      final weakHash = weak.encode('secret');
      expect(strong.upgradeEncoding(weakHash), isTrue);
      expect(weak.upgradeEncoding(weakHash), isFalse);
    });
  });
}
