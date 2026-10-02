part of 'synchronized.dart';

/// {@template lock_registry}
/// A global registry for tracking monitor objects and their corresponding locks.
///
/// This registry ensures that a unique [`SynchronizedLock`] is assigned per monitor object.
/// It uses a [Finalizer] to automatically clean up locks when the monitor is garbage collected.
///
/// Internally, it maintains:
/// - A map of `Object -> SynchronizedLock`
/// - A finalizer to remove locks once the object is no longer used
/// {@endtemplate}
final _lockRegistry = _MonitorRegistry();

/// Internal map storing the association of monitor objects to their lock instances.
final Map<Object, SynchronizedLock> _locks = {};

/// {@template monitor_registry}
/// Registry that manages and returns locks for monitor objects.
///
/// This ensures that each unique object gets a single [SynchronizedLock] instance,
/// and the lock is automatically removed from the internal cache when the object
/// is garbage collected (via [Finalizer]).
///
/// This is useful for monitor-based synchronization where critical sections
/// must be protected per object.
///
/// ### Example
/// ```dart
/// final lock = _lockRegistry.getLock(userSession);
/// await lock.synchronizedAsync(() {
///   // perform thread-safe operations on userSession
/// });
/// ```
/// {@endtemplate}
class _MonitorRegistry {
  final Finalizer<Object> _cleanup = Finalizer((key) {
    _locks.remove(key);
  });

  /// {@macro monitor_registry}
  _MonitorRegistry();

  /// {@template monitor_registry_get_lock}
  /// Returns the [SynchronizedLock] associated with the given [monitor] object.
  ///
  /// If no lock exists yet for the monitor, a new one is created and stored.
  /// A [Finalizer] is also attached to clean up the lock entry when the monitor
  /// is no longer reachable.
  ///
  /// Example:
  /// ```dart
  /// final lock = _lockRegistry.getLock(userSession);
  /// await lock.synchronizedAsync(() {
  ///   // critical section tied to userSession
  /// });
  /// ```
  /// {@endtemplate}
  SynchronizedLock getLock(Object monitor) {
    return _locks.putIfAbsent(monitor, () {
      final lock = SynchronizedLock();
      final token = _LockKey(monitor);
      _cleanup.attach(monitor, token, detach: Object());
      return lock;
    });
  }
}

/// {@template monitor_registry_lock_key}
/// Internal wrapper key used for identifying monitored objects
/// in the [_MonitorRegistry]'s [Finalizer].
///
/// This class exists to decouple identity tracking and cleanup logic.
/// {@endtemplate}
class _LockKey {
  /// The monitor object being tracked.
  final Object monitor;

  /// {@macro monitor_registry_lock_key}
  const _LockKey(this.monitor);
}