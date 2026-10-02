import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

void main() {
  group('FileInputStream', () {
    late File file;
    late FileInputStream stream;

    setUp(() async {
      file = File('test/io/tmp_input.dat');
      await file.writeAsBytes([1, 2, 3, 4, 5, 6, 7, 8]);
      stream = FileInputStream.fromFile(file);
    });

    tearDown(() async {
      await stream.close();
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('readByte reads individual bytes', () async {
      expect(await stream.readByte(), equals(1));
      expect(await stream.readByte(), equals(2));
    });

    test('read into buffer with offset and length', () async {
      final buffer = List<int>.filled(10, 0);
      final bytesRead = await stream.read(buffer, 2, 4);
      expect(bytesRead, equals(4));
      expect(buffer.sublist(2, 6), equals([1, 2, 3, 4]));
    });

    test('skip advances position', () async {
      final skipped = await stream.skip(5);
      expect(skipped, equals(5));
      expect(await stream.readByte(), equals(6));
    });

    test('available returns correct value', () async {
      await stream.readByte(); // read 1
      expect(await stream.available(), equals(7));
    });

    test('readAll returns full data', () async {
      final all = await stream.readAll();
      expect(all, equals([1, 2, 3, 4, 5, 6, 7, 8]));
    });

    test('position tracks correctly', () async {
      await stream.skip(3);
      expect(stream.position, equals(3));
      await stream.readByte();
      expect(stream.position, equals(4));
    });

    test('throws when reading closed stream', () async {
      await stream.close();
      expect(() => stream.readByte(), throwsException);
    });
  });
}