import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

@JetleafTest()
void main() async {
  final service = DefaultConversionService();

  group('Collection Converters', () {
    test('List<String> to List<int>', () {
      final source = ['1', '2', '3'];
      final targetType = Class<List<int>>();
      final result = service.convertTo(source, targetType);
      expect(result, [1, 2, 3]);
    });

    test('List<int> to List<int> (no element conversion)', () {
      final source = [1, 2, 3];
      final targetType = Class<List<int>>();
      final result = service.convertTo(source, targetType);
      expect(result, [1, 2, 3]);
    });

    test('List<String> to Set<int>', () {
      final source = ['1', '2', '1'];
      final targetType = Class<Set<int>>();
      final result = service.convertTo(source, targetType);
      expect(result, {1, 2});
    });

    test('Set<String> to List<int>', () {
      final source = {'1', '2', '3'};
      final targetType = Class<List<int>>();
      final result = service.convertTo(source, targetType);
      expect(result, containsAllInOrder([1, 2, 3])); // Order not guaranteed for Set conversion
    });

    test('Set<int> to Set<int> (no element conversion)', () {
      final source = {1, 2, 3};
      final targetType = Class<Set<int>>();
      final result = service.convertTo(source, targetType);
      expect(result, {1, 2, 3});
    });

    test('Map<String, String> to Map<String, int>', () {
      final source = {'a': '1', 'b': '2'};
      final targetType = Class<Map<String, int>>();
      final result = service.convertTo(source, targetType);
      expect(result, {'a': 1, 'b': 2});
    });

    test('Map<int, String> to Map<String, int>', () {
      final source = {1: '10', 2: '12'};
      final targetType = Class<Map<String, int>>();
      final result = service.convertTo(source, targetType);
      expect(result, {'1': 10, '2': 12}); // String to int conversion for values
    });

    test('Map<String, String> to Map<String, String> (no conversion)', () {
      final source = {'a': '1', 'b': '2'};
      final targetType = Class<Map<String, String>>();
      final result = service.convertTo(source, targetType);
      expect(result, {'a': '1', 'b': '2'});
    });
  });
}