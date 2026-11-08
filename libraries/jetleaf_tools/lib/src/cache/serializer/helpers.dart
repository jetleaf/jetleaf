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

  /// Reads a dynamically-typed value preserving primitives, collections, and Durations.
  dynamic readDynamicValue() {
    final tag = readUint8();
    switch (tag) {
      case 0:
        return null;
      case 1:
        return readBool();
      case 2:
        return int.tryParse(readString()) ?? 0;
      case 3:
        return double.tryParse(readString()) ?? 0.0;
      case 4:
        return readString();
      case 5:
        final len = readUint32();
        final items = List<dynamic>.generate(len, (_) => readDynamicValue());
        if (items.isNotEmpty) {
          if (items.every((e) => e is String)) return items.cast<String>().toList();
          if (items.every((e) => e is int)) return items.cast<int>().toList();
          if (items.every((e) => e is double)) return items.cast<double>().toList();
          if (items.every((e) => e is bool)) return items.cast<bool>().toList();
        }
        return items;
      case 6:
        final len = readUint32();
        final items = <dynamic>{};
        for (var i = 0; i < len; i++) {
          items.add(readDynamicValue());
        }
        if (items.isNotEmpty) {
          if (items.every((e) => e is String)) return items.cast<String>().toSet();
          if (items.every((e) => e is int)) return items.cast<int>().toSet();
          if (items.every((e) => e is bool)) return items.cast<bool>().toSet();
        }
        return items;
      case 7:
        final len = readUint32();
        final map = <dynamic, dynamic>{};
        for (var i = 0; i < len; i++) {
          final k = readDynamicValue();
          final v = readDynamicValue();
          map[k] = v;
        }
        if (map.isNotEmpty && map.keys.every((k) => k is String)) {
          if (map.values.every((v) => v is String)) {
            return map.cast<String, String>();
          }
          return map.cast<String, dynamic>();
        }
        return map;
      case 8:
        final micros = int.tryParse(readString()) ?? 0;
        return Duration(microseconds: micros);
      default:
        return readString();
    }
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
