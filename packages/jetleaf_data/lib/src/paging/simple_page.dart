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

import 'page.dart';
import 'pageable.dart';

/// {@template simple_page}
/// Concrete implementation of [Page<T>] representing a **page of elements**
/// with an optional total element count.
///
/// [SimplePage] stores the page content, pagination metadata from [Pageable],
/// and the total number of elements across the dataset. It calculates
/// total pages and provides navigation helpers accordingly.
///
/// ### Usage Example
/// ```dart
/// final pageRequest = PageRequest.ofSize(10);
/// final page = SimplePage(usersStream, pageRequest, 35);
///
/// print(page.getTotalElements()); // 35
/// print(page.getTotalPages());    // 4
/// print(page.hasNext());          // true
/// print(page.getContent());       // list of users
///
/// // Mapping page content to another type
/// final idPage = page.map((user) => user.id);
/// print(idPage.getContent()); // List<int>
/// ```
/// {@endtemplate}
@Generic(SimplePage)
class SimplePage<T> extends Page<T> {
  /// Reflective class descriptor for [SimplePage].
  static final Class<SimplePage> CLASS = Class<SimplePage>(null, PackageNames.DATA);

  /// The total number of elements in the dataset.
  final int total;

  /// Constructs a [SimplePage] with the given [source] elements, [pageable]
  /// metadata, and optional [total] element count.
  ///
  /// If [total] is not provided, it will be calculated from the pageable's
  /// offset and the number of elements in [source], if applicable.
  ///
  /// {@macro simple_page}
  SimplePage(super.source, super.pageable, [int total = 0])
      : total = pageable.optional()
          .filter((pg) => source.isNotEmpty)
          .filter((pg) => pg.getOffset().plus(pg.getPageSize()).isGreaterThan(total))
          .map((pg) => pg.getOffset().plus(source.length))
          .orElse(total);

  /// Creates a [SimplePage] containing the given [content] and marks it as unpaged.
  ///
  /// This is useful for cases where you have a complete list of items and do not
  /// want to apply any pagination.
  factory SimplePage.withContent(List<T> content) =>
      SimplePage(content, Pageable.unpaged(), content.length);

  @override
  int getTotalElements() => total;

  @override
  int getTotalPages() => isEmpty() ? 1 : total.divideBy(getSize()).ceil();

  @override
  bool hasNext() => getNumber() + 1 < getTotalPages();

  @override
  Page<U> map<U>(U Function(T item) mapper) => SimplePage(convert(mapper), getPageable(), total);
}