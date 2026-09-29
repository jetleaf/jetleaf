import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import '../_test_models.dart';

@JetleafTest()
void main() async {
  final service = DefaultConversionService();

  group('Enum Converters', () {
    test('Enum to String', () {
      expect(service.convert<String>(TestEnum.value1, Class<String>()), 'value1');
      expect(service.convert<String>(TestEnum.value2, Class<String>()), 'value2');
    });

    test('Enum to int', () {
      expect(service.convert<int>(TestEnum.value1, Class<int>()), 0);
      expect(service.convert<int>(TestEnum.value2, Class<int>()), 1);
    });

    test('String to Enum (unsupported by current Class API)', () {
      expect(service.convert<TestEnum>('value1', Class<TestEnum>()), TestEnum.value1);
      expect(service.convert<TestEnum>('value2', Class<TestEnum>()), TestEnum.value2);
    });

    test('int to Enum (unsupported by current Class API)', () {
      expect(service.convert<TestEnum>(0, Class<TestEnum>()), TestEnum.value1);
      expect(service.convert<TestEnum>(1, Class<TestEnum>()), TestEnum.value2);
    });
  });
}