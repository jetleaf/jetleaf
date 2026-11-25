import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

void main() {
  group('BCryptPasswordEncoder', () {
    test('encodes and verifies passwords with \$2b\$ prefix', () {
      final encoder = BCryptPasswordEncoder(strength: 6);
      final hash = encoder.encode('correct-horse-battery-staple');

      expect(hash, startsWith(r'$2b$06$'));
      expect(hash.length, equals(60));
      expect(encoder.matches('correct-horse-battery-staple', hash), isTrue);
      expect(encoder.matches('incorrect-horse', hash), isFalse);
    });

    test('verifies known standard BCrypt test vector', () {
      final encoder = BCryptPasswordEncoder();
      const vector = r'$2y$06$cT521dKwtyTtyWgkzH5AtOAWk74yCWN/1NBOWFFOfLNue92b4fQi6';
      expect(encoder.matches('a', vector), isTrue);
      expect(encoder.matches('b', vector), isFalse);
    });

    test('detects lower cost factor via upgradeEncoding', () {
      final low = BCryptPasswordEncoder(strength: 5);
      final high = BCryptPasswordEncoder(strength: 10);

      final hash = low.encode('secret');
      expect(high.upgradeEncoding(hash), isTrue);
      expect(low.upgradeEncoding(hash), isFalse);
    });
  });
}