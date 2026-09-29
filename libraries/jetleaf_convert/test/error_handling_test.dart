import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import '_test_models.dart';

@JetleafTest()
void main() {
  final service = DefaultConversionService();

  group('Null Handling', () {
    test('null source to primitive throws ConversionException', () {
      expect(
        () => service.convert<int>(null, Class<int>()),
        throwsA(isA<ConversionException>()),
      );
    });

    test('canConvert with null source type', () {
      expect(service.canConvert(null, Class<int>()), isTrue);
      expect(service.canConvert(null, Class<String>()), isTrue);
    });
  });

  group('Error Handling', () {
    test('invalid String to DateTime should throw', () {
      expect(
        () => service.convert<DateTime>('invalid-date', Class<DateTime>()),
        throwsA(anyOf(
          isA<ConversionFailedException>(),
          isA<TypeError>(),
        )),
      );
    });

    test('unsupported conversions should throw ConversionException', () {
      expect(
        () => service.convertTo(MyClass('test', 1), Class<MyClass>(), Class<DateTime>()),
        throwsA(isA<ConversionException>()),
      );
    });
  });

  group('Performance and Edge Cases', () {
    test('large collection of strings to int', () {
      final largeList = List.generate(100, (i) => i.toString());
      final results = <int?>[];
      for (final s in largeList) {
        results.add(service.convert<int>(s, Class<int>()));
      }
      expect(results.length, 100);
      expect(results.first, 0);
      expect(results.last, 99);
    });

    test('empty string conversion', () {
      final result = service.convert<String>('', Class<String>());
      expect(result, '');
    });

    test('same type conversion returns value', () {
      final result = service.convert<int>(42, Class<int>());
      expect(result, 42);
    });
  });
}
