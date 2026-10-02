import 'package:jtl/jtl.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('JtlFactory', () {
    late JtlFactory engine;

    setUp(() {
      engine = JtlFactory(
        assetBuilder: TestAssetBuilder({
          'test/template.html': 'Hello, {{name}}!',
        }).create(),
      );
    });

    test('creates with default components', () {
      final defaultEngine = JtlFactory();
      expect(defaultEngine.getCache(), isA<InMemoryTemplateCache>());
      expect(defaultEngine.getFilterRegistry(), isA<TemplateFilterRegistry>());
      expect(defaultEngine.getExpressionEvaluator(), isA<DefaultExpressionEvaluator>());
      expect(defaultEngine.getVariableResolver(), isA<DefaultVariableResolver>());
    });

    test('render returns SourceCode', () {
      final template = JtlTemplate('test/template.html', {'name': 'World'});
      final result = engine.render(template);
      expect(result.getRenderedContent(), 'Hello, World!');
    });

    test('render caches result', () {
      final template = JtlTemplate('test/template.html', {'name': 'World'});
      final result1 = engine.render(template);
      final result2 = engine.render(template);
      expect(identical(result1, result2), isTrue);
    });

    test('render uses correct cache key', () {
      final template = JtlTemplate('test/template.html', {'name': 'World'});
      engine.render(template);
      expect(engine.getCache().get('test/template.html'), isNotNull);
    });

    test('setTemplateCache replaces cache', () {
      final newCache = InMemoryTemplateCache();
      engine.setTemplateCache(newCache);
      expect(engine.getCache(), same(newCache));
    });

    test('setVariableResolver replaces resolver', () {
      final newResolver = DefaultVariableResolver();
      engine.setVariableResolver(newResolver);
      expect(engine.getVariableResolver(), same(newResolver));
    });

    test('setExpressionEvaluator replaces evaluator', () {
      final newEvaluator = DefaultExpressionEvaluator();
      engine.setExpressionEvaluator(newEvaluator);
      expect(engine.getExpressionEvaluator(), same(newEvaluator));
    });

    test('setFilterRegistry replaces filter registry', () {
      final newRegistry = TemplateFilterRegistry(false);
      engine.setFilterRegistry(newRegistry);
      expect(engine.getFilterRegistry(), same(newRegistry));
    });

    test('setTemplateRenderer replaces renderer', () {
      final assetBuilder = TestAssetBuilder({}).create();
      final newRenderer = DefaultTemplateRenderer(
          TemplateFilterRegistry(), assetBuilder);
      engine.setTemplateRenderer(newRenderer);
      expect(engine.getRenderer(), same(newRenderer));
    });

    test('setAssetBuilder replaces asset builder', () {
      final newBuilder = TestAssetBuilder({'t': 'new'}).create();
      engine.setAssetBuilder(newBuilder);
      expect(engine.getAssetBuilder(), same(newBuilder));
    });

    test('hot-swap: changing resolver affects next render', () {
      final template = JtlTemplate('test/template.html', {'name': 'Alice'});
      final result1 = engine.render(template);
      expect(result1.getRenderedContent(), 'Hello, Alice!');

      final newResolver = DefaultVariableResolver();
      newResolver.setVariables({'name': 'Bob'});
      engine.setVariableResolver(newResolver);

      engine.getCache().invalidateCache();
      final template2 = JtlTemplate('test/template.html', {'name': 'Bob'});
      final result2 = engine.render(template2);
      expect(result2.getRenderedContent(), 'Hello, Bob!');
    });

    test('hot-swap: changing filters affects next render', () {
      final assetBuilder = TestAssetBuilder({'t': '{{name | uppercase}}'}).create();
      final newEngine = JtlFactory(assetBuilder: assetBuilder);

      final template = JtlTemplate('t', {'name': 'hello'});
      final result1 = newEngine.render(template);
      expect(result1.getRenderedContent(), 'HELLO');
    });

    test('render with pre-built asset', () {
      final asset = TestAsset('Pre-built: {{name}}');
      final template = JtlTemplate('test/template.html', {'name': 'World'});
      final result = engine.render(template, asset);
      expect(result.getRenderedContent(), 'Pre-built: World');
    });

    test('getRenderer returns DefaultTemplateRenderer', () {
      expect(engine.getRenderer(), isA<DefaultTemplateRenderer>());
    });
  });

  group('JtlTemplate', () {
    test('stores location and attributes', () {
      final tmpl = JtlTemplate('path/to/template', {'key': 'value'});
      expect(tmpl.getLocation(), 'path/to/template');
      expect(tmpl.getAttributes(), {'key': 'value'});
    });

    test('attributes are unmodifiable', () {
      final tmpl = JtlTemplate('path', {'key': 'value'});
      expect(() => tmpl.getAttributes()['new'] = 'val', throwsA(anything));
    });
  });
}
