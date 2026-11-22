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

/// {@template sort_direction}
/// Represents the direction in which results should be sorted.
///
/// Commonly used for database queries, API filters, and collection
/// utilities that require specifying ascending or descending order.
/// {@endtemplate}
enum SortDirection {
  /// Sort values from smallest → largest (A → Z, 0 → 9).
  ASC,

  /// Sort values from largest → smallest (Z → A, 9 → 0).
  DESC;

  /// Returns `true` if this direction is ascending.
  bool isAscending() => equals(ASC);

  /// Returns `true` if this direction is descending.
  bool isDescending() => equals(DESC);

  /// Parses a string into a [SortDirection].
  ///
  /// The comparison is case-insensitive.
  static SortDirection fromString(String value) {
    return switch (value.toUpperCase()) {
      "ASC" => ASC,
      "DESC" => DESC,
      _ => throw IllegalStateException("Unknown value passed. Value must either be 'desc' or 'asc'."),
    };
  }
}

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

/// {@template sort}
/// Represents an **ordered collection of sorting instructions**, each expressed
/// as a [SortOrder].
///
/// A [Sort] instance models a declarative sorting strategy typically used in
/// database queries, repository abstractions, or in-memory sorting operations.
///
/// ### Usage Example
/// ```dart
/// final s1 = Sort.by([SortOrder.asc('username')]);
/// final s2 = Sort.withDirection(SortDirection.DESC, ['createdAt', 'id']);
/// final merged = s1.and(s2);
/// ```
/// {@endtemplate}
final class Sort extends StandardGenericStream<SortOrder> with EqualsAndHashCode implements GenericStream<SortOrder> {
  /// Reflective class descriptor for [Sort].
  static final Class<Sort> CLASS = Class<Sort>(null, PackageNames.DATA);

  /// A singleton representing the absence of sorting.
  static final Sort UNSORTED = Sort(const []);

  /// {@macro sort}
  Sort(super.source);

  /// Creates a [Sort] using a list of property names and a shared [direction].
  Sort.withDirection(SortDirection direction, List<String> properties)
    : assert(properties.isNotEmpty, "You must provide atleast, one property"),
      super(properties.map((property) => SortOrder(property, direction: direction)));

  /// Creates a new [Sort] using the provided list of [orders].
  static Sort by(List<SortOrder> orders) => orders.isEmpty ? UNSORTED : Sort(orders);

  /// Internal method that applies the given [direction] to all existing orders.
  Sort _withDirection(SortDirection direction) {
    final orders = toList();
    final newList = <SortOrder>[];

    for (final order in orders) {
      newList.add(order.withDirection(direction));
    }

    return Sort.by(newList);
  }

  /// Returns a copy of this [Sort] with all orders set to **descending**.
  Sort descending() => _withDirection(SortDirection.DESC);

  /// Returns a copy of this [Sort] with all orders set to **ascending**.
  Sort ascending() => _withDirection(SortDirection.ASC);

  /// Returns `true` if this sort contains at least one [SortOrder].
  bool isSorted() => toList().isNotEmpty;

  /// Returns `true` if this sort contains no orders.
  bool isEmpty() => toList().isEmpty;

  /// Combines this sort with another [sort], returning a new [Sort].
  Sort and(Sort sort) {
    final current = toList();
    for (final order in sort.toList()) {
      current.add(order);
    }

    return Sort.by(current);
  }

  /// Produces a new [Sort] where each [SortOrder] has its direction reversed.
  Sort reverse([Sort? sort]) {
    final target = sort ?? this;
    final reversed = <SortOrder>[];
    for (final order in target.toList()) {
      reversed.add(order.reverse());
    }

    return Sort.by(reversed);
  }

  /// Retrieves the [SortOrder] associated with the given [property],
  /// or returns `null` if no matching order exists.
  SortOrder? getFor(String property) => toList().find((order) => order.getProperty().equals(property));

  @override
  List<Object?> equalizedProperties() => [toList()];

  @override
  String toString() {
    if (isEmpty()) {
      return "Sort(UNSORTED)";
    }
    return "Sort(${toList()})";
  }
}