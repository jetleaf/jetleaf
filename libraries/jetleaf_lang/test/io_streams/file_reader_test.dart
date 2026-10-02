import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('FileReader', () {
    late File file;
    late FileReader reader;

    setUp(() async {
      file = File('test/io/tmp_text.txt');
      await file.writeAsString('Line1\nLine2\nLine3\nLine4\n');
      reader = FileReader.fromFile(file);
    });

    tearDown(() async {
      await reader.close();
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('readChar returns characters correctly', () async {
      final firstChar = await reader.readChar();
      expect(String.fromCharCode(firstChar), equals('L'));

      final chars = <int>[];
      for (int i = 0; i < 4; i++) {
        chars.add(await reader.readChar());
      }
      expect(String.fromCharCodes(chars), equals('ine1'));
    });

    test('read reads into buffer with offset and length', () async {
      final buffer = List<int>.filled(20, 0);
      final readCount = await reader.read(buffer, 5, 4);
      expect(readCount, equals(4));
      final text = String.fromCharCodes(buffer.sublist(5, 9));
      expect(text, equals('Line'));
    });

    test('readLine reads lines correctly', () async {
      expect(await reader.readLine(), equals('Line1'));
      expect(await reader.readLine(), equals('Line2'));
      expect(await reader.readLine(), equals('Line3'));
      expect(await reader.readLine(), equals('Line4'));
      expect(await reader.readLine(), isNull);
    });

    test('readAll reads remaining content', () async {
      await reader.readLine();
      final rest = await reader.readAll();
      expect(rest.trim(), contains('Line2'));
      expect(rest.trim(), contains('Line3'));
      expect(rest.trim(), contains('Line4'));
    });

    test('skip moves the position forward', () async {
      final skipped = await reader.skip(6); // "Line1\n"
      expect(skipped, equals(6));
      final nextLine = await reader.readLine();
      expect(nextLine, equals('Line2'));
    });

    test('ready returns true when data is available', () async {
      final isReady = await reader.ready();
      expect(isReady, isTrue);
      await reader.readAll();
      expect(await reader.ready(), isFalse);
    });

    test('close closes the stream and throws on access', () async {
      await reader.close();
      expect(() => reader.readChar(), throwsA(isA<StreamClosedException>()));
    });

    test('position tracks correctly', () async {
      await reader.readChar(); // L
      await reader.readChar(); // i
      expect(reader.position, equals(2));
      await reader.readLine(); // ne1
      expect(reader.position, greaterThan(2));
    });

    test('file and encoding getters', () {
      expect(reader.file, equals(file));
      expect(reader.encoding, equals(Closeable.DEFAULT_ENCODING));
    });

    test('throws IOException on invalid file', () async {
      final invalid = FileReader('nonexistent.txt');
      expect(() => invalid.readLine(), throwsA(isA<IOException>()));
    });

    test('throws InvalidArgumentException for invalid read() arguments', () async {
      final buffer = List<int>.filled(5, 0);
      expect(() async => await reader.read(buffer, -1, 2), throwsInvalidArgumentException);
      expect(() async => await reader.read(buffer, 0, 6), throwsInvalidArgumentException);
    });
  });
}