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

import 'abstract_page_request.dart';
import 'pageable.dart';
import 'sort.dart';

/// {@template page_request}
/// Represents a concrete, paged request with page number, page size, and optional [Sort].
///
/// [PageRequest] is a standard implementation of [Pageable] for zero-based
/// pagination in repositories or query builders. It supports:
/// - retrieving offsets,
/// - navigating pages ([getNext], [getPreviousOrFirst], [getFirst]),
/// - modifying sorting ([withDirection], [withSorting]).
///
/// Use static factory methods for convenience:
/// - [of] → page number, page size, direction, and properties
/// - [ofSize] → page size, starting at page 0
///
/// ### Example Usage
/// ```dart
/// final page = PageRequest.of(0, 10, SortDirection.asc, ['name']);
/// print(page.getPageNumber()); // 0
/// print(page.getPageSize());   // 10
/// print(page.getSort());       // Sort([SortOrder(property=name, direction=ASC)])
///
/// final nextPage = page.getNext();
/// print(nextPage.getPageNumber()); // 1
///
/// final customSort = page.withDirection(SortDirection.desc, ['date']);
/// print(customSort.getSort()); // Sort([SortOrder(property=date, direction=DESC)])
/// ```
///
/// ### Design Notes
/// - Immutable value object.
/// - Navigational methods always return new instances.
/// - Equality considers both page properties and sorting.
/// - Integrates with `Limit` and `OffsetScrollPosition` via [Pageable.toLimit]
///   and [Pageable.toScrollPosition].
/// {@endtemplate}
final class PageRequest extends AbstractPageRequest {
  /// Sort configuration for this page request.
  final Sort _sort;

  /// Constructs a [PageRequest] with a page number, page size, and optional [sort].
  ///
  /// If [sort] is not provided, defaults to [Sort.UNSORTED].
  /// 
  /// {@macro page_request}
  PageRequest(super.pageNumber, super.pageSize, [Sort? sort]) : _sort = sort ?? Sort.UNSORTED;

  /// Factory constructor creating a page request with explicit direction and properties.
  ///
  /// Example:
  /// ```dart
  /// final page = PageRequest.of(0, 10, SortDirection.asc, ['name']);
  /// ```
  static PageRequest of(int pageNumber, int pageSize, SortDirection direction, List<String> properties) {
    return PageRequest(pageNumber, pageSize, Sort.withDirection(direction, properties));
  }

  /// Factory constructor for a page request starting at page 0 with the given size.
  ///
  /// Example:
  /// ```dart
  /// final page = PageRequest.ofSize(20);
  /// ```
  static PageRequest ofSize(int pageSize) => PageRequest(0, pageSize);

  @override
  Sort getSort() => _sort;

  @override
  Pageable getNext() => PageRequest(getPageNumber() + 1, getPageSize(), getSort());

  @override
  Pageable getPrevious() => getPageNumber() == 0 ? this : PageRequest(getPageNumber() - 1, getPageSize(), getSort());

  @override
  Pageable getFirst() => PageRequest(0, getPageSize(), getSort());

  @override
  Pageable withPage(int pageNumber) => PageRequest(pageNumber, getPageSize(), getSort());

  /// Returns a new [PageRequest] with the given [direction] and [properties] for sorting.
  ///
  /// Example:
  /// ```dart
  /// final page = PageRequest.of(0, 10, SortDirection.asc, ['name']);
  /// final newPage = page.withDirection(SortDirection.desc, ['date']);
  /// print(newPage.getSort()); // sort by date descending
  /// ```
  Pageable withDirection(SortDirection direction, List<String> properties) => PageRequest(
    getPageNumber(),
    getPageSize(),
    Sort.withDirection(direction, properties)
  );
 
  /// Returns a new [PageRequest] with a different [sort].
  ///
  /// Example:
  /// ```dart
  /// final page = PageRequest.ofSize(20);
  /// final sortedPage = page.withSorting(Sort.by(['name'], SortDirection.asc));
  /// ```
  Pageable withSorting(Sort sort) => PageRequest(getPageNumber(), getPageSize(), sort);

  @override
  List<Object?> equalizedProperties() => [super.equalizedProperties(), _sort];

  @override
  String toString() => 'PageRequest(page: ${getPageNumber()}, size: ${getPageSize()}, sort: $_sort)';
}