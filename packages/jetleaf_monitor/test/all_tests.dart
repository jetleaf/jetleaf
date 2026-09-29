import 'package:test/test.dart';

import 'annotations_test.dart' as annotations_test;
import 'memory_analytics_test.dart' as memory_analytics_test;
import 'memory_reading_test.dart' as memory_reading_test;
import 'monitoring_report_test.dart' as monitoring_report_test;
import 'performance_resource_test.dart' as performance_resource_test;
import 'performance_test.dart' as performance_test;
import 'process_information_test.dart' as process_information_test;
import 'default_monitoring_service_test.dart' as default_monitoring_service_test;

void main() {
  group('Annotations Tests', annotations_test.main);
  group('Memory Reading Tests', memory_reading_test.main);
  group('Memory Analytics Tests', memory_analytics_test.main);
  group('Process Information Tests', process_information_test.main);
  group('Performance Tests', performance_test.main);
  group('Monitoring Report Tests', monitoring_report_test.main);
  group('Performance Resource Tests', performance_resource_test.main);
  group('Default Monitoring Service Tests', default_monitoring_service_test.main);
}
