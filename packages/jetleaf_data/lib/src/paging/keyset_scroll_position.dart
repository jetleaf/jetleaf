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

import 'scroll_position.dart';

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
