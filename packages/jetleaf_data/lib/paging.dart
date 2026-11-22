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

/// 📄 **JetLeaf Paging, Sorting & Scrolling Library**
///
/// Provides pagination, sorting, and cursor/offset scrolling abstractions:
/// - [Pageable], [PageRequest], [AbstractPageRequest], [Unpaged]
/// - [Page], [SimplePage], [Slice], [SlicedChunk]
/// - [Sort], [SortOrder], [SortDirection]
/// - [Limit], [Limiting]
/// - [ScrollPosition], [KeysetScrollPosition], [OffsetScrollPosition],
///   [ScrollDirection]
///
/// ### Usage Example
/// ```dart
/// import 'package:jetleaf_data/paging.dart';
///
/// final pageRequest = PageRequest.of(
///   0,
///   20,
///   Sort.by([SortOrder.desc('createdAt')]),
/// );
/// final page = await userRepository.findPage(pageRequest);
/// ```
library;

export 'src/paging/abstract_page_request.dart';
export 'src/paging/limit.dart';
export 'src/paging/page.dart';
export 'src/paging/page_request.dart';
export 'src/paging/pageable.dart';
export 'src/paging/scroll_position.dart';
export 'src/paging/simple_page.dart';
export 'src/paging/slice.dart';
export 'src/paging/sliced_chunk.dart';
export 'src/paging/sort.dart';
export 'src/paging/unpaged.dart';