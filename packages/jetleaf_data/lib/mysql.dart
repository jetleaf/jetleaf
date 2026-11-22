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

/// 🐬 **JetLeaf MySQL / MariaDB Data Support**
///
/// Import `package:jetleaf_data/mysql.dart` when configuring a MySQL or
/// MariaDB data source so your application only imports [MySqlDialect],
/// [MySqlTypeMapper], and SQL dialect abstractions.
///
/// ### Usage Example
/// ```dart
/// import 'package:jetleaf_data/mysql.dart';
///
/// const dialect = MySqlDialect();
/// final ddl = dialect.renderCreateTable(userMetadata);
/// ```
library;

export 'sql.dart';
export 'src/dialect/mysql/mysql_dialect.dart';
export 'src/dialect/mysql/mysql_type_mapper.dart';