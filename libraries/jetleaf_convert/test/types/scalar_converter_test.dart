import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

@JetleafTest()
void main() async {
  final service = DefaultConversionService();

  group('Scalar Converters', () {
    test('String to int', () {
      expect(service.convert<int>('123', Class<int>()), 123);
      expect(() => service.convert<int>('abc', Class<int>()), throwsA(isA<ConversionFailedException>()));
    });

    test('int to String', () {
      expect(service.convert<String>(123, Class<String>()), '123');
    });

    test('String to double', () {
      expect(service.convert<double>('123.45', Class<double>()), 123.45);
      expect(() => service.convert<double>('abc', Class<double>()), throwsA(isA<ConversionFailedException>()));
    });

    test('double to String', () {
      expect(service.convert<String>(123.45, Class<String>()), '123.45');
    });

    test('String to bool', () {
      expect(service.convert<bool>('true', Class<bool>()), isTrue);
      expect(service.convert<bool>('FALSE', Class<bool>()), isFalse);
      expect(service.convert<bool>('1', Class<bool>()), isTrue);
      expect(service.convert<bool>('0', Class<bool>()), isFalse);
      expect(() => service.convert<bool>('maybe', Class<bool>()), throwsA(isA<ConversionFailedException>()));
    });

    test('bool to String', () {
      expect(service.convert<String>(true, Class<String>()), 'true');
      expect(service.convert<String>(false, Class<String>()), 'false');
    });

    test('DateTime to String', () {
      final now = DateTime.now();
      expect(service.convert<String>(now, Class<String>()), now.toIso8601String());
    });

    test('String to DateTime', () {
      final isoString = '2025-01-01T10:30:00.000Z';
      expect(service.convert<DateTime>(isoString, Class<DateTime>()), DateTime.parse(isoString));
      expect(() => service.convert<DateTime>('invalid-date', Class<DateTime>()), throwsA(isA<ConversionFailedException>()));
    });

    test('Duration to String', () {
      final duration = Duration(hours: 1, minutes: 30, seconds: 15);
      expect(service.convert<String>(duration, Class<String>()), "1:30:15");
    });

    test('String to Duration', () {
      expect(service.convert<Duration>('1:30:15', Class<Duration>()), Duration(hours: 1, minutes: 30, seconds: 15));
      expect(() => service.convert<Duration>('invalid', Class<Duration>()), throwsA(isA<ConversionFailedException>()));
    });

    test('String to Uri', () {
      final uriString = 'https://example.com/path?query=1';
      expect(service.convert<Uri>(uriString, Class<Uri>()), Uri.parse(uriString));
    });

    test('Uri to String', () {
      final uri = Uri.parse('https://example.com');
      expect(service.convert<String>(uri, Class<String>()), uri.toString());
    });

    test('String to RegExp', () {
      final pattern = r'^\d+$';
      expect(service.convert<RegExp>(pattern, Class<RegExp>())?.pattern, pattern);
      expect(() => service.convert<RegExp>('[', Class<RegExp>()), throwsA(isA<ConversionFailedException>()));
    });

    test('RegExp to String', () {
      final regex = RegExp(r'abc');
      expect(service.convert<String>(regex, Class<String>()), regex.pattern);
    });

    test('num to int', () {
      expect(service.convert<int>(10.5, Class<int>()), 10);
      expect(service.convert<int>(10, Class<int>()), 10);
    });

    test('num to double', () {
      expect(service.convert<double>(10, Class<double>()), 10.0);
      expect(service.convert<double>(10.5, Class<double>()), 10.5);
    });
  });
}