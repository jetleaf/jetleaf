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

import '../sql_dialect.dart';
import 'mysql_type_mapper.dart';

/// {@template jetleaf_mysql_dialect}
/// MySQL and MariaDB implementation of [SqlDialect].
///
/// ### Characteristics
/// - Parameter placeholders: `?` ([SqlParameterStyle.questionMark])
/// - Identifier quoting: `` `identifier` ``
/// - Auto-increment DDL: `BIGINT AUTO_INCREMENT`
/// - Upsert suffix helper: `ON DUPLICATE KEY UPDATE` ([buildUpsertSuffix])
///
/// ### Usage Example
/// ```dart
/// const dialect = MySqlDialect();
/// final ddl = dialect.renderCreateTable(userMetadata);
/// ```
/// {@endtemplate}
final class MySqlDialect extends SqlDialect {
  /// Reflective [Class] handle for [MySqlDialect].
  static final Class<MySqlDialect> CLASS = Class<MySqlDialect>(null, PackageNames.DATA);

  /// {@macro jetleaf_mysql_dialect}
  const MySqlDialect();

  @override
  String getName() => 'mysql';

  @override
  SqlParameterStyle getParameterStyle() => SqlParameterStyle.questionMark;

  @override
  bool supportsReturning() => false;

  @override
  bool supportsCreateIndexIfNotExists() => false;

  @override
  String getUnboundedLimitLiteral() => '18446744073709551615';

  @override
  MySqlTypeMapper getTypeMapper() => MySqlTypeMapper();

  @override
  String escapeIdentifier(String identifier) => '`${identifier.replaceAll('`', '``')}`';

  /// Builds the `ON DUPLICATE KEY UPDATE` clause for [updateColumns].
  String buildUpsertSuffix(List<String> updateColumns) {
    final assignments = updateColumns
      .map((column) => '${escapeIdentifier(column)} = VALUES(${escapeIdentifier(column)})')
      .join(', ');
    return ' ON DUPLICATE KEY UPDATE $assignments';
  }

  /// Alias for [buildUpsertSuffix].
  String upsertSuffix(List<String> updateColumns) => buildUpsertSuffix(updateColumns);
}