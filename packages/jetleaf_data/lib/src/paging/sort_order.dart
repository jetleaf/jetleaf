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

import 'sort.dart';

/// {@template sort_order}
/// Represents a **single sorting instruction** consisting of:
/// - a **property** (field name),
/// - a **direction** ([SortDirection]),
/// - and whether the sort should be **case-insensitive**.
///
/// This class is part of the fluent sorting API used to construct declarative,
/// immutable sort configurations for queries, collections, or persistence
/// frameworks.
///
/// ### Usage Example
/// ```dart
/// // Basic ascending order
/// final order = SortOrder('username');
///
/// // Descending order
/// final order = SortOrder.desc('createdAt');
///
/// // Case-insensitive ordering
/// final order = SortOrder('email', ignoreCase: true);
/// ```
/// {@endtemplate}
final class SortOrder with EqualsAndHashCode {
  /// Reflective class descriptor for [SortOrder].
  static final Class<SortOrder> CLASS = Class<SortOrder>(null, PackageNames.DATA);

  /// The default direction used when none is provided: ascending.
  static final SortDirection DEFAULT_DIRECTION = SortDirection.ASC;

  /// The sorting direction (ascending or descending).
  final SortDirection direction;

  /// The property (field) name to be sorted by.
  final String property;

  /// Whether sorting should be case-insensitive.
  final bool ignoreCase;

  /// {@macro sort_order}
  SortOrder(this.property, {SortDirection? direction, bool? ignoreCase})
    : direction = direction ?? DEFAULT_DIRECTION,
      ignoreCase = ignoreCase ?? false,
      assert(property.isNotEmpty, "Property cannot be empty");

  /// Creates a new ascending order for the given [property].
  static SortOrder by(String property) => SortOrder(property);

  /// Creates an ascending sort order for [property].
  static SortOrder asc(String property) => SortOrder(property, direction: DEFAULT_DIRECTION);

  /// Creates a descending sort order for [property].
  static SortOrder desc(String property) => SortOrder(property, direction: SortDirection.DESC);

  /// Returns the sorting direction.
  SortDirection getDirection() => direction;

  /// Returns the property (field) name to sort by.
  String getProperty() => property;

  /// Returns whether sorting is case-insensitive.
  bool isIgnoreCase() => ignoreCase;

  /// Returns `true` if this order sorts in ascending direction.
  bool isAscending() => direction.isAscending();

  /// Returns `true` if this order sorts in descending direction.
  bool isDescending() => direction.isDescending();

  /// Returns a copy of this order with the given [direction].
  SortOrder withDirection(SortDirection direction) => copyWith(direction: direction);

  /// Reverses the sort direction.
  SortOrder reverse() => withDirection(direction.isAscending() ? SortDirection.DESC : DEFAULT_DIRECTION);

  /// Returns a copy of this order with the given [property].
  SortOrder withProperty(String property) => copyWith(property: property);

  /// Returns a copy of this order with case-insensitive sorting enabled.
  SortOrder withIgnoreCase() => copyWith(ignoreCase: true);

  /// Creates a new [Sort] using this order’s direction and the given
  /// list of [properties].
  Sort withProperties(List<String> properties) => Sort.withDirection(direction, properties);

  /// Creates a new [SortOrder] with the optionally overridden values.
  SortOrder copyWith({SortDirection? direction, String? property, bool? ignoreCase}) {
    return SortOrder(
      property ?? this.property,
      direction: direction ?? this.direction,
      ignoreCase: ignoreCase ?? this.ignoreCase,
    );
  }

  @override
  List<Object?> equalizedProperties() => [direction, property, ignoreCase];

  @override
  String toString() => "SortOrder(property: $property, direction: $direction, ignoreCase: $ignoreCase)";
}
