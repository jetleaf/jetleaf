// test/pod_name_generator_test.dart
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/src/name_generator/pod_name_generator.dart';
import 'package:test/test.dart';
import 'package:jetleaf_pod/src/definition/pod_definition.dart';
import 'package:jetleaf_pod/src/definition/pod_definition_registry.dart';

class MockPodDefinition implements PodDefinition {
  @override
  final String name;
  @override
  final Class type;

  MockPodDefinition({required this.name, required this.type});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPodDefinitionRegistry implements PodDefinitionRegistry {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestPodNameGenerator implements PodNameGenerator {
  @override
  String generate(PodDefinition definition, PodDefinitionRegistry registry) {
    return 'test_${definition.name}';
  }

  @override
  String getPackageName() => "test";
}

@JetleafTest()
void main() {
  group('PodNameGenerator', () {
    test('should be an abstract interface', () {
      final generator = TestPodNameGenerator();
      expect(generator, isA<PodNameGenerator>());
    });

    test('should have generate method', () {
      final generator = TestPodNameGenerator();
      final definition = MockPodDefinition(name: 'TestService', type: Class<Object>());
      final registry = MockPodDefinitionRegistry();
      
      final result = generator.generate(definition, registry);
      expect(result, equals('test_TestService'));
    });

    test('should accept different implementations', () {
      // Test that any class implementing the interface works
      final generators = <PodNameGenerator>[
        TestPodNameGenerator(),
        _AnotherTestGenerator(),
      ];
      
      final definition = MockPodDefinition(name: 'Test', type: Class<Object>());
      final registry = MockPodDefinitionRegistry();
      
      for (final generator in generators) {
        expect(() => generator.generate(definition, registry), returnsNormally);
      }
    });
  });
}

class _AnotherTestGenerator implements PodNameGenerator {
  @override
  String generate(PodDefinition definition, PodDefinitionRegistry registry) {
    return 'another_${definition.name}';
  }

  @override
  String getPackageName() => "test";
}