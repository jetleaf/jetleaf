import 'package:test/test.dart';

import 'trigger_test.dart' as trigger_test;
import 'annotation_test.dart' as annotation_test;
import 'exception_test.dart' as exception_test;
import 'task_test.dart' as task_test;
import 'simple_scheduled_task_test.dart' as simple_scheduled_task_test;
import 'concurrent_task_scheduler_test.dart' as concurrent_task_scheduler_test;

void main() {
  group('Trigger Tests', trigger_test.main);
  group('Annotation Tests', annotation_test.main);
  group('Exception Tests', exception_test.main);
  group('Task Tests', task_test.main);
  group('SimpleScheduledTask Tests', simple_scheduled_task_test.main);
  group('ConcurrentTaskScheduler Tests', concurrent_task_scheduler_test.main);
}
