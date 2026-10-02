import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

class MockInputStream extends InputStream {
  final List<int> _data;
  int _position = 0;

  MockInputStream(this._data);

  @override
  Future<int> readByte() async {
    if (isClosed) throw StreamClosedException();
    if (_position >= _data.length) return -1;
    return _data[_position++];
  }
}

void main() {
  group('InputStream', () {
    test('readByte returns correct values and -1 at end', () async {
      final input = MockInputStream([1, 2]);
      expect(await input.readByte(), 1);
      expect(await input.readByte(), 2);
      expect(await input.readByte(), -1);
    });

    test('read fills buffer correctly', () async {
      final input = MockInputStream([1, 2, 3, 4]);
      final buffer = List.filled(4, 0);
      final bytesRead = await input.read(buffer);
      expect(bytesRead, 4);
      expect(buffer, [1, 2, 3, 4]);
    });

    test('readFully throws EndOfStreamException on short data', () async {
      final input = MockInputStream([1, 2]);
      expect(() => input.readFully(3), throwsA(isA<EndOfStreamException>()));
    });

    test('readAll reads all data', () async {
      final input = MockInputStream(List.generate(10, (i) => i));
      final data = await input.readAll();
      expect(data, equals(Uint8List.fromList(List.generate(10, (i) => i))));
    });

    test('skip skips correctly', () async {
      final input = MockInputStream([1, 2, 3, 4, 5]);
      final skipped = await input.skip(3);
      expect(skipped, 3);
      expect(await input.readByte(), 4);
    });

    test('read after close throws', () async {
      final input = MockInputStream([1]);
      await input.close();
      expect(() => input.readByte(), throwsA(isA<StreamClosedException>()));
    });
  });
}