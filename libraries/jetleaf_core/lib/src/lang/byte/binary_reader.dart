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
    final value = _data[_offset];
    _offset += 1;
    return value != 0;
  }

  /// Reads a dynamically-typed value preserving primitives, collections, and Durations.
  dynamic readDynamicValue() {
    final type = readUint8();
    switch (type) {
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
        final items = <dynamic>[];
        for (var i = 0; i < len; i++) {
          items.add(readDynamicValue());
        }
        if (items.isNotEmpty) {
          if (items.every((e) => e is String)) return items.cast<String>();
          if (items.every((e) => e is int)) return items.cast<int>();
          if (items.every((e) => e is bool)) return items.cast<bool>();
        }
        return items;
      case 6:
        final len = readUint32();
        final items = <dynamic>[];
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