import 'dart:convert';

import '../../helpers/equals_and_hash_code.dart';

// ====================================================== SUBCLASS ENTRY ===================================================

/// A single entry in the subclass graph: maps a parent qualified name
/// to its direct children.
class SubClassEntry with EqualsAndHashCode {
  /// The qualified name of the parent class.
  final String parentQualifiedName;

  /// The qualified names of direct children (subclasses, implementors, mixers).
  final List<String> childQualifiedNames;

  const SubClassEntry({
    required this.parentQualifiedName,
    required this.childQualifiedNames,
  });

  /// Creates a [SubClassEntry] from a JSON map.
  factory SubClassEntry.fromJson(Map<String, dynamic> json) {
    return SubClassEntry(
      parentQualifiedName: json['parentQualifiedName'] as String,
      childQualifiedNames: (json['childQualifiedNames'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  /// Converts this entry to a JSON map.
  Map<String, dynamic> toJson() => {
    'parentQualifiedName': parentQualifiedName,
    'childQualifiedNames': childQualifiedNames,
  };

  /// Serializes this entry to a compact binary format.
  List<int> serialize() {
    final bytes = <int>[];
    _writeString(bytes, parentQualifiedName);
    bytes.add(childQualifiedNames.length);
    for (final child in childQualifiedNames) {
      _writeString(bytes, child);
    }
    return bytes;
  }

  /// Deserializes a [SubClassEntry] from binary data starting at [offset].
  /// Returns the entry and the new offset.
  static (SubClassEntry, int) deserialize(List<int> data, int offset) {
    final (parentQn, newOffset) = _readString(data, offset);
    final childCount = data[newOffset];
    var currentOffset = newOffset + 1;
    final children = <String>[];
    for (var i = 0; i < childCount; i++) {
      final (child, nextOffset) = _readString(data, currentOffset);
      children.add(child);
      currentOffset = nextOffset;
    }
    return (
      SubClassEntry(parentQualifiedName: parentQn, childQualifiedNames: children),
      currentOffset,
    );
  }

  @override
  List<Object?> equalizedProperties() => [parentQualifiedName, childQualifiedNames];
}

// =================================================== ANNOTATED METHOD ENTRY ================================================

/// A single entry representing a method annotated with a specific annotation.
class AnnotatedMethodEntry with EqualsAndHashCode {
  /// The simple name of the annotation.
  final String annotationName;

  /// The simple name of the class containing the method.
  final String className;

  /// The simple name of the method.
  final String methodName;

  /// The URI of the library containing the class.
  final String uri;

  const AnnotatedMethodEntry({
    required this.annotationName,
    required this.className,
    required this.methodName,
    required this.uri,
  });

  /// Creates an [AnnotatedMethodEntry] from a JSON map.
  factory AnnotatedMethodEntry.fromJson(Map<String, dynamic> json) {
    return AnnotatedMethodEntry(
      annotationName: json['annotationName'] as String,
      className: json['className'] as String,
      methodName: json['methodName'] as String,
      uri: json['uri'] as String,
    );
  }

  /// Converts this entry to a JSON map.
  Map<String, dynamic> toJson() => {
    'annotationName': annotationName,
    'className': className,
    'methodName': methodName,
    'uri': uri,
  };

  /// Serializes this entry to a compact binary format.
  List<int> serialize() {
    final bytes = <int>[];
    _writeString(bytes, annotationName);
    _writeString(bytes, className);
    _writeString(bytes, methodName);
    _writeString(bytes, uri);
    return bytes;
  }

  /// Deserializes an [AnnotatedMethodEntry] from binary data starting at [offset].
  static (AnnotatedMethodEntry, int) deserialize(List<int> data, int offset) {
    final (annotationName, off1) = _readString(data, offset);
    final (className, off2) = _readString(data, off1);
    final (methodName, off3) = _readString(data, off2);
    final (uri, off4) = _readString(data, off3);
    return (
      AnnotatedMethodEntry(
        annotationName: annotationName,
        className: className,
        methodName: methodName,
        uri: uri,
      ),
      off4,
    );
  }

  @override
  List<Object?> equalizedProperties() => [annotationName, className, methodName, uri];
}

// ==================================================== RUNTIME HINT ENTRY ==================================================

/// A single entry representing a RuntimeHint or RuntimeHintProvider implementation.
class RuntimeHintEntry with EqualsAndHashCode {
  /// The qualified name of the class.
  final String qualifiedName;

  /// The simple name of the class.
  final String name;

  /// The type of hint: 'direct' for RuntimeHint, 'provider' for RuntimeHintProvider.
  final String type;

  const RuntimeHintEntry({
    required this.qualifiedName,
    required this.name,
    required this.type,
  });

  /// Creates a [RuntimeHintEntry] from a JSON map.
  factory RuntimeHintEntry.fromJson(Map<String, dynamic> json) {
    return RuntimeHintEntry(
      qualifiedName: json['qualifiedName'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  /// Converts this entry to a JSON map.
  Map<String, dynamic> toJson() => {
    'qualifiedName': qualifiedName,
    'name': name,
    'type': type,
  };

  /// Serializes this entry to a compact binary format.
  List<int> serialize() {
    final bytes = <int>[];
    _writeString(bytes, qualifiedName);
    _writeString(bytes, name);
    _writeString(bytes, type);
    return bytes;
  }

  /// Deserializes a [RuntimeHintEntry] from binary data starting at [offset].
  static (RuntimeHintEntry, int) deserialize(List<int> data, int offset) {
    final (qualifiedName, off1) = _readString(data, offset);
    final (name, off2) = _readString(data, off1);
    final (type, off3) = _readString(data, off2);
    return (
      RuntimeHintEntry(
        qualifiedName: qualifiedName,
        name: name,
        type: type,
      ),
      off3,
    );
  }

  @override
  List<Object?> equalizedProperties() => [qualifiedName, name, type];
}

// ================================================== HELPER FUNCTIONS =====================================================

/// Writes a length-prefixed UTF-8 string to [bytes].
void _writeString(List<int> bytes, String value) {
  final encoded = utf8.encode(value);
  // Use variable-length encoding for string length
  if (encoded.length < 128) {
    bytes.add(encoded.length);
  } else {
    bytes.add(0x80 | (encoded.length >> 8));
    bytes.add(encoded.length & 0xFF);
  }
  bytes.addAll(encoded);
}

/// Reads a length-prefixed UTF-8 string from [data] starting at [offset].
/// Returns the string and the new offset.
(String, int) _readString(List<int> data, int offset) {
  final lengthByte = data[offset];
  int stringLength;
  int newOffset;

  if (lengthByte < 128) {
    stringLength = lengthByte;
    newOffset = offset + 1;
  } else {
    stringLength = ((lengthByte & 0x7F) << 8) | data[offset + 1];
    newOffset = offset + 2;
  }

  final bytes = data.sublist(newOffset, newOffset + stringLength);
  return (utf8.decode(bytes), newOffset + stringLength);
}
