import 'package:jtl/jtl.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultVariableResolver', () {
    late DefaultVariableResolver resolver;

    setUp(() {
      resolver = DefaultVariableResolver();
    });

    group('Simple variable resolution', () {
      test('resolves string variable', () {
        resolver.setVariables({'name': 'Alice'});
        expect(resolver.resolve('name'), 'Alice');
      });

      test('resolves int variable as string', () {
        resolver.setVariables({'age': 25});
        expect(resolver.resolve('age'), '25');
      });

      test('resolves double variable as string', () {
        resolver.setVariables({'price': 9.99});
        expect(resolver.resolve('price'), '9.99');
      });

      test('resolves bool true as "true"', () {
        resolver.setVariables({'active': true});
        expect(resolver.resolve('active'), 'true');
      });

      test('resolves bool false as "false"', () {
        resolver.setVariables({'active': false});
        expect(resolver.resolve('active'), 'false');
      });

      test('resolves null as empty string', () {
        resolver.setVariables({'value': null});
        expect(resolver.resolve('value'), '');
      });

      test('resolves list as comma-separated string', () {
        resolver.setVariables({'tags': ['dart', 'flutter', 'web']});
        expect(resolver.resolve('tags'), 'dart, flutter, web');
      });

      test('resolves map as toString', () {
        resolver.setVariables({'config': {'key': 'value'}});
        expect(resolver.resolve('config'), contains('key'));
      });

      test('resolves unknown variable as empty string', () {
        resolver.setVariables({});
        expect(resolver.resolve('unknown'), '');
      });
    });

    group('Nested variable resolution (dot notation)', () {
      test('resolves one level deep', () {
        resolver.setVariables({
          'user': {'name': 'Bob'},
        });
        expect(resolver.resolve('user.name'), 'Bob');
      });

      test('resolves two levels deep', () {
        resolver.setVariables({
          'user': {
            'address': {'city': 'Paris'},
          },
        });
        expect(resolver.resolve('user.address.city'), 'Paris');
      });

      test('resolves nested null as empty string', () {
        resolver.setVariables({
          'user': {'name': null},
        });
        expect(resolver.resolve('user.name'), '');
      });

      test('resolves missing nested key as empty string', () {
        resolver.setVariables({'user': {}});
        expect(resolver.resolve('user.missing'), '');
      });

      test('resolves non-map intermediate as empty string', () {
        resolver.setVariables({'user': 'string'});
        expect(resolver.resolve('user.name'), '');
      });
    });

    group('setVariables', () {
      test('replaces all variables', () {
        resolver.setVariables({'a': '1'});
        resolver.setVariables({'b': '2'});
        expect(resolver.resolve('a'), '');
        expect(resolver.resolve('b'), '2');
      });
    });

    group('Whitespace handling', () {
      test('trims variable name', () {
        resolver.setVariables({'name': 'Alice'});
        expect(resolver.resolve('  name  '), 'Alice');
      });

      test('trims nested path parts', () {
        resolver.setVariables({
          'user': {'name': 'Bob'},
        });
        expect(resolver.resolve(' user . name '), 'Bob');
      });
    });
  });
}
