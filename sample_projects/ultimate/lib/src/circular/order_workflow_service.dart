// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Complex Circular Dependency (Service A)
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';
import 'payment_gateway_service.dart';

abstract class OrderWorkflowService {
  String processOrder(String orderId, double amount);
  String getWorkflowStatus(String orderId);
}

@Service('orderWorkflowService')
@Lazy()
class DefaultOrderWorkflowService implements OrderWorkflowService {
  final PaymentGatewayService paymentGateway;

  DefaultOrderWorkflowService(this.paymentGateway);

  @override
  String processOrder(String orderId, double amount) {
    final chargeResult = paymentGateway.charge(orderId, amount);
    return 'ORDER_PROCESSED:$orderId:$chargeResult';
  }

  @override
  String getWorkflowStatus(String orderId) {
    return 'ACTIVE_WORKFLOW:$orderId';
  }
}
