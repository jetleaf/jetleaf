import 'dart:async';
import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

import '../dependencies/exceptions.dart';

class MockReader extends Reader {
  final List<int> _chars;
  int _index = 0;

  MockReader(String input) : _chars = input.codeUnits;

  @override
  Future<int> readChar() async {
    if (isClosed) throw StreamClosedException();
    return _index < _chars.length ? _chars[_index++] : -1;
  }
}

void main() {
  group('Reader', () {
    test('readChar returns characters and -1 at end', () async {
      final reader = MockReader('abc');
      expect(await reader.readChar(), 'a'.codeUnitAt(0));
      expect(await reader.readChar(), 'b'.codeUnitAt(0));
      expect(await reader.readChar(), 'c'.codeUnitAt(0));
      expect(await reader.readChar(), -1);
    });

    test('read reads into buffer correctly', () async {
      final reader = MockReader('hello');
      final buffer = List<int>.filled(5, 0);
      final count = await reader.read(buffer);
      expect(count, 5);
      expect(String.fromCharCodes(buffer), 'hello');
    });

    test('read with offset and length', () async {
      final reader = MockReader('world');
      final buffer = List<int>.filled(10, 0);
      final count = await reader.read(buffer, 3, 5);
      expect(count, 5);
      expect(String.fromCharCodes(buffer.sublist(3, 8)), 'world');
    });

    test('readLine reads single line', () async {
      final reader = MockReader('first\nsecond');
      final line = await reader.readLine();
      expect(line, 'first');
      expect(await reader.readLine(), 'second');
    });

    test('readAll reads full text', () async {
      final reader = MockReader('complete content');
      final all = await reader.readAll();
      expect(all, 'complete content');
    });

    test('skip skips characters', () async {
      final reader = MockReader('1234567890');
      final skipped = await reader.skip(4);
      expect(skipped, 4);
      expect(await reader.readChar(), '5'.codeUnitAt(0));
    });

    test('ready returns false by default', () async {
      final reader = MockReader('anything');
      expect(await reader.ready(), isFalse);
    });

    test('markSupported returns false', () {
      final reader = MockReader('...');
      expect(reader.markSupported(), isFalse);
    });

    test('reset throws IOException by default', () async {
      final reader = MockReader('...');
      expect(() => reader.reset(), throwsA(isA<IOException>()));
    });

    test('close sets isClosed and prevents read', () async {
      final reader = MockReader('data');
      await reader.close();
      expect(reader.isClosed, isTrue);
      expect(() => reader.readChar(), throwsA(isA<StreamClosedException>()));
    });

    test('read throws InvalidArgumentException on bad offset/length', () async {
      final reader = MockReader('bad');
      final buffer = List<int>.filled(5, 0);
      expect(() => reader.read(buffer, -1, 3), throwsInvalidArgumentException);
      expect(() => reader.read(buffer, 1, 10), throwsInvalidArgumentException);
    });
  });
}