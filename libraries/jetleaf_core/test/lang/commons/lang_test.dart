import 'package:test/test.dart';

import '../extensions/bool_extension_test.dart' as bool_extension_test;
import '../extensions/int_extension_test.dart' as int_extension_test;
import '../extensions/double_extension_test.dart' as double_extension_test;
import '../extensions/iterable_extension_test.dart' as iterable_extension_test;
import '../extensions/list_extension_test.dart' as list_extension_test;
import '../extensions/map_extension_test.dart' as map_extension_test;
import '../extensions/num_extension_test.dart' as num_extension_test;
import '../extensions/other_extension_test.dart' as other_extension_test;
import '../extensions/string_extension_test.dart' as string_extension_test;

import '../time/zoned_date_time_test.dart' as zoned_date_time_test;
import '../time/local_date_time_test.dart' as local_date_time_test;
import '../time/zone_id_test.dart' as zone_id_test;
import '../time/local_time_test.dart' as local_time_test;
import '../time/local_date_test.dart' as local_date_test;

import '../collections/array_list_test.dart' as array_list_test;
import '../collections/linked_list_test.dart' as linked_list_test;
import '../collections/stack_test.dart' as stack_test;
import '../collections/queue_test.dart' as queue_test;
import '../collections/linked_queue_test.dart' as linked_queue_test;
import '../collections/linked_stack_test.dart' as linked_stack_test;
import '../collections/hash_map_test.dart' as hash_map_test;
import '../collections/hash_set_test.dart' as hash_set_test;

import '../io/byte_stream_test.dart' as byte_stream_test;
import '../io/byte_array_test.dart' as byte_array_test;
import '../io/byte_test.dart' as byte_test;

import '../io_streams/buffered_input_stream_test.dart' as buffered_input_stream_test;
import '../io_streams/buffered_output_stream_test.dart' as buffered_output_stream_test;
import '../io_streams/buffered_reader_test.dart' as buffered_reader_test;
import '../io_streams/buffered_writer_test.dart' as buffered_writer_test;
import '../io_streams/file_input_stream_test.dart' as file_input_stream_test;
import '../io_streams/file_output_stream_test.dart' as file_output_stream_test;
import '../io_streams/file_reader_test.dart' as file_reader_test;
import '../io_streams/file_writer_test.dart' as file_writer_test;
import '../io_streams/input_stream_test.dart' as input_stream_test;
import '../io_streams/output_stream_test.dart' as output_stream_test;
import '../io_streams/reader_test.dart' as reader_test;
import '../io_streams/writer_test.dart' as writer_test;

import '../math/big_decimal_test.dart' as big_decimal_test;
import '../math/big_integer_test.dart' as big_integer_test;

import '../primitives/boolean_test.dart' as boolean_test;
import '../primitives/integer_test.dart' as integer_test;
import '../primitives/long_test.dart' as long_test;
import '../primitives/float_test.dart' as float_test;
import '../primitives/double_test.dart' as double_test;
import '../primitives/character_test.dart' as character_test;
import '../primitives/short_test.dart' as short_test;

import '../stream/collectors_test.dart' as collectors_test;
import '../stream/double_stream_test.dart' as double_stream_test;
import '../stream/int_stream_test.dart' as int_stream_test;
import '../stream/generic_stream_test.dart' as generic_stream_test;
import '../stream/stream_test.dart' as stream_test;
import '../stream/stream_builder_test.dart' as stream_builder_test;

import 'string_builder_test.dart' as string_builder_test;
import 'optional_test.dart' as optional_test;
import 'instance_test.dart' as instance_test;
import 'regex_utils_test.dart' as regex_utils_test;

void main() => group('Lang Tests', () {
  bool_extension_test.main();
  int_extension_test.main();
  double_extension_test.main();
  iterable_extension_test.main();
  list_extension_test.main();
  map_extension_test.main();
  num_extension_test.main();
  other_extension_test.main();
  string_extension_test.main();

  instance_test.main();
  regex_utils_test.main();

  zoned_date_time_test.main();
  local_date_time_test.main();
  zone_id_test.main();
  local_time_test.main();
  local_date_test.main();
  array_list_test.main();
  linked_list_test.main();
  stack_test.main();
  queue_test.main();
  linked_queue_test.main();
  linked_stack_test.main();
  hash_map_test.main();
  hash_set_test.main();
  big_decimal_test.main();
  big_integer_test.main();
  boolean_test.main();
  byte_stream_test.main();
  byte_array_test.main();
  byte_test.main();
  integer_test.main();
  long_test.main();
  float_test.main();
  double_test.main();
  character_test.main();
  short_test.main();
  string_builder_test.main();
  optional_test.main();

  buffered_input_stream_test.main();
  buffered_output_stream_test.main();
  buffered_reader_test.main();
  buffered_writer_test.main();
  file_input_stream_test.main();
  file_output_stream_test.main();
  file_reader_test.main();
  file_writer_test.main();
  input_stream_test.main();
  output_stream_test.main();
  reader_test.main();
  writer_test.main();

  collectors_test.main();
  double_stream_test.main();
  int_stream_test.main();
  generic_stream_test.main();
  stream_test.main();
  stream_builder_test.main();
});