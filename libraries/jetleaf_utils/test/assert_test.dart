import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/jetleaf_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Assert', () {
    group('state', () {
      test('does not throw when true', () {
        expect(() => Assert.state(true, 'message'), returnsNormally);
      });

      test('throws NoGuaranteeException when false', () {
        expect(
          () => Assert.state(false, 'Invalid state'),
          throwsA(isA<NoGuaranteeException>().having((e) => e.message, 'message', 'Invalid state')),
        );
      });
    });

    group('isTrue', () {
      test('does not throw when true', () {
        expect(() => Assert.isTrue(true, 'message'), returnsNormally);
      });

      test('throws InvalidArgumentException when false', () {
        expect(
          () => Assert.isTrue(false, 'Must be true'),
          throwsA(isA<InvalidArgumentException>().having((e) => e.message, 'message', 'Must be true')),
        );
      });
    });

    group('hasLength', () {
      test('does not throw for non-empty string', () {
        expect(() => Assert.hasLength('hello', 'message'), returnsNormally);
      });

      test('throws for empty string', () {
        expect(
          () => Assert.hasLength('', 'Cannot be empty'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test('throws for null', () {
        expect(
          () => Assert.hasLength(null, 'Cannot be null'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });
    });

    group('hasText', () {
      test('does not throw for text with content', () {
        expect(() => Assert.hasText('hello', 'message'), returnsNormally);
      });

      test('throws for empty string', () {
        expect(
          () => Assert.hasText('', 'Cannot be blank'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test('throws for whitespace-only string', () {
        expect(
          () => Assert.hasText('   ', 'Cannot be blank'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test('throws for null', () {
        expect(
          () => Assert.hasText(null, 'Cannot be null'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });
    });

    group('doesNotContain', () {
      test('does not throw when substring not found', () {
        expect(() => Assert.doesNotContain('hello', 'xyz', 'message'), returnsNormally);
      });

      test('throws when substring found', () {
        expect(
          () => Assert.doesNotContain('hello world', 'world', 'Cannot contain space'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test('does not throw for null text', () {
        expect(() => Assert.doesNotContain(null, 'xyz', 'message'), returnsNormally);
      });
    });

    group('notEmpty', () {
      test('does not throw for non-empty list', () {
        expect(() => Assert.notEmpty([1, 2, 3], 'message'), returnsNormally);
      });

      test('throws for empty list', () {
        expect(
          () => Assert.notEmpty([], 'Cannot be empty'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test('throws for null', () {
        expect(
          () => Assert.notEmpty(null, 'Cannot be null'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });
    });

    group('notEmptyMap', () {
      test('does not throw for non-empty map', () {
        expect(() => Assert.notEmptyMap({'a': 1}, 'message'), returnsNormally);
      });

      test('throws for empty map', () {
        expect(
          () => Assert.notEmptyMap({}, 'Cannot be empty'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test('throws for null', () {
        expect(
          () => Assert.notEmptyMap(null, 'Cannot be null'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });
    });

    group('isInstanceOf', () {
      test('does not throw for correct type', () {
        expect(() => Assert.isInstanceOf<String>('hello', 'message'), returnsNormally);
      });

      test('throws for wrong type', () {
        expect(
          () => Assert.isInstanceOf<String>(42, 'Expected a String'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });

      test('throws for null when type is not nullable', () {
        expect(
          () => Assert.isInstanceOf<String>(null, 'Expected a String'),
          throwsA(isA<InvalidArgumentException>()),
        );
      });
    });
  });
}
