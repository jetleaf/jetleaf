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

import '../document_type_mapper.dart';

/// {@template jetleaf_mongo_type_mapper}
/// MongoDB BSON implementation of [DocumentTypeMapper].
/// {@endtemplate}
final class MongoTypeMapper extends DocumentTypeMapper {
  /// Reflective [Class] handle for [MongoTypeMapper].
  static final Class<MongoTypeMapper> CLASS = Class<MongoTypeMapper>(null, PackageNames.DATA);

  /// {@macro jetleaf_mongo_type_mapper}
  MongoTypeMapper([super.converters]);
}