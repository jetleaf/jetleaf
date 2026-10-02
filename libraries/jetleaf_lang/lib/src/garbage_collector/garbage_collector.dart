import 'dart:async';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../collections/hash_map.dart';

part '_garbage_collector.dart';

/// A lightweight, generic wrapper representing a **tracked runtime resource**
/// managed by the Jetleaf garbage collection system.
///
/// [Garbage] provides a uniform abstraction for associating an arbitrary
/// runtime object with a **stable string key**, enabling deterministic lookup,
/// lifecycle management, and cleanup.
///
/// ---
///
/// #### Purpose
///
/// This class exists to:
/// - Associate runtime objects with a unique identifier
/// - Enable cache- and lifecycle-aware management of resources
/// - Serve as the atomic unit stored inside a [GarbageCollector]
///
/// The generic type [T] represents the actual source object being tracked.
///
/// ---
///
/// #### Generic Handling
///
/// The class is annotated with `@Generic(Garbage)` to ensure Jetleaf can
/// correctly resolve and materialize generic metadata at runtime.
///
/// ---
///
/// #### Example
///
/// ```dart
/// final garbage = collector.getGarbage<MyService>('service:auth');
/// print(garbage?.getSource());
/// ```
@Generic(Garbage)
abstract final class Garbage<T> with EqualsAndHashCode {
  /// Returns the **unique identifier** associated with this garbage entry.
  ///
  /// This key is used by the [GarbageCollector] as the primary lookup
  /// mechanism and must be unique within the collector’s scope.
  String getKey();

  /// Returns the **wrapped source object** managed by this garbage entry.
  ///
  /// This is the actual runtime object being tracked and subject to
  /// cleanup policies enforced by the [GarbageCollector].
  T getSource();
}

/// A centralized, map-backed **runtime garbage manager** used by Jetleaf
/// to track, evict, and periodically clean up cached or temporary objects.
///
/// [GarbageCollector] extends a specialized [HashMap] keyed by `String`,
/// where each entry represents an internally managed garbage item.
///
/// ---
///
/// #### Responsibilities
///
/// - Track runtime objects by key
/// - Enforce size limits and eviction policies
/// - Perform periodic and aggressive cleanup
/// - Provide typed and untyped access to tracked objects
///
/// ---
///
/// #### Lifecycle
///
/// ```text
/// addGarbage → access → cleanup / eviction → removal
/// ```
///
/// Cleanup may be triggered:
/// - Automatically (periodic cleanup)
/// - Aggressively (size or memory pressure)
/// - Manually by the developer
///
/// ---
///
/// #### Equality
///
/// Equality and hash code are derived from internal state via
/// [EqualsAndHashCode], ensuring deterministic comparisons.
abstract final class GarbageCollector extends HashMap<String, _Garbage> with EqualsAndHashCode {
  /// Removes the garbage entry associated with the given [key], if present.
  ///
  /// If an entry exists for [key], it is immediately removed from the
  /// garbage collector and becomes eligible for disposal.
  ///
  /// If no entry exists for the given key, this method performs
  /// **no operation** and does not throw.
  ///
  /// ---
  ///
  /// #### Use Cases
  /// - Explicit cache invalidation
  /// - Manual lifecycle termination of a tracked resource
  /// - Releasing memory tied to a specific runtime key
  ///
  /// ---
  ///
  /// #### Example
  /// ```dart
  /// GC.delete('class:User');
  /// ```
  void delete(String key);

  /// Enables **automatic periodic cleanup** of tracked garbage entries.
  ///
  /// When enabled, the garbage collector will run cleanup logic
  /// at a fixed interval, removing:
  /// - Expired entries
  /// - Evicted entries (based on size limits)
  /// - Internally invalid or stale objects
  ///
  /// The optional [duration] controls how often cleanup is executed.
  ///
  /// ---
  ///
  /// #### Default Behavior
  /// - Runs every **5 minutes** if no duration is provided
  ///
  /// ---
  ///
  /// #### Notes
  /// - The exact cleanup strategy is implementation-dependent
  /// - Safe to call multiple times (implementations may coalesce timers)
  ///
  /// ---
  ///
  /// #### Example
  /// ```dart
  /// // Run cleanup every 10 minutes
  /// GC.enablePeriodicCleanup(Duration(minutes: 10));
  /// ```
  void enablePeriodicCleanup([Duration duration = const Duration(minutes: 5)]);

  /// Returns a **typed garbage entry** associated with the given [key].
  ///
  /// This method enforces the generic type [T] at access time:
  /// - If the key exists *and* the stored value matches [T], the entry is returned
  /// - If the key does not exist, returns `null`
  /// - If the type does not match, returns `null`
  ///
  /// This is the **preferred retrieval method** when the expected type
  /// is known and type safety matters.
  ///
  /// ---
  ///
  /// #### Example
  /// ```dart
  /// final garbage = GC.getGarbage<MyService>('service:auth');
  /// final service = garbage?.getSource();
  /// ```
  Garbage<T>? getGarbage<T>(String key);

  /// Finds a garbage entry associated with the given [key] without
  /// enforcing a generic type constraint.
  ///
  /// This method performs a raw lookup and returns:
  /// - The matching [Garbage] entry if found
  /// - `null` if no entry exists for the key
  ///
  /// ---
  ///
  /// #### Notes
  /// - No type checking is performed
  /// - Intended for diagnostics, debugging, or dynamic scenarios
  ///
  /// ---
  ///
  /// #### Example
  /// ```dart
  /// final garbage = GC.findGarbage('cache:routes');
  /// print(garbage?.getSource());
  /// ```
  Garbage? findGarbage(String key);

  /// Adds a new garbage entry associated with [key] and backed by [source].
  ///
  /// If an entry with the same key already exists:
  /// - The existing entry **may be replaced**
  /// - Cleanup or eviction logic may be triggered
  ///
  /// The returned [Garbage] instance represents the stored entry
  /// and can be used for immediate access.
  ///
  /// ---
  ///
  /// #### Lifecycle
  /// ```text
  /// addGarbage → access → cleanup / eviction → removal
  /// ```
  ///
  /// ---
  ///
  /// #### Example
  /// ```dart
  /// final entry = GC.addGarbage('config:env', envConfig);
  /// print(entry.getSource());
  /// ```
  Garbage<T> addGarbage<T>(String key, T source);

  /// Checks whether a garbage entry exists for the given [key].
  ///
  /// Returns:
  /// - `true` if an entry is currently registered under the key
  /// - `false` otherwise
  ///
  /// This method performs a lightweight existence check without
  /// retrieving or materializing the underlying value.
  ///
  /// ---
  ///
  /// #### Use Cases
  /// - Guarded creation (`if (!exists) add`)
  /// - Conditional cleanup or replacement
  /// - Diagnostics and cache inspection
  ///
  /// ---
  ///
  /// #### Example
  /// ```dart
  /// if (!GC.exists('runtime:scanner')) {
  ///   GC.addGarbage('runtime:scanner', scanner);
  /// }
  /// ```
  bool exists(String key);

  /// Retrieves an existing garbage entry for [key] or **creates and stores**
  /// a new one if it does not already exist.
  ///
  /// This method provides an **idempotent, type-safe** way to ensure that a
  /// garbage entry exists for a given key.
  ///
  /// #### Use Cases
  ///
  /// - Lazy initialization of cached runtime resources
  /// - Ensuring singleton-like objects exist in the collector
  /// - Avoiding duplicate allocations for the same logical resource
  ///
  /// ---
  ///
  /// #### Example
  ///
  /// ```dart
  /// final cache = GC.getOrCreate<Map<String, int>>(
  ///   'stats:counter',
  ///   <String, int>{},
  /// );
  ///
  /// cache.getSource()['hits'] = 1;
  /// ```
  ///
  /// ---
  ///
  /// #### Notes
  ///
  /// - This method **never overwrites** an existing entry
  /// - Cleanup policies may still evict the returned entry later
  Garbage<T> getOrCreate<T>(String key, T source);

  /// Finds an existing garbage entry for [key] or **adds a new untyped entry**
  /// if none exists.
  ///
  /// Unlike [getOrCreate], this method does **not enforce generic typing**
  /// and always returns a raw [Garbage] instance.
  /// 
  /// ---
  ///
  /// #### Example
  ///
  /// ```dart
  /// final entry = GC.findOrAdd(
  ///   'runtime:resolver',
  ///   RuntimeResolver(),
  /// );
  ///
  /// final resolver = entry.getSource() as RuntimeResolver;
  /// ```
  ///
  /// ---
  ///
  /// #### Comparison
  ///
  /// | Method        | Typed | Overwrites | Primary Use Case              |
  /// |---------------|-------|------------|-------------------------------|
  /// | getOrCreate   | ✅    | ❌         | Safe, typed lazy initialization |
  /// | findOrAdd     | ❌    | ❌         | Dynamic or internal caching     |
  ///
  /// ---
  ///
  /// #### Notes
  ///
  /// - Existing entries are never replaced
  /// - Cleanup policies may evict entries at any time
  Garbage findOrAdd(String key, Object source);

  /// Triggers **aggressive cleanup** when internal thresholds are exceeded.
  ///
  /// This method is enabled by default and is typically invoked automatically,
  /// but it is exposed for advanced or manual control scenarios.
  ///
  /// ⚠️ Intended primarily for internal use.
  void performCleanupWhenNecessary();

  /// Immediately performs cleanup of garbage entries according to the
  /// collector’s eviction and retention policies.
  ///
  /// This may remove expired, unused, or excess items.
  void cleanup();

  /// Sets the **maximum number of garbage entries** allowed in the collector.
  ///
  /// ---
  ///
  /// #### Default
  /// - **100 entries**
  ///
  /// When the limit is exceeded, aggressive cleanup or eviction
  /// strategies may be applied.
  ///
  /// ---
  ///
  /// #### Example
  ///
  /// ```dart
  /// GC.setMaxItemSize(500);
  /// ```
  void setMaxItemSize(int maxSize);
}

/// The **global, singleton garbage collector** instance used by Jetleaf.
///
/// This instance is lazily initialized and shared across the runtime,
/// providing a centralized garbage management facility.
final GarbageCollector GC = _GarbageCollector._();