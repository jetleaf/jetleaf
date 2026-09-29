import 'package:jtl/jtl.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateFilterRegistry', () {
    late TemplateFilterRegistry registry;

    setUp(() {
      registry = TemplateFilterRegistry();
    });

    group('Built-in filters are registered', () {
      test('uppercase filter converts to uppercase', () {
        final filter = registry.getFilter('uppercase');
        expect(filter, isNotNull);
        expect(filter!('hello'), 'HELLO');
        expect(filter('Hello World'), 'HELLO WORLD');
        expect(filter(''), '');
      });

      test('lowercase filter converts to lowercase', () {
        final filter = registry.getFilter('lowercase');
        expect(filter, isNotNull);
        expect(filter!('HELLO'), 'hello');
        expect(filter('Hello World'), 'hello world');
      });

      test('trim filter removes whitespace', () {
        final filter = registry.getFilter('trim');
        expect(filter, isNotNull);
        expect(filter!('  hello  '), 'hello');
        expect(filter('hello'), 'hello');
        expect(filter('   '), '');
      });

      test('capitalize filter capitalizes first character', () {
        final filter = registry.getFilter('capitalize');
        expect(filter, isNotNull);
        expect(filter!('hello'), 'Hello');
        expect(filter('Hello'), 'Hello');
        expect(filter('hELLO'), 'HELLO');
        expect(filter(''), '');
      });

      test('titlecase filter capitalizes first character of each word', () {
        final filter = registry.getFilter('titlecase');
        expect(filter, isNotNull);
        expect(filter!('hello world'), 'Hello World');
        expect(filter('hello'), 'Hello');
        expect(filter('a b c'), 'A B C');
        expect(filter(''), '');
      });

      test('length filter returns string length', () {
        final filter = registry.getFilter('length');
        expect(filter, isNotNull);
        expect(filter!('hello'), 5);
        expect(filter(''), 0);
      });

      test('length filter returns list length', () {
        final filter = registry.getFilter('length');
        expect(filter!([1, 2, 3]), 3);
        expect(filter([]), 0);
      });

      test('length filter returns map length', () {
        final filter = registry.getFilter('length');
        expect(filter!({'a': 1, 'b': 2}), 2);
        expect(filter({}), 0);
      });

      test('reverse filter reverses a string', () {
        final filter = registry.getFilter('reverse');
        expect(filter, isNotNull);
        expect(filter!('hello'), 'olleh');
        expect(filter('a'), 'a');
      });

      test('reverse filter reverses a list', () {
        final filter = registry.getFilter('reverse');
        expect(filter!([1, 2, 3]), [3, 2, 1]);
      });

      test('substring filter truncates long strings', () {
        final filter = registry.getFilter('substring');
        expect(filter, isNotNull);
        expect(filter!('short'), 'short');
        expect(filter('a very long string'), 'a very lon...');
      });

      test('abs filter returns absolute value', () {
        final filter = registry.getFilter('abs');
        expect(filter, isNotNull);
        expect(filter!(-5), 5);
        expect(filter(5), 5);
        expect(filter(0), 0);
      });

      test('round filter rounds double to nearest integer', () {
        final filter = registry.getFilter('round');
        expect(filter, isNotNull);
        expect(filter!(3.7), 4);
        expect(filter(3.2), 3);
      });

      test('ceil filter ceils a double', () {
        final filter = registry.getFilter('ceil');
        expect(filter, isNotNull);
        expect(filter!(3.1), 4);
        expect(filter(3.0), 3);
      });

      test('floor filter floors a double', () {
        final filter = registry.getFilter('floor');
        expect(filter, isNotNull);
        expect(filter!(3.9), 3);
        expect(filter(3.0), 3);
      });

      test('toFixed filter formats to 2 decimal places', () {
        final filter = registry.getFilter('toFixed');
        expect(filter, isNotNull);
        expect(filter!(3.14159), '3.14');
        expect(filter(3.0), '3.00');
      });

      test('default filter returns empty string for null/empty', () {
        final filter = registry.getFilter('default');
        expect(filter, isNotNull);
        expect(filter!(null), '');
        expect(filter(''), '');
        expect(filter('hello'), 'hello');
      });

      test('emptycheck filter returns N/A for null/empty', () {
        final filter = registry.getFilter('emptycheck');
        expect(filter, isNotNull);
        expect(filter!(null), 'N/A');
        expect(filter(''), 'N/A');
        expect(filter('hello'), 'hello');
      });

      test('first filter returns first element of list', () {
        final filter = registry.getFilter('first');
        expect(filter, isNotNull);
        expect(filter!([1, 2, 3]), 1);
        expect(filter([]), <dynamic>[]);
      });

      test('last filter returns last element of list', () {
        final filter = registry.getFilter('last');
        expect(filter, isNotNull);
        expect(filter!([1, 2, 3]), 3);
        expect(filter([]), <dynamic>[]);
      });

      test('join filter joins list with comma separator', () {
        final filter = registry.getFilter('join');
        expect(filter, isNotNull);
        expect(filter!([1, 2, 3]), '1, 2, 3');
        expect(filter(['a', 'b']), 'a, b');
      });

      test('size filter returns list/map size', () {
        final filter = registry.getFilter('size');
        expect(filter, isNotNull);
        expect(filter!([1, 2, 3]), 3);
        expect(filter({'a': 1}), 1);
        expect(filter('string'), 0);
      });

      test('urlencode filter URL-encodes a string', () {
        final filter = registry.getFilter('urlencode');
        expect(filter, isNotNull);
        expect(filter!('hello world'), 'hello%20world');
        expect(filter('a&b=c'), 'a%26b%3Dc');
      });

      test('htmlescape filter escapes HTML characters', () {
        final filter = registry.getFilter('htmlescape');
        expect(filter, isNotNull);
        expect(filter!('<script>alert("xss")</script>'),
            '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;');
        expect(filter("it's"), "it&#x27;s");
        expect(filter('a&b'), 'a&amp;b');
      });
    });

    group('Custom filter registration', () {
      test('registerFilter adds a new filter', () {
        registry.registerFilter('double', (value) {
          if (value is num) return value * 2;
          return value;
        });

        final filter = registry.getFilter('double');
        expect(filter, isNotNull);
        expect(filter!(10), 20);
        expect(filter(5.5), 11.0);
      });

      test('registerFilter overwrites existing filter', () {
        registry.registerFilter('custom', (value) => 'first');
        expect(registry.getFilter('custom')!(null), 'first');

        registry.registerFilter('custom', (value) => 'second');
        expect(registry.getFilter('custom')!(null), 'second');
      });

      test('getFilter returns null for unknown filter', () {
        expect(registry.getFilter('nonexistent'), isNull);
      });
    });

    group('Registry without built-in filters', () {
      test('empty registry has no built-in filters', () {
        final emptyRegistry = TemplateFilterRegistry(false);
        expect(emptyRegistry.getFilter('uppercase'), isNull);
        expect(emptyRegistry.getFilter('lowercase'), isNull);
        expect(emptyRegistry.getFilter('trim'), isNull);
      });

      test('can add filters to empty registry', () {
        final emptyRegistry = TemplateFilterRegistry(false);
        emptyRegistry.registerFilter('custom', (value) => 'result');
        expect(emptyRegistry.getFilter('custom')!(null), 'result');
      });
    });
  });
}
