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

import 'scroll_position.dart';

/// {@template offset_scroll_position}
/// Represents an **offset-based scroll position**, commonly used for
/// index-based pagination (e.g., SQL `LIMIT/OFFSET`, list slicing,
/// sequential pagination).
///
/// An offset of `-1` indicates the **initial position**, meaning no scroll
/// has yet occurred.
/// {@endtemplate}
final class OffsetScrollPosition with EqualsAndHashCode implements ScrollPosition {
  /// Reflective class descriptor for [OffsetScrollPosition].
  static final Class<OffsetScrollPosition> CLASS = Class<OffsetScrollPosition>(null, PackageNames.DATA);

  /// The singleton instance representing the **initial** offset (`-1`).
  static final OffsetScrollPosition INITIAL = OffsetScrollPosition(-1);

  /// Internal raw offset value (`-1` represents initial state).
  final int _offset;

  /// {@macro offset_scroll_position}
  OffsetScrollPosition(this._offset);

  /// Returns the **initial** [OffsetScrollPosition].
  static OffsetScrollPosition initial() => INITIAL;

  /// Creates a new [OffsetScrollPosition] with the given non-negative [offset].
  static OffsetScrollPosition of(int offset) {
    assert(offset >= 0, "Offset cannot be negative");
    return OffsetScrollPosition(offset);
  }

  /// Returns the current offset value.
  int getOffset() {
    assert(_offset >= 0, "Offset cannot be negative. When using initial, always check isInitial() first.");
    return _offset;
  }

  /// Advances the current offset by the given [advance] amount.
  OffsetScrollPosition advanceBy(int advance) {
    final value = isInitial() ? advance : _offset.plus(advance);
    return OffsetScrollPosition(value.isLessThan(0) ? 0 : value);
  }

  @override
  bool isInitial() => this == INITIAL || _offset == -1;

  @override
  List<Object?> equalizedProperties() => [_offset];
}
