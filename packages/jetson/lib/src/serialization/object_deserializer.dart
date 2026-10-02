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
import 'deserialization_context.dart';
import 'object_serializable.dart';

/// {@template jetleaf_object_deserializer}
/// A generic, pluggable **object deserializer** responsible for converting
/// structured data (parsed through a [Parser]) into fully-typed Dart objects.
///
/// `ObjectDeserializer<T, Token>` is a central abstraction in Jetleaf’s
/// data-binding layer. It defines how raw parser tokens (JSON, YAML, custom
/// formats, etc.) are transformed into instances of type [T], using
/// introspection metadata provided through [Class] and runtime utilities
/// from [DeserializationContext].
///
/// This interface enables:
/// - Custom deserialization logic for user-defined types  
/// - Framework-level wiring for annotated model classes  
/// - Integration with converters and nested deserializers  
///
/// ### Typical Usage
/// ```dart
/// final parser = JsonParser.fromString(jsonString);
/// final context = DeserializationContext.default();
///
/// final deserializer = UserDeserializer();
/// final user = deserializer.deserialize(parser, context, Class<User>());
/// ```
///
/// ### Responsibilities
/// - Interpret parser tokens belonging to a structured object (maps, lists,
///   primitives, nested types)
/// - Construct Dart object instances through metadata in [Class]
/// - Delegate nested values to the [DeserializationContext]
/// - Support overrides, converters, and custom hooks
///
/// ### Object Construction Pipeline
/// | Step | Description |
/// |------|-------------|
/// | 1 | Determine if the type can be handled via [canDeserialize] |
/// | 2 | Read tokens from [Parser] sequentially |
/// | 3 | Match fields to Dart constructors or setters |
/// | 4 | Convert fields using nested deserializers or converters |
/// | 5 | Produce a fully constructed object instance of type [T] |
///
/// ### Error Handling
/// Implementations should throw detailed, type-aware exceptions when:
/// - A required field is missing  
/// - Type conversion fails  
/// - The token structure does not match the expected object shape  
/// - Construction of the object instance is not possible  
///
/// ### Design Notes
/// - Deserializers are fully pluggable, allowing frameworks or applications to
///   register custom deserializers at runtime.  
/// - Integrates with Jetleaf’s reflection API (`Class<T>`) for metadata,
///   enabling advanced features such as generic resolution, annotations, and
///   runtime converters.  
/// - Token type is parameterized so deserializers may work across different
///   parser backends (JSON, YAML, custom DSLs).
///
/// ### See Also
/// - [Parser] — streaming token parser used to read input  
/// - [DeserializationContext] — manages nested deserialization  
/// - [ObjectMapper.readValue] — high-level API for reading structured data  
/// - [ObjectSerializable] — parent serialization contract  
/// {@endtemplate}
@Generic(ObjectDeserializer)
abstract class ObjectDeserializer<T, P extends Parser, Context extends DeserializationContext> implements ObjectSerializable, ClassGettable<T> {
  /// Represents the [ObjectDeserializer] type for reflection-based discovery.
  ///
  /// Provides the framework with the ability to map object structures back into
  /// Dart objects using registered or inferred deserializers.
  static final Class<ObjectDeserializer> CLASS = Class<ObjectDeserializer>(null, PackageNames.JETSON);

  /// Creates a new [ObjectDeserializer].
  ///
  /// {@macro json_deserializer}
  const ObjectDeserializer();

  /// Returns whether the given [type] can be **deserialized** by the system.
  ///
  /// Implementations should determine if a registered deserializer or converter
  /// exists for the specified class type [T].
  ///
  /// Returns:
  /// - `true` → if the type can be deserialized into an object instance.
  /// - `false` → if no compatible deserializer is available.
  ///
  /// ### Example
  /// ```dart
  /// if (serializer.canDeserialize(Class<User>)) {
  ///   final user = serializer.deserialize(parser, context, Class<User>());
  /// }
  /// ```
  bool canDeserialize(Class type);

  /// Determines whether this deserializer **supports the given deserialization context**.
  ///
  /// The method allows deserializers to indicate whether they can correctly
  /// handle input data within the provided [context]. This can include:
  /// - Inspecting configuration flags in the context  
  /// - Checking type mappings or registered adapters  
  /// - Ensuring compatibility with the target format (JSON, YAML, XML, etc.)  
  ///
  /// Returns:
  /// - `true` → if this deserializer can safely convert input data within the [context]  
  /// - `false` → if the deserializer cannot handle data under the current context
  ///
  /// ### Example
  /// ```dart
  /// final context = DeserializationContext.default();
  /// if (deserializer.supports(context)) {
  ///   final user = deserializer.deserialize(map, context);
  /// }
  /// ```
  ///
  /// ### Notes
  /// - Used internally by the deserialization framework to dynamically select
  ///   appropriate deserializers.  
  /// - Implementations may consider format-specific capabilities, feature flags,
  ///   or runtime conditions when deciding support.
  bool supports(DeserializationContext context) => context is Context;

  /// Deserializes an object of type [T] using the given [P] and
  /// [DeserializationContext].
  ///
  /// This method reads tokens from the provided [parser], interprets them
  /// according to the target type metadata, and reconstructs an instance
  /// of [T].
  ///
  /// ### Example
  /// ```dart
  /// final user = UserDeserializer().deserialize(parser, context, Class<User>());
  /// ```
  ///
  /// ### Responsibilities
  /// - Interpret object tokens from the parser sequentially  
  /// - Use [DeserializationContext] for nested deserialization and converters  
  /// - Handle complex object graphs, lists, and maps recursively  
  /// - Return a fully reconstructed object of type [T]
  ///
  /// ### Error Handling
  /// Should throw a descriptive exception if:
  /// - object structure mismatches the expected type  
  /// - Required fields are missing or invalid  
  /// - Type conversion fails during object creation
  ///
  /// ### See also
  /// - [DeserializationContext]
  /// - [P]
  /// - [ObjectMapper.readValue]
  T? deserialize(P parser, Context ctxt, Class toClass);
}