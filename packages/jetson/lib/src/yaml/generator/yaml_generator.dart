// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_lang/lang.dart';

import '../../base/generator.dart';

/// {@template jetson_yaml_generator}
/// A format-specific [Generator] for producing YAML output.
///
/// The **YamlGenerator** defines the primitive write operations needed to
/// serialize Dart objects into valid YAML. Higher-level serializers—such as
/// Jetson’s reflection-based object serializers—use this interface to emit
/// structured YAML without depending on any particular YAML library.
///
/// YAML requires indentation-based structure, mappings, sequences, scalar
/// values, and key/value formatting. This interface abstracts those operations
/// so Jetson serializers can remain format-agnostic.
///
/// ### Responsibilities
/// - Emit YAML mappings (objects) and sequences (lists)  
/// - Write scalar values such as strings, numbers, booleans, and null  
/// - Ensure proper key/value ordering and structural correctness  
/// - Delegate indentation, formatting, and style rules to the concrete
///   implementation (e.g., block vs. flow styles)
///
/// ### Notes
/// - Implementations may write to memory, streams, or files  
/// - Indentation handling is implementation-defined  
/// - Not all YAML styles (e.g., flow mappings) must be supported  
///
/// ### Example (conceptual)
/// ```dart
/// generator.writeStartMapping();
/// generator.writeKey('name');
/// generator.writeString('Alice');
/// generator.writeKey('roles');
/// generator.writeStartSequence();
/// generator.writeString('admin');
/// generator.writeString('editor');
/// generator.writeEndSequence();
/// generator.writeEndMapping();
///
/// print(generator.toString());
/// ```
///
/// Which might produce:
/// ```yaml
/// name: "Alice"
/// roles:
///   - "admin"
///   - "editor"
/// ```
///
/// ### See also
/// - [Generator] — base abstraction for all format generators  
/// - YAML serializers using this generator  
/// - Jetson’s object serialization pipeline  
/// {@endtemplate}
abstract interface class YamlGenerator implements Generator {
  /// Represents the [YamlGenerator] type for reflection and dynamic resolution.
  static final Class<YamlGenerator> CLASS = Class<YamlGenerator>(null, PackageNames.JETSON);

  /// Begins a new YAML mapping (equivalent to an object or dictionary).
  ///
  /// Implementations should begin a new indentation block appropriate for YAML.
  void writeStartMapping();

  /// Closes the current YAML mapping.
  ///
  /// Implementations should decrease indentation depth appropriately.
  void writeEndMapping();

  /// Begins a YAML sequence (list).
  ///
  /// A new indentation level is typically started, and subsequent values should
  /// be written using list item notation (`-`).
  void writeStartSequence();

  /// Ends the current YAML sequence.
  ///
  /// Implementations should reduce indentation depth accordingly.
  void writeEndSequence();

  /// Writes a mapping key for a YAML object.
  ///
  /// This should position the generator to expect a value next.
  void writeKey(String key);

  /// Writes a numeric scalar value.
  void writeNumber(num value);

  /// Writes a boolean scalar value.
  void writeBoolean(bool value);

  /// Writes a null value, typically rendered as `null` in YAML.
  void writeNull();
}