import 'package:test/test.dart';

import 'jetson_test.dart' as jetson_test;
import 'string_json_generator_test.dart' as string_json_generator_test;
import 'string_json_parser_test.dart' as string_json_parser_test;
import 'json_validator_test.dart' as json_validator_test;
import 'naming_strategies_test.dart' as naming_strategies_test;
import 'json_nodes_test.dart' as json_nodes_test;
import 'exceptions_test.dart' as exceptions_test;

void main() {
  group('jetson', () {
    jetson_test.main();
  });
  group('string_json_generator', () {
    string_json_generator_test.main();
  });
  group('string_json_parser', () {
    string_json_parser_test.main();
  });
  group('json_validator', () {
    json_validator_test.main();
  });
  group('naming_strategies', () {
    naming_strategies_test.main();
  });
  group('json_nodes', () {
    json_nodes_test.main();
  });
  group('exceptions', () {
    exceptions_test.main();
  });
}