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

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/utils.dart';

/// {@template jetleaf_version}
/// Utility class for retrieving the current JetLeaf framework version.
///
/// This class attempts to resolve the version of the JetLeaf package at runtime
/// using the [PackageUtil] and the package name defined in [Constant.PACKAGE_NAME].
/// If the version cannot be resolved, it defaults to `'Unknown'`.
///
/// ### Example:
/// ```dart
/// final version = JetLeafVersion.getVersion();
/// print('Running JetLeaf v$version');
/// ```
///
/// This is useful for diagnostics, logging, version-aware features,
/// and startup banners.
/// {@endtemplate}
abstract class JetLeafVersion {
  /// {@macro jetleaf_version}
  ///
  /// Returns the current JetLeaf version as a [String].
  ///
  /// If the package metadata cannot be resolved (e.g., in AOT mode or during tests),
  /// this will return `'Unknown'`.
  ///
  /// ### Example:
  /// ```dart
  /// print('JetLeaf Framework Version: ${JetLeafVersion.getVersion()}');
  /// ```
  static String getVersion() {
    try {
      Package? package = PackageUtils.getPackage(PackageNames.MAIN);
      return package?.getVersion() ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
}