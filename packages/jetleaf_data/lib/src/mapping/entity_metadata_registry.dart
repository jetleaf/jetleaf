// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/lang.dart';

import 'default_entity_metadata_registry.dart';
import 'entity_metadata.dart';
import 'naming_strategy.dart';

/// {@template jetleaf_entity_metadata_registry}
/// Read-only registry contract for looking up [EntityMetadata] descriptors by
/// entity [Type] or generic type parameter [T].
///
/// ### See Also
/// - [ConfigurableEntityMetadataRegistry]
/// - [DefaultEntityMetadataRegistry]
/// - [EntityMetadata]
/// {@endtemplate}
abstract interface class EntityMetadataRegistry {
  /// Reflective [Class] handle for [EntityMetadataRegistry].
  static final Class<EntityMetadataRegistry> CLASS = Class<EntityMetadataRegistry>(null, PackageNames.DATA);

  /// Shared default [DefaultEntityMetadataRegistry] instance.
  static final DefaultEntityMetadataRegistry instance = DefaultEntityMetadataRegistry.instance;

  /// Returns the shared default [DefaultEntityMetadataRegistry] instance.
  static DefaultEntityMetadataRegistry getSharedInstance() => DefaultEntityMetadataRegistry.getSharedInstance();

  /// Returns the cached or newly built [EntityMetadata] for entity type [T].
  EntityMetadata<T> get<T>();

  /// Returns the cached or newly built [EntityMetadata] for the runtime
  /// [entityType].
  EntityMetadata<dynamic> getForType(Type entityType);

  /// Returns `true` if metadata for [entityType] is already registered.
  bool contains(Type entityType);

  /// Returns the active [NamingStrategy] used by this registry.
  NamingStrategy getNamingStrategy();
}

/// {@template jetleaf_configurable_entity_metadata_registry}
/// Configurable extension of [EntityMetadataRegistry] supporting runtime
/// registration of custom [EntityMetadata] descriptors and [NamingStrategy]
/// customization.
/// {@endtemplate}
abstract interface class ConfigurableEntityMetadataRegistry implements EntityMetadataRegistry {
  /// Reflective [Class] handle for [ConfigurableEntityMetadataRegistry].
  static final Class<ConfigurableEntityMetadataRegistry> CLASS = Class<ConfigurableEntityMetadataRegistry>(null, PackageNames.DATA);

  /// Registers pre-built [metadata] in the registry.
  void register(EntityMetadata<dynamic> metadata);

  /// Updates the [NamingStrategy] used when building new entity metadata.
  void setNamingStrategy(NamingStrategy namingStrategy);

  /// Clears all cached [EntityMetadata] entries.
  void clear();
}