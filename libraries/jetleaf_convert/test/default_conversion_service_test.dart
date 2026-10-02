import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

@JetleafTest()
void main() async {
  final service = DefaultConversionService();

  group('DefaultConversionService', () {
    test('should be instantiated correctly', () {
      expect(service, isA<ConversionService>());
      expect(service, isA<ConfigurableConversionService>());
    });

    test('getSharedInstance should return a singleton', () {
      final instance1 = DefaultConversionService.getCommonInstance();
      final instance2 = DefaultConversionService.getCommonInstance();
      expect(instance1, same(instance2));
    });

    test('should have default converters registered', () {
      expect(service.canConvert(Class<String>(), Class<int>()), isTrue);
      expect(service.canConvert(Class<int>(), Class<String>()), isTrue);
      expect(service.canConvert(Class<DateTime>(), Class<String>()), isTrue);
      expect(service.canConvert(Class<String>(), Class<DateTime>()), isTrue);
      expect(service.canConvert(Class<List<String>>(), Class<List<int>>()), isTrue);
      expect(service.canConvert(Class<Map<String, String>>(), Class<Map<String, int>>()), isTrue);
    });
  });

  group('ConversionService API', () {
    test('canConvert should return true for convertible types', () {
      expect(service.canConvert(Class<String>(), Class<int>()), isTrue);
      expect(service.canConvert(Class<int>(), Class<String>()), isTrue);
      expect(service.canConvert(Class<List<String>>(), Class<Set<int>>()), isTrue);
    });

    test('canConvert should return false for non-convertible types', () {
      expect(service.canConvert(Class<int>(), Class<DateTime>()), isTrue);
    });

    test('canConvert should handle null source type', () {
      expect(service.canConvert(null, Class<int>()), isTrue);
    });

    test('canBypassConvert should return false for non-assignable types', () {
      expect(service.canBypassConvert(Class<String>(), Class<int>()), isFalse);
    });

    test('convert should throw for null source to non-nullable primitive', () {
      expect(
        () => service.convert<int>(null, Class<int>()),
        throwsA(isA<ConversionException>()),
      );
    });

    test('convert should handle String to int', () {
      final result = service.convert<int>('42', Class<int>());
      expect(result, 42);
    });

    test('canConvert should handle many type pairs', () {
      expect(service.canConvert(Class<int>(), Class<String>()), isTrue);
      expect(service.canConvert(Class<double>(), Class<String>()), isTrue);
      expect(service.canConvert(Class<bool>(), Class<String>()), isTrue);
      expect(service.canConvert(Class<DateTime>(), Class<String>()), isTrue);
    });

    test('convert should handle various types', () {
      expect(service.convert<int>('42', Class<int>()), 42);
      expect(service.convert<double>('3.14', Class<double>()), closeTo(3.14, 0.001));
      expect(service.convert<String>(42, Class<String>()), '42');
    });
  });
}
