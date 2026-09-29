import 'package:jtl/jtl.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('InMemoryTemplateCache', () {
    late InMemoryTemplateCache cache;

    setUp(() {
      cache = InMemoryTemplateCache();
    });

    test('get returns null for missing template', () {
      expect(cache.get('nonexistent'), isNull);
    });

    test('put and get retrieve cached SourceCode', () {
      final source = SourceCodeBuilder()
          .withAsset(TestAsset('content'))
          .withCodeStructure(CodeStructureBuilder().build())
          .withRenderedContent('rendered')
          .withRawContent('raw')
          .build();

      cache.put('test', source);
      final cached = cache.get('test');
      expect(cached, isNotNull);
      expect(cached!.getRenderedContent(), 'rendered');
      expect(cached.getRawContent(), 'raw');
    });

    test('put overwrites existing entry', () {
      final source1 = SourceCodeBuilder()
          .withAsset(TestAsset('c1'))
          .withCodeStructure(CodeStructureBuilder().build())
          .withRenderedContent('first')
          .withRawContent('raw1')
          .build();
      final source2 = SourceCodeBuilder()
          .withAsset(TestAsset('c2'))
          .withCodeStructure(CodeStructureBuilder().build())
          .withRenderedContent('second')
          .withRawContent('raw2')
          .build();

      cache.put('test', source1);
      cache.put('test', source2);
      expect(cache.get('test')!.getRenderedContent(), 'second');
    });

    test('remove deletes specific entry', () {
      final source = SourceCodeBuilder()
          .withAsset(TestAsset('c'))
          .withCodeStructure(CodeStructureBuilder().build())
          .withRenderedContent('rendered')
          .withRawContent('raw')
          .build();

      cache.put('test', source);
      expect(cache.get('test'), isNotNull);

      cache.remove('test');
      expect(cache.get('test'), isNull);
    });

    test('remove on nonexistent key does not throw', () {
      expect(() => cache.remove('nonexistent'), returnsNormally);
    });

    test('invalidateCache clears all entries', () {
      final source = SourceCodeBuilder()
          .withAsset(TestAsset('c'))
          .withCodeStructure(CodeStructureBuilder().build())
          .withRenderedContent('rendered')
          .withRawContent('raw')
          .build();

      cache.put('a', source);
      cache.put('b', source);
      cache.put('c', source);

      cache.invalidateCache();

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), isNull);
    });

    test('multiple templates stored independently', () {
      final source1 = SourceCodeBuilder()
          .withAsset(TestAsset('c1'))
          .withCodeStructure(CodeStructureBuilder().build())
          .withRenderedContent('one')
          .withRawContent('r1')
          .build();
      final source2 = SourceCodeBuilder()
          .withAsset(TestAsset('c2'))
          .withCodeStructure(CodeStructureBuilder().build())
          .withRenderedContent('two')
          .withRawContent('r2')
          .build();

      cache.put('template1', source1);
      cache.put('template2', source2);

      expect(cache.get('template1')!.getRenderedContent(), 'one');
      expect(cache.get('template2')!.getRenderedContent(), 'two');
    });
  });
}
