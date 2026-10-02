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

/// {@template jetson_generator}
/// A low-level, format-agnostic output writer used by Jetson's serialization
/// pipeline.
///
/// A **Generator** is responsible for producing the serialized representation of
/// Dart objects. While JSON is the most common target, generator implementations
/// may also produce YAML, XML, binary formats, or custom domain-specific outputs.
///
/// The generator provides primitive write operations—such as writing strings,
/// numbers, field names, delimiters, and structural boundaries—allowing concrete
/// implementations to define how data is encoded in a particular format.
///
/// Jetson serializers operate exclusively through this interface and never depend
/// on a specific output format. This enables:
///
/// - JSON generators  
/// - YAML generators  
/// - XML generators  
/// - In-memory or streaming writers  
/// - Custom user-defined output formats
///
/// ### Core Responsibilities
/// - Provide primitive write operations (e.g., writing strings or tokens)  
/// - Maintain structural correctness of the output  
/// - Optionally buffer output and expose it through [toString]  
/// - Support both in-memory and streamed serialization
///
/// ### Notes
/// - Concrete implementations may include additional format-specific methods  
/// - Some generators may not support in-memory buffering, in which case
///   [toString] may throw  
///
/// ### See also
/// - [ObjectSerializer] — Uses a generator to write serialized data  
/// - JSON/YAML/XML generator implementations  
/// {@endtemplate}
abstract interface class Generator implements Closeable {
  /// Writes a **string value**.
  ///
  /// Implementations must apply any required escaping rules for the target
  /// format (e.g., quoting, special character escaping, control sequences).
  ///
  /// ### Example
  /// ```dart
  /// generator.writeString('Hello, World');
  /// ```
  void writeString(String value);

  /// Returns the **final generated output string**, if supported.
  ///
  /// This method provides access to the complete serialized result when the
  /// generator writes to an in-memory buffer.
  ///
  /// ### Example
  /// ```dart
  /// final output = generator.toString();
  /// print(output);
  /// ```
  ///
  /// ### Notes
  /// - Not all generators store output in memory (e.g., streaming writers)  
  /// - Implementations may throw [UnsupportedError] if not applicable  
  @override
  String toString();
}