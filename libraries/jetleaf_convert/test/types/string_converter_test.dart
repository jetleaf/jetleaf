import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

@JetleafTest()
void main() {
  final service = DefaultConversionService();

  group('String Converters', () {
    group('String to Primitives', () {
      test('String to int', () {
        expect(service.convert<int>('123', Class<int>()), 123);
        expect(service.convert<int>('-456', Class<int>()), -456);
        expect(service.convert<int>('0', Class<int>()), 0);
        expect(() => service.convert<int>('abc', Class<int>()), 
            throwsA(isA<ConversionFailedException>()));
        expect(() => service.convert<int>('12.34', Class<int>()), 
            throwsA(isA<ConversionFailedException>()));
      });

      test('String to double', () {
        expect(service.convert<double>('123.45', Class<double>()), 123.45);
        expect(service.convert<double>('-67.89', Class<double>()), -67.89);
        expect(service.convert<double>('0.0', Class<double>()), 0.0);
        expect(service.convert<double>('123', Class<double>()), 123.0);
        expect(() => service.convert<double>('abc', Class<double>()), 
            throwsA(isA<ConversionFailedException>()));
      });

      test('String to bool', () {
        expect(service.convert<bool>('true', Class<bool>()), isTrue);
        expect(service.convert<bool>('TRUE', Class<bool>()), isTrue);
        expect(service.convert<bool>('false', Class<bool>()), isFalse);
        expect(service.convert<bool>('FALSE', Class<bool>()), isFalse);
        expect(service.convert<bool>('1', Class<bool>()), isTrue);
        expect(service.convert<bool>('0', Class<bool>()), isFalse);
        expect(() => service.convert<bool>('maybe', Class<bool>()), 
            throwsA(isA<ConversionFailedException>()));
      });

      test('String to num', () {
        expect(service.convert<num>('123', Class<num>()), 123);
        expect(service.convert<num>('123.45', Class<num>()), 123.45);
        expect(service.convert<num>('-67', Class<num>()), -67);
      });
    });

    group('Primitives to String', () {
      test('int to String', () {
        expect(service.convert<String>(123, Class<String>()), '123');
        expect(service.convert<String>(-456, Class<String>()), '-456');
        expect(service.convert<String>(0, Class<String>()), '0');
      });

      test('double to String', () {
        expect(service.convert<String>(123.45, Class<String>()), '123.45');
        expect(service.convert<String>(-67.89, Class<String>()), '-67.89');
        expect(service.convert<String>(0.0, Class<String>()), '0.0');
      });

      test('bool to String', () {
        expect(service.convert<String>(true, Class<String>()), 'true');
        expect(service.convert<String>(false, Class<String>()), 'false');
      });
    });
  });
}