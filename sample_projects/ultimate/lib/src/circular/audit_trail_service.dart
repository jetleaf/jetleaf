// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Complex Circular Dependency (Service C with @Lazy)
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';
import 'order_workflow_service.dart';

abstract class AuditTrailService {
  void logEvent(String entityId, String event);
  List<String> getAuditLogs();
}

@Service('auditTrailService')
@Lazy()
class DefaultAuditTrailService implements AuditTrailService {
  final OrderWorkflowService orderWorkflow;
  final List<String> logs = [];

  DefaultAuditTrailService(this.orderWorkflow);

  @override
  void logEvent(String entityId, String event) {
    // Calling back into the circular dependency across the cycle
    final status = orderWorkflow.getWorkflowStatus(entityId);
    logs.add('AUDIT:[$status] $event');
  }

  @override
  List<String> getAuditLogs() => List.unmodifiable(logs);
}
