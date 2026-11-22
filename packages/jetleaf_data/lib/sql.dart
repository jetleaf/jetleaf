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

/// 🗃 **JetLeaf Relational SQL Abstractions**
///
/// Provides the base [DatabaseDialect], [RenderedQuery], [SqlDialect],
/// [SqlTypeMapper], [SqlParameterStyle], and SQL [Migration] abstractions for
/// relational SQL engines without pulling document/NoSQL symbols into scope.
///
/// ### Usage Example
/// ```dart
/// import 'package:jetleaf_data/sql.dart';
///
/// final class CockroachDialect extends SqlDialect {
///   // Customize identifier quoting, parameter style, and DDL generation
/// }
/// ```
library;

export 'src/dialect/database_dialect.dart';
export 'src/dialect/sql_dialect.dart';
export 'src/dialect/sql_type_mapper.dart';
export 'src/migration/migration.dart';