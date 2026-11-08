import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/logging.dart';

@Component()
class CliLifecycle {
  static final Log _logger = LogFactory.getLog(CliLifecycle);

  bool isInitialized = false;
  bool isReady = false;
  bool isDestroyed = false;

  @PostConstruct()
  void onInit() {
    isInitialized = true;
    _logger.info('CliLifecycle: @PostConstruct triggered - subsystem initialized.');
  }

  @OnApplicationReady()
  void onReady() {
    isReady = true;
    _logger.info('CliLifecycle: @OnApplicationReady triggered - application ready.');
  }

  @PreDestroy()
  void onDestroy() {
    isDestroyed = true;
    _logger.info('CliLifecycle: @PreDestroy triggered - cleaning up resources.');
  }
}
