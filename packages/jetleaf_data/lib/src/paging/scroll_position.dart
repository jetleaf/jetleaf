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

import 'dart:collection';

import 'package:jetleaf_core/lang.dart';

/// {@template scroll_direction}
/// Represents the direction of a **scrolling action**, such as navigating
/// through paginated results, lists, or timeline-like structures.
///
/// ### Directions
/// - **[ScrollDirection.FORWARD]** → Moves toward later/next items
/// - **[ScrollDirection.BACKWARD]** → Moves toward earlier/previous items
/// {@endtemplate}
enum ScrollDirection {
  /// Scrolls **forward**, toward next elements in a list.
  FORWARD,

  /// Scrolls **backward**, toward previous elements in a list.
  BACKWARD;

  /// Returns the **opposite** scroll direction.
  ScrollDirection reverse() => this == FORWARD ? BACKWARD : FORWARD;
}

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
  static KeysetScrollPosition forward(Map<String, Object> keys) => KeysetScrollPosition.of(ScrollDirection.FORWARD, keys);

  /// Creates a **key-set scroll position moving backward** from the given [keys].
  static KeysetScrollPosition backward(Map<String, Object> keys) => KeysetScrollPosition.of(ScrollDirection.BACKWARD, keys);

  /// Creates an **offset-based scroll position** at the given [offset].
  static OffsetScrollPosition offSet([int? offset]) {
    if (offset == null) {
      return OffsetScrollPosition.initial();
    }

    return OffsetScrollPosition.of(offset);
  }
}

/// {@template key_set_scroll_position}
/// Represents a **key-set (cursor-based) scroll position** in a collection.
///
/// Each instance contains:
/// - a map of `keys` representing the current cursor position
/// - a `direction` indicating whether the scroll is **forward** or **backward**
///
/// This class is used in **cursor-based pagination** or any context where
/// navigating a dataset relies on the last known key values rather than an offset.
/// {@endtemplate}
final class KeysetScrollPosition with EqualsAndHashCode implements ScrollPosition {
  /// Reflective class descriptor for [KeysetScrollPosition].
  static final Class<KeysetScrollPosition> CLASS = Class<KeysetScrollPosition>(null, PackageNames.DATA);

  /// Singleton representing an empty forward scroll position.
  static final KeysetScrollPosition EMPTY_FORWARD = KeysetScrollPosition(ScrollDirection.FORWARD, {});

  /// Singleton representing an empty backward scroll position.
  static final KeysetScrollPosition EMPTY_BACKWARD = KeysetScrollPosition(ScrollDirection.BACKWARD, {});

  /// The cursor keys representing the current scroll position.
  final Map<String, Object> keys;

  /// The direction of the scroll.
  final ScrollDirection direction;

  /// {@macro key_set_scroll_position}
  KeysetScrollPosition(this.direction, this.keys);

  /// Returns the **initial forward scroll position**.
  static KeysetScrollPosition initial() => EMPTY_FORWARD;

  /// Creates a [KeysetScrollPosition] from the given [direction] and [keys].
  static KeysetScrollPosition of(ScrollDirection direction, Map<String, Object> keys) {
    if (keys.isEmpty) {
      return direction == ScrollDirection.FORWARD ? EMPTY_FORWARD : EMPTY_BACKWARD;
    }

    return KeysetScrollPosition(direction, UnmodifiableMapView(keys));
  }

  /// Returns the cursor keys representing the current scroll position.
  Map<String, Object> getKeys() => keys;

  /// Returns the direction of the scroll.
  ScrollDirection getDirection() => direction;

  /// Returns `true` if this position scrolls **forward**.
  bool scrollsForward() => direction == ScrollDirection.FORWARD;

  /// Returns `true` if this position scrolls **backward**.
  bool scrollsBackward() => direction == ScrollDirection.BACKWARD;

  /// Returns a new scroll position moving **forward**.
  KeysetScrollPosition scrollForward() => direction == ScrollDirection.FORWARD
      ? this
      : KeysetScrollPosition(ScrollDirection.FORWARD, keys);

  /// Returns a new scroll position moving **backward**.
  KeysetScrollPosition scrollBackward() => direction == ScrollDirection.BACKWARD
      ? this
      : KeysetScrollPosition(ScrollDirection.BACKWARD, keys);

  /// Returns a new [KeysetScrollPosition] with **reversed direction**.
  KeysetScrollPosition reverse() => KeysetScrollPosition(direction.reverse(), keys);

  @override
  bool isInitial() => keys.isEmpty;

  @override
  List<Object?> equalizedProperties() => [direction, keys];
}

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