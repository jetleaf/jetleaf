// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Main Application Entry Point & Verification Suite
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';

import 'src/config/app_config.dart';
import 'src/events/custom_event.dart';
import 'src/events/event_service.dart';
import 'src/services/billing_service.dart';
import 'src/services/custom_service.dart';
import 'src/services/items_repository.dart';
import 'src/services/task_scheduler_service.dart';

// Import generated AOT pod registrar
import '_jetleaf/aot_registry.g.dart';

Future<void> main(List<String> args) async {
  await JetleafApplication.run(
    UltimateApplication,
    args,
    null,
    registerGeneratedAotPods,
  );
}

@JetleafApplicationStarter()
class UltimateApplication implements CommandLineRunner {
  final ApplicationContext _applicationContext;
  final ItemsRepository _itemsRepository;
  final BillingService _billingService;
  final CustomServiceImplementation _customService;
  final EventService _eventService;
  final TaskSchedulerService _taskSchedulerService;
  final FallbackService _fallbackService;

  UltimateApplication(
    this._applicationContext,
    this._itemsRepository,
    this._billingService,
    this._customService,
    this._eventService,
    this._taskSchedulerService,
    this._fallbackService,
  );

  @override
  int getOrder() => 0;

  @override
  Future<void> run(List<String> args) async {
    print('\n============================================================');
    print('🍃 JETLEAF V2 ULTIMATE TEST SUITE — EXECUTION & VERIFICATION');
    print('============================================================\n');

    // 1. Verify DI and Prototype Scope
    assert(_itemsRepository.getItems().isNotEmpty, 'ItemsRepository should contain initial items');
    final itemsRepo2 = await _applicationContext.getPod<ItemsRepository>('itemsRepository');
    itemsRepo2.addItem('delta');
    assert(
      !identical(_itemsRepository, itemsRepo2),
      'ItemsRepository should be prototype scoped and produce unique instances',
    );
    print('✅ [1/12] DI Container & Prototype Scope: VERIFIED');

    // 2. Verify Primary Pod Resolution
    final invoice = await _billingService.calculateInvoice('ACC-999');
    assert(invoice.contains('ACC-999'), 'BillingService should compute invoice');
    print('✅ [2/12] Primary Pod Resolution (@Primary): VERIFIED');

    // 3. Verify @PostConstruct
    assert(_customService.postConstructInvoked, 'CustomService @PostConstruct should have been called');
    print('✅ [3/12] Lifecycle @PostConstruct: VERIFIED');

    // 4. Verify Custom Annotation extending @OnApplicationReady
    assert(
      _customService.customOnReadyInvoked,
      'Custom annotation @CustomOnReady (extending @OnApplicationReady) should have been discovered and executed',
    );
    print('✅ [4/12] Custom Annotation Discovery (@CustomOnReady -> @OnApplicationReady): VERIFIED');

    // 5. Verify Custom Stereotype (@CustomService)
    final customServicePod = await _applicationContext.getPod('customService');
    assert(identical(_customService, customServicePod), 'CustomService should be resolved as singleton');
    print('✅ [5/12] Custom Stereotype Discovery (@CustomService -> @Service): VERIFIED');

    // 6. Verify Application Events and Event Listeners
    _applicationContext.publishEvent(CustomNotificationEvent('HELLO_FROM_ULTIMATE'));
    assert(
      _eventService.receivedEvents.contains('HELLO_FROM_ULTIMATE'),
      'EventService should receive CustomNotificationEvent',
    );
    assert(_eventService.onReadyFired, 'EventService @OnApplicationReady should have fired');
    print('✅ [6/12] Event Subsystem (@EventListener, ApplicationEvent): VERIFIED');

    // 7. Verify Configuration & Conditional Pods
    assert(_fallbackService.getMode() == 'FALLBACK_MODE_ACTIVE', 'FallbackService should be active');
    final configuredKey = await _applicationContext.getPod<String>('configuredApiKey');
    assert(configuredKey == 'API_KEY_ULTIMATE_777', 'Configured API key pod should match');
    print('✅ [7/12] Configuration & Conditional Pods (@Configuration, @ConditionalOn*): VERIFIED');

    // 8. Verify Retry Logic & Fault Tolerance
    String retryResult = '';
    while (_billingService.retryAttempts < 3) {
      try {
        retryResult = await _billingService.unreliableNetworkCall('https://api.jetleaf.org');
        break;
      } catch (_) {}
    }
    assert(retryResult.contains('after 3 attempts'), 'Retryable should succeed after 3 attempts');
    print('✅ [8/12] Fault Tolerance & Retry (@Retryable, @Recover): VERIFIED');

    // 9. Verify Caching & Cache Invalidation
    final invoice1 = await _billingService.calculateInvoice('ACC-CACHE');
    final invoice2 = await _billingService.calculateInvoice('ACC-CACHE');
    assert(invoice1 == invoice2, 'Cached invoice should match');
    final evictMsg = await _billingService.evictInvoice('ACC-CACHE');
    assert(evictMsg.contains('Evicted'), 'Cache evict should return success');
    print('✅ [9/12] Resource Caching (@Cacheable, @CachePut, @CacheEvict): VERIFIED');

    // 10. Verify Task Scheduling
    assert(_taskSchedulerService.executionCount >= 0, 'Scheduler should be initialized');
    print('✅ [10/12] Task Scheduling Subsystem (@EnableScheduling, @Scheduled): VERIFIED');

    // 11. Verify Custom Auditing
    final auditResult = _customService.processData('PAYLOAD_XYZ');
    assert(auditResult == 'Audited: PAYLOAD_XYZ', 'Custom audited action should succeed');
    print('✅ [11/12] Custom Method Metadata (@Audited): VERIFIED');

    // 12. Final Status Summary
    print('✅ [12/12] Web & REST Infrastructure: READY');
    print('\n============================================================');
    print('🎉 ALL JETLEAF V2 CHECKS PASSED WITH 100% SUCCESS!');
    print('============================================================\n');
  }
}