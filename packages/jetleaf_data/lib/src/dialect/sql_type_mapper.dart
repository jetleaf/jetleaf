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

import '../mapping/column_metadata.dart';
import '../mapping/type_converter_registry.dart';

/// {@template jetleaf_sql_type_mapper}
/// Abstract base class mapping Dart entity attributes and [ColumnMetadata]
/// descriptors to relational SQL DDL column types and bindable column values.
///
/// ### See Also
/// - `SqlDialect`
/// - [ColumnMetadata]
/// - [TypeConverterRegistry]
/// {@endtemplate}
abstract class SqlTypeMapper with EqualsAndHashCode {
  /// Reflective [Class] handle for [SqlTypeMapper].
  static final Class<SqlTypeMapper> CLASS =
      Class<SqlTypeMapper>(null, PackageNames.DATA);

  final TypeConverterRegistry _converters;

  /// {@macro jetleaf_sql_type_mapper}
  SqlTypeMapper([TypeConverterRegistry? converters])
      : _converters = converters ?? TypeConverterRegistry.instance;

  /// Returns the [TypeConverterRegistry] backing value conversions.
  TypeConverterRegistry getConverters() => _converters;

  /// Returns the SQL DDL type fragment for [column] (e.g. `'VARCHAR(255)'`,
  /// `'BIGINT'`, `'BOOLEAN'`).
  String getColumnType(ColumnMetadata column);

  /// Alias for [getColumnType].
  String columnType(ColumnMetadata column) => getColumnType(column);

  /// Returns the SQL DDL type used for optimistic lock `@DataVersion` columns.
  String getVersionColumnType() => 'BIGINT';

  /// Returns the SQL DDL type used for auto-increment primary key columns.
  String getAutoIncrementColumnType();

  /// Returns the SQL DDL type used for floating-point numbers.
  String getFloatingPointType();

  /// Returns the SQL DDL type used for `DateTime` columns.
  String getDateTimeType();

  /// Returns the SQL DDL type used for unbounded text columns.
  String getLargeTextType();

  /// Returns the SQL DDL type for variable-length strings of [length], falling
  /// back to [getLargeTextType] when [length] is `null`.
  String getStringType(int? length) =>
      length != null ? 'VARCHAR($length)' : getLargeTextType();

  /// Converts an entity attribute [value] to its SQL column value.
  Object? toColumnValue(Object? value, ColumnMetadata column) {
    if (value == null) return null;
    return _converters.toColumn(value, value.runtimeType);
  }

  /// Converts a raw SQL column [value] back to the declared attribute type of
  /// [column].
  Object? fromColumnValue(Object? value, ColumnMetadata column) {
    if (value == null) return null;
    return _converters.fromColumn(value, column.getFieldType());
  }

  @override
  List<Object?> equalizedProperties() => [runtimeType, _converters];
}
