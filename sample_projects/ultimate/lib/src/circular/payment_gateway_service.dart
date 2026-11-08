// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Complex Circular Dependency (Service B)
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';
import 'audit_trail_service.dart';

abstract class PaymentGatewayService {
  String charge(String orderId, double amount);
}

@Service('paymentGatewayService')
@Lazy()
class DefaultPaymentGatewayService implements PaymentGatewayService {
  final AuditTrailService auditTrail;

  DefaultPaymentGatewayService(this.auditTrail);

  @override
  String charge(String orderId, double amount) {
    auditTrail.logEvent(orderId, 'PAYMENT_CHARGED_\$$amount');
    return 'CHARGED_\$$amount';
  }
}
