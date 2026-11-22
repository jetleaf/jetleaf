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

import 'entity_metadata.dart';
import 'entity_metadata_builder.dart';
import 'entity_metadata_registry.dart';
import 'naming_strategy.dart';

/// {@template jetleaf_default_entity_metadata_registry}
/// Default synchronized implementation of [ConfigurableEntityMetadataRegistry]
/// that builds and caches [EntityMetadata] descriptors on demand via
/// [EntityMetadataBuilder].
///
/// ### Thread Safety
/// All cache reads and writes are synchronized via JetLeaf's `synchronized`
/// primitive.
///
/// ### Usage Example
/// ```dart
/// final registry = DefaultEntityMetadataRegistry();
/// final metadata = registry.get<User>();
/// print('Table: ${metadata.getTableName()}');
/// ```
///
/// ### See Also
/// - [EntityMetadataRegistry]
/// - [ConfigurableEntityMetadataRegistry]
/// - [EntityMetadataBuilder]
/// {@endtemplate}
final class DefaultEntityMetadataRegistry with EqualsAndHashCode implements ConfigurableEntityMetadataRegistry {
  /// Reflective [Class] handle for [DefaultEntityMetadataRegistry].
  static final Class<DefaultEntityMetadataRegistry> CLASS = Class<DefaultEntityMetadataRegistry>(null, PackageNames.DATA);

  /// Process-wide shared default registry instance.
  static final DefaultEntityMetadataRegistry instance = DefaultEntityMetadataRegistry();

  /// Returns the process-wide shared default registry instance.
  static DefaultEntityMetadataRegistry getSharedInstance() => instance;

  EntityMetadataBuilder _builder;
  final Map<Type, EntityMetadata<dynamic>> _cache = {};

  /// {@macro jetleaf_default_entity_metadata_registry}
  DefaultEntityMetadataRegistry([EntityMetadataBuilder? builder])
      : _builder = builder ?? const EntityMetadataBuilder();

  @override
  NamingStrategy getNamingStrategy() => _builder.getNamingStrategy();

  @override
  void setNamingStrategy(NamingStrategy namingStrategy) {
    synchronized(_cache, () {
      _builder = EntityMetadataBuilder(namingStrategy: namingStrategy);
      _cache.clear();
    });
  }

  @override
  bool contains(Type entityType) {
    return synchronized(_cache, () => _cache.containsKey(entityType));
  }

  @override
  EntityMetadata<T> get<T>() {
    return synchronized(_cache, () {
      final cached = _cache[T];
      if (cached != null) {
        return cached as EntityMetadata<T>;
      }

      final built = _builder.build<T>(Class<T>());
      _cache[T] = built;
      return built;
    });
  }

  @override
  EntityMetadata<dynamic> getForType(Type type) {
    return synchronized(_cache, () {
      final cached = _cache[type];
      if (cached != null) {
        return cached;
      }

      final Class<dynamic> entityClass = Class.forName(type.toString());
      final built = _builder.build(entityClass);
      _cache[type] = built;
      return built;
    });
  }

  @override
  void register(EntityMetadata<dynamic> metadata) {
    synchronized(_cache, () {
      _cache[metadata.getEntityType()] = metadata;
    });
  }

  @override
  void clear() {
    synchronized(_cache, _cache.clear);
  }

  @override
  List<Object?> equalizedProperties() => [_builder, runtimeType];
}