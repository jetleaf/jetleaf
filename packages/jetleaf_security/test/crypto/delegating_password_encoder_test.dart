import 'package:jetleaf_core/utils.dart' show ParserException;
import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import 'package:jetleaf_security/jetleaf_security.dart';
import 'package:test/test.dart';

class _StubEncoder implements PasswordEncoder {
  @override
  String encode(String rawPassword) => 'hash($rawPassword)';

  @override
  bool matches(String rawPassword, String encodedPassword) =>
      encodedPassword == 'hash($rawPassword)';

  @override
  bool upgradeEncoding(String encodedPassword) => false;

  @override
  Future<String> encodeAsync(String rawPassword) async => encode(rawPassword);

  @override
  Future<bool> matchesAsync(String rawPassword, String encodedPassword) async =>
      matches(rawPassword, encodedPassword);
}

void main() {
  group('DelegatingPasswordEncoder', () {
    final encoder = DelegatingPasswordEncoder('stub', {'stub': _StubEncoder()});

    test('prefixes newly encoded hashes with the default id', () {
      expect(encoder.encode('secret'), '{stub}hash(secret)');
    });

    test('verifies a prefixed hash with the selected encoder', () {
      expect(encoder.matches('secret', '{stub}hash(secret)'), isTrue);
      expect(encoder.matches('wrong', '{stub}hash(secret)'), isFalse);
    });

    test('rejects an unknown id with a clear error', () {
      expect(
        () => encoder.matches('secret', '{unknown}hash(secret)'),
        throwsA(isA<IllegalArgumentException>()),
      );
    });

    test('unprefixed hashes use the default encoder when allowed', () {
      expect(encoder.matches('secret', 'hash(secret)'), isTrue);
      final strict = DelegatingPasswordEncoder(
        'stub',
        {'stub': _StubEncoder()},
        allowUnprefixedHashes: false,
      );
      expect(() => strict.matches('secret', 'hash(secret)'), throwsA(isA<ParserException>()));
    });

    test('requires the default id to be registered', () {
      expect(
        () => DelegatingPasswordEncoder('missing', {'stub': _StubEncoder()}),
        throwsA(isA<IllegalArgumentException>()),
      );
    });

    test('factory registers the three built-in encoders', () {
      final delegating = PasswordEncoderFactories.createDelegatingPasswordEncoder();
      expect(
        delegating.encode('secret'),
        startsWith('{argon2id}\$argon2id\$'),
      );
      expect(delegating.encoders.keys, containsAll(['argon2id', 'bcrypt', 'pbkdf2']));
    });
  });
}
