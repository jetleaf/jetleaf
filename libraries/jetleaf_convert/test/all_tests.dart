import 'package:test/test.dart';

import 'default_conversion_service_test.dart' as default_conversion_service_test;
import 'error_handling_test.dart' as error_handling_test;
import 'custom_converter_test.dart' as custom_converter_test;
import 'converting_comparator_test.dart' as converting_comparator_test;
import 'conversion_utils_test.dart' as conversion_utils_test;
import 'types/numeric_converter_test.dart' as numeric_converter_test;
import 'types/scalar_converter_test.dart' as scalar_converter_test;
import 'types/uri_and_regex_converter_test.dart' as uri_and_regex_converter_test;
import 'types/collection_converter_test.dart' as collection_converter_test;
import 'types/jl_converter_test.dart' as jl_converter_test;
import 'types/object_converter_test.dart' as object_converter_test;
import 'types/byte_converter_test.dart' as byte_converter_test;
import 'types/dart_converter_test.dart' as dart_converter_test;
import 'types/string_converter_test.dart' as string_converter_test;
import 'types/map_converter_test.dart' as map_converter_test;
import 'types/enum_converter_test.dart' as enum_converter_test;
import 'types/date_time_converter_test.dart' as date_time_converter_test;

void main() {
  group('default_conversion_service', () {
    default_conversion_service_test.main();
  });
  group('error_handling', () {
    error_handling_test.main();
  });
  group('custom_converter', () {
    custom_converter_test.main();
  });
  group('converting_comparator', () {
    converting_comparator_test.main();
  });
  group('conversion_utils', () {
    conversion_utils_test.main();
  });
  group('types/numeric', () {
    numeric_converter_test.main();
  });
  group('types/scalar', () {
    scalar_converter_test.main();
  });
  group('types/uri_and_regex', () {
    uri_and_regex_converter_test.main();
  });
  group('types/collection', () {
    collection_converter_test.main();
  });
  group('types/jl', () {
    jl_converter_test.main();
  });
  group('types/object', () {
    object_converter_test.main();
  });
  group('types/byte', () {
    byte_converter_test.main();
  });
  group('types/dart', () {
    dart_converter_test.main();
  });
  group('types/string', () {
    string_converter_test.main();
  });
  group('types/map', () {
    map_converter_test.main();
  });
  group('types/enum', () {
    enum_converter_test.main();
  });
  group('types/date_time', () {
    date_time_converter_test.main();
  });
}