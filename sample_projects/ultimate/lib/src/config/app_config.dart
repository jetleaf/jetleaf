// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Configuration and AutoConfiguration with Conditional Logic
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';
import '../events/event_service.dart';

class SecondaryConfig {
  @Pod(value: 'secondarySetting')
  String secondarySetting() => 'SECONDARY_SETTING_ACTIVE';
}

abstract interface class FallbackService {
  String getMode();
}

class DefaultFallbackService implements FallbackService {
  @override
  String getMode() => 'FALLBACK_MODE_ACTIVE';
}

@Configuration('appConfig')
@Import([ClassType<SecondaryConfig>()])
class AppConfig {
  @Pod(value: 'configuredApiKey')
  @ConditionalOnProperty(prefix: 'ultimate', names: ['feature.enabled'], havingValue: 'true', matchIfMissing: true)
  @ConditionalOnClass([ClassType<EventService>()])
  @ConditionalOnExpression('1 + 1 == 2')
  @DependsOn(['eventService'])
  @Role(DesignRole.INFRASTRUCTURE)
  String configuredApiKey() => 'API_KEY_ULTIMATE_777';

  @Pod(value: 'fallbackService')
  @ConditionalOnMissingPod(values: [ClassType<FallbackService>()])
  FallbackService fallbackService() => DefaultFallbackService();
}
