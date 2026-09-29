import 'package:jetleaf_env/property.dart';
import 'package:test/test.dart';

void main() {
  group('PropertySourceOrderingRules', () {
    final sources = [
      MapPropertySource('alpha', {}),
      MapPropertySource('beta', {}),
      MapPropertySource('gamma', {}),
    ];

    group('AlphabeticalRule', () {
      test('sorts sources alphabetically by name', () {
        final rule = AlphabeticalRule();
        final result = rule.apply(sources);
        expect(result[0].getName(), equals('alpha'));
        expect(result[1].getName(), equals('beta'));
        expect(result[2].getName(), equals('gamma'));
      });
    });

    group('BeforeRule', () {
      test('ensures one source appears before another', () {
        final rule = BeforeRule('beta', 'alpha');
        final result = rule.apply(sources);
        final betaIndex = result.indexWhere((s) => s.getName() == 'beta');
        final alphaIndex = result.indexWhere((s) => s.getName() == 'alpha');
        expect(betaIndex, lessThan(alphaIndex));
      });
    });
  });
}