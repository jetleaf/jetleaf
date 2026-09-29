import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';

class _MockInputStream extends InputStream {
  final Uint8List _data;
  int _pos = 0;

  _MockInputStream(String str) : _data = Uint8List.fromList(str.codeUnits);

  @override
  Future<int> read(List<int> b, [int offset = 0, int? length]) async {
    length ??= b.length - offset;
    if (_pos >= _data.length) return -1;
    final remaining = _data.length - _pos;
    final toRead = length.clamp(0, remaining);
    b.setRange(offset, offset + toRead, _data, _pos);
    _pos += toRead;
    return toRead;
  }

  @override
  Future<int> readByte() async {
    if (_pos >= _data.length) return -1;
    return _data[_pos++];
  }

  @override
  Future<int> skip(int n) async {
    final skipped = (n <= (_data.length - _pos)) ? n : (_data.length - _pos);
    _pos += skipped;
    return skipped;
  }

  @override
  Future<int> available() async => _data.length - _pos;
}

void main() {
  group('BufferedInputStream', () {
    test('reads bytes one by one', () async {
      final stream = BufferedInputStream(_MockInputStream('abc'), bufferSize: 2);
      expect(await stream.readByte(), equals('a'.codeUnitAt(0)));
      expect(await stream.readByte(), equals('b'.codeUnitAt(0)));
      expect(await stream.readByte(), equals('c'.codeUnitAt(0)));
      expect(await stream.readByte(), equals(-1));
      await stream.close();
    });

    test('reads into buffer with offset', () async {
      final stream = BufferedInputStream(_MockInputStream('abcdefg'), bufferSize: 4);
      final buffer = Uint8List(7);
      final count1 = await stream.read(buffer, 0, 4);
      expect(count1, equals(4));
      expect(String.fromCharCodes(buffer.sublist(0, 4)), equals('abcd'));
      final count2 = await stream.read(buffer, 4, 3);
      expect(count2, equals(3));
      expect(String.fromCharCodes(buffer), equals('abcdefg'));
      expect(await stream.read(buffer), equals(-1));
      await stream.close();
    });

    test('skip bytes correctly', () async {
      final stream = BufferedInputStream(_MockInputStream('abcdef'));
      expect(await stream.skip(3), equals(3));
      expect(await stream.readByte(), equals('d'.codeUnitAt(0)));
      await stream.close();
    });

    test('mark and reset', () async {
      final stream = BufferedInputStream(_MockInputStream('abcdef'), bufferSize: 4);
      expect(await stream.readByte(), equals('a'.codeUnitAt(0)));
      stream.mark(10);
      expect(await stream.readByte(), equals('b'.codeUnitAt(0)));
      expect(await stream.readByte(), equals('c'.codeUnitAt(0)));
      await stream.reset();
      expect(await stream.readByte(), equals('b'.codeUnitAt(0)));
      await stream.close();
    });

    test('available returns correct count', () async {
      final stream = BufferedInputStream(_MockInputStream('abc'));
      await stream.readByte();
      final avail = await stream.available();
      expect(avail, greaterThan(0));
      await stream.close();
    });

    test('bufferedCount returns correct value', () async {
      final stream = BufferedInputStream(_MockInputStream('12345'), bufferSize: 4);
      await stream.readByte();
      expect(stream.bufferedCount, inInclusiveRange(1, 3));
      await stream.close();
    });
  });
}