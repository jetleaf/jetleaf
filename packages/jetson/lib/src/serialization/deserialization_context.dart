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

import '../base/object_mapper.dart';
import '../base/parser.dart';
import 'base_serializer.dart';
import 'object_deserializer.dart';

/// {@template jetleaf_deserialization_context}
/// A stateful, format-agnostic **deserialization context** that coordinates
/// all operations required to convert parser tokens into Dart object graphs.
///
/// `DeserializationContext` acts as the execution environment for the Jetson
/// deserialization pipeline, providing access to:
/// - Registered [ObjectDeserializer] instances  
/// - Type metadata (`Class<T>`)  
/// - Naming strategies  
/// - Conversion rules for primitives and custom scalars  
/// - Runtime configuration and contextual flags  
///
/// It abstracts away the details of locating the correct deserializer,
/// resolving nested types, and ensuring structural correctness as data is
/// read from any [Parser] implementation (JSON, YAML, binary formats, etc.).
///
/// ### Purpose
/// The context enables Jetson to:
/// - Deserialize arbitrarily complex objects with nested structures  
/// - Support polymorphism, generics, union types, and converters  
/// - Track state (e.g., reference resolution, depth, mode flags)  
/// - Provide a consistent interface regardless of underlying format  
///
/// ### Typical Usage
/// ```dart
/// final parser = JsonFactory.createParser(jsonString);
/// final clazz  = Class.forType(User);
///
/// final user = context.deserialize<User>(parser, clazz);
/// ```
///
/// ### Responsibilities
/// - Resolve the appropriate [ObjectDeserializer] for a target [Class]  
/// - Coordinate parsing and hand off to the deserializer  
/// - Supply conversion adapters for primitives and custom scalar types  
/// - Manage naming strategy alignment (e.g., snake_case → camelCase)  
/// - Handle nested deserialization recursively  
///
/// ### Deserialization Pipeline
/// | Step | Description |
/// |------|-------------|
/// | 1 | Accept an active [Parser] positioned at an object/token |
/// | 2 | Resolve an [ObjectDeserializer] using [findDeserializerForType] |
/// | 3 | Delegate parsing to the resolved deserializer |
/// | 4 | Recursively resolve nested objects/collections |
/// | 5 | Apply conversions, adapters, and naming strategies |
/// | 6 | Produce a fully constructed Dart object graph |
///
/// ### Design Notes
/// - The context is format-agnostic: only the parser defines the input format.  
/// - Supports custom deserializers, type adapters, and polymorphic dispatch.  
/// - Used internally by [ObjectMapper] but can be utilized directly.  
/// - May maintain per-operation state such as reference maps or mode flags.  
///
/// ### Error Handling
/// Implementations must throw descriptive exceptions when:
/// - Parsed structure does not match the target type  
/// - A required field is missing or invalid  
/// - No compatible deserializer exists for a given [Class]  
/// - Scalar conversion fails for a field or constructor argument  
///
/// ### See Also
/// - [ObjectDeserializer] — reconstructs typed objects  
/// - [Parser] — streams structural and scalar tokens  
/// - [ObjectMapper.readValue] — high-level entry point  
/// - [ConversionService] — scalar/type adaptation  
/// {@endtemplate}
@Generic(DeserializationContext)
abstract interface class DeserializationContext<P extends Parser> implements BaseSerializer {
  /// Represents the [DeserializationContext] type for reflection and runtime
  /// discovery within the Jetson framework.
  ///
  /// Enables flexible management of state and configuration during an object (like json)
  /// deserialization, including resolving object references, managing
  /// type adapters, and applying contextual settings.
  static final Class<DeserializationContext> CLASS = Class<DeserializationContext>(null, PackageNames.JETSON);

  /// Locates a registered [ObjectDeserializer] capable of handling the given [type].
  ///
  /// This method queries the internal deserializer registry associated with
  /// the active [ObjectMapper]. If no custom deserializer is found, the
  /// framework attempts to provide a default handler.
  ///
  /// ### Example
  /// ```dart
  /// final deserializer = context.findDeserializerForType(Class.forType(User));
  /// if (deserializer != null) {
  ///   final user = deserializer.deserialize(parser, context);
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Enables polymorphic and user-defined deserialization strategies  
  /// - Typically used internally by [ObjectMapper.readValue]  
  /// - Returns `null` if no compatible deserializer is registered
  ObjectDeserializer? findDeserializerForType(Class type);

  /// Returns the **active [ObjectMapper]** performing serialization.
  ///
  /// The [ObjectMapper] provides access to Jetleaf’s configuration,
  /// registered modules, serializer registry, and naming conventions.
  ///
  /// ### Example
  /// ```dart
  /// final mapper = serializer.getObjectMapper();
  /// final json = mapper.writeValueAsString(user);
  /// ```
  ///
  /// ### Notes
  /// - Enables recursive serialization for nested objects  
  /// - May expose internal feature flags and serializer adapters  
  /// - Should not be `null` during active serialization
  ObjectMapper getObjectMapper();

  /// Deserializes an object of type [T] from the current [Parser<Token>] state.
  ///
  /// This method delegates parsing to the appropriate [ObjectDeserializer],
  /// which reconstructs the object from the token stream provided by [parser].
  ///
  /// ### Example
  /// ```dart
  /// final parser = JsonFactory.createParser(jsonString);
  /// final user = context.deserialize<User>(parser, Class.forType(User));
  /// ```
  ///
  /// ### Behavior
  /// - Traverses tokens from [Parser<Token>] in sequence  
  /// - Resolves nested objects, collections, and primitives recursively  
  /// - Uses [ConversionService] for scalar coercion and type adaptation  
  /// - Applies [NamingStrategy] for field name alignment
  ///
  /// ### Error Handling
  /// Throws an exception if:
  /// - The an object (like json) structure is invalid or incomplete  
  /// - No compatible deserializer can be found for [type]
  ///
  /// ### See also
  /// - [ObjectDeserializer.deserialize]
  /// - [ObjectMapper.readValue]
  T deserialize<T>(P parser, Class<T> type);
}