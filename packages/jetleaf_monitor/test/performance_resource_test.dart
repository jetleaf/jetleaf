import 'package:jetleaf_monitor/jetleaf_monitor.dart';
import 'package:jetleaf_monitor/src/core/default_monitoring_service.dart' show PerformanceResource;
import 'package:jetleaf_core/core.dart';
import 'package:test/test.dart';

void main() {
  ConfigurablePerformance createPerf(String name, {String location = 'Test'}) {
    return ConfigurablePerformance(name: name, location: location);
  }

  group('PerformanceResource', () {
    late PerformanceResource resource;

    setUp(() {
      resource = PerformanceResource();
    });

    test('should be empty initially', () {
      expect(resource.isEmpty, isTrue);
      expect(resource.length, equals(0));
    });

    test('should add performance entry via put', () {
      resource['MyMethod'] = createPerf('MyMethod');
      expect(resource.length, equals(1));
      expect(resource.isEmpty, isFalse);
    });

    test('should retrieve performance entry by key', () {
      resource['MyMethod'] = createPerf('MyMethod');
      final retrieved = resource.get('MyMethod');
      expect(retrieved, isNotNull);
      expect(retrieved!.getName(), equals('MyMethod'));
    });

    test('should return null for nonexistent key', () {
      final retrieved = resource.get('Nonexistent');
      expect(retrieved, isNull);
    });

    test('should check existence', () {
      resource['MyMethod'] = createPerf('MyMethod');
      expect(resource.exists('MyMethod'), isTrue);
      expect(resource.exists('Other'), isFalse);
    });

    test('should overwrite existing entry', () {
      resource['MyMethod'] = createPerf('MyMethod');
      resource['MyMethod'] = createPerf('MyMethod');
      expect(resource.length, equals(1));
    });

    test('should support multiple entries', () {
      resource['Method1'] = createPerf('Method1');
      resource['Method2'] = createPerf('Method2');
      resource['Method3'] = createPerf('Method3');
      expect(resource.length, equals(3));
      expect(resource.exists('Method1'), isTrue);
      expect(resource.exists('Method2'), isTrue);
      expect(resource.exists('Method3'), isTrue);
    });

    test('should return values', () {
      resource['A'] = createPerf('A');
      resource['B'] = createPerf('B');
      final values = resource.values.toList();
      expect(values.length, equals(2));
    });

    test('should return keys', () {
      resource['X'] = createPerf('X');
      resource['Y'] = createPerf('Y');
      final keys = resource.keys.toList();
      expect(keys, contains('X'));
      expect(keys, contains('Y'));
    });

    test('should remove entry', () {
      resource['MyMethod'] = createPerf('MyMethod');
      resource.remove('MyMethod');
      expect(resource.exists('MyMethod'), isFalse);
      expect(resource.isEmpty, isTrue);
    });

    test('should implement Resource interface', () {
      expect(resource, isA<Resource<String, ConfigurablePerformance>>());
    });

    test('should support put operator', () {
      resource['Op1'] = createPerf('Op1');
      expect(resource.exists('Op1'), isTrue);
      expect(resource.get('Op1')!.getName(), equals('Op1'));
    });

    test('should support get operator', () {
      resource['Op2'] = createPerf('Op2');
      final perf = resource['Op2'];
      expect(perf, isNotNull);
      expect(perf!.getName(), equals('Op2'));
    });

    test('should clear all entries', () {
      resource['A'] = createPerf('A');
      resource['B'] = createPerf('B');
      resource.clear();
      expect(resource.isEmpty, isTrue);
    });
  });
}
