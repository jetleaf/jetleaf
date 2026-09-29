import 'dart:convert';
import 'dart:typed_data';

/// Reader for parsing binary data produced by [BinaryBuilder].
class BinaryReader {
  final Uint8List _data;
  int _offset = 0;

  BinaryReader(this._data);

  int readUint8() {
    final value = _data[_offset];
    _offset += 1;
    return value;
  }

  int readUint16() {
    final value = (_data[_offset] << 8) | _data[_offset + 1];
    _offset += 2;
    return value;
  }

  int readUint32() {
    final value = (_data[_offset] << 24) |
        (_data[_offset + 1] << 16) |
        (_data[_offset + 2] << 8) |
        _data[_offset + 3];
    _offset += 4;
    return value;
  }

  int readUint64() {
    int value = 0;
    for (var i = 0; i < 8; i++) {
      value = (value << 8) | _data[_offset + i];
    }
    _offset += 8;
    return value;
  }

  List<int> readBytes(int count) {
    final bytes = _data.sublist(_offset, _offset + count);
    _offset += count;
    return bytes;
  }

  /// Reads a length-prefixed string.
  String readString() {
    final length = readUint16();
    final bytes = _data.sublist(_offset, _offset + length);
    _offset += length;
    return utf8.decode(bytes);
  }

  bool readBool() {
    return readUint8() != 0;
  }
}

/// Builder for constructing binary data efficiently.
class BinaryBuilder {
  final BytesBuilder _bytes = BytesBuilder();

  void writeUint8(int value) {
    _bytes.addByte(value);
  }

  void writeUint16(int value) {
    _bytes.addByte((value >> 8) & 0xFF);
    _bytes.addByte(value & 0xFF);
  }

  void writeUint32(int value) {
    _bytes.addByte((value >> 24) & 0xFF);
    _bytes.addByte((value >> 16) & 0xFF);
    _bytes.addByte((value >> 8) & 0xFF);
    _bytes.addByte(value & 0xFF);
  }

  void writeUint64(int value) {
    _bytes.addByte((value >> 56) & 0xFF);
    _bytes.addByte((value >> 48) & 0xFF);
    _bytes.addByte((value >> 40) & 0xFF);
    _bytes.addByte((value >> 32) & 0xFF);
    _bytes.addByte((value >> 24) & 0xFF);
    _bytes.addByte((value >> 16) & 0xFF);
    _bytes.addByte((value >> 8) & 0xFF);
    _bytes.addByte(value & 0xFF);
  }

  void writeBytes(List<int> bytes) {
    _bytes.add(bytes);
  }

  /// Writes a length-prefixed string.
  void writeString(String s) {
    final encoded = utf8.encode(s);
    writeUint16(encoded.length);
    _bytes.add(encoded);
  }

  void writeBool(bool value) {
    _bytes.addByte(value ? 1 : 0);
  }

  Uint8List toBytes() {
    return _bytes.toBytes();
  }
}
