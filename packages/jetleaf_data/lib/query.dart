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

/// 🔍 **JetLeaf Query Derivation & Binding Library**
///
/// Exposes the method-name query derivation parser, criteria AST, and
/// parameter binding infrastructure:
/// - [PartTree], [PartSubject], [Criterion], [PartCriterion], [CompositeCriterion]
/// - [Part] & [PartOperator]
/// - [QueryCriteria] & [QueryType]
/// - [QueryMethod], [QueryExecution], [ReturnKind]
/// - [ParameterBinder] & [BoundParameters]
///
/// ### Usage Example
/// ```dart
/// import 'package:jetleaf_data/query.dart';
///
/// final tree = PartTree.parse('findTop5ByActiveTrueOrderByCreatedAtDesc', metadata: userMetadata);
/// ```
library;

export 'src/query/parameter_binder.dart';
export 'src/query/part.dart';
export 'src/query/part_tree.dart';
export 'src/query/query_criteria.dart';
export 'src/query/query_method.dart';