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

/// Represents the style of a YAML scalar value.
enum YamlStyle {
  /// Plain scalar style (no quotes, the default)
  PLAIN,
  
  /// Single-quoted scalar style (e.g., 'single quoted')
  SINGLE_QUOTED,
  
  /// Double-quoted scalar style (e.g., "double quoted")
  DOUBLE_QUOTED,
  
  /// Literal block scalar style (with |)
  LITERAL,
  
  /// Folded block scalar style (with >)
  FOLDED,
  
  /// Single-line flow scalar style (in [ ] or { })
  FLOW,
  
  /// Multi-line flow scalar style (in [ ] or { } with line breaks)
  MULTILINE_FLOW,
}

/// Extension methods for [YamlStyle].
extension YamlStyleExtensions on YamlStyle {
  /// Returns true if this style is a block style (literal or folded).
  bool get isBlock => this == YamlStyle.LITERAL || this == YamlStyle.FOLDED;
  
  /// Returns true if this style is a quoted style (single or double quoted).
  bool get isQuoted => this == YamlStyle.SINGLE_QUOTED || this == YamlStyle.DOUBLE_QUOTED;
  
  /// Returns true if this style is a flow style (flow or multiline flow).
  bool get isFlow => this == YamlStyle.FLOW || this == YamlStyle.MULTILINE_FLOW;
  
  /// Returns the appropriate quote character for this style.
  /// Returns empty string if not a quoted style.
  String get quoteChar {
    switch (this) {
      case YamlStyle.SINGLE_QUOTED:
        return "'";
      case YamlStyle.DOUBLE_QUOTED:
        return '"';
      default:
        return '';
    }
  }
  
  /// Returns the block style indicator character.
  /// Returns empty string if not a block style.
  String get blockStyleIndicator {
    switch (this) {
      case YamlStyle.LITERAL:
        return '|';
      case YamlStyle.FOLDED:
        return '>';
      default:
        return '';
    }
  }
}