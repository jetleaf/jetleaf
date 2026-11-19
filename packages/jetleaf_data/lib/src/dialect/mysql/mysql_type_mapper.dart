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

/// {@template jetleaf_mysql_type_mapper}
/// MySQL and MariaDB implementation of [SqlTypeMapper].
/// {@endtemplate}
final class MySqlTypeMapper extends SqlTypeMapper {
  /// Reflective [Class] handle for [MySqlTypeMapper].
  static final Class<MySqlTypeMapper> CLASS =
      Class<MySqlTypeMapper>(null, PackageNames.DATA);

  /// {@macro jetleaf_mysql_type_mapper}
  MySqlTypeMapper([super.converters]);

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
      return 'TINYINT(1)';
    }
    if (type == DateTime) {
      return getDateTimeType();
    }

    return 'VARCHAR(255)';
  }

  @override
  String getAutoIncrementColumnType() => 'BIGINT AUTO_INCREMENT';

  @override
  String getFloatingPointType() => 'DOUBLE';

  @override
  String getDateTimeType() => 'DATETIME(6)';

  @override
  String getLargeTextType() => 'TEXT';
}
