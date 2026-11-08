// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Scheduled Task Service
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

@Component('taskSchedulerService')
@EnableScheduling()
class TaskSchedulerService {
  int executionCount = 0;

  TaskSchedulerService();

  @Scheduled(fixedRate: Duration(milliseconds: 200))
  void executeHeartbeat() {
    executionCount++;
  }
}
