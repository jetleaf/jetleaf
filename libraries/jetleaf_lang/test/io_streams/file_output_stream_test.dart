import 'dart:io';

import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

void main() {
  group('FileOutputStream', () {
    late File file;

    setUp(() {
      file = File('test/io/tmp_output.dat');
    });

    tearDown(() async {
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('writeByte writes single byte', () async {
      final out = FileOutputStream.fromFile(file);
      await out.writeByte(0x7F);
      await out.close();

      expect(await file.readAsBytes(), equals([0x7F]));
    });

    test('write writes full list', () async {
      final out = FileOutputStream.fromFile(file);
      await out.write([1, 2, 3, 4]);
      await out.close();

      final bytes = await file.readAsBytes();
      expect(bytes, equals([1, 2, 3, 4]));
    });

    test('write with offset and length', () async {
      final out = FileOutputStream.fromFile(file);
      await out.write([9, 8, 7, 6, 5], 1, 3); // should write 8, 7, 6
      await out.close();

      expect(await file.readAsBytes(), equals([8, 7, 6]));
    });

    test('append mode appends data', () async {
      await file.writeAsBytes([1, 2, 3]);
      final out = FileOutputStream.fromFile(file, append: true);
      await out.write([4, 5]);
      await out.close();

      expect(await file.readAsBytes(), equals([1, 2, 3, 4, 5]));
    });

    test('flush does not throw', () async {
      final out = FileOutputStream.fromFile(file);
      await out.writeByte(1);
      await out.flush();
      await out.close();

      expect(await file.readAsBytes(), equals([1]));
    });

    test('position updates correctly', () async {
      final out = FileOutputStream.fromFile(file);
      expect(out.position, equals(0));
      await out.writeByte(2);
      expect(out.position, equals(1));
      await out.write([1, 2, 3]);
      expect(out.position, equals(4));
      await out.close();
    });

    test('isAppendMode reflects true or false', () {
      final out1 = FileOutputStream.fromFile(file);
      final out2 = FileOutputStream.fromFile(file, append: true);
      expect(out1.isAppendMode, isFalse);
      expect(out2.isAppendMode, isTrue);
    });
  });
}