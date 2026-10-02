import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

@JetleafTest()
void main() {
  final service = DefaultConversionService();

  group('Numeric Converters', () {
    test('num to int', () {
      expect(service.convert<int>(10.5, Class<int>()), 10);
      expect(service.convert<int>(10.4, Class<int>()), 10);
      expect(service.convert<int>(10, Class<int>()), 10);
      expect(service.convert<int>(-10.5, Class<int>()), -10);
    });

    test('num to double', () {
      expect(service.convert<double>(10, Class<double>()), 10.0);
      expect(service.convert<double>(10.5, Class<double>()), 10.5);
    });

    test('int to double', () {
      expect(service.convert<double>(42, Class<double>()), 42.0);
    });

    test('double to int', () {
      expect(service.convert<int>(42.7, Class<int>()), 42);
      expect(service.convert<int>(42.3, Class<int>()), 42);
    });
  });
}