import 'dart:convert';
import 'dart:typed_data';

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

  /// Writes a dynamically-typed value preserving primitives, collections, and Durations.
  void writeDynamicValue(dynamic value) {
    if (value == null) {
      writeUint8(0);
    } else if (value is bool) {
      writeUint8(1);
      writeBool(value);
    } else if (value is int) {
      writeUint8(2);
      writeString(value.toString());
    } else if (value is double) {
      writeUint8(3);
      writeString(value.toString());
    } else if (value is String) {
      writeUint8(4);
      writeString(value);
    } else if (value is List) {
      writeUint8(5);
      writeUint32(value.length);
      for (final item in value) {
        writeDynamicValue(item);
      }
    } else if (value is Set) {
      writeUint8(6);
      writeUint32(value.length);
      for (final item in value) {
        writeDynamicValue(item);
      }
    } else if (value is Map) {
      writeUint8(7);
      writeUint32(value.length);
      for (final entry in value.entries) {
        writeDynamicValue(entry.key);
        writeDynamicValue(entry.value);
      }
    } else if (value is Duration) {
      writeUint8(8);
      writeString(value.inMicroseconds.toString());
    } else {
      writeUint8(4);
      writeString(value.toString());
    }
  }

  Uint8List toBytes() {
    return _bytes.toBytes();
  }
}