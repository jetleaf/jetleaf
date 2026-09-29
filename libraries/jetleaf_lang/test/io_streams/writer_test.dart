import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

class MockWriter extends Writer {
  final StringBuffer buffer = StringBuffer();
  bool flushed = false;

  @override
  Future<void> writeChar(int c) async {
    if (isClosed) throw StreamClosedException();
    buffer.writeCharCode(c);
  }

  @override
  Future<void> flush() async {
    if (isClosed) throw StreamClosedException();
    flushed = true;
  }

  @override
  Future<void> close() async {
    if (isClosed) throw StreamClosedException();
    await super.close();
    flushed = true;
  }
}

void main() {
  group('Writer', () {
    test('writeChar writes character', () async {
      final writer = MockWriter();
      await writer.writeChar('A'.codeUnitAt(0));
      expect(writer.buffer.toString(), 'A');
    });

    test('writeChars writes list of chars', () async {
      final writer = MockWriter();
      await writer.writeChars('Hello'.codeUnits);
      expect(writer.buffer.toString(), 'Hello');
    });

    test('write writes string with offset and length', () async {
      final writer = MockWriter();
      await writer.write('Hello, World!', 7, 5);
      expect(writer.buffer.toString(), 'World');
    });

    test('writeLine writes string and newline', () async {
      final writer = MockWriter();
      await writer.writeLine('Line 1');
      expect(writer.buffer.toString(), 'Line 1\n');
    });

    test('writeLine with null writes "null" and newline', () async {
      final writer = MockWriter();
      await writer.write('null');
      await writer.writeLine();
      expect(writer.buffer.toString(), 'null\n');
    });

    test('writeObject writes object string representation', () async {
      final writer = MockWriter();
      await writer.writeObject(42);
      expect(writer.buffer.toString(), '42');
    });

    test('append writes single char and returns writer', () async {
      final writer = MockWriter();
      final returned = await writer.append('Z'.codeUnitAt(0));
      expect(writer.buffer.toString(), 'Z');
      expect(returned, same(writer));
    });

    test('appendString appends a string and returns writer', () async {
      final writer = MockWriter();
      final returned = await writer.appendString('Yo');
      expect(writer.buffer.toString(), 'Yo');
      expect(returned, same(writer));
    });

    test('flush sets flushed flag', () async {
      final writer = MockWriter();
      await writer.flush();
      expect(writer.flushed, isTrue);
    });

    test('close sets isClosed and flushes', () async {
      final writer = MockWriter();
      expect(writer.isClosed, isFalse);
      await writer.close();
      expect(writer.isClosed, isTrue);
      expect(writer.flushed, isTrue);
    });

    test('write after close throws', () async {
      final writer = MockWriter();
      await writer.close();
      expect(() => writer.write('Oops'), throwsA(isA<StreamClosedException>()));
    });

    test('writeChars throws on invalid offset/length', () async {
      final writer = MockWriter();
      final chars = 'hello'.codeUnits;
      expect(() => writer.writeChars(chars, -1), throwsInvalidArgumentException);
      expect(() => writer.writeChars(chars, 0, 10), throwsInvalidArgumentException);
    });

    test('write throws on invalid offset/length', () async {
      final writer = MockWriter();
      expect(() => writer.write('hi', -1), throwsInvalidArgumentException);
      expect(() => writer.write('hi', 1, 10), throwsInvalidArgumentException);
    });
  });
}