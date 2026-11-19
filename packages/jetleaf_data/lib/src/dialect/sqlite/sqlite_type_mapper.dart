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

/// {@template jetleaf_sqlite_type_mapper}
/// SQLite implementation of [SqlTypeMapper] based on SQLite type affinities.
/// {@endtemplate}
final class SqliteTypeMapper extends SqlTypeMapper {
  /// Reflective [Class] handle for [SqliteTypeMapper].
  static final Class<SqliteTypeMapper> CLASS =
      Class<SqliteTypeMapper>(null, PackageNames.DATA);

  /// {@macro jetleaf_sqlite_type_mapper}
  SqliteTypeMapper([super.converters]);

  @override
  String getColumnType(ColumnMetadata column) {
    final type = column.getFieldType();

    if (type == String) return 'TEXT';
    if (type == int || column.isVersion()) return 'INTEGER';
    if (type == double || type == num) return 'REAL';
    if (type == bool) return 'INTEGER';
    if (type == DateTime) return 'TEXT';

    return 'TEXT';
  }

  @override
  String getAutoIncrementColumnType() => 'INTEGER PRIMARY KEY AUTOINCREMENT';

  @override
  String getFloatingPointType() => 'REAL';

  @override
  String getDateTimeType() => 'TEXT';

  @override
  String getLargeTextType() => 'TEXT';
}
