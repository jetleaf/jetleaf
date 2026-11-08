import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';

class SampleRepository {
  final List<String> items = ['item1', 'item2'];
}

class SampleService {
  final SampleRepository repository;
  bool initialized = false;
  bool destroyed = false;

  SampleService(this.repository);

  void onInit() {
    initialized = true;
  }

  void onDestroy() {
    destroyed = true;
  }
}

class SampleRunner implements CommandLineRunner {
  bool ran = false;
  List<String> receivedArgs = [];

  @override
  int getOrder() => 0;

  @override
  void run(List<String> args) {
    ran = true;
    receivedArgs = args;
  }
}

class TestApplication {}

Future<void> sampleAotRegistrar([DefaultListablePodFactory? factory]) async {
  if (factory == null) return;
  
  // 0. Register TestApplication
  await factory.registerDefinition('testApplication', RootPodDefinition(
    type: Class<TestApplication>(),
    instanceSupplier: (f) => TestApplication(),
  )..name = 'testApplication');

  // 1. Register SampleRepository
  await factory.registerDefinition('sampleRepository', RootPodDefinition(
    type: Class<SampleRepository>(),
    instanceSupplier: (f) => SampleRepository(),
  )..name = 'sampleRepository');

  // 2. Register SampleService with dependency on SampleRepository
  await factory.registerDefinition('sampleService', RootPodDefinition(
    type: Class<SampleService>(),
    instanceSupplier: (f) async => SampleService(await f.get(Class<SampleRepository>())),
    initMethodInvoker: (instance) => (instance as SampleService).onInit(),
    destroyMethodInvoker: (instance) => (instance as SampleService).onDestroy(),
  )..name = 'sampleService');

  // 3. Register SampleRunner (CommandLineRunner)
  await factory.registerDefinition('sampleRunner', RootPodDefinition(
    type: Class<SampleRunner>(),
    instanceSupplier: (f) => SampleRunner(),
  )..name = 'sampleRunner');
}

void main() {
  group('Jetleaf AOT Application Bootstrap', () {
    test('boots application with zero-reflection AOT registrar and executes CommandLineRunner', () async {
      final app = JetleafApplication(TestApplication());
      app.setBannerMode(BannerMode.OFF);
      app.setApplicationType(ApplicationType.NONE);
      app.setAotRegistrar(sampleAotRegistrar);

      final context = await app.create(['--test.arg=123'], null);
      expect(context, isNotNull);

      // Verify SampleRepository pod was instantiated
      final repo = await context!.getPod<SampleRepository>('sampleRepository');
      expect(repo, isNotNull);
      expect(repo.items, equals(['item1', 'item2']));

      // Verify SampleService pod was instantiated with repo injected & initMethodInvoker called
      final service = await context.getPod<SampleService>('sampleService');
      expect(service, isNotNull);
      expect(service.repository, same(repo));
      expect(service.initialized, isTrue);
      expect(service.destroyed, isFalse);

      // Verify CommandLineRunner executed
      final runner = await context.getPod<SampleRunner>('sampleRunner');
      expect(runner.ran, isTrue);
      expect(runner.receivedArgs, contains('--test.arg=123'));

      // Close context and verify destroyMethodInvoker called
      await context.close();
      expect(service.destroyed, isTrue);
    });
  });
}
