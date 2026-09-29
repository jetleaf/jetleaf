import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_convert/src/helpers/_commons.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import '_test_models.dart';

@JetleafTest()
void main() async {
  final service = DefaultConversionService();

  group('ConversionUtils', () {
    test(
      'invokeConverter should wrap other exceptions in ConversionFailedException',
      () {
        final converter = _ThrowingConverter();
        expect(
          () => ConversionUtils.invoke(
            converter,
            'data',
            Class<String>(),
            Class<int>(),
          ),
          throwsA(
            isA<ConversionFailedException>().having(
              (e) => e.point,
              'point',
              isA<StateError>(),
            ),
          ),
        );
      },
    );

    test('canConvertElements should return true for convertible elements', () {
      expect(
        ConversionUtils.canConvert(Class<String>(), Class<int>(), service),
        isTrue,
      );
      expect(
        ConversionUtils.canConvert(Class<int>(), Class<num>(), service),
        isTrue,
      );
      expect(
        ConversionUtils.canConvert(Class<int>(), Class<DateTime>(), service),
        isTrue,
      );
    });

    test(
      'canConvertElements should return false for non-convertible elements',
      () {
        expect(
          ConversionUtils.canConvert(
            Class<Symbol>(),
            Class<DateTime>(),
            service,
          ),
          isFalse,
        );
      },
    );

    test('canConvertElements should handle null targetElementType', () {
      expect(
        ConversionUtils.canConvert(Class<String>(), null, service),
        isTrue,
      );
    });

    test('canConvertElements should handle null sourceElementType', () {
      expect(
        ConversionUtils.canConvert(null, Class<String>(), service),
        isTrue,
      );
    });

    test('getEnumType should return enum Class for enum type', () {
      final enumClass = ConversionUtils.getEnumType(Class<TestEnum>());
      expect(enumClass.getType(), TestEnum);
      expect(enumClass.isEnum(), isTrue);
    });

    test('getEnumType should throw for non-enum type', () {
      expect(
        () => ConversionUtils.getEnumType(Class<String>()),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ConversionUtils.getEnumType(Class<MyClass>()),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

class _ThrowingConverter extends CommonPairedConverter {
  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(Class<String>(), Class<int>()),
  };

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    throw StateError('Simulated conversion error');
  }
}