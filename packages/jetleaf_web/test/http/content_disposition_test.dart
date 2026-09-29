import 'package:test/test.dart';
import 'package:jetleaf_web/src/http/content_disposition.dart';

void main() {
  group('ContentDisposition - Builder', () {
    test('attachment() builds attachment type', () {
      final cd = ContentDisposition.attachment().build();
      expect(cd.getIsAttachment(), isTrue);
      expect(cd.getDispositionType(), 'attachment');
    });

    test('formData() builds form-data type', () {
      final cd = ContentDisposition.formData().build();
      expect(cd.getIsFormData(), isTrue);
    });

    test('inline() builds inline type', () {
      final cd = ContentDisposition.inline().build();
      expect(cd.getIsInline(), isTrue);
    });

    test('builder with name and filename', () {
      final cd = ContentDisposition.builder('form-data')
          .name('file')
          .filename('example.txt')
          .build();
      expect(cd.getParamName(), 'file');
      expect(cd.getFileName(), 'example.txt');
    });

    test('empty content disposition', () {
      final cd = ContentDisposition.empty();
      expect(cd.getDispositionType(), '');
      expect(cd.getParamName(), isNull);
      expect(cd.getFileName(), isNull);
    });
  });

  group('ContentDisposition - parse()', () {
    test('parses form-data with name and filename', () {
      final cd = ContentDisposition.parse(
        'form-data; name="file"; filename="test.txt"',
      );
      expect(cd.getIsFormData(), isTrue);
      expect(cd.getParamName(), 'file');
      expect(cd.getFileName(), 'test.txt');
    });

    test('parses attachment with filename', () {
      final cd = ContentDisposition.parse(
        'attachment; filename="report.pdf"',
      );
      expect(cd.getIsAttachment(), isTrue);
      expect(cd.getFileName(), 'report.pdf');
    });

    test('parses inline disposition', () {
      final cd = ContentDisposition.parse('inline');
      expect(cd.getIsInline(), isTrue);
    });
  });

  group('ContentDisposition - toString()', () {
    test('formats with type, name, and filename', () {
      final cd = ContentDisposition.builder('form-data')
          .name('file')
          .filename('test.txt')
          .build();
      expect(cd.toString(), 'form-data; name="file"; filename="test.txt"');
    });

    test('escapes quotes in filename', () {
      final cd = ContentDisposition.builder('attachment')
          .filename('file"name.txt')
          .build();
      expect(cd.toString(), contains('file\\"name.txt'));
    });
  });

  group('ContentDisposition - Equality', () {
    test('same parameters are equal', () {
      final cd1 = ContentDisposition.builder('form-data').name('file').build();
      final cd2 = ContentDisposition.builder('form-data').name('file').build();
      expect(cd1, equals(cd2));
    });

    test('different parameters are not equal', () {
      final cd1 = ContentDisposition.builder('form-data').name('a').build();
      final cd2 = ContentDisposition.builder('form-data').name('b').build();
      expect(cd1, isNot(equals(cd2)));
    });
  });
}