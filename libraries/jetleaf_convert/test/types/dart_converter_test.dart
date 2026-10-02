import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_convert/src/helpers/_commons.dart';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../_test_models.dart';

class StreamConverter extends CommonConverter<List<int>, Stream<int>> {
  @override
  Stream<int> convert(List<int> source) {
    return Stream.fromIterable(source);
  }
}

class StreamIntToListIntConverter extends CommonConverter<Stream<int>, List<int>> {
  @override
  List<int> convert(Stream<int> source) {
    List<int> result = [];
    source.forEach((element) {
      result.add(element);
    });
    return result;
  }
}

@JetleafTest()
void main() {
  final service = DefaultConversionService();
  service.addConverter(StreamConverter(), sourceType: Class<List<int>>(), targetType: Class<Stream<int>>());
  service.addConverter(StreamIntToListIntConverter(), sourceType: Class<Stream<int>>(), targetType: Class<List<int>>());

  group('Number Generic Converter', () {
    test('num to int conversion', () {
      final result = service.convert<int>(3.7, Class<int>());
      expect(result, 3);
    });

    test('num to double conversion', () {
      final result = service.convert<double>(5, Class<double>());
      expect(result, 5.0);
    });

    test('num to String conversion', () {
      final result = service.convert<String>(42, Class<String>());
      expect(result, '42');
    });

    test('num to Integer conversion', () {
      final result = service.convert<Integer>(7, Class<Integer>());
      expect(result, Integer.valueOf(7));
    });

    test('num to Boolean conversion', () {
      final result = service.convert<Boolean>(1, Class<Boolean>());
      expect(result, Boolean.TRUE);
    });
  });

  group('Int Generic Converter', () {
    test('int to double conversion', () {
      final result = service.convert<double>(5, Class<double>());
      expect(result, 5.0);
    });

    test('int to String conversion', () {
      final result = service.convert<String>(42, Class<String>());
      expect(result, '42');
    });

    test('int to Long conversion', () {
      final result = service.convert<Long>(123, Class<Long>());
      expect(result, Long.valueOf(123));
    });

    test('int to Boolean conversion', () {
      final result = service.convert<Boolean>(0, Class<Boolean>());
      expect(result, Boolean.FALSE);
    });
  });

  group('Double Generic Converter', () {
    test('double to int conversion', () {
      final result = service.convert<int>(3.7, Class<int>());
      expect(result, 3);
    });

    test('double to String conversion', () {
      final result = service.convert<String>(3.14, Class<String>());
      expect(result, '3.14');
    });

    test('double to Float conversion', () {
      final result = service.convert<Float>(2.5, Class<Float>());
      expect(result, Float.valueOf(2.5));
    });
  });

  group('String Generic Converter', () {
    test('String to int conversion', () {
      final result = service.convert<int>('42', Class<int>());
      expect(result, 42);
    });

    test('String to double conversion', () {
      final result = service.convert<double>('3.14', Class<double>());
      expect(result, 3.14);
    });

    test('String to Integer conversion', () {
      final result = service.convert<Integer>('123', Class<Integer>());
      expect(result, Integer.valueOf(123));
    });

    test('String to Boolean conversion - true values', () {
      expect(service.convert<Boolean>('TRUE', Class<Boolean>()), Boolean.TRUE);
      expect(service.convert<Boolean>('1', Class<Boolean>()), Boolean.TRUE);
    });

    test('String to Boolean conversion - false values', () {
      expect(service.convert<Boolean>('FALSE', Class<Boolean>()), Boolean.FALSE);
      expect(service.convert<Boolean>('0', Class<Boolean>()), Boolean.FALSE);
    });

    test('String to Boolean conversion throws on invalid', () {
      expect(() => service.convert<Boolean>('invalid', Class<Boolean>()), 
          throwsA(isA<ConversionFailedException>()));
    });
  });

  group('Bool Generic Converter', () {
    test('bool to int conversion - true', () {
      final result = service.convert<int>(true, Class<int>());
      expect(result, 1);
    });

    test('bool to int conversion - false', () {
      final result = service.convert<int>(false, Class<int>());
      expect(result, 0);
    });

    test('bool to String conversion - true', () {
      final result = service.convert<String>(true, Class<String>());
      expect(result, 'true');
    });

    test('bool to String conversion - false', () {
      final result = service.convert<String>(false, Class<String>());
      expect(result, 'false');
    });

    test('bool to Integer conversion', () {
      final result = service.convert<Integer>(true, Class<Integer>());
      expect(result, Integer.valueOf(1));
    });
  });

  group('BigInt Generic Converter', () {
    test('BigInt to int conversion', () {
      final result = service.convert<int>(BigInt.from(42), Class<int>());
      expect(result, 42);
    });

    test('BigInt to String conversion', () {
      final result = service.convert<String>(BigInt.from(123), Class<String>());
      expect(result, '123');
    });

    test('BigInt to Integer conversion', () {
      final result = service.convert<Integer>(BigInt.from(999), Class<Integer>());
      expect(result, Integer.valueOf(999));
    });
  });

  group('Integer Generic Converter', () {
    test('Integer to int conversion', () {
      final result = service.convert<int>(Integer.valueOf(42), Class<int>());
      expect(result, 42);
    });

    test('Integer to String conversion', () {
      final result = service.convert<String>(Integer.valueOf(123), Class<String>());
      expect(result, '123');
    });

    test('Integer to double conversion', () {
      final result = service.convert<double>(Integer.valueOf(7), Class<double>());
      expect(result, 7.0);
    });
  });

  group('Long Generic Converter', () {
    test('Long to int conversion', () {
      final result = service.convert<int>(Long.valueOf(42), Class<int>());
      expect(result, 42);
    });

    test('Long to String conversion', () {
      final result = service.convert<String>(Long.valueOf(123), Class<String>());
      expect(result, '123');
    });
  });

  group('Float Generic Converter', () {
    test('Float to int conversion', () {
      final result = service.convert<int>(Float.valueOf(3.7), Class<int>());
      expect(result, 3);
    });

    test('Float to double conversion', () {
      final result = service.convert<double>(Float.valueOf(2.5), Class<double>());
      expect(result, 2.5);
    });
  });

  group('BigInteger Generic Converter', () {
    test('BigInteger to int conversion', () {
      final result = service.convert<int>(BigInteger.fromInt(42), Class<int>());
      expect(result, 42);
    });

    test('BigInteger to String conversion', () {
      final result = service.convert<String>(BigInteger.fromInt(123), Class<String>());
      expect(result, '123');
    });
  });

  group('BigDecimal Generic Converter', () {
    test('BigDecimal to int conversion', () {
      final result = service.convert<int>(BigDecimal.fromInt(42), Class<int>());
      expect(result, 42);
    });

    test('BigDecimal to double conversion', () {
      final result = service.convert<double>(BigDecimal.fromInt(314), Class<double>());
      expect(result, 314.0);
    });
  });

  group('Boolean Generic Converter', () {
    test('Boolean to bool conversion - true', () {
      final result = service.convert<bool>(Boolean.TRUE, Class<bool>());
      expect(result, true);
    });

    test('Boolean to bool conversion - false', () {
      final result = service.convert<bool>(Boolean.FALSE, Class<bool>());
      expect(result, false);
    });

    test('Boolean to int conversion - true', () {
      final result = service.convert<int>(Boolean.TRUE, Class<int>());
      expect(result, 1);
    });

    test('Boolean to String conversion - true', () {
      final result = service.convert<String>(Boolean.TRUE, Class<String>());
      expect(result, 'true');
    });
  });

  group('Character Generic Converter', () {
    test('Character to String conversion', () {
      final result = service.convert<String>(Character.valueOf('A'), Class<String>());
      expect(result, 'A');
    });

    test('Character to int conversion', () {
      final result = service.convert<int>(Character.valueOf('A'), Class<int>());
      expect(result, 65); // ASCII code for 'A'
    });
  });

  group('Runes Converters', () {
    test('String to Runes conversion', () {
      final result = service.convert<Runes>('hello', Class<Runes>());
      expect(result, Runes('hello'));
    });

    test('Runes to String conversion', () {
      final result = service.convert<String>(Runes('hello'), Class<String>());
      expect(result, 'hello');
    });
  });

  group('Symbol Converters', () {
    test('String to Symbol conversion', () {
      final result = service.convert<Symbol>('test', Class<Symbol>());
      expect(result.toString(), contains('test'));
    });

    test('Symbol to String conversion', () {
      final symbol = Symbol('test_symbol');
      final result = service.convert<String>(symbol, Class<String>());
      expect(result, 'test_symbol');
    });
  });

  group('URI Converters', () {
    test('String to Uri conversion', () {
      final result = service.convert<Uri>('https://example.com', Class<Uri>());
      expect(result, Uri.parse('https://example.com'));
    });

    test('Uri to String conversion', () {
      final uri = Uri.parse('https://example.com/path');
      final result = service.convert<String>(uri, Class<String>());
      expect(result, 'https://example.com/path');
    });
  });

  group('RegExp Converters', () {
    test('String to RegExp conversion', () {
      final result = service.convert<RegExp>('a+b*', Class<RegExp>());
      expect(result, isA<RegExp>());
      expect(result?.pattern, 'a+b*');
    });

    test('RegExp to String conversion', () {
      final regex = RegExp('test[0-9]+');
      final result = service.convert<String>(regex, Class<String>());
      expect(result, 'test[0-9]+');
    });
  });

  group('Pattern Converters', () {
    test('String to Pattern conversion', () {
      final result = service.convert<Pattern>('pattern', Class<Pattern>());
      expect(result, isA<RegExp>());
    });

    test('Pattern to String conversion', () {
      final pattern = RegExp('test');
      final result = service.convert<String>(pattern, Class<String>());
      expect(result, 'test');
    });
  });

  group('Enum Converters', () {
    test('String to Enum conversion', () {
      final result = service.convert<TestEnum>('value1', Class<TestEnum>());
      expect(result, TestEnum.value1);
    });

    test('Enum to String conversion', () {
      final result = service.convert<String>(TestEnum.value2, Class<String>());
      expect(result, 'value2');
    });

    test('int to Enum conversion', () {
      final result = service.convert<TestEnum>(2, Class<TestEnum>());
      expect(result, TestEnum.value3);
    });

    test('Enum to int conversion', () {
      final result = service.convert<int>(TestEnum.value1, Class<int>());
      expect(result, 0);
    });
  });

  group('Stream Converters', () {
    test('List to Stream conversion', () async {
      final list = [1, 2, 3];
      final result = service.convert<Stream<int>>(list, Class<Stream<int>>());
      
      final collected = await result?.toList();
      expect(collected, [1, 2, 3]);
    });

    // test('Stream to List conversion', () async {
    //   final stream = Stream.fromIterable([4, 5, 6]);
    //   final result = service.convert<List<int>>(stream, Class<List<int>>());
    //   expect(result, [4, 5, 6]);
    // });
  });

  group('Edge Cases and Error Handling', () {
    test('Null input returns null', () {
      final result = service.convert<String>(null, Class<String>());
      expect(result, isNull);
    });

    test('Invalid string to number conversion throws', () {
      expect(() => service.convert<int>('not_a_number', Class<int>()), 
          throwsA(isA<ConversionFailedException>()));
    });

    test('Large number conversions', () {
      final bigNumber = BigInt.from(999999999);
      final result = service.convert<int>(bigNumber, Class<int>());
      expect(result, 999999999);
    });

    test('Boolean edge cases', () {
      expect(service.convert<bool>(1, Class<bool>()), true);
      expect(service.convert<bool>(0, Class<bool>()), false);
      expect(service.convert<bool>('true', Class<bool>()), true);
      expect(service.convert<bool>('false', Class<bool>()), false);
    });
  });

  group('Cross-type Integration Tests', () {
    test('Multiple conversion steps', () {
      // String -> Integer -> int -> double -> String
      final step1 = service.convert<Integer>('42', Class<Integer>());
      final step2 = service.convert<int>(step1, Class<int>());
      final step3 = service.convert<double>(step2, Class<double>());
      final result = service.convert<String>(step3, Class<String>());
      
      expect(result, '42.0');
    });

    test('Complex type conversion chain', () {
      // bool -> int -> BigInt -> String -> Integer
      final step1 = service.convert<int>(true, Class<int>());
      final step2 = service.convert<BigInt>(step1, Class<BigInt>());
      final step3 = service.convert<String>(step2, Class<String>());
      final result = service.convert<Integer>(step3, Class<Integer>());
      
      expect(result, Integer.valueOf(1));
    });
  });
}