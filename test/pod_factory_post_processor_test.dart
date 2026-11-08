import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf/src/pod_factory_post_processor/lazy_initialization_pod_factory_post_processor.dart';

void main() {
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

  group('Runner interfaces', () {
    test('Runner should be interface', () {
      expect(Runner, isA<Type>());
    });

    test('ApplicationRunner should be interface', () {
      expect(ApplicationRunner, isA<Type>());
    });

    test('CommandLineRunner should be interface', () {
      expect(CommandLineRunner, isA<Type>());
    });
  });

  group('ApplicationTypeFilter', () {
    test('should create instance', () {
      final filter = ApplicationTypeFilter();
      expect(filter, isNotNull);
    });

    test('should implement TypeFilter', () {
      final filter = ApplicationTypeFilter();
      expect(filter, isA<TypeFilter>());
    });
  });

  group('JetleafConfigParser', () {
    test('should create instance', () {
      final parser = JetleafConfigParser();
      expect(parser, isNotNull);
    });
  });
}
