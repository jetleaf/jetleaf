import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf/src/env/models.dart';
import 'package:jetleaf/src/env/jetleaf_property_source_order_rule.dart';
import 'package:jetleaf/src/pod_factory_post_processor/lazy_initialization_pod_factory_post_processor.dart';

void main() {
  group('EnvironmentSource', () {
    test('should create with profile and properties', () {
      final source = EnvironmentSource('dev', {'key': 'value'});
      expect(source.profile, equals('dev'));
      expect(source.properties, equals({'key': 'value'}));
    });

    test('should create with empty properties', () {
      final source = EnvironmentSource('prod', {});
      expect(source.profile, equals('prod'));
      expect(source.properties, isEmpty);
    });

    test('should have correct toString', () {
      final source = EnvironmentSource('test', {'a': 1});
      expect(source.toString(), contains('EnvironmentSource'));
      expect(source.toString(), contains('test'));
    });

    test('should be immutable', () {
      final source = EnvironmentSource('dev', {'key': 'value'});
      expect(source.profile, equals('dev'));
    });
  });

  group('ParsedEnvironmentSource', () {
    test('should create with package name, profile, and properties', () {
      final source = ParsedEnvironmentSource(
        'jetleaf_core',
        'dev',
        {'port': 8080},
      );
      expect(source.packageName, equals('jetleaf_core'));
      expect(source.profile, equals('dev'));
      expect(source.properties, equals({'port': 8080}));
    });

    test('should extend EnvironmentSource', () {
      final source = ParsedEnvironmentSource(
        'jetleaf_core',
        'dev',
        {},
      );
      expect(source, isA<EnvironmentSource>());
    });

    test('should have correct toString', () {
      final source = ParsedEnvironmentSource(
        'jetleaf_core',
        'dev',
        {'key': 'value'},
      );
      expect(source.toString(), contains('ParsedEnvironmentSource'));
      expect(source.toString(), contains('jetleaf_core'));
    });
  });

  group('JetleafPropertySourceOrderRule', () {
    test('should create with active profiles', () {
      final rule = JetleafPropertySourceOrderRule(['dev', 'prod']);
      expect(rule, isNotNull);
    });

    test('should implement PropertySourceOrderRule', () {
      final rule = JetleafPropertySourceOrderRule(['dev']);
      expect(rule, isA<PropertySourceOrderRule>());
    });

    test('should sort property sources', () {
      final rule = JetleafPropertySourceOrderRule(['dev']);
      final sources = [
        MapPropertySource('systemEnvironment', {'key': 'env'}),
        MapPropertySource('systemProperties', {'key': 'sys'}),
        MapPropertySource('dev', {'key': 'dev'}),
        MapPropertySource('commandLineArgs', {'key': 'cli'}),
      ];
      final sorted = rule.apply(sources);
      expect(sorted, isNotNull);
      expect(sorted.length, equals(4));
    });

    test('should prioritize command line args first', () {
      final rule = JetleafPropertySourceOrderRule(['dev']);
      final sources = [
        MapPropertySource('systemProperties', {'key': 'sys'}),
        MapPropertySource('commandLineArgs', {'key': 'cli'}),
      ];
      final sorted = rule.apply(sources);
      expect(sorted.first.getName(), equals('commandLineArgs'));
    });

    test('should prioritize system properties before system environment', () {
      final rule = JetleafPropertySourceOrderRule(['dev']);
      final sources = [
        MapPropertySource('systemEnvironment', {'key': 'env'}),
        MapPropertySource('systemProperties', {'key': 'sys'}),
      ];
      final sorted = rule.apply(sources);
      expect(sorted.first.getName(), equals('systemProperties'));
      expect(sorted.last.getName(), equals('systemEnvironment'));
    });

    test('should prioritize active profiles', () {
      final rule = JetleafPropertySourceOrderRule(['dev']);
      final sources = [
        MapPropertySource('other', {'key': 'other'}),
        MapPropertySource('dev', {'key': 'dev'}),
      ];
      final sorted = rule.apply(sources);
      final devIndex = sorted.indexWhere((s) => s.getName() == 'dev');
      final otherIndex = sorted.indexWhere((s) => s.getName() == 'other');
      expect(devIndex, lessThan(otherIndex));
    });

    test('should handle empty active profiles', () {
      final rule = JetleafPropertySourceOrderRule([]);
      final sources = [
        MapPropertySource('systemProperties', {'key': 'sys'}),
        MapPropertySource('custom', {'key': 'custom'}),
      ];
      final sorted = rule.apply(sources);
      expect(sorted.length, equals(2));
    });
  });

  group('DefaultPropertiesPropertySource', () {
    test('should create with properties', () {
      final source = DefaultPropertiesPropertySource({'key': 'value'});
      expect(source, isNotNull);
      expect(source, isA<MapPropertySource>());
    });

    test('should have correct name', () {
      final source = DefaultPropertiesPropertySource({'key': 'value'});
      expect(source.getName(), equals(GlobalEnvironment.RESERVED_DEFAULT_PROFILE_NAME));
    });

    test('should return properties', () {
      final props = {'app.name': 'test', 'app.version': '1.0'};
      final source = DefaultPropertiesPropertySource(props);
      expect(source.getSource(), equals(props));
    });

    test('hasMatchingName should return true for matching source', () {
      final source = DefaultPropertiesPropertySource({'key': 'value'});
      expect(DefaultPropertiesPropertySource.hasMatchingName(source), isTrue);
    });

    test('hasMatchingName should return false for non-matching source', () {
      final source = MapPropertySource('other', {'key': 'value'});
      expect(DefaultPropertiesPropertySource.hasMatchingName(source), isFalse);
    });

    test('hasMatchingName should return false for null', () {
      expect(DefaultPropertiesPropertySource.hasMatchingName(null), isFalse);
    });

    test('ifNotEmpty should invoke action for non-empty map', () {
      var called = false;
      DefaultPropertiesPropertySource.ifNotEmpty({'key': 'value'}, (source) {
        called = true;
        expect(source, isA<DefaultPropertiesPropertySource>());
      });
      expect(called, isTrue);
    });

    test('ifNotEmpty should not invoke action for empty map', () {
      var called = false;
      DefaultPropertiesPropertySource.ifNotEmpty({}, (source) {
        called = true;
      });
      expect(called, isFalse);
    });

    test('ifNotEmpty should not invoke action for null action', () {
      DefaultPropertiesPropertySource.ifNotEmpty({'key': 'value'}, null);
    });
  });

  group('ApplicationInfoPropertySource', () {
    test('should create with source class', () {
      final source = ApplicationInfoPropertySource(null);
      expect(source, isNotNull);
      expect(source, isA<MapPropertySource>());
    });

    test('should have correct NAME', () {
      expect(ApplicationInfoPropertySource.NAME, equals('applicationInfo'));
    });

    test('should have application info properties', () {
      final source = ApplicationInfoPropertySource(null);
      final props = source.getSource();
      expect(props, isA<Map>());
      expect(props.containsKey(JetleafApplication.JETLEAF_APPLICATION_PID), isTrue);
    });
  });

  group('LazyInitializationPodFactoryPostProcessor', () {
    test('should create instance', () {
      final processor = LazyInitializationPodFactoryPostProcessor();
      expect(processor, isNotNull);
    });

    test('should implement PodFactoryPostProcessor', () {
      final processor = LazyInitializationPodFactoryPostProcessor();
      expect(processor, isA<PodFactoryPostProcessor>());
    });

    test('should implement PriorityOrdered', () {
      final processor = LazyInitializationPodFactoryPostProcessor();
      expect(processor, isA<PriorityOrdered>());
    });

    test('should have correct order', () {
      final processor = LazyInitializationPodFactoryPostProcessor();
      expect(processor.getOrder(), equals(Ordered.HIGHEST_PRECEDENCE - 2));
    });
  });
}
