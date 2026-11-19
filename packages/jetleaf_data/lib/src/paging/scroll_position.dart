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

import 'keyset_scroll_position.dart';
import 'offset_scroll_position.dart';
import 'scroll_direction.dart';

export 'keyset_scroll_position.dart';
export 'offset_scroll_position.dart';
export 'scroll_direction.dart';

/// {@template scroll_position}
/// Represents a **position in a scrollable or paginated collection**.
///
/// This abstract interface provides a common abstraction for different types
/// of scrolling strategies, including:
/// - **Key-set based scrolling** ([KeysetScrollPosition])
/// - **Offset-based scrolling** ([OffsetScrollPosition])
/// {@endtemplate}
abstract interface class ScrollPosition with EqualsAndHashCode {
  /// Reflective class descriptor for [ScrollPosition].
  static final Class<ScrollPosition> CLASS = Class<ScrollPosition>(null, PackageNames.DATA);

  /// Returns `true` if this scroll position represents the **initial position**
  /// of the collection or dataset.
  bool isInitial();

  /// Creates a **key-set scroll position at the initial position**.
  static KeysetScrollPosition keySet() => KeysetScrollPosition.initial();

  /// Creates a **key-set scroll position moving forward** from the given [keys].
  static KeysetScrollPosition forward(Map<String, Object> keys) =>
      KeysetScrollPosition.of(ScrollDirection.FORWARD, keys);

  /// Creates a **key-set scroll position moving backward** from the given [keys].
  static KeysetScrollPosition backward(Map<String, Object> keys) =>
      KeysetScrollPosition.of(ScrollDirection.BACKWARD, keys);

  /// Creates an **offset-based scroll position** at the given [offset].
  static OffsetScrollPosition offSet([int? offset]) {
    if (offset == null) {
      return OffsetScrollPosition.initial();
    }

    return OffsetScrollPosition.of(offset);
  }
}
