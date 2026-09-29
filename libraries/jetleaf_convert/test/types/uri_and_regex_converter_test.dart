import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

@JetleafTest()
void main() {
  final service = DefaultConversionService();

  group('URI Converters', () {
    test('String to Uri', () {
      final uriString = 'https://example.com/path?query=1';
      final result = service.convert<Uri>(uriString, Class<Uri>());
      expect(result?.scheme, 'https');
      expect(result?.host, 'example.com');
      expect(result?.path, '/path');
    });

    test('Uri to String', () {
      final uri = Uri.parse('https://example.com');
      expect(service.convert<String>(uri, Class<String>()), 
          'https://example.com');
    });
  });

  group('RegExp Converters', () {
    test('String to RegExp', () {
      final pattern = r'^\d+$';
      final result = service.convert<RegExp>(pattern, Class<RegExp>());
      expect(result?.pattern, pattern);
      expect(() => service.convert<RegExp>('[', Class<RegExp>()), 
          throwsA(isA<ConversionFailedException>()));
    });

    test('RegExp to String', () {
      final regex = RegExp(r'abc');
      expect(service.convert<String>(regex, Class<String>()), 'abc');
    });
  });
}