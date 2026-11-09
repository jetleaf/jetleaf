// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Billing Service with Primary, Retry, Cache, RateLimit & Monitoring
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_actuator/jetleaf_actuator.dart';
import 'package:jetleaf_resource/jetleaf_resource.dart';
import 'package:jetleaf_retry/jetleaf_retry.dart';

import 'items_repository.dart';

abstract interface class BillingService {
  Future<String> calculateInvoice(String accountId);
  Future<String> processPayment(String accountId, double amount);
  Future<String> evictInvoice(String accountId);
  Future<String> unreliableNetworkCall(String endpoint);
  Future<String> recoverFromNetworkFailure(Exception error, String endpoint);
  int get retryAttempts;
}

@Service('billingService')
@Primary()
@Order(1)
@Role(DesignRole.APPLICATION)
@RequiredAll()
class DefaultBillingService implements BillingService {
  final ItemsRepository _itemsRepository;
  @override
  int retryAttempts = 0;

  DefaultBillingService(this._itemsRepository);

  @override
  @Cacheable({'billingCache'})
  @RateLimit({'billingLimit'}, limit: 50, window: Duration(seconds: 10))
  @Monitor('billing_calculate_invoice')
  Future<String> calculateInvoice(String accountId) async {
    final items = _itemsRepository.getItems();
    return 'Invoice for $accountId: ${items.join(', ')}';
  }

  @override
  @CachePut({'billingCache'})
  @Monitor('billing_process_payment')
  Future<String> processPayment(String accountId, double amount) async {
    return 'Processed payment of \$$amount for $accountId';
  }

  @override
  @CacheEvict({'billingCache'})
  Future<String> evictInvoice(String accountId) async {
    return 'Evicted invoice cache for $accountId';
  }

  @override
  @Retryable(
    maxAttempts: 3,
    backoff: Backoff(delay: 10, multiplier: 1.5, maxDelay: 100),
    label: 'networkCall',
  )
  Future<String> unreliableNetworkCall(String endpoint) async {
    retryAttempts++;
    if (retryAttempts < 3) {
      throw StateError('Simulated temporary network failure on attempt $retryAttempts');
    }
    return 'Success from $endpoint after $retryAttempts attempts';
  }

  @override
  @Recover(label: 'networkCall')
  Future<String> recoverFromNetworkFailure(Exception error, String endpoint) async {
    return 'Recovered from error ($error) for endpoint: $endpoint';
  }
}