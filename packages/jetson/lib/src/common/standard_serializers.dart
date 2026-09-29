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

import '../base/generator.dart';
import '../json/generator/json_generator.dart';
import '../serialization/object_serializer.dart';
import '../serialization/serialization_context.dart';

/// {@template string_serializer}
/// Serializes Dart `String` values into JSON string values.
///
/// The [StringSerializer] performs a direct, lossless mapping from a Dart
/// `String` to a JSON string using the active [Generator]. No escaping or
/// transformation is performed beyond what the generator itself handles.
///
/// ### Serialization Rules
/// - Always writes a JSON string via `generator.writeString()`.
/// - Never writes `null` (the serialization framework handles nullability).
///
/// ### Example
/// ```dart
/// final serializer = StringSerializer();
/// serializer.serialize("hello", generator, context);
/// // Produces: "hello"
/// ```
///
/// ### Notes
/// - This serializer is intentionally minimal.
/// - For domain-specific string transformation (e.g., base64 encoding, masking,
///   trimming), use a `JsonConverter`.
/// {@endtemplate}
@Generic(StringSerializer)
final class StringSerializer<G extends Generator, C extends SerializationContext> extends ObjectSerializer<String, G, C> {
  /// Creates a new [StringSerializer].
  ///
  /// {@macro string_deserializer}
  const StringSerializer();

  @override
  bool canSerialize(Class type) => type == Class<String>() || type.getType() == String;

  @override
  void serialize(String value, G generator, C ctxt) {
    generator.writeString(value);
  }

  @override
  Class<String> toClass() => Class<String>(null, PackageNames.DART);
}

/// {@template int_serializer}
/// Serializes Dart `int` values into JSON numeric values.
///
/// The [IntSerializer] handles integer serialization for both JSON-specific
/// generators and generic text-based generators:
///
/// ### Serialization Rules
/// - If the active generator is a [JsonGenerator], the value is emitted as a
///   JSON number via `writeNumber()`.
/// - For non-JSON generators, an integer is serialized as its string
///   representation using `writeString()`.
///
/// This allows the serializer to work seamlessly with multiple output formats
/// while always maintaining correct JSON number semantics.
///
/// ### Example
/// ```dart
/// final serializer = IntSerializer();
/// serializer.serialize(123, generator, context);
/// // JSON output: 123
/// ```
///
/// ### Notes
/// - This serializer does **not** perform any range validation.
/// - For formatting requirements (e.g., padding, hex, locale formatting),
///   consider using a custom `JsonConverter`.
/// {@endtemplate}
@Generic(IntSerializer)
final class IntSerializer<G extends Generator, C extends SerializationContext> extends ObjectSerializer<int, G, C> {
  /// Creates a new [IntSerializer].
  ///
  /// {@macro int_deserializer}
  const IntSerializer();

  @override
  bool canSerialize(Class type) => type == Class<int>() || type.getType() == int;

  @override
  void serialize(int value, G generator, C ctxt) {
    if (generator is JsonGenerator) {
      generator.writeNumber(value);
    } else {
      generator.writeString(value.toString());
    }
  }

  @override
  Class<int> toClass() => Class<int>(null, PackageNames.DART);
}

/// {@template double_serializer}
/// Serializes Dart `double` values into JSON numeric values.
///
/// The [DoubleSerializer] ensures correct emission of floating-point numbers
/// across different generator types:
///
/// ### Serialization Rules
/// - When the active generator is a [JsonGenerator], the value is written as a
///   JSON number via `writeNumber()`.
/// - For non-JSON generators, the value is serialized as its string
///   representation using `writeString()`.
///
/// This allows the serializer to maintain proper JSON semantics while still
/// functioning in flexible output environments.
///
/// ### Example
/// ```dart
/// final serializer = DoubleSerializer();
/// serializer.serialize(3.14, generator, context);
/// // JSON output: 3.14
/// ```
///
/// ### Notes
/// - No precision rounding or formatting is performed; the raw `double` is
///   passed to the generator.
/// - If custom numeric formatting is required (e.g., fixed decimal places,
///   exponential notation), implement a `JsonConverter`.
/// {@endtemplate}
@Generic(DoubleSerializer)
final class DoubleSerializer<G extends Generator, C extends SerializationContext> extends ObjectSerializer<double, G, C> {
  /// Creates a new [DoubleSerializer].
  ///
  /// {@macro double_deserializer}
  const DoubleSerializer();

  @override
  bool canSerialize(Class type) => type == Class<double>() || type.getType() == double;

  @override
  void serialize(double value, G generator, C ctxt) {
    if (generator is JsonGenerator) {
      generator.writeNumber(value);
    } else {
      generator.writeString(value.toString());
    }
  }

  @override
  Class<double> toClass() => Class<double>(null, PackageNames.DART);
}

/// {@template num_serializer}
/// Serializes Dart `num` values into JSON numeric values.
///
/// The [NumSerializer] provides a unified serializer for all numeric values
/// that extend Dart’s `num` type, including both `int` and `double`.
///
/// ### Serialization Rules
/// - If the generator is a [JsonGenerator], the numeric value is written as a
///   JSON number using `writeNumber()`.
/// - For non-JSON generators, the number is converted to a string via
///   `toString()` and emitted with `writeString()`.
///
/// This flexibility allows the serializer to operate consistently across JSON
/// and non-JSON output targets.
///
/// ### Example
/// ```dart
/// final serializer = NumSerializer();
/// serializer.serialize(42.7, generator, context);
/// // JSON output: 42.7
/// ```
///
/// ### Notes
/// - No rounding, formatting, or type coercion is applied.
/// - Use a domain-specific `JsonConverter` if you need formatted output
///   (e.g., fixed decimal precision or localized number formats).
/// {@endtemplate}
@Generic(NumSerializer)
final class NumSerializer<G extends Generator, C extends SerializationContext> extends ObjectSerializer<num, G, C> {
  /// Creates a new [NumSerializer].
  ///
  /// {@macro num_deserializer}
  const NumSerializer();

  @override
  bool canSerialize(Class type) => type == Class<num>() || type.getType() == num;

  @override
  void serialize(num value, G generator, C ctxt) {
    if (generator is JsonGenerator) {
      generator.writeNumber(value);
    } else {
      generator.writeString(value.toString());
    }
  }

  @override
  Class<num> toClass() => Class<num>(null, PackageNames.DART);
}

/// {@template bool_serializer}
/// Serializes Dart `bool` values into JSON boolean values.
///
/// The [BoolSerializer] handles boolean serialization for both JSON-specific
/// generators and generic text-based generators:
///
/// ### Serialization Rules
/// - When the generator is a [JsonGenerator], the value is written as a JSON
///   boolean using `writeBoolean()`.
/// - For non-JSON generators, the boolean value is converted to a string via
///   `toString()` and emitted using `writeString()`.
///
/// This ensures correct JSON boolean semantics while maintaining flexibility
/// for other output formats.
///
/// ### Example
/// ```dart
/// final serializer = BoolSerializer();
/// serializer.serialize(true, generator, context);
/// // JSON output: true
/// ```
///
/// ### Notes
/// - No transformation or coercion is performed; the raw boolean is emitted.
/// - For domain-specific serialization rules (e.g., `"yes"/"no"`), use a
///   `JsonConverter`.
/// {@endtemplate}
@Generic(BoolSerializer)
final class BoolSerializer<G extends Generator, C extends SerializationContext> extends ObjectSerializer<bool, G, C> {
  /// Creates a new [BoolSerializer].
  ///
  /// {@macro bool_deserializer}
  const BoolSerializer();

  @override
  bool canSerialize(Class type) => type == Class<bool>() || type.getType() == bool;

  @override
  void serialize(bool value, G generator, C ctxt) {
    if (generator is JsonGenerator) {
      generator.writeBoolean(value);
    } else {
      generator.writeString(value.toString());
    }
  }

  @override
  Class<bool> toClass() => Class<bool>(null, PackageNames.DART);
}