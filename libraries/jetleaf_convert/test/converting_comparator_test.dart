import 'package:jetleaf_convert/jetleaf_convert.dart';
import 'package:jetleaf_lang/jetleaf_lang.dart';
import 'package:test/test.dart';

import '_test_models.dart';

@JetleafTest()
void main() async {
  group('ConvertingComparator', () {
    test('should sort MapEntry by keys', () {
      final entries = [
        MapEntry('c', 1),
        MapEntry('a', 3),
        MapEntry('b', 2),
      ];
      entries.sort(ConvertingComparator.mapEntryKeys(Comparator.naturalOrder()).compare);
      expect(entries.map((e) => e.key), ['a', 'b', 'c']);
    });

    test('should sort MapEntry by values', () {
      final entries = [
        MapEntry('a', 3),
        MapEntry('b', 1),
        MapEntry('c', 2),
      ];
      entries.sort(ConvertingComparator.mapEntryValues(Comparator.naturalOrder()).compare);
      expect(entries.map((e) => e.value), [1, 2, 3]);
    });

    test('should use ConversionServiceConverter', () {
      final customService = DefaultConversionService();
      customService.addConverter(sourceType: Class<String>(), targetType: Class<int>(), CustomConverter()); // Registers x2 converter

      final comparator = ConvertingComparator.withConverter(
        Comparator.naturalOrder(),
        customService,
        Class<int>(),
      );
      final list = ['1', '5', '2']; // Will be converted to [2, 10, 4]
      list.sort(comparator.compare);
      expect(list, ['1', '2', '5']); // Sorted by converted values
    });
  });
}