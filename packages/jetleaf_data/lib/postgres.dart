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

/// 🐘 **JetLeaf PostgreSQL Data Support**
///
/// Import `package:jetleaf_data/postgres.dart` when configuring a PostgreSQL
/// or CockroachDB data source so your application only imports PostgreSQL
/// dialect and type-mapping classes.
library;

export 'sql.dart';
export 'src/dialect/postgres/postgres_dialect.dart';
export 'src/dialect/postgres/postgres_type_mapper.dart';
