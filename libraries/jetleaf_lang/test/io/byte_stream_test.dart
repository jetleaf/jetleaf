import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'dart:typed_data';

import '../dependencies/exceptions.dart';

void main() {
  group('ByteStream Tests', () {
    test('fromList constructor', () async {
      ByteStream stream = ByteStream.fromList([72, 101, 108, 108, 111]);
      List<int> data = await stream.readAll();
      expect(data, equals([72, 101, 108, 108, 111]));
    });

    test('fromString constructor', () async {
      ByteStream stream = ByteStream.fromString("Hello");
      String result = await stream.readAllAsString();
      expect(result, equals("Hello"));
    });

    test('fromUint8List constructor', () async {
      Uint8List data = Uint8List.fromList([1, 2, 3, 4, 5]);
      ByteStream stream = ByteStream.fromUint8List(data);
      List<int> result = await stream.readAll();
      expect(result, equals([1, 2, 3, 4, 5]));
    });

    test('readAllAsUint8List', () async {
      ByteStream stream = ByteStream.fromList([1, 2, 3, 4, 5]);
      Uint8List result = await stream.readAllAsUint8List();
      expect(result, isA<Uint8List>());
      expect(result.toList(), equals([1, 2, 3, 4, 5]));
    });

    test('read specific count', () async {
      ByteStream stream = ByteStream.fromList([1, 2, 3, 4, 5]);
      List<int> result = await stream.read(3);
      expect(result, equals([1, 2, 3]));
    });

    test('empty stream with write operations', () async {
      ByteStream stream = ByteStream.empty();
      
      stream.write([72, 101, 108, 108, 111]);
      stream.writeString(" World");
      stream.writeByte(33); // !
      stream.close();
      
      List<int> result = await stream.readAll();
      String text = String.fromCharCodes(result);
      expect(text, equals("Hello World!"));
    });

    test('writeByte validation', () {
      ByteStream stream = ByteStream.empty();
      
      expect(() => stream.writeByte(256), throwsInvalidArgumentException);
      expect(() => stream.writeByte(-1), throwsInvalidArgumentException);
      expect(() => stream.writeByte(255), returnsNormally);
      expect(() => stream.writeByte(0), returnsNormally);
    });

    test('write to read-only stream throws error', () {
      ByteStream stream = ByteStream.fromList([1, 2, 3]);
      expect(() => stream.write([4, 5, 6]), throwsNoGuaranteeException);
    });

    test('map transformation', () async {
      ByteStream stream = ByteStream.fromList([1, 2, 3, 4, 5]);
      ByteStream mapped = stream.map((chunk) => chunk.map((b) => b * 2).toList());
      
      List<int> result = await mapped.readAll();
      expect(result, equals([2, 4, 6, 8, 10]));
    });

    test('where filtering', () async {
      ByteStream stream = ByteStream.fromList([1, 2, 3, 4, 5, 6]);
      ByteStream filtered = stream.where((chunk) => chunk.any((b) => b % 2 == 0));
      
      List<int> result = await filtered.readAll();
      expect(result, equals([1, 2, 3, 4, 5, 6])); // All chunks contain even numbers
    });

    test('skip and take', () async {
      ByteStream stream1 = ByteStream.fromArrays([[1, 2], [3, 4], [5, 6]]);
      ByteStream skipped = stream1.skip(1);
      List<int> result1 = await skipped.readAll();
      expect(result1, equals([3, 4, 5, 6]));
      
      ByteStream stream2 = ByteStream.fromArrays([[1, 2], [3, 4], [5, 6]]);
      ByteStream taken = stream2.take(2);
      List<int> result2 = await taken.readAll();
      expect(result2, equals([1, 2, 3, 4]));
    });

    test('concat static method', () async {
      ByteStream stream1 = ByteStream.fromList([1, 2, 3]);
      ByteStream stream2 = ByteStream.fromList([4, 5, 6]);
      ByteStream stream3 = ByteStream.fromList([7, 8, 9]);
      
      ByteStream concatenated = ByteStream.concat([stream1, stream2, stream3]);
      List<int> result = await concatenated.readAll();
      expect(result, equals([1, 2, 3, 4, 5, 6, 7, 8, 9]));
    });

    test('repeat static method', () async {
      ByteStream repeated = ByteStream.repeat([1, 2], 3);
      List<int> result = await repeated.readAll();
      expect(result, equals([1, 2, 1, 2, 1, 2]));
    });

    test('fromArrays static method', () async {
      ByteStream stream = ByteStream.fromArrays([[1, 2], [3, 4], [5, 6]]);
      List<int> result = await stream.readAll();
      expect(result, equals([1, 2, 3, 4, 5, 6]));
    });

    test('listen method', () async {
      ByteStream stream = ByteStream.fromList([1, 2, 3, 4, 5]);
      List<int> received = [];
      bool done = false;
      
      stream.listen(
        (data) => received.addAll(data),
        onDone: () => done = true,
      );
      
      // Wait a bit for the stream to complete
      await Future.delayed(Duration(milliseconds: 10));
      
      expect(received, equals([1, 2, 3, 4, 5]));
      expect(done, isTrue);
    });

    test('length property', () async {
      ByteStream stream = ByteStream.fromList([1, 2, 3, 4, 5]);
      int length = await stream.length;
      expect(length, equals(5));
    });

    test('toList method', () async {
      ByteStream stream = ByteStream.fromList([1, 2, 3, 4, 5]);
      List<int> result = await stream.toList();
      expect(result, equals([1, 2, 3, 4, 5]));
    });
  });
}
