import 'dart:typed_data';

import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

@JetleafTest()
void main() {
  final service = DefaultConversionService();

  group('ByteMultiConverter', () {
    test('Byte to String', () {
      final byte = Byte.fromString('Hello');
      final result = service.convert<String>(byte, Class<String>());
      expect(result, 'Hello');
    });

    test('String to Byte', () {
      final result = service.convert<Byte>('Hello', Class<Byte>());
      expect(result.toString(), 'Hello');
    });

    test('Byte to List<int>', () {
      final byte = Byte.fromString('A'); // ASCII = 65
      final result = service.convert<List<int>>(byte, Class<List<int>>());
      expect(result, [65]);
    });

    test('List<int> to Byte (single element)', () {
      final source = [65];
      final result = service.convert<Byte>(source, Class<Byte>());
      expect(result.toString(), 'A');
    });

    test('Byte to Uint8List', () {
      final byte = Byte.fromString('B'); // ASCII = 66
      final result = service.convert<Uint8List>(byte, Class<Uint8List>());
      expect(result, Uint8List.fromList([66]));
    });

    test('Uint8List to Byte', () {
      final source = Uint8List.fromList([67]); // ASCII = 'C'
      final result = service.convert<Byte>(source, Class<Byte>());
      expect(result.toString(), 'C');
    });
  });
}