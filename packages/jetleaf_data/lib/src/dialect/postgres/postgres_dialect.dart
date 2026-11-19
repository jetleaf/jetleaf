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
import 'postgres_type_mapper.dart';

/// {@template jetleaf_postgres_dialect}
/// PostgreSQL implementation of [SqlDialect].
///
/// ### Characteristics
/// - Parameter placeholders: `$1, $2, ...` ([SqlParameterStyle.dollarNumbered])
/// - Identifier quoting: `"identifier"`
/// - Auto-increment DDL: `BIGSERIAL`
/// - Supports `INSERT ... RETURNING`
/// - Supports `CREATE INDEX IF NOT EXISTS`
/// {@endtemplate}
final class PostgreSqlDialect extends SqlDialect {
  /// Reflective [Class] handle for [PostgreSqlDialect].
  static final Class<PostgreSqlDialect> CLASS =
      Class<PostgreSqlDialect>(null, PackageNames.DATA);

  /// {@macro jetleaf_postgres_dialect}
  const PostgreSqlDialect();

  @override
  String getName() => 'postgresql';

  @override
  SqlParameterStyle getParameterStyle() => SqlParameterStyle.dollarNumbered;

  @override
  bool supportsReturning() => true;

  @override
  bool supportsCreateIndexIfNotExists() => true;

  @override
  String getUnboundedLimitLiteral() => '-1';

  @override
  PostgresTypeMapper getTypeMapper() => PostgresTypeMapper();
}
