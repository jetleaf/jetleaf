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
/// Provides the base [SqlDialect], [SqlTypeMapper], and [SqlParameterStyle]
/// abstractions for relational SQL engines.
library;

export 'src/dialect/database_dialect.dart';
export 'src/dialect/rendered_query.dart';
export 'src/dialect/sql_dialect.dart';
export 'src/dialect/sql_parameter_style.dart';
export 'src/dialect/sql_type_mapper.dart';
export 'src/migration/sql_migration.dart';
