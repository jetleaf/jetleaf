import 'dart:io';
import 'package:jetleaf/jetleaf.dart';
import 'src/services/resource_service.dart';
import 'src/runners/resource_verification_runner.dart';
import '_jetleaf/aot_registry.g.dart';

@JetleafApplicationStarter()
class ResourceApp {
  static final Log _logger = LogFactory.getLog(ResourceApp);
}

Future<void> main(List<String> args) async {
  ResourceApp._logger.info('Starting ResourceApp...');
  final app = JetleafApplication(ResourceApp);
  app.setApplicationType(ApplicationType.NONE);
  app.setAotRegistrar(registerGeneratedAotPods);

  final context = await app.create(args, null);
  if (context == null) {
    print('Failed to start application context');
    exit(1);
  }

  final service = await context.getPod<ResourceService>('resourceService');
  final runner = await context.getPod<ResourceVerificationRunner>('resourceVerificationRunner');

  print('================ RESOURCE APP EXECUTION REPORT ================');
  print('Active Profiles: ${service.activeProfiles}');
  print('Injected App Name (@Value): ${service.injectedAppName}');
  print('Injected App Port (@Value): ${service.injectedAppPort}');
  print('Injected Debug Feature (@Value): ${service.injectedDebugFeature}');
  print('Injected Metrics Feature (@Value): ${service.injectedMetricsFeature}');
  print('ConfigurationProperty Name: ${service.appProperties.name}');
  print('ConfigurationProperty Port: ${service.appProperties.port}');
  print('Template Loaded: ${runner.templateContent?.contains("Hello from Jetleaf Resources!") == true}');
  print('JSON Asset Loaded: ${runner.jsonContent?.contains("JSON Asset") == true}');
  print('Total Discovered Assets: ${service.getAllDiscoveredAssetPaths().length}');
  print('================================================================');

  await JetleafApplication.exit(context, []);
  exit(0);
}
