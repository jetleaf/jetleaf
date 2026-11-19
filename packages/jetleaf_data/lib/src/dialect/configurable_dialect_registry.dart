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

import 'dialect_registry.dart';

/// {@template jetleaf_configurable_dialect_registry}
/// Configurable extension of [DialectRegistry] supporting dynamic dialect
/// registration, removal, and clearing.
/// {@endtemplate}
abstract interface class ConfigurableDialectRegistry implements DialectRegistry {
  /// Reflective [Class] handle for [ConfigurableDialectRegistry].
  static final Class<ConfigurableDialectRegistry> CLASS =
      Class<ConfigurableDialectRegistry>(null, PackageNames.DATA);

  /// Removes the dialect registration for [name].
  void unregister(String name);

  /// Removes all dialect registrations.
  void clear();
}
