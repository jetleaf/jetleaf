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

import 'pageable.dart';
import 'sort.dart';

/// {@template unpaged}
/// Represents an **unpaged pagination request**, i.e., a sentinel object
/// indicating that no pagination boundaries should be applied.
///
/// Unpaged instances are typically returned by [Pageable.unpaged] and can
/// optionally carry a [Sort] specification. All page-related operations
/// (page number, offset, size) are unsupported and will throw exceptions.
///
/// ### Usage Example
/// ```dart
/// final unpaged = Unpaged.sorted(Sort.asc("username"));
///
/// print(unpaged.isPaged()); // false
/// print(unpaged.getSort()); // Sort([SortOrder(property=username, ...)])
/// ```
///
/// ### Design Notes
/// - Immutable class with singleton-style optimization for unsorted instances.
/// - Overrides all page-specific methods to throw [IllegalStateException].
/// - `Sort` is the only meaningful property; defaults to [Sort.UNSORTED].
/// - Safe to use as a default when no pagination is required.
/// {@endtemplate}
final class Unpaged extends Pageable {
  /// Singleton instance representing an unpaged, unsorted request.
  static final Pageable UNSORTED = Unpaged(Sort.UNSORTED);

  /// Returns an unpaged instance with the given [sort], or UNSORTED if the
  /// sort is not defined.
  ///
  /// ```dart
  /// final unpagedSorted = Unpaged.sorted(Sort.asc("id"));
  /// ```
  static Pageable sorted(Sort sort) => sort.isSorted() ? Unpaged(sort) : UNSORTED;

  /// The sort configuration applied to this unpaged request.
  final Sort _sort;

  /// {@macro unpaged}
  Unpaged(this._sort);

  @override
  List<Object?> equalizedProperties() => [_sort];

  @override
  Pageable getFirst() => this;

  @override
  int getOffset() => throw IllegalStateException("Cannot get offset for an unpaged request. Unpaged instances have no page boundaries.");

  @override
  int getPageNumber() => throw IllegalStateException("Cannot get page number for an unpaged request. This Pageable is not paginated.");

  @override
  int getPageSize() => throw IllegalStateException("Cannot get page size for an unpaged request. Use a paged Pageable to access page size.");

  @override
  Sort getSort() => _sort;

  @override
  bool hasPrevious() => false;

  @override
  bool isPaged() => false;

  @override
  Pageable getNext() => this;

  @override
  Pageable getPreviousOrFirst() => this;

  @override
  Pageable withPage(int pageNumber) => pageNumber.equals(0) 
    ? this
    : throw IllegalStateException("Cannot create a paged instance from an unpaged Pageable. Requested page index: $pageNumber. Valid index for unpaged is only 0.");
}