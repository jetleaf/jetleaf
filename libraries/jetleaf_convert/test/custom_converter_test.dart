import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import '_test_models.dart';

@JetleafTest()
void main() async {
  final service = DefaultConversionService();

  group('ConverterRegistry and Custom Converters', () {
    test('addConverter should register a custom Converter', () {
      service.addConverter(CustomConverter());
      expect(service.canConvert(Class<String>(), Class<int>()), isTrue);
    });

    test('addConverterWithClass should register a custom Converter with specific types', () {
      service.addConverter(sourceType: Class<String>(), targetType: Class<int>(), CustomConverter());
      expect(service.canConvert(Class<String>(), Class<int>()), isTrue);
    });

    test('addGenericConverter should register a custom GenericConverter', () {
      service.addPairedConverter(CustomGenericConverter());
      expect(service.canConvert(Class<String>(), Class<bool>()), isTrue);
    });

    test('addConverterFactory should register a custom ConverterFactory', () {
      service.addConverterFactory(CustomConverterFactory());
      expect(service.canConvert(Class<String>(), Class<int>()), isTrue);
      expect(service.canConvert(Class<String>(), Class<double>()), isTrue);
    });

    test('removeConvertible should remove a registered converter', () {
      service.addConverter(sourceType: Class<String>(), targetType: Class<int>(), CustomConverter());
      service.remove(Class<String>(), Class<int>());
      expect(service.canConvert(Class<String>(), Class<int>()), isTrue); // default still available
    });

    test('convertTo should throw ConversionException for unconvertible types', () {
      expect(
        () => service.convertTo(MyClass('test', 1), Class<MyClass>(), Class<DateTime>()),
        throwsA(isA<ConversionException>()),
      );
    });
  });

  group('Fallback Converters', () {
    test('Object to String (using toString())', () {
      final source = MyClass('Bob', 25);
      expect(service.convert<String>(source, Class<String>()), 'MyClass(name: Bob, age: 25)');
    });

    test('String to int via default converter', () {
      expect(service.convert<int>('42', Class<int>()), 42);
    });

    test('int to String via default converter', () {
      expect(service.convert<String>(42, Class<String>()), '42');
    });

    test('double to String via default converter', () {
      expect(service.convert<String>(3.14, Class<String>()), '3.14');
    });

    test('bool to String via default converter', () {
      expect(service.convert<String>(true, Class<String>()), 'true');
    });
  });
}
