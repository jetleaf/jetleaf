import 'package:jetleaf_env/property.dart';
import 'package:test/test.dart';

void main() {
  group('MapPropertySource', () {
    test('containsProperty returns true for existing key', () {
      final source = MapPropertySource('test', {'key1': 'value1'});
      expect(source.containsProperty('key1'), isTrue);
    });

    test('containsProperty returns false for missing key', () {
      final source = MapPropertySource('test', {'key1': 'value1'});
      expect(source.containsProperty('key2'), isFalse);
    });

    test('getProperty returns value for existing key', () {
      final source = MapPropertySource('test', {'key1': 'value1'});
      expect(source.getProperty('key1'), equals('value1'));
    });

    test('getProperty returns null for missing key', () {
      final source = MapPropertySource('test', {'key1': 'value1'});
      expect(source.getProperty('key2'), isNull);
    });

    test('getName returns the source name', () {
      final source = MapPropertySource('mySource', {});
      expect(source.getName(), equals('mySource'));
    });

    test('getSource returns the underlying map', () {
      final map = {'key1': 'value1'};
      final source = MapPropertySource('test', map);
      expect(source.getSource(), equals(map));
    });
  });

  group('CompositePropertySource', () {
    test('respects property source order', () {
      final composite = CompositePropertySource('composite');
      composite.addPropertySource(MapPropertySource('second', {'key': 'fromSecond'}));
      composite.addPropertySource(MapPropertySource('first', {'key': 'fromFirst'}));

      expect(composite.getProperty('key'), equals('fromSecond'));
    });

    test('addFirstPropertySource puts source at beginning', () {
      final composite = CompositePropertySource('composite');
      composite.addPropertySource(MapPropertySource('second', {'key': 'fromSecond'}));
      composite.addFirstPropertySource(MapPropertySource('first', {'key': 'fromFirst'}));

      expect(composite.getProperty('key'), equals('fromFirst'));
    });

    test('getPropertySources returns all sources', () {
      final composite = CompositePropertySource('composite');
      composite.addPropertySource(MapPropertySource('s1', {}));
      composite.addPropertySource(MapPropertySource('s2', {}));

      expect(composite.getPropertySources(), hasLength(2));
    });

    test('containsProperty checks across all sources', () {
      final composite = CompositePropertySource('composite');
      composite.addPropertySource(MapPropertySource('s1', {'key1': 'v1'}));
      composite.addPropertySource(MapPropertySource('s2', {'key2': 'v2'}));

      expect(composite.containsProperty('key1'), isTrue);
      expect(composite.containsProperty('key2'), isTrue);
      expect(composite.containsProperty('key3'), isFalse);
    });
  });

  group('MutablePropertySources', () {
    test('addLast adds source to end', () {
      final sources = MutablePropertySources();
      sources.addLast(MapPropertySource('first', {'key': 'first'}));
      sources.addLast(MapPropertySource('last', {'key': 'last'}));

      final names = sources.map((s) => s.getName()).toList();
      expect(names.first, equals('first'));
      expect(names.last, equals('last'));
    });

    test('addFirst adds source to beginning', () {
      final sources = MutablePropertySources();
      sources.addLast(MapPropertySource('first', {'key': 'first'}));
      sources.addFirst(MapPropertySource('newFirst', {'key': 'newFirst'}));

      final names = sources.map((s) => s.getName()).toList();
      expect(names.first, equals('newFirst'));
    });

    test('remove removes a property source', () {
      final sources = MutablePropertySources();
      sources.addLast(MapPropertySource('test', {}));
      expect(sources.length, equals(1));

      sources.remove('test');
      expect(sources.length, equals(0));
    });

    test('get retrieves source by name', () {
      final sources = MutablePropertySources();
      sources.addLast(MapPropertySource('test', {'key': 'value'}));

      final source = sources.get('test');
      expect(source, isNotNull);
      expect(source!.getProperty('key'), equals('value'));
    });

    test('get returns null for non-existent source', () {
      final sources = MutablePropertySources();
      expect(sources.get('missing'), isNull);
    });
  });

  group('ListablePropertySource', () {
    test('containsProperty checks property names', () {
      final source = _TestListablePropertySource(['key1', 'key2']);
      expect(source.containsProperty('key1'), isTrue);
      expect(source.containsProperty('key3'), isFalse);
    });

    test('getPropertyNames returns all names', () {
      final source = _TestListablePropertySource(['key1', 'key2']);
      expect(source.getPropertyNames(), equals(['key1', 'key2']));
    });
  });
}

class _TestListablePropertySource extends ListablePropertySource<Object> {
  final List<String> _names;
  _TestListablePropertySource(this._names) : super('test', Object());

  @override
  List<String> getPropertyNames() => _names;

  @override
  Object? getProperty(String name) => name;
}