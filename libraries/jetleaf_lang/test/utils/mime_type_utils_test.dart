import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('MimeTypeUtils', () {
    group('checkToken', () {
      test('accepts valid tokens', () {
        expect(() => MimeTypeUtils.checkToken('text'), returnsNormally);
        expect(() => MimeTypeUtils.checkToken('plain'), returnsNormally);
        expect(() => MimeTypeUtils.checkToken('UTF-8'), returnsNormally);
        expect(() => MimeTypeUtils.checkToken('application'), returnsNormally);
      });

      test('rejects invalid token characters', () {
        expect(() => MimeTypeUtils.checkToken('text/plain'), throwsIllegalArgumentException);
        expect(() => MimeTypeUtils.checkToken('text '), throwsIllegalArgumentException);
        expect(() => MimeTypeUtils.checkToken('text;'), throwsIllegalArgumentException);
      });
    });

    group('isQuotedString', () {
      test('returns true for double-quoted strings', () {
        expect(MimeTypeUtils.isQuotedString('"hello"'), isTrue);
      });

      test('returns true for single-quoted strings', () {
        expect(MimeTypeUtils.isQuotedString("'hello'"), isTrue);
      });

      test('returns false for unquoted strings', () {
        expect(MimeTypeUtils.isQuotedString('hello'), isFalse);
      });

      test('returns false for strings shorter than 2', () {
        expect(MimeTypeUtils.isQuotedString(''), isFalse);
        expect(MimeTypeUtils.isQuotedString('"'), isFalse);
      });

      test('returns false for mismatched quotes', () {
        expect(MimeTypeUtils.isQuotedString('"hello\''), isFalse);
      });
    });

    group('unquote', () {
      test('removes double quotes', () {
        expect(MimeTypeUtils.unquote('"hello"'), equals('hello'));
      });

      test('removes single quotes', () {
        expect(MimeTypeUtils.unquote("'hello'"), equals('hello'));
      });

      test('returns unquoted string as-is', () {
        expect(MimeTypeUtils.unquote('hello'), equals('hello'));
      });
    });

    group('createParametersMap', () {
      test('returns empty map for null input', () {
        expect(MimeTypeUtils.createParametersMap(null), isEmpty);
      });

      test('returns empty map for empty input', () {
        expect(MimeTypeUtils.createParametersMap({}), isEmpty);
      });

      test('creates unmodifiable map', () {
        final map = MimeTypeUtils.createParametersMap({'charset': 'UTF-8'});
        expect(() => map['new'] = 'value', throwsUnsupportedError);
      });

      test('validates token characters in keys', () {
        expect(
          () => MimeTypeUtils.createParametersMap({'bad key': 'value'}),
          throwsIllegalArgumentException,
        );
      });
    });

    group('parseMimeType', () {
      test('parses simple type/subtype', () {
        final mt = MimeTypeUtils.parseMimeType('text/plain');
        expect(mt.type, equals('text'));
        expect(mt.subtype, equals('plain'));
        expect(mt.parameters, isEmpty);
      });

      test('normalizes to lowercase', () {
        final mt = MimeTypeUtils.parseMimeType('TEXT/PLAIN');
        expect(mt.type, equals('text'));
        expect(mt.subtype, equals('plain'));
      });

      test('parses with charset parameter', () {
        final mt = MimeTypeUtils.parseMimeType('text/plain; charset=UTF-8');
        expect(mt.type, equals('text'));
        expect(mt.subtype, equals('plain'));
        expect(mt.charset, equals('UTF-8'));
      });

      test('parses with multiple parameters', () {
        final mt = MimeTypeUtils.parseMimeType('text/plain; charset=UTF-8; level=1');
        expect(mt.getParameter('charset'), equals('UTF-8'));
        expect(mt.getParameter('level'), equals('1'));
      });

      test('parses wildcard type', () {
        final mt = MimeTypeUtils.parseMimeType('*/*');
        expect(mt.type, equals('*'));
        expect(mt.subtype, equals('*'));
      });

      test('parses subtype with suffix', () {
        final mt = MimeTypeUtils.parseMimeType('application/vnd.api+json');
        expect(mt.type, equals('application'));
        expect(mt.subtype, equals('vnd.api+json'));
        expect(mt.subtypeSuffix, equals('json'));
      });

      test('parses quoted parameter value', () {
        final mt = MimeTypeUtils.parseMimeType('text/plain; charset="UTF-8"');
        expect(mt.getParameter('charset'), equals('"UTF-8"'));
      });

      test('throws on empty string', () {
        expect(() => MimeTypeUtils.parseMimeType(''), throwsIllegalArgumentException);
      });

      test('throws on missing slash', () {
        expect(() => MimeTypeUtils.parseMimeType('textplain'), throwsIllegalArgumentException);
      });

      test('throws on empty type', () {
        expect(() => MimeTypeUtils.parseMimeType('/plain'), throwsIllegalArgumentException);
      });

      test('throws on empty subtype', () {
        expect(() => MimeTypeUtils.parseMimeType('text/'), throwsIllegalArgumentException);
      });

      test('parses application/json', () {
        final mt = MimeTypeUtils.parseMimeType('application/json');
        expect(mt.type, equals('application'));
        expect(mt.subtype, equals('json'));
      });

      test('parses image/png', () {
        final mt = MimeTypeUtils.parseMimeType('image/png');
        expect(mt.type, equals('image'));
        expect(mt.subtype, equals('png'));
      });
    });

    group('parseMimeTypes', () {
      test('parses comma-separated types', () {
        final types = MimeTypeUtils.parseMimeTypes('text/plain, text/html');
        expect(types.length, equals(2));
        expect(types[0].type, equals('text'));
        expect(types[0].subtype, equals('plain'));
        expect(types[1].type, equals('text'));
        expect(types[1].subtype, equals('html'));
      });

      test('returns empty list for empty string', () {
        expect(MimeTypeUtils.parseMimeTypes(''), isEmpty);
      });

      test('handles whitespace around commas', () {
        final types = MimeTypeUtils.parseMimeTypes('text/plain , text/html');
        expect(types.length, equals(2));
      });
    });

    group('supportsMimeType', () {
      test('returns true for matching type', () {
        expect(
          MimeTypeUtils.supportsMimeType('text/plain', ['text/plain']),
          isTrue,
        );
      });

      test('returns true for wildcard match', () {
        expect(
          MimeTypeUtils.supportsMimeType('text/plain', ['text/*']),
          isTrue,
        );
      });

      test('returns false for non-matching type', () {
        expect(
          MimeTypeUtils.supportsMimeType('text/plain', ['image/png']),
          isFalse,
        );
      });
    });

    group('caseInsensitiveCompare', () {
      test('compares case-insensitively first', () {
        expect(MimeTypeUtils.caseInsensitiveCompare('a', 'B'), lessThan(0));
        expect(MimeTypeUtils.caseInsensitiveCompare('B', 'a'), greaterThan(0));
      });

      test('uses case-sensitive as tiebreaker', () {
        expect(MimeTypeUtils.caseInsensitiveCompare('a', 'A'), greaterThan(0));
        expect(MimeTypeUtils.caseInsensitiveCompare('A', 'a'), lessThan(0));
      });
    });
  });
}
