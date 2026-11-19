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
import 'sqlite_type_mapper.dart';

/// {@template jetleaf_sqlite_dialect}
/// SQLite implementation of [SqlDialect] for embedded, in-memory, and Flutter
/// client persistence.
/// {@endtemplate}
final class SqliteDialect extends SqlDialect {
  /// Reflective [Class] handle for [SqliteDialect].
  static final Class<SqliteDialect> CLASS =
      Class<SqliteDialect>(null, PackageNames.DATA);

  /// {@macro jetleaf_sqlite_dialect}
  const SqliteDialect();

  @override
  String getName() => 'sqlite';

  @override
  SqlParameterStyle getParameterStyle() => SqlParameterStyle.questionMark;

  @override
  bool supportsReturning() => true;

  @override
  bool supportsCreateIndexIfNotExists() => true;

  @override
  bool hasInlineAutoIncrementPrimaryKey() => true;

  @override
  String getUnboundedLimitLiteral() => '-1';

  @override
  SqliteTypeMapper getTypeMapper() => SqliteTypeMapper();
}
