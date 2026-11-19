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
import 'simple_page.dart';
import 'sliced_chunk.dart';

export 'simple_page.dart';

/// {@template page}
/// Represents a **full page of data** in a paginated dataset.
///
/// A [Page] extends [SlicedChunk] and provides additional metadata such as:
/// - the total number of pages
/// - the total number of elements in the dataset
///
/// Pages are typically returned by repository or service layers when querying
/// paginated data. They combine content, paging metadata, and sorting information.
///
/// ### Usage Example
/// ```dart
/// final page = repository.findUsers(PageRequest.ofSize(20));
///
/// print(page.getNumber());          // current page number
/// print(page.getSize());            // page size
/// print(page.getTotalPages());      // total pages
/// print(page.getTotalElements());   // total elements
/// print(page.getContent());         // list of users in current page
/// print(page.hasNext());            // true if there is a next page
/// ```
/// {@endtemplate}
@Generic(Page)
abstract class Page<T> extends SlicedChunk<T> {
  /// Reflective class descriptor for [Page].
  static final Class<Page> CLASS = Class<Page>(null, PackageNames.DATA);

  /// Constructs a [Page] with the given stream of [source] elements
  /// and the associated [Pageable] for pagination metadata.
  /// 
  /// {@macro page}
  Page(super.source, super.pageable);

  /// Returns an **empty page** with the optional [pageable] metadata.
  static Page<T> empty<T>([Pageable? pageable]) => SimplePage([], pageable ?? Pageable.unpaged());

  /// Returns the **total number of pages** in the dataset.
  int getTotalPages();

  /// Returns the **total number of elements** across all pages.
  int getTotalElements();

  @override
  Page<U> map<U>(U Function(T item) mapper);
}
