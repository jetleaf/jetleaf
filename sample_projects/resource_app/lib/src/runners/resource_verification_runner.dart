import 'package:jetleaf/jetleaf.dart';
import '../services/resource_service.dart';

@Component()
class ResourceVerificationRunner implements CommandLineRunner {
  static final Log _logger = LogFactory.getLog(ResourceVerificationRunner);

  final ResourceService _service;
  bool verified = false;
  String? templateContent;
  String? jsonContent;

  ResourceVerificationRunner(this._service);

  @override
  int getOrder() => 1;

  @override
  Future<void> run(List<String> args) async {
    _logger.info('ResourceVerificationRunner: Verifying resources and profile configuration...');
    
    templateContent = await _service.readWelcomeTemplate();
    jsonContent = await _service.readJsonConfig();
    verified = true;

    _logger.info('Active profiles: ${_service.activeProfiles}');
    _logger.info('AppProperties name: ${_service.appProperties.name}, port: ${_service.appProperties.port}');
    _logger.info('@Value injected name: ${_service.injectedAppName}, port: ${_service.injectedAppPort}');
    _logger.info('@Value injected debug: ${_service.injectedDebugFeature}, metrics: ${_service.injectedMetricsFeature}');
    _logger.info('Discovered asset count: ${_service.getAllDiscoveredAssetPaths().length}');
  }
}
