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

import 'limit.dart';
import 'page_request.dart';
import 'scroll_position.dart';
import 'sort.dart';
import 'unpaged.dart';

/// {@template pageable}
/// Represents a pagination request describing which slice of data should be
/// retrieved from a paged resource.
///
/// A [Pageable] defines:
/// - the **page number** (zero-based),
/// - the **page size** (number of items per page),
/// - an associated [Sort] definition,
/// - navigation capabilities such as [getNext], [getPreviousOrFirst], and [getFirst].
///
/// Two concrete implementations typically exist:
/// - [PageRequest] — A fully defined, paginated request.
/// - [Unpaged] — A sentinel representing “no pagination”.
///
/// This abstraction unifies pagination logic across repositories, query
/// builders, and web controllers.
///
/// ### Usage Example
/// ```dart
/// final pageable = PageRequest.of(0, 20, Sort.asc("username"));
///
/// print(pageable.getPageNumber()); // 0
/// print(pageable.getPageSize());   // 20
/// print(pageable.getSort());       // Sort([SortOrder(property=username, ...]])
///
/// final next = pageable.next();
/// print(next.getPageNumber());     // 1
/// ```
///
/// ### Unpaged Example
/// ```dart
/// final unpaged = Pageable.unpaged();
/// print(unpaged.isUnpaged()); // true
/// print(unpaged.getSort());   // Sort.UNSORTED
/// ```
///
/// ### Design Notes
/// - All page numbers are **zero-based**.
/// - Unpaged instances represent unlimited queries (converted via [toLimit]).  
/// - Navigation methods always return new, immutable instances.  
/// - `scrollPosition` conversion uses exclusive semantics (offset - 1).  
///
/// ### Example Behaviors
/// | Condition            | Value               |
/// |----------------------|---------------------|
/// | `Pageable.unpaged()` | `isPaged == false`  |
/// | `PageRequest(...)`   | `isPaged == true`   |
/// | unpaged → `toLimit`  | `Limit.unlimited()` |
/// | paged → `toLimit`    | `Limit.of(pageSize)`|
///
/// ### See Also
/// - [Sort]
/// - [SortOrder]
/// - [Limit]
/// - [OffsetScrollPosition]
/// - [PageRequest]
/// - [Unpaged]
/// {@endtemplate}
abstract class Pageable with EqualsAndHashCode {
  /// Creates an unpaged instance, optionally applying a [sort].
  ///
  /// ### Example
  /// ```dart
  /// final pageable = Pageable.unpaged();
  /// final sortedUnpaged = Pageable.unpaged(Sort.asc("name"));
  /// ```
  static Pageable unpaged([Sort? sort]) => Unpaged.sorted(sort ?? Sort.UNSORTED);

  /// Creates a paged request with the given [pageSize], starting at page `0`.
  ///
  /// ### Example
  /// ```dart
  /// final pageable = Pageable.ofSize(50);
  /// print(pageable.getPageSize()); // 50
  /// ```
  static Pageable ofSize(int pageSize) => PageRequest(0, pageSize);

  /// Indicates whether this instance represents a paged request.
  ///
  /// For paged instances, always returns `true`.  
  /// Unpaged implementations override this to return `false`.
  bool isPaged() => true;

  /// Indicates whether this instance represents an unpaged request.
  ///
  /// Defaults to the negation of [isPaged].
  bool isUnpaged() => !isPaged();

  /// Returns the zero-based page number.
  int getPageNumber();

  /// Returns the page size (number of elements per page).
  int getPageSize();

  /// Returns the offset of the first element on the page.
  ///
  /// Typically:  
  /// `offset = pageNumber * pageSize`
  int getOffset();

  /// Returns the sort configuration applied to this pagination request.
  Sort getSort();

  /// Returns the sort defined on this instance, or falls back to the
  /// provided [sort] if this one is unsorted.
  ///
  /// ### Example
  /// ```dart
  /// final fallback = Sort.asc("id");
  /// final actual = pageable.getSortOr(fallback);
  /// ```
  Sort getSortOr(Sort sort) => getSort().isSorted() ? getSort() : sort;

  /// Returns a new [Pageable] pointing to the next page in the sequence.
  ///
  /// Example:
  /// ```dart
  /// final nextPage = currentPage.getNext();
  /// ```
  Pageable getNext();

  /// Returns the previous page if one exists, or the first page if currently at page `0`.
  ///
  /// This is useful for navigating backwards safely without throwing exceptions.
  ///
  /// Example:
  /// ```dart
  /// final previous = currentPage.getPreviousOrFirst();
  /// ```
  Pageable getPreviousOrFirst();

  /// Returns a [Pageable] pointing to the first page (page `0`).
  ///
  /// Example:
  /// ```dart
  /// final firstPage = currentPage.getFirst();
  /// ```
  Pageable getFirst();

  /// Returns a new [Pageable] with the given [pageNumber].
  ///
  /// Use this to jump to an arbitrary page in the sequence.
  ///
  /// Example:
  /// ```dart
  /// final page5 = currentPage.withPage(5);
  /// ```
  Pageable withPage(int pageNumber);

  /// Returns `true` if this pagination request has a previous page available.
  ///
  /// Example:
  /// ```dart
  /// if (currentPage.hasPrevious()) {
  ///   final previous = currentPage.getPreviousOrFirst();
  /// }
  /// ```
  bool hasPrevious();

  /// Returns an [Optional] containing this [Pageable] if it is paged,
  /// or empty if this represents an unpaged request.
  ///
  /// Example:
  /// ```dart
  /// final opt = currentPage.optional();
  /// opt.ifPresent((p) => print(p.getPageNumber()));
  /// ```
  Optional<Pageable> optional() => isUnpaged() ? Optional.empty() : Optional.of(this);

  /// Converts this pagination request into a [Limit].
  ///
  /// - Unpaged → `Limit.unlimited()`  
  /// - Paged → `Limit.of(getPageSize())`
  ///
  /// ### Example
  /// ```dart
  /// final limit = pageable.toLimit();
  /// ```
  Limit toLimit() {
    if (isUnpaged()) {
			return Limit.unlimited();
		}

		return Limit.of(getPageSize());
  }

  /// Converts this pagination request into an [OffsetScrollPosition].
  ///
  /// - Unpaged → throws [UnsupportedOperationException]  
  /// - Paged → creates an exclusive offset (`offset - 1`)  
  ///
  /// ### Example
  /// ```dart
  /// final pos = pageable.toScrollPosition();
  /// ```
  OffsetScrollPosition toScrollPosition() {
    if (isUnpaged()) {
			throw UnsupportedOperationException("Cannot create OffsetScrollPosition from an unpaged instance");
		}

    // scrolling is exclusive → subtract one when offset > 0
		return getOffset() > 0 ? ScrollPosition.offSet(getOffset() - 1) : ScrollPosition.offSet();
  }
}