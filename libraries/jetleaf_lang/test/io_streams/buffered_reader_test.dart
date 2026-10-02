import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

void main() {
  group('BufferedReader', () {
    late String tempPath;

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('reader_test');
      tempPath = '${dir.path}/sample.txt';
    });

    tearDown(() async {
      final file = File(tempPath);
      if (await file.exists()) await file.delete();
    });

    test('reads characters one by one', () async {
      await File(tempPath).writeAsString('abc');
      final reader = BufferedReader(FileReader(tempPath), bufferSize: 2);

      expect(await reader.readChar(), equals('a'.codeUnitAt(0)));
      expect(await reader.readChar(), equals('b'.codeUnitAt(0)));
      expect(await reader.readChar(), equals('c'.codeUnitAt(0)));
      expect(await reader.readChar(), equals(-1));

      await reader.close();
    });

    test('reads lines correctly', () async {
      await File(tempPath).writeAsString('line1\nline2\r\nline3');
      final reader = BufferedReader(FileReader(tempPath), bufferSize: 5);

      expect(await reader.readLine(), equals('line1'));
      expect(await reader.readLine(), equals('line2'));
      expect(await reader.readLine(), equals('line3'));
      expect(await reader.readLine(), isNull);

      await reader.close();
    });

    test('reads into buffer with offsets', () async {
      await File(tempPath).writeAsString('abcdef');
      final reader = BufferedReader(FileReader(tempPath), bufferSize: 3);
      final buffer = List<int>.filled(6, 0);

      final count1 = await reader.read(buffer, 0, 4);
      expect(count1, equals(4));
      expect(String.fromCharCodes(buffer.take(4)), equals('abcd'));

      final count2 = await reader.read(buffer, 4, 2);
      expect(count2, equals(2));
      expect(String.fromCharCodes(buffer), equals('abcdef'));

      expect(await reader.read(buffer), equals(-1));
      await reader.close();
    });

    test('skip skips correctly', () async {
      await File(tempPath).writeAsString('abcdef');
      final reader = BufferedReader(FileReader(tempPath));

      expect(await reader.skip(3), equals(3));
      final char = await reader.readChar();
      expect(char, equals('d'.codeUnitAt(0)));

      await reader.close();
    });

    test('ready returns true if data available', () async {
      await File(tempPath).writeAsString('hi');
      final reader = BufferedReader(FileReader(tempPath));
      expect(await reader.ready(), isTrue);
      await reader.close();
    });

    test('readLine handles \r and \r\n properly across buffers', () async {
      await File(tempPath).writeAsString('first\rsecond\r\nthird');
      final reader = BufferedReader(FileReader(tempPath), bufferSize: 6);

      expect(await reader.readLine(), equals('first'));
      expect(await reader.readLine(), equals('second'));
      expect(await reader.readLine(), equals('third'));
      expect(await reader.readLine(), isNull);

      await reader.close();
    });
  });
}