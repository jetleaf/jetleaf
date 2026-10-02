import 'package:test/test.dart';

import 'string_utils_test.dart' as string_utils_test;
import 'trace_frame_test.dart' as trace_frame_test;
import 'exceptions_test.dart' as exceptions_test;
import 'assert_test.dart' as assert_test;
import 'parser/json_parser_test.dart' as json_parser_test;
import 'parser/yaml_parser_test.dart' as yaml_parser_test;
import 'parser/dart_parser_test.dart' as dart_parser_test;
import 'parser/xml_parser_test.dart' as xml_parser_test;
import 'parser/env_parser_test.dart' as env_parser_test;
import 'parser/properties_parser_test.dart' as properties_parser_test;
import 'parser/all_parser_test.dart' as all_parser_test;
import 'placeholder/placeholder_test.dart' as placeholder_test;

void main() {
  group('string_utils', () {
    string_utils_test.main();
  });
  group('trace_frame', () {
    trace_frame_test.main();
  });
  group('exceptions', () {
    exceptions_test.main();
  });
  group('assert', () {
    assert_test.main();
  });
  group('parser/json', () {
    json_parser_test.main();
  });
  group('parser/yaml', () {
    yaml_parser_test.main();
  });
  group('parser/dart', () {
    dart_parser_test.main();
  });
  group('parser/xml', () {
    xml_parser_test.main();
  });
  group('parser/env', () {
    env_parser_test.main();
  });
  group('parser/properties', () {
    properties_parser_test.main();
  });
  group('parser/all', () {
    all_parser_test.main();
  });
  group('placeholder', () {
    placeholder_test.main();
  });
}