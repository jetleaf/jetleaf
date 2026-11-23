import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

/// Known-answer vectors from the Argon2 reference implementation, as published
/// in RFC 9106 / draft-irtf-cfrg-argon2 section 5 and reproduced by
/// RustCrypto's `argon2` KAT suite.
void main() {
  group('Argon2id published vectors', () {
    test('m=256,t=2,p=1 reference vector', () {
      final encoder = Argon2idPasswordEncoder(
        memoryKiB: 256,
        iterations: 2,
        parallelism: 1,
      );
      const phc =
          r'$argon2id$v=19$m=256,t=2,p=1$c29tZXNhbHQ$nf65EOgLrQMR/uIPnA4rEsF5h7TKyQwu9U1bMCHGi/4';

      expect(encoder.matches('password', phc), isTrue);
      expect(encoder.matches('wrong-password', phc), isFalse);
    });

    test('m=256,t=2,p=2 reference vector', () {
      final encoder = Argon2idPasswordEncoder(
        memoryKiB: 256,
        iterations: 2,
        parallelism: 2,
      );
      const phc =
          r'$argon2id$v=19$m=256,t=2,p=2$c29tZXNhbHQ$bQk8UB/VmZZF4Oo79iDXuL5/0ttZwg2f/5U52iv1cDc';

      expect(encoder.matches('password', phc), isTrue);
    });

    test('m=65536,t=2,p=1 reference vector', () {
      final encoder = Argon2idPasswordEncoder(
        memoryKiB: 65536,
        iterations: 2,
        parallelism: 1,
      );
      const phc =
          r'$argon2id$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$CTFhFdXPJO1aFaMaO6Mm5c8y7cJHAph8ArZWb2GRPPc';

      expect(encoder.matches('password', phc), isTrue);
    });
  });
}
