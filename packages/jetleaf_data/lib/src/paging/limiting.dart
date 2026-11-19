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

/// {@template limiting}
/// Marker mixin indicating that a type provides limiting behavior.
///
/// This mixin itself defines no behavior. It is used purely as a semantic
/// indicator so that frameworks and utilities can detect whether a type
/// participates in limiting operations (for example, pagination limits,
/// maximum result sizes, or query bounds).
/// {@endtemplate}
abstract mixin class Limiting {
  /// Reflective class descriptor for [Limiting].
  static final Class<Limiting> CLASS = Class<Limiting>(null, PackageNames.DATA);
}
