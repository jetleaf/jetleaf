// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'source_code.dart';

/// {@template template_cache}
/// An **interface for caching rendered templates** to improve performance
/// and reduce repeated parsing/rendering of template content.
///
/// Templates are often rendered multiple times with the same context or
/// unchanged content. Without caching, each render would require parsing
/// the template, processing includes, loops, conditionals, and filters,
/// which can be computationally expensive. Implementations of [TemplateCache]
/// store pre-rendered [SourceCode] objects for reuse, minimizing redundant
/// work and improving response times.
///
/// ### Responsibilities
/// - Store fully-rendered [SourceCode] objects keyed by template identifiers.
/// - Provide fast retrieval of cached templates.
/// - Support removing or clearing cached entries to handle template updates
///   or invalidation policies.
///
/// ### Usage
/// 1. A template is requested by the renderer.
/// 2. The cache is checked using [get(template)].
/// 3. If a cached [SourceCode] exists, it is returned directly.
/// 4. If not, the template is rendered, stored via [put(template, sourceCode)],
///    and returned.
///
/// ### Example Implementation
/// ```dart
/// class InMemoryTemplateCache implements TemplateCache {
///   final _cache = <String, SourceCode>{};
///
///   @override
///   SourceCode? get(String template) => _cache[template];
///
///   @override
///   void put(String template, SourceCode sourceCode) {
///     _cache[template] = sourceCode;
///   }
///
///   @override
///   void remove(String template) => _cache.remove(template);
///
///   @override
///   void invalidateCache() => _cache.clear();
/// }
/// ```
///
/// ### Design Notes
/// - Caching strategy can be memory-based, disk-based, or hybrid.
/// - Implementations should consider **thread-safety** if used in concurrent
///   environments.
/// - Cache invalidation is the responsibility of the implementation; for
///   example, templates can be removed individually via [remove] or entirely
///   via [invalidateCache].
/// - Proper use of caching significantly reduces template rendering latency
///   and CPU usage.
///
/// ### Integration
/// - Typically used in conjunction with [TemplateRenderer] and
///   [SourceCode] to provide efficient template rendering pipelines.
/// - Cached [SourceCode] includes both raw and rendered content, along with
///   parsed template structures for potential reuse in further processing.
/// {@endtemplate}
abstract interface class TemplateCache {
  /// Retrieves a cached [SourceCode] object for a given template.
  ///
  /// - **Parameters**
  ///   - `template`: The unique identifier or path of the template.
  ///
  /// - **Returns**
  ///   - The cached [SourceCode] object if the template exists in the cache.
  ///   - `null` if the template is not present or has been removed.
  ///
  /// - **Behavior**
  ///   - This method does **not** trigger template rendering. It only
  ///     checks the cache for an existing rendered result.
  ///   - Implementations may return a copy of the cached object or a
  ///     reference, depending on mutability guarantees.
  ///
  /// - **Example**
  /// ```dart
  /// final cached = cache.get("homepage");
  /// if (cached != null) {
  ///   print(cached.renderedContent);
  /// }
  /// ```
  SourceCode? get(String template);

  /// Stores a rendered [SourceCode] object in the cache for a given template.
  ///
  /// - **Parameters**
  ///   - `template`: The unique identifier or path of the template.
  ///   - `sourceCode`: The rendered [SourceCode] object to cache.
  ///
  /// - **Behavior**
  ///   - If a cached entry already exists for this template, it should
  ///     be replaced with the new [sourceCode].
  ///   - This method does **not** perform any rendering; the object is
  ///     assumed to be fully rendered and ready for reuse.
  ///
  /// - **Example**
  /// ```dart
  /// final rendered = renderer.render(template);
  /// cache.put("homepage", rendered);
  /// ```
  void put(String template, SourceCode sourceCode);

  /// Removes a cached [SourceCode] object for a given template.
  ///
  /// - **Parameters**
  ///   - `template`: The unique identifier or path of the template to remove.
  ///
  /// - **Behavior**
  ///   - If the template exists in the cache, it is removed.
  ///   - If the template does not exist, the method does nothing.
  ///   - Implementations may also handle resource cleanup if necessary.
  ///
  /// - **Example**
  /// ```dart
  /// cache.remove("homepage");
  /// ```
  void remove(String template);

  /// Clears all cached templates from the cache.
  ///
  /// - **Behavior**
  ///   - Removes all [SourceCode] entries from the cache, regardless of
  ///     template identifiers.
  ///   - Useful for invalidating stale templates after changes in
  ///     source files or during application shutdown.
  ///
  /// - **Example**
  /// ```dart
  /// cache.invalidateCache();
  /// ```
  void invalidateCache();
}

/// {@template in_memory_template_cache}
/// An **in-memory implementation** of [TemplateCache] that stores rendered
/// templates in a simple `Map<String, SourceCode>`.
///
/// This cache is designed for fast, temporary storage of templates during
/// the runtime of an application. It is ideal for development environments
/// or scenarios where template changes are infrequent and memory usage is acceptable.
///
/// ### Features
/// - Stores [SourceCode] objects in memory keyed by template identifiers.
/// - Provides fast retrieval of previously rendered templates.
/// - Supports cache invalidation by template or full cache clear.
/// - Simple, lightweight implementation with no external dependencies.
///
/// ### Example Usage
/// ```dart
/// final cache = InMemoryTemplateCache();
/// final source = renderer.render(template);
/// cache.put("homepage", source);
///
/// final cached = cache.get("homepage");
/// print(cached?.renderedContent);
///
/// cache.remove("homepage");
/// cache.invalidateCache();
/// ```
///
/// ### Design Notes
/// - **Thread-safety**: This implementation is not synchronized; concurrent
///   access may require external locking if used in multithreaded contexts.
/// - **Lifecycle**: Cache contents exist only during the process lifetime.
/// - **Performance**: Retrieval and insertion are O(1) due to `Map` storage.
/// {@endtemplate}
final class InMemoryTemplateCache implements TemplateCache {
  /// Internal cache storage mapping template identifiers to rendered [SourceCode].
  final Map<String, SourceCode> _cache = {};

  /// {@macro in_memory_template_cache}
  InMemoryTemplateCache();

  @override
  SourceCode? get(String template) => _cache[template];

  @override
  void put(String template, SourceCode sourceCode) {
    _cache[template] = sourceCode;
  }

  @override
  void remove(String template) {
    _cache.remove(template);
  }

  @override
  void invalidateCache() {
    _cache.clear();
  }
}