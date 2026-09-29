import 'package:test/test.dart';
import 'package:jetleaf_web/src/http/etag.dart';

void main() {
  group('ETag - Creation', () {
    test('creates strong ETag', () {
      final etag = ETag('abc123', false);
      expect(etag.tag, 'abc123');
      expect(etag.weak, isFalse);
    });

    test('creates weak ETag', () {
      final etag = ETag('xyz', true);
      expect(etag.tag, 'xyz');
      expect(etag.weak, isTrue);
    });
  });

  group('ETag - getFormattedTag()', () {
    test('formats strong ETag', () {
      expect(ETag('abc', false).getFormattedTag(), '"abc"');
    });

    test('formats weak ETag', () {
      expect(ETag('abc', true).getFormattedTag(), 'W/"abc"');
    });

    test('wildcard returns *', () {
      expect(ETag.wildcard.getFormattedTag(), '*');
    });
  });

  group('ETag - isWildcard()', () {
    test('wildcard is wildcard', () {
      expect(ETag.wildcard.isWildcard(), isTrue);
    });

    test('regular ETag is not wildcard', () {
      expect(ETag('abc', false).isWildcard(), isFalse);
    });
  });

  group('ETag - compare()', () {
    test('strong comparison matches strong ETags', () {
      expect(ETag('abc', false).compare(ETag('abc', false), true), isTrue);
    });

    test('strong comparison fails for weak ETags', () {
      expect(ETag('abc', true).compare(ETag('abc', false), true), isFalse);
    });

    test('weak comparison matches regardless of weak flag', () {
      expect(ETag('abc', false).compare(ETag('abc', true), false), isTrue);
    });

    test('different tags do not match', () {
      expect(ETag('abc', false).compare(ETag('xyz', false), false), isFalse);
    });

    test('empty tags do not match', () {
      expect(ETag('', false).compare(ETag('', false), false), isFalse);
    });
  });

  group('ETag - create()', () {
    test('parses strong quoted ETag', () {
      final etag = ETag.create('"abc123"');
      expect(etag.tag, 'abc123');
      expect(etag.weak, isFalse);
    });

    test('parses weak ETag', () {
      final etag = ETag.create('W/"xyz"');
      expect(etag.tag, 'xyz');
      expect(etag.weak, isTrue);
    });
  });

  group('ETag - parse()', () {
    test('parses single strong ETag', () {
      final etags = ETag.parse('"abc123"');
      expect(etags.length, 1);
      expect(etags[0].tag, 'abc123');
    });

    test('parses wildcard', () {
      final etags = ETag.parse('*');
      expect(etags.length, 1);
      expect(etags[0].isWildcard(), isTrue);
    });

    test('parses multiple ETags', () {
      final etags = ETag.parse('"abc", "xyz"');
      expect(etags.length, 2);
    });

    test('parses weak and strong ETags', () {
      final etags = ETag.parse('"strong", W/"weak"');
      expect(etags.length, 2);
      expect(etags[0].weak, isFalse);
      expect(etags[1].weak, isTrue);
    });
  });

  group('ETag - quoteETagIfNecessary()', () {
    test('quotes unquoted tag', () {
      expect(ETag.quoteETagIfNecessary('abc'), '"abc"');
    });

    test('does not double-quote already quoted tag', () {
      expect(ETag.quoteETagIfNecessary('"abc"'), '"abc"');
    });

    test('does not double-quote weak tag', () {
      expect(ETag.quoteETagIfNecessary('W/"abc"'), 'W/"abc"');
    });
  });

  group('ETag - Equality', () {
    test('same tag and weak are equal', () {
      expect(ETag('abc', false), equals(ETag('abc', false)));
    });

    test('different weak flag makes not equal', () {
      expect(ETag('abc', false), isNot(equals(ETag('abc', true))));
    });
  });

  group('ETag - toString()', () {
    test('delegates to getFormattedTag', () {
      expect(ETag('abc', false).toString(), '"abc"');
    });
  });
}