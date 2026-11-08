import 'package:jetleaf_core/core.dart';
import 'package:jetleaf_core/env.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/logging.dart';
import '../config/app_properties.dart';

@Service()
class ResourceService implements EnvironmentAware {
  static final Log _logger = LogFactory.getLog(ResourceService);

  final AppProperties appProperties;
  late Environment _environment;

  @Value('#{app.name}')
  late String injectedAppName;

  @Value('#{app.port:8000}')
  late int injectedAppPort;

  @Value('#{feature.debug:false}')
  late bool injectedDebugFeature;

  @Value('#{feature.metrics:false}')
  late bool injectedMetricsFeature;

  ResourceService(this.appProperties);

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }

  Environment get environment => _environment;

  List<String> get activeProfiles => _environment.getActiveProfiles();

  Future<String> readWelcomeTemplate() async {
    final loader = AssetLoader.forPackage('resource_app');
    final content = await loader.load('resources/templates/welcome.txt');
    _logger.info('Loaded welcome template (${content.length} chars)');
    return content;
  }

  Future<String> readJsonConfig() async {
    final loader = AssetLoader.forPackage('resource_app');
    final content = await loader.load('assets/data/config.json');
    _logger.info('Loaded JSON config (${content.length} chars)');
    return content;
  }

  List<String> getAllDiscoveredAssetPaths() {
    return Runtime.getAllAssets().map((a) => a.getFilePath()).toList();
  }
}