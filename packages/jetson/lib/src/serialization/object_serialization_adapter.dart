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
import '../base/parser.dart';
import 'deserialization_context.dart';
import 'object_deserializer.dart';
import 'object_serializable.dart';
import 'object_serializer.dart';
import 'serialization_context.dart';

/// {@template jetson_object_serialization_adapter}
/// Combines both **serialization** and **deserialization** responsibilities
/// for a single type [T] into one unified adapter.
///
/// This interface allows a single implementation to handle:
/// - Serializing [T] into a target output format via a [Generator]  
/// - Deserializing [T] from an input source via a [Parser]
///
/// The type parameters are as follows:
/// - [T] — The target type being (de)serialized  
/// - [G] — The generator type for writing objects (e.g., JSON, YAML, XML)  
/// - [P] — The parser type for reading objects  
/// - [DC] — The deserialization context type  
/// - [SC] — The serialization context type
///
/// ### Usage Example
/// ```dart
/// class UserAdapter extends ObjectSerializationAdapter<User, JsonGenerator, JsonParser, DeserializationContext, SerializationContext> {
///   @override
///   void serialize(User value, JsonGenerator generator, SerializationContext context) {
///     // implement serialization
///   }
///
///   @override
///   User? deserialize(JsonParser parser, DeserializationContext context, Class toClass) {
///     // implement deserialization
///   }
/// }
/// ```
///
/// ### Notes
/// - Ensures consistency: the same adapter handles both directions for [T]  
/// - Integrates with Jetson’s [SerializationContext] and [DeserializationContext]  
/// - Useful for polymorphic types, complex objects, or custom converters
///
/// {@endtemplate}
@Generic(ObjectSerializationAdapter)
abstract class ObjectSerializationAdapter<
  T,
  G extends Generator,
  P extends Parser,
  DC extends DeserializationContext,
  SC extends SerializationContext
> implements ObjectSerializable, ObjectSerializer<T, G, SC>, ObjectDeserializer<T, P, DC> {
  @override
  bool supportsContext(SerializationContext context) => context is SC;

  @override
  bool supports(DeserializationContext context) => context is DC;
}