import 'package:test/test.dart';
import 'package:jetleaf_core/src/pod/core/default_listable_pod_factory.dart';
import 'package:jetleaf_core/src/pod/definition/pod_definition.dart';
import 'package:jetleaf_core/lang.dart';

class MockUserRepository {
  final Map<String, String> _data = {'1': 'Alice', '2': 'Bob'};
  String? findUser(String id) => _data[id];
}

class MockUserService {
  final MockUserRepository repository;
  bool isInitialized = false;
  bool isDestroyed = false;

  MockUserService(this.repository);

  void init() {
    isInitialized = true;
  }

  void destroy() {
    isDestroyed = true;
  }
}

void main() {
  group('AOT Pod Instantiation & Lifecycle (Zero Reflection)', () {
    late DefaultListablePodFactory factory;

    setUp(() {
      factory = DefaultListablePodFactory();
    });

    test('should instantiate pod via direct AOT instanceSupplier without reflection', () async {
      // Register MockUserRepository
      await factory.registerDefinition('userRepository', RootPodDefinition(
        type: Class<MockUserRepository>(),
        instanceSupplier: (f) => MockUserRepository(),
      ));

      // Register MockUserService with constructor injection via supplier
      await factory.registerDefinition('userService', RootPodDefinition(
        type: Class<MockUserService>(),
        instanceSupplier: (f) async {
          final repo = await f.getPod('userRepository');
          return MockUserService(repo as MockUserRepository);
        },
        initMethodInvoker: (instance) {
          (instance as MockUserService).init();
        },
        destroyMethodInvoker: (instance) {
          (instance as MockUserService).destroy();
        },
      ));

      // Fetch pod
      final service = await factory.getPod('userService') as MockUserService;

      expect(service, isNotNull);
      expect(service.repository, isNotNull);
      expect(service.repository.findUser('1'), equals('Alice'));
      expect(service.isInitialized, isTrue, reason: 'initMethodInvoker should have been invoked');
      expect(service.isDestroyed, isFalse);

      // Destroy singletons
      await factory.destroySingletons();
      expect(service.isDestroyed, isTrue, reason: 'destroyMethodInvoker should have been invoked');
    });

    test('should resolve singleton caching with AOT suppliers', () async {
      await factory.registerDefinition('userRepository', RootPodDefinition(
        type: Class<MockUserRepository>(),
        instanceSupplier: (f) => MockUserRepository(),
      ));

      final first = await factory.getPod('userRepository');
      final second = await factory.getPod('userRepository');

      expect(identical(first, second), isTrue, reason: 'Singleton should return the same instance');
    });
  });
}
