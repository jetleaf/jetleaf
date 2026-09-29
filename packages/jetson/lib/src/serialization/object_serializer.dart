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
import 'serialization_context.dart';
import 'object_serializable.dart';

/// {@template jetleaf_object_serializer}
/// A generic, extensible **object serializer** responsible for converting Dart
/// objects into structured, generator-friendly representations (such as JSON
/// objects, YAML maps, or custom AST nodes).
///
/// `ObjectSerializer<T, Generator>` forms the core abstraction used by Jetleaf’s
/// serialization framework. It defines how instances of [T] are transformed into
/// transferable structures using a format-specific [Generator] and a
/// [SerializationContext] for nested and custom serialization strategies.
///
/// ### Purpose
/// Serializers allow Jetleaf (and downstream frameworks) to:
/// - Serialize annotated or runtime-discovered Dart classes  
/// - Apply naming strategies (e.g., snake_case vs camelCase)  
/// - Produce consistent, predictable output across formats  
/// - Integrate custom serializers for domain-specific types  
///
/// ### Typical Usage
/// ```dart
/// final generator = JsonGenerator();
/// final provider  = SerializerProvider.default();
///
/// final serializer = UserSerializer();
/// serializer.serialize(user, generator, provider);
///
/// print(generator.toJsonString());
/// // {"id":1,"name":"Alice"}
/// ```
///
/// ### Responsibilities
/// - Convert an instance of [T] into a structured object representation  
/// - Emit map/array/primitive entries through the provided [Generator]  
/// - Transform field names using the active [NamingStrategy]  
/// - Delegate nested objects to [SerializationContext]  
/// - Ensure output is structurally valid for the target format  
///
/// ### Serialization Pipeline
/// | Step | Description |
/// |------|-------------|
/// | 1 | Verify serializer compatibility via [canSerialize] |
/// | 2 | Begin object structure (e.g., `startObject()`) |
/// | 3 | Emit each field with transformed key names |
/// | 4 | Serialize nested objects using the provider |
/// | 5 | End object structure and finalize output |
///
/// ### Design Notes
/// - Serialization is intentionally separated from parsing/formatting, allowing
///   different backends (JSON, YAML, BSON, etc.) to share the same model-level
///   serializers.
/// - Works directly with Jetleaf’s reflection API (`Class<T>`) to determine
///   fields, annotations, and visibility rules.
/// - Fully supports user-implemented serializers for custom models.
///
/// ### Error Handling
/// Implementations must throw clear, descriptive errors when:
/// - A required field cannot be written  
/// - A value is unsupported by the serializer or generator  
/// - Output structure would become invalid or inconsistent  
///
/// ### See Also
/// - [Generator] — writes structured output for the target format  
/// - [SerializationContext] — locates nested serializers  
/// - [NamingStrategy] — transforms field names consistently  
/// - [JsonSerializer] — default JSON implementation  
/// {@endtemplate}
@Generic(ObjectSerializer)
abstract class ObjectSerializer<T, G extends Generator, Context extends SerializationContext> implements ObjectSerializable, ClassGettable<T> {
  /// Represents the [ObjectSerializer] type for reflection and type resolution.
  ///
  /// Allows Jetson to dynamically locate, register, and apply serializers
  /// for specific Dart types when converting objects into an object structures.
  static final Class<ObjectSerializer> CLASS = Class<ObjectSerializer>(null, PackageNames.JETSON);

  /// Creates a new [ObjectSerializer].
  ///
  /// {@macro json_serializer}
  const ObjectSerializer();

  /// Returns whether the given [type] can be **serialized** by the system.
  ///
  /// Implementations should determine if a registered serializer or converter
  /// exists for the specified class type [T].
  ///
  /// Returns:
  /// - `true` → if the type can be serialized into a transferable format (e.g., an object).
  /// - `false` → if no compatible serializer is available.
  ///
  /// ### Example
  /// ```dart
  /// if (serializer.canSerialize(Class<User>)) {
  ///   final json = serializer.serialize(user);
  /// }
  /// ```
  bool canSerialize(Class type);

  /// Determines whether this serializer **supports the given serialization context**.
  ///
  /// The method allows serializers to indicate whether they are capable of
  /// handling objects within the provided [context]. This can include:
  /// - Checking global configuration flags in the context  
  /// - Inspecting the currently active naming strategy  
  /// - Determining compatibility with format-specific rules (JSON, YAML, etc.)  
  ///
  /// Returns:
  /// - `true` → if this serializer can operate correctly within the provided [context]  
  /// - `false` → if the serializer cannot safely handle serialization for the current context
  ///
  /// ### Example
  /// ```dart
  /// final context = SerializationContext.default();
  /// if (serializer.supports(context)) {
  ///   serializer.serialize(user, generator, context);
  /// }
  /// ```
  ///
  /// ### Notes
  /// - This method is often used internally by the serialization framework to
  ///   select appropriate serializers dynamically.  
  /// - Implementations may consider format-specific capabilities, feature flags,
  ///   or runtime conditions when deciding support.
  bool supportsContext(SerializationContext context) => context is Context;

  /// Serializes an object of type [T] into an object using the provided [Generator]
  /// and [SerializationContext].
  ///
  /// Implementations should:
  /// - Write fields in the correct an object structure using [generator]  
  /// - Apply the active [NamingStrategy] for key transformation  
  /// - Use the [SerializationContext] for nested or custom serialization  
  ///
  /// ### Example
  /// ```dart
  /// serializer.serialize(user, generator, provider);
  /// final json = generator.toJsonString();
  /// print(json); // {"id":1,"name":"Alice"}
  /// ```
  ///
  /// ### Notes
  /// - Should write valid an object output  
  /// - May recursively serialize nested objects  
  /// - Must maintain structural integrity of objects and collections
  ///
  /// ### Error Handling
  /// Implementations should throw descriptive errors if:
  /// - A required field cannot be serialized  
  /// - An unsupported type is encountered  
  /// - an object structural consistency cannot be guaranteed
  ///
  /// ### See also
  /// - [Generator]
  /// - [SerializationContext]
  /// - [JsonDeserializer]
  void serialize(T value, G generator, Context serializer);
}