import 'package:test/test.dart';
import 'package:jetleaf/jetleaf.dart';
import 'package:resource_app/resource_app.dart';
import 'package:resource_app/src/services/resource_service.dart';
import 'package:resource_app/src/runners/resource_verification_runner.dart';
import 'package:resource_app/_jetleaf/aot_registry.g.dart';

void main() {
  group('ResourceApp Tests', () {
    test('loads default profile configuration and assets', () async {
      final app = JetleafApplication(ResourceApp);
      app.setApplicationType(ApplicationType.NONE);
      app.setAotRegistrar(registerGeneratedAotPods);

      final context = await app.create([], null);
      expect(context, isNotNull);

      final service = await context!.getPod<ResourceService>('resourceService');
      expect(service.injectedAppName, equals('ResourceApp'));
      expect(service.injectedAppPort, equals(8000));
      expect(service.injectedDebugFeature, isFalse);
      expect(service.injectedMetricsFeature, isFalse);

      final runner = await context.getPod<ResourceVerificationRunner>('resourceVerificationRunner');
      expect(runner.verified, isTrue);
      expect(runner.templateContent, contains('Hello from Jetleaf Resources!'));
      expect(runner.jsonContent, contains('JSON Asset'));

      await JetleafApplication.exit(context, []);
    });

    test('loads dev profile with property overrides', () async {
      final app = JetleafApplication(ResourceApp);
      app.setApplicationType(ApplicationType.NONE);
      app.setAotRegistrar(registerGeneratedAotPods);

      final context = await app.create(['--jetleaf.profiles.active=dev'], null);
      expect(context, isNotNull);

      final service = await context!.getPod<ResourceService>('resourceService');
      expect(service.activeProfiles, contains('dev'));
      expect(service.injectedAppName, equals('ResourceApp-Dev'));
      expect(service.injectedAppPort, equals(8081));
      expect(service.injectedDebugFeature, isTrue);
      expect(service.injectedMetricsFeature, isFalse);

      await JetleafApplication.exit(context, []);
    });

    test('loads prod profile with property overrides', () async {
      final app = JetleafApplication(ResourceApp);
      app.setApplicationType(ApplicationType.NONE);
      app.setAotRegistrar(registerGeneratedAotPods);

      final context = await app.create(['--jetleaf.profiles.active=prod'], null);
      expect(context, isNotNull);

      final service = await context!.getPod<ResourceService>('resourceService');
      expect(service.activeProfiles, contains('prod'));
      expect(service.injectedAppName, equals('ResourceApp-Prod'));
      expect(service.injectedAppPort, equals(9000));
      expect(service.injectedDebugFeature, isFalse);
      expect(service.injectedMetricsFeature, isTrue);

      await JetleafApplication.exit(context, []);
    });
  });
}
