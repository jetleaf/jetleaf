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

import 'sort_direction.dart';
import 'sort_order.dart';

export 'sort_direction.dart';
export 'sort_order.dart';

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
