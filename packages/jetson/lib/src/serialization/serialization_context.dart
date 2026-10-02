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
import '../base/object_mapper.dart';
import 'base_serializer.dart';
import 'object_serializer.dart';

/// {@template jetleaf_serialization_context}
/// A stateful, format-agnostic **serialization context** responsible for
/// orchestrating Jetson’s object-to-structure serialization pipeline.
///
/// `SerializationContext` provides all services required to convert a Dart
/// object graph into a structured output representation (such as JSON maps,
/// lists, and primitive values) using a pluggable set of [ObjectSerializer]
/// implementations.
///
/// It serves as the execution environment for all serialization operations,
/// enabling:
/// - Dynamic discovery of serializers for specific Dart types  
/// - Nested serialization of complex object graphs  
/// - Application of naming strategies for key transformation  
/// - Scalar and custom type conversion  
/// - Format-independent structural generation via a [G]  
///
/// ### Purpose
/// The context abstracts the logic of:
/// - Selecting the correct serializer for a given type  
/// - Applying configuration (naming, converters, null-handling)  
/// - Recursively serializing fields, collections, and maps  
/// - Ensuring structure validity and stable ordering (when required)  
///
/// ### Typical Usage
/// ```dart
/// final generator = JsonFactory.createGenerator();
/// final clazz = Class.forType(User);
///
/// context.serialize(user, generator);
/// final output = generator.toJsonString();
/// ```
///
/// ### Responsibilities
/// - Resolve the appropriate [ObjectSerializer] for a given type  
/// - Propagate serialization requests to nested serializers  
/// - Maintain formatting rules (naming strategy, null inclusion, ordering)  
/// - Invoke scalar conversions where needed  
/// - Cooperate with the [G] to produce structurally valid output  
///
/// ### Serialization Pipeline
/// | Step | Description |
/// |------|-------------|
/// | 1 | Accept a Dart object and active [G] |
/// | 2 | Resolve an [ObjectSerializer] via [findSerializerForType] |
/// | 3 | Invoke `serializer.serialize()` with generator + context |
/// | 4 | Recursively serialize nested fields/collections/maps |
/// | 5 | Apply naming strategy, null/empty rules, converters |
/// | 6 | Produce completed structured output via the generator |
///
/// ### Design Notes
/// - The context is completely decoupled from any specific output format.  
///   Only the [G] determines the resulting representation.  
/// - Supports custom serializers, type adapters, polymorphism, and generics.  
/// - Used internally by [ObjectMapper] but can be invoked directly.  
/// - Ideal for custom object serialization strategies and plugin systems.  
///
/// ### Error Handling
/// Implementations should produce descriptive exceptions when:  
/// - No suitable serializer exists for the given object type  
/// - A field cannot be serialized due to invalid data  
/// - A serializer violates structural integrity (e.g., mismatched generator calls)  
/// - Scalar or custom converter logic fails  
///
/// ### See Also
/// - [ObjectSerializer] — serializes fields into generator output  
/// - [G] — format-agnostic structural writer  
/// - [ObjectMapper.writeValue] — high-level entry point  
/// - [NamingStrategy] — controls key transformation  
/// {@endtemplate}
@Generic(SerializationContext)
abstract interface class SerializationContext<G extends Generator> implements BaseSerializer {
  /// Represents the [SerializationContext] type for runtime reflection.
  ///
  /// Used internally by Jetson to manage and supply serializers for complex
  /// types, handling caching, configuration, and contextual serialization logic.
  static final Class<SerializationContext> CLASS = Class<SerializationContext>(null, PackageNames.JETSON);

  /// Finds and returns a **[ObjectSerializer]** suitable for the given [type].
  ///
  /// Looks up registered serializers, falling back to default implementations
  /// if no explicit one is found.
  ///
  /// ### Example
  /// ```dart
  /// final serializer = provider.findSerializerForType(Class.forType(User));
  /// serializer?.serialize(user, generator, provider);
  /// ```
  ///
  /// ### Notes
  /// - Returns `null` if no serializer is registered for the given type  
  /// - Used internally by [ObjectMapper] and nested serializers
  ObjectSerializer? findSerializerForType(Class type);

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

  /// Serializes the given [object] using a registered or default serializer.
  ///
  /// This method provides a unified entry point for serializing arbitrary
  /// objects through the [SerializationContext] context.
  ///
  /// ### Example
  /// ```dart
  /// provider.serialize(user, generator);
  /// ```
  ///
  /// ### Notes
  /// - Delegates to the appropriate [ObjectSerializer]  
  /// - Writes output to the provided [G]
  void serialize(Object? object, G generator);
}