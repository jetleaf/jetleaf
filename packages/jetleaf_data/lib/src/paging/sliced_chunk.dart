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

import 'pageable.dart';
import 'slice.dart';
import 'sort.dart';

/// {@template sliced_chunk}
/// Concrete implementation of [Slice<T>] backed by a [Pageable] and a stream of elements.
///
/// [SlicedChunk] represents a **chunk of data** corresponding to a single slice/page.
/// It decorates a [GenericStream] of elements with pagination metadata and sorting
/// information from a [Pageable].
///
/// Unlike [Slice], which is purely abstract, [SlicedChunk] provides default
/// implementations for most navigation and content-related methods.
///
/// ### Usage Example
/// ```dart
/// final pageRequest = PageRequest.of(0, 10, SortDirection.asc, ['name']);
/// final chunk = SlicedChunk(usersStream, pageRequest);
///
/// print(chunk.getNumber());           // 0
/// print(chunk.getSize());             // 10
/// print(chunk.getNumberOfElements()); // actual number of users in the stream
/// print(chunk.hasContent());          // true if stream is not empty
/// print(chunk.getContent());          // immutable list of users
/// print(chunk.getSort());             // Sort applied to this chunk
/// ```
/// {@endtemplate}
@Generic(SlicedChunk)
abstract class SlicedChunk<T> extends Slice<T> {
  /// The underlying pageable object containing page number, size, and sort.
  final Pageable _pageable;

  /// {@macro sliced_chunk}
  ///
  /// [source] is the stream of elements representing the chunk content.
  /// [_pageable] provides pagination metadata and sorting.
  SlicedChunk(super.source, this._pageable);

  @override
  int getNumber() => _pageable.isPaged() ? _pageable.getPageNumber() : 0;

  @override
  int getSize() => _pageable.isPaged() ? _pageable.getPageSize() : toList().length;

  @override
  int getNumberOfElements() => toList().length;

  @override
  bool hasPrevious() => getNumber() > 0;

  @override
  bool isFirst() => !hasPrevious();

  @override
  bool isLast() => !hasNext();

  @override
  bool hasContent() => toList().isNotEmpty;

  @override
  List<T> getContent() => UnmodifiableListView(toList());

  @override
  Sort getSort() => _pageable.getSort();

  @override
  Pageable getPageable() => _pageable;

  @override
  Pageable nextPageable() => hasNext() ? _pageable.getNext() : Pageable.unpaged();

  @override
  Pageable previousPageable() => hasPrevious() ? _pageable.getPreviousOrFirst() : Pageable.unpaged();

  /// Returns `true` if this page contains no elements.
  ///
  /// This is a convenience method equivalent to checking:
  /// ```dart
  /// page.getSize() == 0
  /// ```
  ///
  /// Example:
  /// ```dart
  /// if (page.isEmpty()) {
  ///   print('No items on this page');
  /// }
  /// ```
  bool isEmpty() => getSize() == 0;

  /// Returns `true` if this page contains one or more elements.
  ///
  /// This is the inverse of [isEmpty].  
  /// Equivalent to checking:
  /// ```dart
  /// page.getSize() > 0
  /// ```
  ///
  /// Example:
  /// ```dart
  /// if (page.isNotEmpty()) {
  ///   print('There are items on this page');
  /// }
  /// ```
  bool isNotEmpty() => !isEmpty();

  /// Converts each element in this chunk using the provided [converter] function.
  ///
  /// Returns a new `List<U>` containing the transformed elements.
  ///
  /// ### Example
  /// ```dart
  /// final ids = chunk.convert((user) => user.id);
  /// ```
  List<U> convert<U>(U Function(T item) converter) => map(converter).collect();

  @override
  List<Object?> equalizedProperties() => [_pageable];
}