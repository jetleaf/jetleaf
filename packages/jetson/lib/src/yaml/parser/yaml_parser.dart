// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import '../yaml_token.dart';
import '../../base/parser.dart';

/// {@template yaml_parser}
/// A **streaming YAML reader** that sequentially exposes parsed YAML tokens.
///
/// The [YamlParser] provides low-level, pull-based access to YAML input,
/// allowing deserializers to process data incrementally without loading
/// entire documents into memory.
///
/// ### Overview
/// - Reads from strings, byte streams, or character sources
/// - Emits tokens ([YamlToken]) as it parses
/// - Allows skipping nested structures efficiently
/// - Supports anchors and aliases for reference resolution
///
/// ### See also
/// - [YamlToken]
/// - [YamlObjectMapper]
/// - [YamlNode]
/// {@endtemplate}
abstract interface class YamlParser implements Parser<YamlToken> {
  /// Returns the **anchor name** if this token is anchored.
  ///
  /// For tokens with anchors (e.g., `&anchor value`), returns the anchor name.
  /// Returns `null` if no anchor is present.
  String? getAnchor();

  /// Returns the **alias reference** if this token is an alias.
  ///
  /// For ALIAS tokens, returns the referenced anchor name.
  String? getAlias();
}