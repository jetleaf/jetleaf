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

import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_env/env.dart';

import '../naming_strategy/naming_strategy.dart';

/// {@template serializer}
/// Base interface for all serializers within the Jetleaf mapping framework.
///
/// A [BaseSerializer] provides access to shared components that drive JSON
/// serialization — including the active [ObjectMapper], [NamingStrategy],
/// and [ConversionService].  
///
/// This interface defines the contextual backbone used by higher-level
/// abstractions like [SerializerProvider] and concrete serializers
/// (e.g., [JsonSerializer]).
///
/// ### Overview
/// - Exposes serialization configuration and environment context  
/// - Provides consistent naming and conversion behavior  
/// - Used internally by [ObjectMapper] and serializer adapters
///
/// ### Example
/// ```dart
/// final naming = serializer.getNamingStrategy();
/// final jsonKey = naming.toJsonName('userName'); // user_name
/// ```
///
/// ### See also
/// - [ObjectMapper]
/// - [NamingStrategy]
/// - [ConversionService]
/// - [SerializerProvider]
/// {@endtemplate}
abstract interface class BaseSerializer {
  /// Returns the **naming strategy** used for field name conversion.
  ///
  /// The [NamingStrategy] controls how Dart property names are transformed
  /// into JSON-compatible keys, enabling conventions such as
  /// `camelCase`, `snake_case`, or `kebab-case`.
  ///
  /// ### Example
  /// ```dart
  /// final strategy = serializer.getNamingStrategy();
  /// final jsonKey = strategy.toJsonName('createdAt');
  /// print(jsonKey); // created_at
  /// ```
  ///
  /// ### Notes
  /// - Ensures consistent key naming across serializers  
  /// - Used by property-level serializers during object traversal  
  /// - Should be reversible via [NamingStrategy.toDartName]
  NamingStrategy getNamingStrategy();

  /// Returns the **global [ConversionService]** responsible for
  /// type coercions and primitive value conversions.
  ///
  /// The [ConversionService] provides a unified interface for adapting
  /// types between Dart primitives, enums, and other supported conversions.
  ///
  /// ### Example
  /// ```dart
  /// final service = serializer.getConversionService();
  /// final value = service.convert<int>('42');
  /// print(value); // 42
  /// ```
  ///
  /// ### Notes
  /// - Enables consistent numeric, string, and enum conversions  
  /// - Accessible to custom serializers and adapters  
  /// - Should be thread-safe and stateless where possible
  ConversionService getConversionService();

  /// Returns the active [Environment] configuration associated with this mapper.
  ///
  /// The [Environment] defines runtime configuration and context for the
  /// serialization/deserialization.
  ///
  /// ### Responsibilities
  /// - Exposes active profiles and property values  
  /// - Provides configuration lookup for converters and modules  
  /// - Influences conditional serialization rules or module registration  
  ///
  /// ### Example
  /// ```dart
  /// final env = objectMapper.getEnvironment();
  /// if (env.activeProfiles.contains('production')) {
  ///   // Customize behavior for production mode
  /// }
  /// ```
  ///
  /// ### See also
  /// - [ObjectMapper]
  /// - [JsonSerializer]
  /// - [JsonDeserializer]
  Environment getEnvironment();
}
