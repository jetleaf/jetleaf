import 'package:test/test.dart';
import 'package:jetleaf_web/src/http/media_type.dart';

void main() {
  group('MediaType - Constants', () {
    test('APPLICATION_JSON has correct type and subtype', () {
      expect(MediaType.APPLICATION_JSON.getType(), 'application');
      expect(MediaType.APPLICATION_JSON.getSubtype(), 'json');
      expect(MediaType.APPLICATION_JSON.getMimeType(), 'application/json');
    });

    test('TEXT_PLAIN has correct type and subtype', () {
      expect(MediaType.TEXT_PLAIN.getType(), 'text');
      expect(MediaType.TEXT_PLAIN.getSubtype(), 'plain');
    });

    test('TEXT_HTML has correct type and subtype', () {
      expect(MediaType.TEXT_HTML.getType(), 'text');
      expect(MediaType.TEXT_HTML.getSubtype(), 'html');
    });

    test('ALL is wildcard type and subtype', () {
      expect(MediaType.ALL.isWildcardType(), isTrue);
      expect(MediaType.ALL.isWildcardSubtype(), isTrue);
    });

    test('MULTIPART_FORM_DATA has correct type', () {
      expect(MediaType.MULTIPART_FORM_DATA.getType(), 'multipart');
      expect(MediaType.MULTIPART_FORM_DATA.getSubtype(), 'form-data');
    });

    test('APPLICATION_OCTET_STREAM has correct values', () {
      expect(MediaType.APPLICATION_OCTET_STREAM.getMimeType(), 'application/octet-stream');
    });
  });

  group('MediaType - parse()', () {
    test('parses simple media type', () {
      final mt = MediaType.parse('application/json');
      expect(mt.getType(), 'application');
      expect(mt.getSubtype(), 'json');
      expect(mt.getParameters(), isEmpty);
    });

    test('parses media type with charset parameter', () {
      final mt = MediaType.parse('text/html; charset=utf-8');
      expect(mt.getType(), 'text');
      expect(mt.getSubtype(), 'html');
      expect(mt.getCharset(), 'utf-8');
    });

    test('parses media type with multiple parameters', () {
      final mt = MediaType.parse('multipart/form-data; boundary=----abc');
      expect(mt.getParameters()['boundary'], '----abc');
    });

    test('normalizes type and subtype to lowercase', () {
      final mt = MediaType.parse('Application/JSON');
      expect(mt.getType(), 'application');
      expect(mt.getSubtype(), 'json');
    });
  });

  group('MediaType - withCharset()', () {
    test('adds charset parameter', () {
      final mt = MediaType.TEXT_PLAIN.withCharset('utf-8');
      expect(mt.getCharset(), 'utf-8');
    });

    test('creates new instance', () {
      final original = MediaType.TEXT_PLAIN;
      final modified = original.withCharset('utf-8');
      expect(original.getCharset(), isNull);
      expect(modified.getCharset(), 'utf-8');
    });
  });

  group('MediaType - Compatibility', () {
    test('identical types are compatible', () {
      expect(MediaType.APPLICATION_JSON.isCompatibleWith(MediaType.APPLICATION_JSON), isTrue);
    });

    test('wildcard type matches anything', () {
      expect(MediaType.ALL.isCompatibleWith(MediaType.APPLICATION_JSON), isTrue);
    });

    test('different types are not compatible', () {
      expect(MediaType.APPLICATION_JSON.isCompatibleWith(MediaType.TEXT_PLAIN), isFalse);
    });
  });

  group('MediaType - Equality', () {
    test('same media types are equal', () {
      expect(MediaType.APPLICATION_JSON, equals(MediaType.APPLICATION_JSON));
    });

    test('different media types are not equal', () {
      expect(MediaType.APPLICATION_JSON, isNot(equals(MediaType.TEXT_PLAIN)));
    });

    test('parsed equal to constant', () {
      final parsed = MediaType.parse('application/json');
      expect(parsed, equals(MediaType.APPLICATION_JSON));
    });
  });

  group('MediaType - toString()', () {
    test('formats without parameters', () {
      expect(MediaType.APPLICATION_JSON.toString(), 'application/json');
    });

    test('formats with parameters', () {
      final mt = MediaType('text', 'html', {'charset': 'utf-8'});
      expect(mt.toString(), 'text/html; charset=utf-8');
    });
  });
}