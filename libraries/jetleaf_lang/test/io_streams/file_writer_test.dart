import 'dart:convert';
import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import '../dependencies/exceptions.dart';

void main() {
  group('FileWriter', () {
    late File file;
    late FileWriter writer;

    setUp(() {
      file = File('test/io/tmp_output.txt');
      if (file.existsSync()) file.deleteSync();
    });

    tearDown(() async {
      await writer.close();
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('writeChar and flush writes single characters', () async {
      writer = FileWriter.fromFile(file);
      await writer.writeChar('A'.codeUnitAt(0));
      expect(writer.bufferedCount, 1);
      await writer.flush();
      expect(writer.bufferedCount, 0);
      expect(await file.readAsString(), 'A');
    });

    test('writeChars writes a range of characters', () async {
      writer = FileWriter.fromFile(file);
      final chars = 'Hello, Dart!'.codeUnits;
      await writer.writeChars(chars, 7, 4); // Dart
      await writer.flush();
      expect(await file.readAsString(), 'Dart');
    });

    test('write with offset and length works correctly', () async {
      writer = FileWriter.fromFile(file);
      await writer.write('Programming', 3, 5); // gramm
      await writer.flush();
      expect(await file.readAsString(), 'gramm');
    });

    test('flush writes the buffer to the file', () async {
      writer = FileWriter.fromFile(file);
      await writer.write('Buffered');
      expect(writer.bufferedCount, greaterThan(0));
      await writer.flush();
      expect(writer.bufferedCount, equals(0));
      expect(await file.readAsString(), 'Buffered');
    });

    test('close flushes and closes the file', () async {
      writer = FileWriter.fromFile(file);
      await writer.write('Final');
      await writer.close();
      expect(await file.readAsString(), 'Final');
      expect(() => writer.write('Fail'), throwsA(isA<StreamClosedException>()));
    });

    test('append mode writes to the end of file', () async {
      file.writeAsStringSync('Start\n');
      writer = FileWriter.fromFile(file, append: true);
      await writer.write('Appended');
      await writer.flush();
      final content = await file.readAsString();
      expect(content, contains('Start'));
      expect(content, endsWith('Appended'));
    });

    test('throws InvalidArgumentException for invalid writeChars args', () async {
      writer = FileWriter.fromFile(file);
      final buffer = [65, 66, 67];
      expect(() => writer.writeChars(buffer, -1, 2), throwsInvalidArgumentException);
      expect(() => writer.writeChars(buffer, 0, 5), throwsInvalidArgumentException);
    });

    test('throws InvalidArgumentException for invalid write() args', () async {
      writer = FileWriter.fromFile(file);
      expect(() => writer.write('Hi', -1, 1), throwsInvalidArgumentException);
      expect(() => writer.write('Hi', 0, 5), throwsInvalidArgumentException);
    });

    test('file, encoding, appendMode, position getters', () async {
      writer = FileWriter.fromFile(file, append: true, encoding: Encoding.getByName('utf-8')!);
      await writer.write('Hello');
      await writer.flush();
      expect(writer.file, file);
      expect(writer.encoding, Encoding.getByName('utf-8')!);
      expect(writer.isAppendMode, isTrue);
      expect(writer.position, greaterThan(0));
    });

    test('throws IOException when writing to invalid file', () async {
      final invalid = FileWriter('/invalid/path/file.txt');
      expect(() => invalid.write('fail'), throwsA(isA<IOException>()));
    });
  });
}