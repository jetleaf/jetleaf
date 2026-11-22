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

/// 📄 **JetLeaf Document Store Abstractions**
///
/// Provides the base [DatabaseDialect], [RenderedQuery], [DocumentDialect], and
/// [DocumentTypeMapper] abstractions for NoSQL document databases without
/// pulling any relational SQL dialect symbols into scope.
///
/// ### Usage Example
/// ```dart
/// import 'package:jetleaf_data/document.dart';
///
/// final class CustomDocumentDialect extends DocumentDialect {
///   // Implement document query rendering and type mapping
/// }
/// ```
library;

export 'src/dialect/database_dialect.dart';
export 'src/dialect/document_dialect.dart';
export 'src/dialect/document_type_mapper.dart';