import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

class MockOutputStream extends OutputStream {
  final List<int> _written = [];

  List<int> get written => _written;

  @override
  Future<void> writeByte(int b) async {
    if (isClosed) throw StreamClosedException();
    _written.add(b & 0xFF);
  }

  @override
  Future<void> writeObject(Object? obj) async {
    if (isClosed) throw StreamClosedException();
    writeString(obj.toString());
  }
}

void main() {
  group('OutputStream', () {
    late MockOutputStream output;

    setUp(() {
      output = MockOutputStream();
    });

    test('writeByte writes a single byte', () async {
      await output.writeByte(65);
      expect(output.written, [65]);
    });

    test('write writes multiple bytes', () async {
      await output.write([1, 2, 3, 4]);
      expect(output.written, [1, 2, 3, 4]);
    });

    test('write with offset and length', () async {
      await output.write([10, 20, 30, 40, 50], 1, 3);
      expect(output.written, [20, 30, 40]);
    });

    test('writeBytes writes a Uint8List', () async {
      await output.writeBytes(Uint8List.fromList([100, 101]));
      expect(output.written, [100, 101]);
    });

    test('writeString encodes string to UTF-8 bytes', () async {
      await output.writeString('ABC');
      expect(output.written, 'ABC'.codeUnits);
    });

    test('flush does not throw when stream is open', () async {
      expect(() => output.flush(), returnsNormally);
    });

    test('close flushes and prevents further writes', () async {
      await output.writeByte(1);
      await output.close();
      expect(output.isClosed, true);
      expect(() => output.writeByte(2), throwsA(isA<StreamClosedException>()));
    });

    test('write throws if offset or length is invalid', () async {
      expect(() => output.write([1, 2, 3], -1), throwsInvalidArgumentException);
      expect(() => output.write([1, 2, 3], 1, 5), throwsInvalidArgumentException);
    });
  });
}