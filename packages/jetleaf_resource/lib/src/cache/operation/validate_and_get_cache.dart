import 'dart:async';

import '../annotations.dart';
import '../core/cache_operation_context.dart';
import '../storage/cache_storage.dart';

/// Validates cache applicability for the given [annotation] and [context],
/// returning the resolved cache instances if caching should proceed.
///
/// The validation process involves three steps:
///
/// 1. **Resolve cache instances**  
///    Uses the provided [CacheOperationContext] to locate or create the
///    cache(s) referenced in the [Cacheable] annotation.
///
/// 2. **Evaluate the "unless" condition**  
///    If the `unless` predicate evaluates to `true`, caching is explicitly
///    disabled for this invocation, and the method returns `null`.
///
/// 3. **Evaluate the "condition" predicate**  
///    If the `condition` predicate evaluates to `false`, the caching criteria
///    are not met, and the method returns `null`.
///
/// Returns a `Future` that completes with the collection of `CacheStorage`
/// instances if caching is allowed, or `null` if caching should be skipped.
Future<Iterable<CacheStorage>?> validateAndGetCaches<T>(Cacheable annotation, CacheOperationContext<T> context) async {
  // ─────────────────────────────────────────────────────────────
  // STEP 1: Resolve cache instances
  // ─────────────────────────────────────────────────────────────
  final caches = await context.resolveCaches(annotation, context.getMethodInvocation());

  // ─────────────────────────────────────────────────────────────
  // STEP 2: Set resources from cache to the context
  // ─────────────────────────────────────────────────────────────
  context.setResources(caches.map((cache) => cache.getResource()).toList());

  // ─────────────────────────────────────────────────────────────
  // STEP 3: Evaluate the "unless" condition — skip if true
  // ─────────────────────────────────────────────────────────────
  final unlessResult = await annotation.unless.shouldApply(context);
  if (unlessResult) {
    // Caching is explicitly disabled for this invocation.
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 4: Evaluate the "condition" — skip if false
  // ─────────────────────────────────────────────────────────────
  final conditionResult = await annotation.condition.shouldApply(context);
  if (!conditionResult) {
    // Does not meet caching criteria.
    return null;
  }

  return caches;
}