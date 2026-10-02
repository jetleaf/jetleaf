import 'package:jtl/jtl.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('TextCodeElement', () {
    test('has null opening/closing tags and tag name', () {
      final element = TextCodeElement(line: 'Hello', content: 'Hello');
      expect(element.getOpeningTag(), isNull);
      expect(element.getClosingTag(), isNull);
      expect(element.getTagName(), isNull);
    });

    test('returns correct line and content', () {
      final element = TextCodeElement(line: 'console.log("Hi");', content: 'log');
      expect(element.getLine(), 'console.log("Hi");');
      expect(element.getContent(), 'log');
    });

    test('returns empty children by default', () {
      final element = TextCodeElement(line: 'x', content: 'x');
      expect(element.getChildren(), isEmpty);
    });

    test('returns provided children', () {
      final child = TextCodeElement(line: 'child', content: 'child');
      final parent = TextCodeElement(line: 'parent', content: 'parent', children: [child]);
      expect(parent.getChildren().length, 1);
      expect(parent.getChildren().first.getContent(), 'child');
    });

    test('children list is unmodifiable', () {
      final element = TextCodeElement(line: 'x', content: 'x');
      expect(() => element.getChildren().add(TextCodeElement(line: 'y', content: 'y')),
          throwsA(anything));
    });
  });

  group('HtmlTagElement', () {
    test('stores tag name, opening/closing tags', () {
      final element = HtmlTagElement(
        tagName: 'div',
        line: '<div>Hello</div>',
        content: 'Hello',
        openingTag: '<div>',
        closingTag: '</div>',
      );
      expect(element.getTagName(), 'div');
      expect(element.getOpeningTag(), '<div>');
      expect(element.getClosingTag(), '</div>');
    });

    test('returns correct line and content', () {
      final element = HtmlTagElement(
        tagName: 'p',
        line: '<p>Text</p>',
        content: 'Text',
      );
      expect(element.getLine(), '<p>Text</p>');
      expect(element.getContent(), 'Text');
    });

    test('children are unmodifiable', () {
      final element = HtmlTagElement(tagName: 'div', line: '<div/>', content: '');
      expect(() => element.getChildren().add(TextCodeElement(line: 'x', content: 'x')),
          throwsA(anything));
    });
  });

  group('ConditionalStatement', () {
    test('stores condition and provides correct tags', () {
      final stmt = ConditionalStatement(
        condition: 'showBanner',
        statement: 'Show banner',
        line: '{{#if showBanner}}',
        content: 'Banner content',
      );
      expect(stmt.condition, 'showBanner');
      expect(stmt.getStatement(), 'Show banner');
      expect(stmt.getOpeningTag(), '{{#if showBanner}}');
      expect(stmt.getClosingTag(), '{{/if}}');
      expect(stmt.getTagName(), 'if');
      expect(stmt.getContent(), 'Banner content');
    });
  });

  group('ForEachStatement', () {
    test('stores itemsKey and provides correct tags', () {
      final stmt = ForEachStatement(
        itemsKey: 'users',
        statement: 'Render users',
        line: '{{#each users}}',
        content: '{{this.name}}',
      );
      expect(stmt.getItemsKey(), 'users');
      expect(stmt.getStatement(), 'Render users');
      expect(stmt.getOpeningTag(), '{{#each users}}');
      expect(stmt.getClosingTag(), '{{/each}}');
      expect(stmt.getTagName(), 'each');
    });
  });

  group('IncludeStatement', () {
    test('stores templateName and provides correct tag', () {
      final stmt = IncludeStatement(
        templateName: 'header',
        statement: 'Include header',
        line: '{{>header}}',
      );
      expect(stmt.getTemplateName(), 'header');
      expect(stmt.getStatement(), 'Include header');
      expect(stmt.getOpeningTag(), '{{>header}}');
      expect(stmt.getClosingTag(), isNull);
      expect(stmt.getTagName(), 'include');
      expect(stmt.getChildren(), isEmpty);
    });
  });

  group('CodeStructureBuilder', () {
    test('builds with default HTML type', () {
      final structure = CodeStructureBuilder().build();
      expect(structure.getType(), 'HTML');
      expect(structure.getElements(), isEmpty);
    });

    test('builds with custom type', () {
      final structure = CodeStructureBuilder().withType('JS').build();
      expect(structure.getType(), 'JS');
    });

    test('adds elements', () {
      final el = TextCodeElement(line: 'x', content: 'x');
      final structure = CodeStructureBuilder()
          .addElement(el)
          .build();
      expect(structure.getElements().length, 1);
    });

    test('adds multiple elements', () {
      final el1 = TextCodeElement(line: 'a', content: 'a');
      final el2 = TextCodeElement(line: 'b', content: 'b');
      final structure = CodeStructureBuilder()
          .addElements([el1, el2])
          .build();
      expect(structure.getElements().length, 2);
    });

    test('elements list is unmodifiable', () {
      final structure = CodeStructureBuilder().build();
      expect(
          () => structure
              .getElements()
              .add(TextCodeElement(line: 'x', content: 'x')),
          throwsA(anything));
    });
  });

  group('SourceCodeBuilder', () {
    test('builds SourceCode with all properties', () {
      final asset = TestAsset('content');
      final structure = CodeStructureBuilder().build();
      final source = SourceCodeBuilder()
          .withAsset(asset)
          .withCodeStructure(structure)
          .withRenderedContent('rendered')
          .withRawContent('raw')
          .build();

      expect(source.getAsset(), asset);
      expect(source.getCodeStructure(), structure);
      expect(source.getRenderedContent(), 'rendered');
      expect(source.getRawContent(), 'raw');
    });
  });

  group('DefaultCodeStructure', () {
    test('returns unmodifiable elements', () {
      final el = TextCodeElement(line: 'x', content: 'x');
      final structure = DefaultCodeStructure([el], 'HTML');
      expect(() => structure.getElements().add(TextCodeElement(line: 'y', content: 'y')),
          throwsA(anything));
    });
  });
}
