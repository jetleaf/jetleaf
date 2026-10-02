import 'package:test/test.dart';

import 'declaration/mixin_declaration_test.dart' as mixin_declaration_test;
import 'declaration/method_declaration_test.dart' as method_declaration_test;
import 'declaration/class_declaration_test.dart' as class_declaration_test;
import 'declaration/constructor_declaration_test.dart' as constructor_declaration_test;
import 'declaration/parameter_declaration_test.dart' as parameter_declaration_test;
import 'declaration/field_declaration_test.dart' as field_declaration_test;
import 'declaration/annotation_declaration_test.dart' as annotation_declaration_test;
import 'declaration/enum_declaration_test.dart' as enum_declaration_test;
import 'declaration/record_declaration_test.dart' as record_declaration_test;
import 'runtime_hint/runtime_hint_test.dart' as runtime_hint_test;
import 'helpers/advanced_test.dart' as advanced_test;
import 'helpers/simple_equals_and_hash_code_test.dart' as simple_equals_and_hash_code_test;
import 'helpers/more_test.dart' as more_test;
import 'helpers/to_string_test.dart' as to_string_test;
import 'helpers/deep_test.dart' as deep_test;
import 'helpers/equals_and_hash_code_test.dart' as equals_and_hash_code_test;
import 'generic_parser_test.dart' as generic_parser_test;
import 'runtime/declaration_test.dart' as declaration_test;
import 'runtime/reflection_utils_test.dart' as reflection_utils_test;
import 'runtime/utils_test.dart' as utils_test;
import 'cache/cache_serializer_test.dart' as cache_serializer_test;
import 'vm/discoverable_test.dart' as discoverable_test;
import 'vm/entry_writer_test.dart' as entry_writer_test;
import 'vm/jetleaf_vm_file_test.dart' as jetleaf_vm_file_test;
import 'vm/packages_json_test.dart' as packages_json_test;

void main() {
  group('declaration/mixin', () {
    mixin_declaration_test.main();
  });
  group('declaration/method', () {
    method_declaration_test.main();
  });
  group('declaration/class', () {
    class_declaration_test.main();
  });
  group('declaration/constructor', () {
    constructor_declaration_test.main();
  });
  group('declaration/parameter', () {
    parameter_declaration_test.main();
  });
  group('declaration/field', () {
    field_declaration_test.main();
  });
  group('declaration/annotation', () {
    annotation_declaration_test.main();
  });
  group('declaration/enum', () {
    enum_declaration_test.main();
  });
  group('declaration/record', () {
    record_declaration_test.main();
  });
  group('runtime_hint', () {
    runtime_hint_test.main();
  });
  group('helpers/advanced', () {
    advanced_test.main();
  });
  group('helpers/simple_equals_and_hash_code', () {
    simple_equals_and_hash_code_test.main();
  });
  group('helpers/more', () {
    more_test.main();
  });
  group('helpers/to_string', () {
    to_string_test.main();
  });
  group('helpers/deep', () {
    deep_test.main();
  });
  group('helpers/equals_and_hash_code', () {
    equals_and_hash_code_test.main();
  });
  group('generic_parser', () {
    generic_parser_test.main();
  });
  group('runtime/declaration', () {
    declaration_test.main();
  });
  group('runtime/reflection_utils', () {
    reflection_utils_test.main();
  });
  group('runtime/utils', () {
    utils_test.main();
  });
  group('cache/cache_serializer', () {
    cache_serializer_test.main();
  });
  group('vm/discoverable', () {
    discoverable_test.main();
  });
  group('vm/entry_writer', () {
    entry_writer_test.main();
  });
  group('vm/jetleaf_vm_file', () {
    jetleaf_vm_file_test.main();
  });
  group('vm/packages_json', () {
    packages_json_test.main();
  });
}
