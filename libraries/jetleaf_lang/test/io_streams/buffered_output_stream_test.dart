import 'dart:io';
import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

void main() {
  group('BufferedOutputStream', () {
    late String tempPath;

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('output_test');
      tempPath = '${dir.path}/output.bin';
    });

    tearDown(() async {
      final file = File(tempPath);
      if (await file.exists()) await file.delete();
    });

    test('writes single bytes and flushes correctly', () async {
      final output = BufferedOutputStream(FileOutputStream(tempPath), bufferSize: 4);
      await output.writeByte(65); // 'A'
      await output.writeByte(66); // 'B'
      expect(output.bufferedCount, equals(2));
      await output.flush();
      expect(output.bufferedCount, equals(0));
      await output.close();

      final content = await File(tempPath).readAsBytes();
      expect(content, equals([65, 66]));
    });

    test('writes full buffer and flushes automatically', () async {
      final output = BufferedOutputStream(FileOutputStream(tempPath), bufferSize: 2);
      await output.writeByte(1);
      await output.writeByte(2);
      await output.writeByte(3); // Triggers auto flush
      await output.flush();
      await output.close();

      final content = await File(tempPath).readAsBytes();
      expect(content, equals([1, 2, 3]));
    });

    test('writes large data directly when bigger than buffer', () async {
      final output = BufferedOutputStream(FileOutputStream(tempPath), bufferSize: 4);
      final data = Uint8List.fromList(List.generate(10, (i) => i));
      await output.write(data);
      await output.close();

      final content = await File(tempPath).readAsBytes();
      expect(content, equals(data));
    });

    test('write with offset and length', () async {
      final output = BufferedOutputStream(FileOutputStream(tempPath), bufferSize: 6);
      final data = [0, 1, 2, 3, 4, 5, 6];
      await output.write(data, 2, 4); // write 2,3,4,5
      await output.flush();
      await output.close();

      final content = await File(tempPath).readAsBytes();
      expect(content, equals([2, 3, 4, 5]));
    });

    test('close flushes and closes underlying stream', () async {
      final output = BufferedOutputStream(FileOutputStream(tempPath));
      await output.writeByte(99);
      await output.close();

      final content = await File(tempPath).readAsBytes();
      expect(content, equals([99]));
    });

    test('bufferedCount and remainingBufferSpace work correctly', () async {
      final output = BufferedOutputStream(FileOutputStream(tempPath), bufferSize: 3);
      await output.writeByte(1);
      expect(output.bufferedCount, equals(1));
      expect(output.remainingBufferSpace, equals(2));
      await output.writeByte(2);
      expect(output.bufferedCount, equals(2));
      expect(output.remainingBufferSpace, equals(1));
      await output.flush();
      expect(output.bufferedCount, equals(0));
      expect(output.remainingBufferSpace, equals(3));
      await output.close();
    });
  });
}