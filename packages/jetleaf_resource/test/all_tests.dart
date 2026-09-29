import 'package:test/test.dart';

import 'annotations_test.dart' as annotations_test;
import 'base_test.dart' as base_test;
import 'cache_event_test.dart' as cache_event_test;
import 'cache_eviction_test.dart' as cache_eviction_test;
import 'cache_metrics_test.dart' as cache_metrics_test;
import 'cache_storage_test.dart' as cache_storage_test;
import 'error_handler_test.dart' as error_handler_test;
import 'key_generator_test.dart' as key_generator_test;
import 'rate_limit_test.dart' as rate_limit_test;

void main() {
  group('Annotations Tests', annotations_test.main);
  group('Base Tests', base_test.main);
  group('Cache Event Tests', cache_event_test.main);
  group('Cache Eviction Tests', cache_eviction_test.main);
  group('Cache Metrics Tests', cache_metrics_test.main);
  group('Cache Storage Tests', cache_storage_test.main);
  group('Error Handler Tests', error_handler_test.main);
  group('Key Generator Tests', key_generator_test.main);
  group('Rate Limit Tests', rate_limit_test.main);
}
