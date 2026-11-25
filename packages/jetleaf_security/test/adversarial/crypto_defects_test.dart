import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

/// Red-phase tests for defect 17 in the rewrite specification.
void main() {
  group('Crypto hardening defects (red phase)', () {
    test('bcrypt rejects a strength that makes derivation infeasible', () {
      expect(
        () => BCryptPasswordEncoder(strength: 31),
        throwsA(isA<IllegalArgumentException>()),
        reason: 'strength 31 means 1 << 31 rounds, an effective denial of service',
      );
    });
  });
}