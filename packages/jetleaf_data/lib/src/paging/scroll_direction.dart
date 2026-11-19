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
