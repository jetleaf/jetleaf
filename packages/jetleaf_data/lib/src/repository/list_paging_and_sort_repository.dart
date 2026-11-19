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

import '../paging/sort.dart';
import 'paging_and_sort_repository.dart';

/// {@template jetleaf_list_paging_and_sort_repository}
/// A generic **list-based paging and sorting repository**, extending
/// [PagingAndSortRepository] and ensuring that sorted results are
/// returned as [List] instead of a generic [Iterable].
/// {@endtemplate}
@Generic(ListPagingAndSortRepository)
abstract class ListPagingAndSortRepository<T, ID>
    extends PagingAndSortRepository<T, ID> {
  /// The reflective [Class] handle representing the `ListPagingAndSortRepository` interface.
  static final Class<ListPagingAndSortRepository> CLASS =
      Class<ListPagingAndSortRepository>(null, PackageNames.DATA);

  /// Retrieves all entities sorted according to the given [sort] as a [List].
  @override
  Future<List<T>> findAllSorted(Sort sort) async =>
      List.from(await super.findAllSorted(sort));
}
