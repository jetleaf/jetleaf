import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('DefaultTemplateRenderer', () {
    group('Variable interpolation', () {
      test('renders simple variable', () {
        final result = renderTemplate(
          'Hello, {{name}}!',
          attributes: {'name': 'World'},
        );
        expect(result.getRenderedContent(), 'Hello, World!');
      });

      test('renders multiple variables', () {
        final result = renderTemplate(
          '{{greeting}}, {{name}}!',
          attributes: {'greeting': 'Hello', 'name': 'World'},
        );
        expect(result.getRenderedContent(), 'Hello, World!');
      });

      test('renders missing variable as empty string', () {
        final result = renderTemplate(
          'Hello, {{name}}!',
          attributes: {},
        );
        expect(result.getRenderedContent(), 'Hello, !');
      });

      test('renders nested variable via dot notation', () {
        final result = renderTemplate(
          'City: {{user.city}}',
          attributes: {'user': {'city': 'Paris'}},
        );
        expect(result.getRenderedContent(), 'City: Paris');
      });

      test('HTML escapes variable values', () {
        final result = renderTemplate(
          '{{content}}',
          attributes: {'content': '<script>alert("xss")</script>'},
        );
        expect(result.getRenderedContent(), '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;');
      });

      test('HTML escapes single quotes', () {
        final result = renderTemplate(
          '{{content}}',
          attributes: {'content': "it's"},
        );
        expect(result.getRenderedContent(), 'it&#x27;s');
      });

      test('HTML escapes ampersands', () {
        final result = renderTemplate(
          '{{content}}',
          attributes: {'content': 'a & b'},
        );
        expect(result.getRenderedContent(), 'a &amp; b');
      });
    });

    group('Conditional rendering', () {
      test('renders content when condition is true', () {
        final result = renderTemplate(
          '{{#if showBanner}}<div>Banner</div>{{/if}}',
          attributes: {'showBanner': 'true'},
        );
        expect(result.getRenderedContent(), '<div>Banner</div>');
      });

      test('hides content when condition is false', () {
        final result = renderTemplate(
          '{{#if showBanner}}<div>Banner</div>{{/if}}',
          attributes: {'showBanner': false},
        );
        expect(result.getRenderedContent(), '');
      });

      test('hides content when variable is missing', () {
        final result = renderTemplate(
          '{{#if showBanner}}<div>Banner</div>{{/if}}',
          attributes: {},
        );
        expect(result.getRenderedContent(), '');
      });

      test('renders variables inside conditional block', () {
        final result = renderTemplate(
          '{{#if showBanner}}Hello, {{name}}!{{/if}}',
          attributes: {'showBanner': 'true', 'name': 'World'},
        );
        expect(result.getRenderedContent(), 'Hello, World!');
      });

      test('handles complex condition with &&', () {
        final result = renderTemplate(
          '{{#if a && b}}Both{{/if}}',
          attributes: {'a': 'true', 'b': 'true'},
        );
        expect(result.getRenderedContent(), 'Both');
      });

      test('handles comparison in condition', () {
        final result = renderTemplate(
          '{{#if age >= 18}}Adult{{/if}}',
          attributes: {'age': 21},
        );
        expect(result.getRenderedContent(), 'Adult');
      });
    });

    group('Loop rendering', () {
      test('renders list items', () {
        final result = renderTemplate(
          '{{#each items}}<li>{{this}}</li>{{/each}}',
          attributes: {'items': ['A', 'B', 'C']},
        );
        expect(result.getRenderedContent(), '<li>A</li><li>B</li><li>C</li>');
      });

      test('renders empty list as empty string', () {
        final result = renderTemplate(
          '{{#each items}}<li>{{this}}</li>{{/each}}',
          attributes: {'items': <String>[]},
        );
        expect(result.getRenderedContent(), '');
      });

      test('renders missing list as empty string', () {
        final result = renderTemplate(
          '{{#each items}}<li>{{this}}</li>{{/each}}',
          attributes: {},
        );
        expect(result.getRenderedContent(), '');
      });

      test('provides @index variable', () {
        final result = renderTemplate(
          '{{#each items}}{{@index}}: {{this}} {{/each}}',
          attributes: {'items': ['A', 'B']},
        );
        expect(result.getRenderedContent(), '0: A 1: B ');
      });

      test('provides @first variable', () {
        final result = renderTemplate(
          '{{#each items}}{{#if @first}}FIRST {{/if}}{{this}} {{/each}}',
          attributes: {'items': ['A', 'B', 'C']},
        );
        expect(result.getRenderedContent(), 'FIRST A B C ');
      });

      test('provides @last variable', () {
        final result = renderTemplate(
          '{{#each items}}{{#if @last}}LAST{{/if}}{{this}} {{/each}}',
          attributes: {'items': ['A', 'B', 'C']},
        );
        expect(result.getRenderedContent(), 'A B LASTC ');
      });

      test('renders nested objects in loop', () {
        final result = renderTemplate(
          '{{#each users}}{{this.name}} {{/each}}',
          attributes: {
            'users': [
              {'name': 'Alice'},
              {'name': 'Bob'},
            ],
          },
        );
        expect(result.getRenderedContent(), 'Alice Bob ');
      });
    });

    group('Filter rendering', () {
      test('applies single filter', () {
        final result = renderTemplate(
          '{{name | uppercase}}',
          attributes: {'name': 'hello'},
        );
        expect(result.getRenderedContent(), 'HELLO');
      });

      test('applies chained filters', () {
        final result = renderTemplate(
          '{{name | uppercase | trim}}',
          attributes: {'name': '  hello  '},
        );
        expect(result.getRenderedContent(), 'HELLO');
      });

      test('applies capitalize filter', () {
        final result = renderTemplate(
          '{{name | capitalize}}',
          attributes: {'name': 'hello'},
        );
        expect(result.getRenderedContent(), 'Hello');
      });

      test('applies length filter', () {
        final result = renderTemplate(
          '{{items | length}}',
          attributes: {'items': ['a', 'b', 'c']},
        );
        expect(result.getRenderedContent(), '3');
      });

      test('applies htmlescape filter', () {
        final result = renderTemplate(
          '{{content | htmlescape}}',
          attributes: {'content': '<b>bold</b>'},
        );
        expect(result.getRenderedContent(), '&lt;b&gt;bold&lt;/b&gt;');
      });
    });

    group('Include rendering', () {
      test('renders include as placeholder comment', () {
        final result = renderTemplate(
          '{{>header}}',
          attributes: {},
        );
        expect(result.getRenderedContent(), '<!-- Include: header -->');
      });
    });

    group('Raw content and structure', () {
      test('preserves raw content', () {
        final result = renderTemplate(
          'Hello, {{name}}!',
          attributes: {'name': 'World'},
        );
        expect(result.getRawContent(), 'Hello, {{name}}!');
      });

      test('returns HTML code structure', () {
        final result = renderTemplate(
          '<div>Hello</div>',
          attributes: {},
        );
        expect(result.getCodeStructure().getType(), 'HTML');
      });
    });

    group('Mixed content', () {
      test('renders template with variables, conditionals, and loops', () {
        final result = renderTemplate(
          '<h1>{{title}}</h1>'
          '{{#if showItems}}'
          '<ul>'
          '{{#each items}}<li>{{this}}</li>{{/each}}'
          '</ul>'
          '{{/if}}',
          attributes: {
            'title': 'My Page',
            'showItems': 'true',
            'items': ['Item 1', 'Item 2'],
          },
        );
        expect(result.getRenderedContent(),
            '<h1>My Page</h1><ul><li>Item 1</li><li>Item 2</li></ul>');
      });
    });
  });
}
