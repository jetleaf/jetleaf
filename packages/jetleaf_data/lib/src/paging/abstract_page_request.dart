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

/// {@template abstract_page_request}
/// Base class for paged requests that define **page number** and **page size**.
///
/// This class provides common logic for all paginated requests, including:
/// - computing offsets
/// - checking for previous pages
/// - equality and hash code support
///
/// Concrete implementations should extend this class and implement [getPrevious].
///
/// ### Usage Example
/// ```dart
/// final request = MyPageRequest(0, 20);
///
/// print(request.getPageNumber()); // 0
/// print(request.getPageSize());   // 20
/// print(request.getOffset());     // 0
/// print(request.hasPrevious());   // false
/// ```
///
/// ### Design Notes
/// - `_pageNumber` is zero-based.  
/// - `_pageSize` must be at least 1.  
/// - Equality is based on `_pageNumber` and `_pageSize`.  
/// - Supports converting page requests into offset-based scroll positions
///   via [Pageable.toScrollPosition] and limits via [Pageable.toLimit].
/// {@endtemplate}
abstract class AbstractPageRequest extends Pageable {
  /// The zero-based page number.
  final int _pageNumber;

  /// The size of the page (number of items per page).
  final int _pageSize;

  /// {@macro abstract_page_request}
  ///
  /// Throws an assertion error if [pageNumber] < 0 or [pageSize] < 1.
  AbstractPageRequest(this._pageNumber, this._pageSize)
    : assert(_pageNumber >= 0, "Page number must not be less than 0"),
      assert(_pageSize >= 1, "Page size must not be less than 1");

  @override
  int getPageNumber() => _pageNumber;

  @override
  int getPageSize() => _pageSize;

  @override
  int getOffset() => _pageNumber.multiplyBy(_pageSize);

  @override
  bool hasPrevious() => _pageNumber > 0;

  @override
  Pageable getPreviousOrFirst() => hasPrevious() ? getPrevious() : getFirst();

  /// Returns the **previous page** in the pagination sequence.
  ///
  /// This method is intended to provide a convenient way to navigate backward
  /// through paginated data. It is **abstract** in [AbstractPageRequest] because
  /// the concrete logic for constructing the previous page depends on the
  /// specific subclass implementation (for example, `PageRequest` or
  /// `CustomPageRequest`).
  ///
  /// ### Usage
  /// ```dart
  /// final currentPage = MyPageRequest(2, 20);
  /// final previousPage = currentPage.getPrevious();
  /// print(previousPage.getPageNumber()); // 1
  /// ```
  ///
  /// ### Notes
  /// - Subclasses **must** implement this method.
  /// - If the current page is the first page (page 0), the caller should use
  ///   [getPreviousOrFirst] instead to safely obtain a valid Pageable.
  /// - The returned Pageable should maintain the same page size as the current instance.
  ///
  /// ### See Also
  /// - [getPreviousOrFirst] — returns either the previous page or the first page if none exist.
  /// - [getFirst] — returns the first page in the sequence.
  Pageable getPrevious();

  @override
  List<Object?> equalizedProperties() => [_pageNumber, _pageSize];
}