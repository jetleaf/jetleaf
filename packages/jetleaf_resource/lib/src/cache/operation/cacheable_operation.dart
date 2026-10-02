import 'dart:async';

import '../annotations.dart';
import '../core/cache_operation_context.dart';
import 'cache_operation.dart';
import 'validate_and_get_cache.dart';

/// {@template jetleaf_cacheable_operation}
/// Represents the execution logic for a `@Cacheable` method within the Jetleaf
/// resource management framework.
///
/// A **cacheable operation** determines whether a method invocation should be
/// served from cache or executed normally, based on the declarative rules defined
/// in the [`Cacheable`] annotation and the associated runtime [CacheOperationContext].
///
/// ### Overview
/// This operation forms the foundation of Jetleaf’s transparent caching layer.
/// It follows a reactive, non-blocking contract that integrates seamlessly with
/// asynchronous or synchronous methods.
///
/// When invoked, it performs the following sequence:
///
/// 1. **Evaluate exclusion (`unless`) condition** — if this evaluates to `true`,
///    caching is completely bypassed for the current invocation.
/// 2. **Evaluate eligibility (`condition`) expression** — if this evaluates to
///    `false`, the method execution proceeds without cache interaction.
/// 3. **Resolve cache instances** from the context (typically via the
///    [CacheResolver] or PodFactory lookup).
/// 4. **Generate a unique cache key** using the configured [CustomKeyGenerator],
///    method parameters, and context metadata.
/// 5. **Attempt cache retrieval** — if a matching entry is found, it is applied
///    directly as the method result, marking a cache hit.
/// 6. **Mark cache miss** — if no cache contains the requested entry, the context
///    flags the invocation for standard method execution (after which a
///    `CachePut` or similar operation may populate it).
///
/// ### Error Handling
/// - Cache lookup failures (I/O, serialization, or resolver errors) are captured
///   via [CacheErrorType.GET] and reported to the [CacheOperationContext].
/// - A failure in one cache does not terminate the chain; the next cache is
///   attempted automatically.
///
/// ### Thread-Safety and Concurrency
/// Implementations are stateless and safe for concurrent access. The contextual
/// state is isolated in the provided [CacheOperationContext].
///
/// ### Example
/// ```dart
/// @Cacheable(cacheNames: {'users'}, condition: WhenExpr('#args[0] != null'))
/// Future<User?> findUserById(String id) async {
///   return await database.findUser(id);
/// }
/// ```
///
/// ### Behavior Summary
/// | Step | Description | Outcome |
/// |------|--------------|----------|
/// | 1 | Evaluate `unless` | Skip caching if `true` |
/// | 2 | Evaluate `condition` | Skip caching if `false` |
/// | 3 | Resolve caches | May throw if unavailable |
/// | 4 | Generate key | Delegates to key generator |
/// | 5 | Attempt get() | Apply result if hit |
/// | 6 | Cache miss | Proceed with method execution |
///
/// {@endtemplate}
final class CacheableOperation implements CacheOperation {
  /// The `@Cacheable` annotation that defines cache metadata and behavior.
  ///
  /// This includes cache names, key generator, conditions, and resolver configuration.
  final Cacheable annotation;

  /// Creates a new [CacheableOperation] bound to a specific annotation instance.
  const CacheableOperation(this.annotation);

  /// {@macro jetleaf_cacheable_operation}
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
    // STEP 2: Generate a cache key
    // ─────────────────────────────────────────────────────────────
    final key = await context.generateKey(annotation.keyGenerator);

    // ─────────────────────────────────────────────────────────────
    // STEP 3: Attempt retrieval from each cache
    // ─────────────────────────────────────────────────────────────
    for (final cache in caches) {
      try {
        final cachedValue = await cache.get(key);
        if (cachedValue != null) {
          // Cache hit — immediately return cached data
          context.setCachedResult(cachedValue.get());
          return;
        }
      } catch (e, st) {
        // Isolate and record cache-specific exceptions
        await context.onGet(e, st, cache, key);
      }
    }

    // ─────────────────────────────────────────────────────────────
    // STEP 4: No hit found — mark cache miss
    // ─────────────────────────────────────────────────────────────
    context.setCacheMiss();
  }
}