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

import 'page_request.dart';
import 'pageable.dart';
import 'sort.dart';

/// {@template slice}
/// Represents a **slice of a paginated dataset**, containing a subset of items
/// along with metadata about pagination and sorting.
///
/// A [Slice] differs from a full page in that it focuses primarily on the **current
/// subset of data**, rather than the entire collection. It provides:
/// - the current **slice number** and **size**
/// - the actual content as a `List<T>`
/// - **sorting information**
/// - navigational helpers (`hasNext`, `hasPrevious`, `nextPageable`, etc.)
///
/// [Slice] is generic over [T], the type of items contained, and integrates
/// seamlessly with [PageRequest], [Pageable], and [Sort].
///
/// ### Usage Example
/// ```dart
/// Slice<User> slice = ...; // obtained from repository or service
///
/// print(slice.getNumber());          // 0
/// print(slice.getSize());            // 20
/// print(slice.getNumberOfElements()); // 15
/// print(slice.getContent());         // list of users
/// print(slice.hasNext());            // true if another slice exists
///
/// final nextPageable = slice.nextPageable();
/// final previousPageable = slice.previousOrFirstPageable();
///
/// final ids = slice.slice((user) => user.id).getContent(); // mapping elements
/// ```
///
/// ### Design Notes
/// - [Slice] is intended for service or repository layers returning paginated results.
/// - Supports **element transformation** via [slice].  
/// - Navigation methods return new [Pageable] instances pointing to appropriate slices.
/// - Equality and hash code are typically implemented in concrete subclasses.
/// {@endtemplate}
@Generic(Slice)
abstract class Slice<T> extends StandardGenericStream<T> implements GenericStream<T>, EqualsAndHashCode {
  /// {@macro slice}
  Slice(super.source);

  /// Returns the **zero-based number** of this slice in the dataset.
  ///
  /// Typically used in combination with [getSize] to compute offsets
  /// in queries or API calls.
  ///
  /// ### Example
  /// ```dart
  /// final currentPage = slice.getNumber();
  /// print("Currently viewing slice number: $currentPage");
  /// ```
  int getNumber();

  /// Returns the **maximum number of elements** that can be contained in this slice.
  ///
  /// This is typically equivalent to the page size configured in the underlying
  /// [Pageable] or [PageRequest].
  ///
  /// ### Example
  /// ```dart
  /// final pageSize = slice.getSize();
  /// print("Max elements per slice: $pageSize");
  /// ```
  int getSize();

  /// Returns the **number of elements actually contained** in this slice.
  ///
  /// Can be smaller than [getSize] for the last slice of a dataset.
  ///
  /// ### Example
  /// ```dart
  /// print("Number of elements in this slice: ${slice.getNumberOfElements()}");
  /// ```
  int getNumberOfElements();

  /// Returns the list of items contained in this slice.
  ///
  /// The returned list is usually immutable. Modifying it may break internal invariants.
  ///
  /// ### Example
  /// ```dart
  /// final users = slice.getContent();
  /// users.forEach((user) => print(user.username));
  /// ```
  List<T> getContent();

  /// Returns `true` if this slice contains **any elements**.
  ///
  /// Useful for short-circuiting operations when a slice may be empty.
  ///
  /// ### Example
  /// ```dart
  /// if (slice.hasContent()) {
  ///   print("Slice contains ${slice.getNumberOfElements()} items");
  /// } else {
  ///   print("Slice is empty");
  /// }
  /// ```
  bool hasContent();

  /// Returns the [Sort] configuration applied to this slice.
  ///
  /// This can be used to generate subsequent queries or maintain consistent ordering.
  ///
  /// ### Example
  /// ```dart
  /// final sort = slice.getSort();
  /// print("Sorting applied: $sort");
  /// ```
  Sort getSort();

  /// Returns `true` if this slice is the first slice in the dataset.
  ///
  /// ### Example
  /// ```dart
  /// if (slice.isFirst()) print("Currently at the first slice");
  /// ```
  bool isFirst();

  /// Returns `true` if this slice is the last slice in the dataset.
  ///
  /// Determining this may require knowledge of total elements in the dataset.
  ///
  /// ### Example
  /// ```dart
  /// if (slice.isLast()) print("Currently at the last slice");
  /// ```
  bool isLast();

  /// Returns `true` if there exists a subsequent slice after this one.
  ///
  /// Useful for generating "Next" navigation links or deciding whether
  /// to request more data from the repository.
  ///
  /// ### Example
  /// ```dart
  /// if (slice.hasNext()) fetchNextSlice(slice.nextPageable());
  /// ```
  bool hasNext();

  /// Returns `true` if there exists a preceding slice before this one.
  ///
  /// ### Example
  /// ```dart
  /// if (slice.hasPrevious()) fetchPreviousSlice(slice.previousPageable());
  /// ```
  bool hasPrevious();

  /// Returns a [Pageable] representing the current slice.
  ///
  /// Useful when converting slices to pageable requests for repository queries.
  ///
  /// ### Example
  /// ```dart
  /// final currentPageable = slice.getPageable();
  /// print(currentPageable.getPageNumber());
  /// ```
  Pageable getPageable() => PageRequest(getNumber(), getSize(), getSort());

  /// Returns a [Pageable] representing the next slice.
  ///
  /// Calling this when [hasNext] is `false` may result in an empty slice in the next query.
  ///
  /// ### Example
  /// ```dart
  /// final nextPageable = slice.nextPageable();
  /// ```
  Pageable nextPageable();

  /// Returns a [Pageable] representing the previous slice.
  ///
  /// Calling this when [hasPrevious] is `false` should return the first slice.
  ///
  /// ### Example
  /// ```dart
  /// final previousPageable = slice.previousPageable();
  /// ```
  Pageable previousPageable();

  /// Returns the next [Pageable] if [hasNext] is `true`, otherwise returns the
  /// current [Pageable].
  ///
  /// Convenient for safe navigation without checking `hasNext`.
  ///
  /// ### Example
  /// ```dart
  /// final nextOrCurrent = slice.nextOrLastPageable();
  /// ```
  Pageable nextOrLastPageable() => hasNext() ? nextPageable() : getPageable();

  /// Returns the previous [Pageable] if [hasPrevious] is `true`, otherwise returns
  /// the current [Pageable].
  ///
  /// Convenient for safe navigation without checking `hasPrevious`.
  ///
  /// ### Example
  /// ```dart
  /// final previousOrCurrent = slice.previousOrFirstPageable();
  /// ```
  Pageable previousOrFirstPageable() => hasPrevious() ? previousPageable() : getPageable();

  /// Returns a new [Slice<U>] by applying the [mapper] function to each element.
  ///
  /// This is useful for mapping the content to a different type while retaining
  /// slice metadata (page number, size, sorting, navigation).
  ///
  /// ### Example
  /// ```dart
  /// final idSlice = slice.map((user) => user.id);
  /// print(idSlice.getContent()); // List<int> of user IDs
  /// ```
  @override
  Slice<U> map<U>(U Function(T item) mapper);
}