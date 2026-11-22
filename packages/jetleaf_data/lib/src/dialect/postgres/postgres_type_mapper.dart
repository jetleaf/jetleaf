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

import '../../mapping/column_metadata.dart';
import '../sql_type_mapper.dart';

/// {@template jetleaf_postgres_type_mapper}
/// PostgreSQL implementation of [SqlTypeMapper].
///
/// | Dart Type | PostgreSQL Column Type |
/// |-----------|------------------------|
/// | `String` (with length) | `VARCHAR(n)` |
/// | `String` (no length) | `TEXT` |
/// | `int` | `BIGINT` |
/// | `double` / `num` | `DOUBLE PRECISION` or `NUMERIC(p, s)` |
/// | `bool` | `BOOLEAN` |
/// | `DateTime` | `TIMESTAMP` |
/// | `Enum` | `VARCHAR(255)` |
/// | `@DataVersion` | `BIGINT` |
/// | Auto-increment `@Id` | `BIGSERIAL` |
/// {@endtemplate}
final class PostgresTypeMapper extends SqlTypeMapper {
  /// Reflective [Class] handle for [PostgresTypeMapper].
  static final Class<PostgresTypeMapper> CLASS = Class<PostgresTypeMapper>(null, PackageNames.DATA);

  /// {@macro jetleaf_postgres_type_mapper}
  PostgresTypeMapper([super.converters]);

  @override
  String getColumnType(ColumnMetadata column) {
    if (column.isVersion()) {
      return getVersionColumnType();
    }

    final type = column.getFieldType();
    if (type == String) {
      return getStringType(column.getLength());
    }
    if (type == int) {
      return 'BIGINT';
    }
    if (type == double || type == num) {
      final precision = column.getPrecision();
      final scale = column.getScale();
      if (precision != null) {
        return 'NUMERIC($precision${scale != null ? ', $scale' : ''})';
      }
      return getFloatingPointType();
    }
    if (type == bool) {
      return 'BOOLEAN';
    }
    if (type == DateTime) {
      return getDateTimeType();
    }

    return 'VARCHAR(255)';
  }

  @override
  String getAutoIncrementColumnType() => 'BIGSERIAL';

  @override
  String getFloatingPointType() => 'DOUBLE PRECISION';

  @override
  String getDateTimeType() => 'TIMESTAMP';

  @override
  String getLargeTextType() => 'TEXT';
}