import 'dart:async';

import '../annotations.dart';
import '../core/cache_operation_context.dart';
import 'cache_operation.dart';
import 'validate_and_get_cache.dart';

/// {@template jetleaf_cache_evict_operation}
/// Represents the execution logic for a `@CacheEvict` method within the Jetleaf
/// caching subsystem.
///
/// A **cache eviction operation** removes one or more entries from configured
/// caches based on the annotation configuration and evaluated runtime
/// conditions. This operation helps maintain cache integrity by ensuring that
/// outdated or invalid data is removed when a mutating method executes.
///
/// ### Overview
/// The `CacheEvictOperation` provides flexible cache removal semantics for
/// post-modification scenarios (e.g., after a database update). It supports both
/// **selective eviction** (removing a specific key) and **bulk eviction**
/// (clearing all entries in the cache).
///
/// ### Execution Flow
/// The eviction logic proceeds as follows:
///
/// 1. **Evaluate the `unless` condition** — if this evaluates to `true`, the
///    eviction process is skipped.
/// 2. **Evaluate the `condition` expression** — if this evaluates to `false`,
///    eviction does not proceed.
/// 3. **Resolve cache instances** — all [CacheManager] instances specified by
///    the annotation are located through the [CacheOperationContext].
/// 4. **Perform the eviction**:
///    - If [`allEntries`] is `true`, clears all entries from each cache.
///    - Otherwise, generates a cache key and evicts the corresponding entry.
/// 5. **Handle errors gracefully** — exceptions raised by cache implementations
///    are caught and reported to the [CacheOperationContext].
///
/// ### Configuration Options
/// - **`allEntries`** — If `true`, clears the entire cache rather than a single key.
/// - **`beforeInvocation`** — If `true`, eviction occurs *before* the method
///   executes; otherwise, it runs *after* completion.
/// - **`condition`** — A [ResourceCondition] controlling when eviction should
///   occur. Defaults to [WhenAlways].
/// - **`unless`** — A [ResourceCondition] that, if evaluated to `true`, prevents
///   eviction entirely. Defaults to [WhenNever].
///
/// ### Error Handling
/// - Errors during cache eviction or clearing are passed to
///   [CacheOperationContext.handleError].
/// - A single cache error does not interrupt eviction attempts on other caches.
/// - The operation does not rethrow by default; instead, each cache handles
///   its own failure path.
///
/// ### Thread-Safety
/// This operation is stateless and designed for concurrent use. Each invocation
/// operates exclusively on the data contained within its
/// [CacheOperationContext].
///
/// ### Example
/// ```dart
/// @CacheEvict(
///   cacheNames: {'users'},
///   allEntries: false,
///   beforeInvocation: false,
///   condition: WhenExpr('#args[0] != null'),
/// )
/// Future<void> deleteUser(String userId) async {
///   await repository.removeUser(userId);
/// }
/// ```
///
/// ### Behavior Summary
/// | Step | Description | Outcome |
/// |------|--------------|----------|
/// | 1 | Evaluate `unless` | Skip eviction if `true` |
/// | 2 | Evaluate `condition` | Skip eviction if `false` |
/// | 3 | Resolve caches | Locate configured cache managers |
/// | 4 | Evict or clear | Remove specific key or all entries |
/// | 5 | Handle errors | Report failures without aborting |
///
/// ### Usage Scenarios
/// - Removing cached data after database updates or deletions.
/// - Clearing cache regions after global state invalidation.
/// - Supporting pre- and post-invocation cache invalidation flows for data-driven
///   services.
///
/// {@endtemplate}
final class CacheEvictOperation implements CacheOperation {
  /// The `@CacheEvict` annotation defining this operation’s configuration.
  ///
  /// Contains metadata such as cache names, conditional expressions,
  /// and optional references to cache manager and key generator classes.
  final CacheEvict annotation;

  /// Creates a new [CacheEvictOperation] instance based on the given annotation.
  const CacheEvictOperation(this.annotation);

  /// {@macro jetleaf_cache_evict_operation}
  @override
  FutureOr<void> execute<T>(CacheOperationContext<T> context) async {
    // ─────────────────────────────────────────────────────────────
    // STEP 1: Resolve caches and determine if caching should proceed.
    // ─────────────────────────────────────────────────────────────
    final caches = await validateAndGetCaches(annotation, context);
    if (caches == null) {
      return null;
    }

    // ─────────────────────────────────────────────────────────────
    // STEP 2: Evict specific key or clear all entries
    // ─────────────────────────────────────────────────────────────
    if (annotation.allEntries) {
      // Full cache clear
      for (final cache in caches) {
        try {
          await cache.clear();
        } catch (e, st) {
          await context.onClear(e, st, cache);
        }
      }
    } else {
      // Targeted eviction by key
      final key = await context.generateKey(annotation.keyGenerator);
      for (final cache in caches) {
        try {
          await cache.evict(key);
        } catch (e, st) {
          await context.onEvict(e, st, cache, key);
        }
      }
    }
  }
}