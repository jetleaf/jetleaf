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

/// 🍃 **JetLeaf MongoDB Data Support**
///
/// Import `package:jetleaf_data/mongo.dart` when configuring a MongoDB
/// document store so your application only imports [MongoDialect],
/// [MongoTypeMapper], and document dialect abstractions without SQL dialects in
/// scope.
///
/// ### Usage Example
/// ```dart
/// import 'package:jetleaf_data/mongo.dart';
///
/// const dialect = MongoDialect();
/// final query = dialect.renderQuery(criteria);
/// print(query.getDocument());
/// ```
library;

export 'document.dart';
export 'src/dialect/mongo/mongo_dialect.dart';
export 'src/dialect/mongo/mongo_type_mapper.dart';