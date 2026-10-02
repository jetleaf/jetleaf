import 'package:test/test.dart';

import 'banner_test.dart' as banner_test;
import 'context_test.dart' as context_test;
import 'env_test.dart' as env_test;
import 'entry_test.dart' as entry_test;
import 'exception_handler_test.dart' as exception_handler_test;
import 'jetleaf_application_test.dart' as jetleaf_application_test;
import 'jetleaf_exception_test.dart' as jetleaf_exception_test;
import 'jetleaf_version_test.dart' as jetleaf_version_test;
import 'listener_test.dart' as listener_test;
import 'logging_test.dart' as logging_test;
import 'pod_factory_post_processor_test.dart' as pod_factory_post_processor_test;
import 'shutdown_test.dart' as shutdown_test;

void main() {
  group('Banner Tests', banner_test.main);
  group('Context Tests', context_test.main);
  group('Environment Tests', env_test.main);
  group('Entry Tests', entry_test.main);
  group('Exception Handler Tests', exception_handler_test.main);
  group('Jetleaf Application Tests', jetleaf_application_test.main);
  group('Jetleaf Exception Tests', jetleaf_exception_test.main);
  group('Jetleaf Version Tests', jetleaf_version_test.main);
  group('Listener Tests', listener_test.main);
  group('Logging Tests', logging_test.main);
  group('Pod Factory Post Processor Tests', pod_factory_post_processor_test.main);
  group('Shutdown Tests', shutdown_test.main);
}
