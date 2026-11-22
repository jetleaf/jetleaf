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

import '../mapping/entity_metadata.dart';
import '../mapping/type_converter_registry.dart';
import 'row_mapper.dart';

/// {@template jetleaf_entity_row_mapper}
/// Reflective [RowMapper] that hydrates `@Entity` instances of type [T] using
/// [EntityMetadata] and [TypeConverterRegistry].
///
/// Matches column names case-insensitively and normalizes underscores so both
/// `snake_case` SQL columns and `camelCase` document keys map cleanly to
/// entity properties.
/// {@endtemplate}
@Generic(EntityRowMapper)
final class EntityRowMapper<T> with EqualsAndHashCode implements RowMapper<T> {
  /// Reflective [Class] handle for [EntityRowMapper].
  static final Class<EntityRowMapper> CLASS = Class<EntityRowMapper>(null, PackageNames.DATA);

  final EntityMetadata<T> _metadata;
  final TypeConverterRegistry _converters;

  /// {@macro jetleaf_entity_row_mapper}
  EntityRowMapper(
    this._metadata, [
    TypeConverterRegistry? converters,
  ]) : _converters = converters ?? TypeConverterRegistry.instance;

  /// Returns the [EntityMetadata] driving row hydration.
  EntityMetadata<T> getMetadata() => _metadata;

  /// Returns the [TypeConverterRegistry] used for column value conversion.
  TypeConverterRegistry getConverters() => _converters;

  static String _normalize(String value) => value.toLowerCase().replaceAll('_', '');

  @override
  T mapRow(Map<String, Object?> row) {
    final normalized = <String, Object?>{};
    for (final entry in row.entries) {
      normalized[_normalize(entry.key)] = entry.value;
    }

    final entity = _metadata.newInstance();
    for (final column in _metadata.getColumns()) {
      final normalizedName = _normalize(column.getName());
      if (!normalized.containsKey(normalizedName)) {
        continue;
      }

      final raw = normalized[normalizedName];
      _metadata.writeAttribute(
        entity,
        column.getProperty(),
        _converters.fromColumn(raw, column.getFieldType()),
      );
    }

    return entity;
  }

  @override
  List<Object?> equalizedProperties() => [_metadata, _converters];
}