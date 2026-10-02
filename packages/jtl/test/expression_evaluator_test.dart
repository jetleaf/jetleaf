import 'package:jtl/jtl.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultExpressionEvaluator', () {
    late DefaultExpressionEvaluator evaluator;
    late DefaultVariableResolver resolver;
    late DefaultTemplateContext context;

    setUp(() {
      evaluator = DefaultExpressionEvaluator();
      resolver = DefaultVariableResolver();
      context = DefaultTemplateContext(resolver);
    });

    group('Truthiness evaluation', () {
      test('true is truthy', () {
        expect(evaluator.evaluate('true', context), isTrue);
      });

      test('false is falsy', () {
        expect(evaluator.evaluate('false', context), isFalse);
      });

      test('null is falsy', () {
        expect(evaluator.evaluate('null', context), isFalse);
      });

      test('non-empty string variable is truthy', () {
        resolver.setVariables({'name': 'Alice'});
        expect(evaluator.evaluate('name', context), isTrue);
      });

      test('empty string variable is falsy', () {
        resolver.setVariables({'name': ''});
        expect(evaluator.evaluate('name', context), isFalse);
      });

      test('missing variable is falsy', () {
        expect(evaluator.evaluate('missing', context), isFalse);
      });

      test('non-zero number is truthy', () {
        resolver.setVariables({'count': 42});
        expect(evaluator.evaluate('count', context), isTrue);
      });

      test('zero number is falsy via variable', () {
        resolver.setVariables({'count': 0});
        expect(evaluator.evaluate('count', context), isFalse);
      });

      test('bool false variable is falsy', () {
        resolver.setVariables({'flag': false});
        expect(evaluator.evaluate('flag', context), isFalse);
      });
    });

    group('Comparison operators', () {
      test('== equality', () {
        resolver.setVariables({'age': 25});
        expect(evaluator.evaluate('age == 25', context), isTrue);
        expect(evaluator.evaluate('age == 30', context), isFalse);
      });

      test('!= inequality', () {
        resolver.setVariables({'age': 25});
        expect(evaluator.evaluate('age != 30', context), isTrue);
        expect(evaluator.evaluate('age != 25', context), isFalse);
      });

      test('> greater than', () {
        resolver.setVariables({'age': 25});
        expect(evaluator.evaluate('age > 20', context), isTrue);
        expect(evaluator.evaluate('age > 30', context), isFalse);
      });

      test('< less than', () {
        resolver.setVariables({'age': 25});
        expect(evaluator.evaluate('age < 30', context), isTrue);
        expect(evaluator.evaluate('age < 20', context), isFalse);
      });

      test('>= greater or equal', () {
        resolver.setVariables({'age': 25});
        expect(evaluator.evaluate('age >= 25', context), isTrue);
        expect(evaluator.evaluate('age >= 30', context), isFalse);
      });

      test('<= less or equal', () {
        resolver.setVariables({'age': 25});
        expect(evaluator.evaluate('age <= 25', context), isTrue);
        expect(evaluator.evaluate('age <= 20', context), isFalse);
      });

      test('string equality', () {
        resolver.setVariables({'name': 'Alice'});
        expect(evaluator.evaluate('name == "Alice"', context), isTrue);
        expect(evaluator.evaluate('name == "Bob"', context), isFalse);
      });
    });

    group('Logical operators', () {
      test('&& AND operator', () {
        resolver.setVariables({'a': true, 'b': true});
        expect(evaluator.evaluate('a && b', context), isTrue);

        resolver.setVariables({'a': true, 'b': false});
        expect(evaluator.evaluate('a && b', context), isFalse);
      });

      test('|| OR operator', () {
        resolver.setVariables({'a': true, 'b': false});
        expect(evaluator.evaluate('a || b', context), isTrue);

        resolver.setVariables({'a': false, 'b': false});
        expect(evaluator.evaluate('a || b', context), isFalse);
      });

      test('complex expression with && and ||', () {
        resolver.setVariables({'a': true, 'b': false, 'c': true});
        expect(evaluator.evaluate('a && b || c', context), isTrue);
      });
    });

    group('Nullish coalescing', () {
      test('returns left if not null', () {
        resolver.setVariables({'value': 'hello'});
        expect(evaluator.evaluate('value ?? "default"', context), isTrue);
      });

      test('returns right if left is null', () {
        resolver.setVariables({});
        expect(evaluator.evaluate('missing ?? "default"', context), isTrue);
      });
    });

    group('Literal values', () {
      test('string literal', () {
        expect(evaluator.evaluate('"hello"', context), isTrue);
      });

      test('integer literal', () {
        expect(evaluator.evaluate('42', context), isTrue);
      });

      test('double literal', () {
        expect(evaluator.evaluate('3.14', context), isTrue);
      });
    });
  });
}
