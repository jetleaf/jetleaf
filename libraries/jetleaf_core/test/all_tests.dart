import 'package:test/test.dart';

import 'convert/all_tests.dart' as convert_tests;
import 'core/all_tests.dart' as core_tests;
import 'env/all_tests.dart' as env_tests;
import 'lang/all_tests.dart' as lang_tests;
import 'logging/all_tests.dart' as logging_tests;
import 'pod/all_tests.dart' as pod_tests;
import 'utils/all_tests.dart' as utils_tests;

void main() {
  group('Jetleaf Core Unit Tests', () {
    convert_tests.main();
    core_tests.main();
    env_tests.main();
    lang_tests.main();
    logging_tests.main();
    pod_tests.main();
    utils_tests.main();
  });
}