import 'package:test/test.dart';

import 'env_test.dart' as env_test;
import 'advanced_env_test.dart' as advanced_env_test;
import 'command_line_args_test.dart' as command_line_args_test;
import 'property_source_test.dart' as property_source_test;
import 'profiles_test.dart' as profiles_test;
import 'application_arguments_test.dart' as application_arguments_test;
import 'property_source_ordering_test.dart' as property_source_ordering_test;
import 'jetleaf_property_test.dart' as jetleaf_property_test;

void main() {
  group('env', () {
    env_test.main();
  });
  group('advanced_env', () {
    advanced_env_test.main();
  });
  group('command_line_args', () {
    command_line_args_test.main();
  });
  group('property_source', () {
    property_source_test.main();
  });
  group('profiles', () {
    profiles_test.main();
  });
  group('application_arguments', () {
    application_arguments_test.main();
  });
  group('property_source_ordering', () {
    property_source_ordering_test.main();
  });
  group('jetleaf_property', () {
    jetleaf_property_test.main();
  });
}