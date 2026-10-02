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

import '../base/parser.dart';
import '../serialization/deserialization_context.dart';
import '../serialization/object_deserializer.dart';

/// {@template string_deserializer}
/// Deserializes JSON values into Dart `String` instances.
///
/// The [StringDeserializer] provides simple, reliable conversion of JSON
/// primitives into `String` values. Any non-null JSON value is converted using
/// its `.toString()` representation, while `null` values are returned as `null`.
///
/// ### Core Responsibilities
/// - Convert JSON primitive values into Dart `String`.
/// - Treat `null` JSON tokens as `null`.
/// - Accept any JSON primitive type (number, boolean, string) and coerce it to
///   a string representation.
///
/// ### Example
/// ```dart
/// final deserializer = StringDeserializer();
///
/// final parser = JsonParser('"hello"');
/// final result = deserializer.deserialize(parser, context, Class.forType(String));
/// // result == "hello"
/// ```
///
/// ### Notes
/// - This deserializer does **not** enforce that the source JSON token is a
///   string. Any non-null value is stringified.
/// - Integrates with Jetleaf's generic deserialization pipeline via
///   [ObjectDeserializer].
/// {@endtemplate}
@Generic(StringDeserializer)
final class StringDeserializer<P extends Parser, C extends DeserializationContext> extends ObjectDeserializer<String, P, C> {
  /// Creates a new [StringDeserializer].
  ///
  /// {@macro string_deserializer}
  const StringDeserializer();

  @override
  bool canDeserialize(Class type) => type == Class<String>() || type.getType() == String;

  @override
  String? deserialize(P parser, C ctxt, Class toClass) {
    final value = parser.getCurrentValue();

    if (value == null) {
      return null;
    }

    try {
      final converter = ctxt.getConversionService();
      final result = converter.convert(value, Class<String>());
      if (result != null) {
        return result;
      }
    } catch (_) {
      if (value is String) return value;
      return value.toString();
    }
    
    return value.toString();
  }

  @override
  Class<String> toClass() => Class<String>(null, PackageNames.DART);
}

/// {@template int_deserializer}
/// Deserializes JSON numeric values into Dart `int` instances.
///
/// The [IntDeserializer] converts JSON numbers into Dart integers with safe
/// fallback behavior:
///
/// - If the JSON value is already an `int`, it is returned unchanged.
/// - If the JSON value is a `num` (e.g., a double), it is coerced using
///   `.toInt()`.
/// - If the value is a string, the deserializer attempts `int.tryParse()`.
/// - `null` JSON values yield `null`.
///
/// ### Core Responsibilities
/// - Safely coerce JSON numeric values into Dart `int`.
/// - Handle numbers, numeric strings, and null values gracefully.
/// - Integrate cleanly into Jetleaf's deserialization pipeline.
///
/// ### Example
/// ```dart
/// final deserializer = IntDeserializer();
///
/// final parser = JsonParser('42');
/// final result = deserializer.deserialize(parser, context, Class.forType(int));
/// // result == 42
/// ```
///
/// ### Notes
/// - Floating-point input is truncated using `.toInt()`.
/// - Non-numeric strings return `null` via `int.tryParse`.
/// {@endtemplate}
@Generic(IntDeserializer)
final class IntDeserializer<P extends Parser, C extends DeserializationContext> extends ObjectDeserializer<int, P, C> {
  /// Creates a new [IntDeserializer].
  ///
  /// {@macro int_deserializer}
  const IntDeserializer();

  @override
  bool canDeserialize(Class type) => type == Class<int>() || type.getType() == int;

  @override
  int? deserialize(P parser, C ctxt, Class toClass) {
    final value = parser.getCurrentValue();

    if (value == null) {
      return null;
    }

    try {
      final converter = ctxt.getConversionService();
      final result = converter.convert(value, Class<int>());
      if (result != null) {
        return result;
      }
    } catch (_) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }
    
    return int.tryParse(value.toString());
  }

  @override
  Class<int> toClass() => Class<int>(null, PackageNames.DART);
}

/// {@template double_deserializer}
/// Deserializes JSON numeric values into Dart `double` instances.
///
/// The [DoubleDeserializer] converts JSON numbers and numeric-like strings into
/// Dart `double` values, applying relaxed and safe coercion rules:
///
/// - Returns the value directly if it is already a `double`.
/// - Converts any `num` into a `double` using `.toDouble()`.
/// - Attempts `double.tryParse()` for string values.
/// - Returns `null` when the JSON value is `null`.
///
/// ### Core Responsibilities
/// - Provide safe and predictable coercion of JSON numeric values to `double`.
/// - Handle integers, doubles, numeric strings, and nulls.
/// - Integrate seamlessly with Jetleaf's deserialization strategy.
///
/// ### Example
/// ```dart
/// final deserializer = DoubleDeserializer();
///
/// final parser = JsonParser('3.14');
/// final result = deserializer.deserialize(parser, context, Class.forType(double));
/// // result == 3.14
/// ```
///
/// ### Notes
/// - Non-numeric strings result in `null` via `double.tryParse`.
/// - Avoids throwing format exceptions unless upstream parser errors occur.
/// {@endtemplate}
@Generic(DoubleDeserializer)
final class DoubleDeserializer<P extends Parser, C extends DeserializationContext> extends ObjectDeserializer<double, P, C> {
  /// Creates a new [DoubleDeserializer].
  ///
  /// {@macro double_deserializer}
  const DoubleDeserializer();

  @override
  bool canDeserialize(Class type) => type == Class<double>() || type.getType() == double;

  @override
  double? deserialize(P parser, C ctxt, Class toClass) {
    final value = parser.getCurrentValue();

    if (value == null) {
      return null;
    }

    try {
      final converter = ctxt.getConversionService();
      final result = converter.convert(value, Class<double>());
      if (result != null) {
        return result;
      }
    } catch (_) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }
    
    return double.tryParse(value.toString());
  }

  @override
  Class<double> toClass() => Class<double>(null, PackageNames.DART);
}

/// {@template num_deserializer}
/// Deserializes JSON numeric values into Dart `num` instances.
///
/// The [NumDeserializer] provides flexible conversion of JSON numeric types
/// into Dart’s root numeric type, `num`. This enables seamless handling of
/// values that could be either `int` or `double` at runtime.
///
/// ### Conversion Rules
/// - If the JSON value is already a `num`, it is returned as-is.
/// - If the value is a string, the deserializer attempts `num.tryParse()`.
/// - `null` JSON values produce `null`.
///
/// ### Core Responsibilities
/// - Provide a generic numeric deserializer when the exact numeric type is
///   unknown.
/// - Gracefully handle integers, floating-point numbers, numeric strings, and
///   null values.
/// - Integrate cleanly with Jetleaf’s deserialization pipeline.
///
/// ### Example
/// ```dart
/// final deserializer = NumDeserializer();
///
/// final parser = JsonParser('42.5');
/// final result = deserializer.deserialize(parser, context, Class.forType(num));
/// // result == 42.5
/// ```
///
/// ### Notes
/// - If parsing fails (e.g., non-numeric string), `null` is returned.
/// - This deserializer does **not** attempt to guess whether a number should be
///   an `int` or a `double`; callers should request a more specific type if they
///   require one.
/// {@endtemplate}
@Generic(NumDeserializer)
final class NumDeserializer<P extends Parser, C extends DeserializationContext> extends ObjectDeserializer<num, P, C> {
  /// Creates a new [NumDeserializer].
  ///
  /// {@macro num_deserializer}
  const NumDeserializer();

  @override
  bool canDeserialize(Class type) => type == Class<num>() || type.getType() == num;

  @override
  num? deserialize(P parser, C ctxt, Class toClass) {
    final value = parser.getCurrentValue();

    if (value == null) {
      return null;
    }

    try {
      final converter = ctxt.getConversionService();
      final result = converter.convert(value, Class<num>());
      if (result != null) {
        return result;
      }
    } catch (_) {
      if (value is num) return value;
      return num.tryParse(value.toString());
    }
    
    return num.tryParse(value.toString());
  }

  @override
  Class<num> toClass() => Class<num>(null, PackageNames.DART);
}

/// {@template bool_deserializer}
/// Deserializes JSON boolean-like values into Dart `bool` instances.
///
/// The [BoolDeserializer] provides flexible and tolerant conversion from JSON
/// values into Dart booleans. It supports native JSON booleans as well as
/// common string representations.
///
/// ### Conversion Rules
/// - If the JSON value is already a `bool`, it is returned as-is.
/// - If the value is a `String`, it is interpreted case-insensitively:
///   - `"true"` → `true`
///   - `"false"` → `false`
///   - Any other string returns `false`.
/// - For any other type, the deserializer returns `false`.
/// - `null` JSON values produce `null`.
///
/// ### Example
/// ```dart
/// final deserializer = BoolDeserializer();
///
/// parser.setValue("TRUE");
/// final result = deserializer.deserialize(parser, context, Class.forType(bool));
/// // result == true
/// ```
///
/// ### Notes
/// - This deserializer is intentionally permissive with strings, but does not
///   attempt to coerce numbers (e.g. `0`, `1`) into booleans.
/// - If you require domain-specific truthiness rules, consider implementing a
///   custom `JsonConverter`.
/// {@endtemplate}
@Generic(BoolDeserializer)
final class BoolDeserializer<P extends Parser, C extends DeserializationContext> extends ObjectDeserializer<bool, P, C> {
  /// Creates a new [BoolDeserializer].
  ///
  /// {@macro bool_deserializer}
  const BoolDeserializer();

  @override
  bool canDeserialize(Class type) => type == Class<bool>() || type.getType() == bool;

  @override
  bool? deserialize(P parser, C ctxt, Class toClass) {
    final value = parser.getCurrentValue();

    if (value == null) {
      return null;
    }

    try {
      final converter = ctxt.getConversionService();
      final result = converter.convert(value, Class<bool>());
      if (result != null) {
        return result;
      }
    } catch (_) {
      if (value is bool) return value;
      if (value is String) {
        return value.equalsIgnoreCase("true");
      }
    }

    return bool.tryParse(value.toString());
  }

  @override
  Class<bool> toClass() => Class<bool>(null, PackageNames.DART);
}