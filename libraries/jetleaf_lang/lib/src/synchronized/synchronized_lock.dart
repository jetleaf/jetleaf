import 'dart:async';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';

/// {@template synchronized_lock}
/// A reentrant async lock for critical section execution.
///
/// This class serializes access to an async [FutureOr] function
/// by maintaining a queue. Reentrancy is supported within the same [Zone].
///
/// Features:
/// - Queue-based task execution for `synchronizedAsync`
/// - Reentrancy (based on Dart zones) for both `synchronized` and `synchronizedAsync`
///
/// Example:
/// ```dart
/// final lock = SynchronizedLock();
///
/// await lock.synchronizedAsync(() async {
///   // Only one async block can execute here at a time
/// });
///
/// lock.synchronized(() {
///   // Only one sync block can execute here at a time,
///   // and it will not queue if another zone holds the lock.
/// });
/// ```
/// {@endtemplate}
class SynchronizedLock {
  final List<_LockRequest> _queue = []; // Using List as a simple queue
  bool _isLocked = false; // Indicates if the lock is currently held
  Zone? _currentLockingZone; // The Zone that currently holds the lock
  int _reentrantCount = 0; // How many times the current Zone has re-entered

  /// {@template synchronized_lock_synchronized_async}
  /// Executes the [action] within an asynchronous synchronized block.
  ///
  /// Only one [action] may execute at a time per lock. If the current [Zone]
  /// has already acquired the lock, the function is treated as reentrant and allowed.
  /// Otherwise, the action is queued and executed when the lock becomes available.
  ///
  /// Example:
  /// ```dart
  /// await lock.synchronizedAsync(() async {
  ///   // Do something asynchronous
  /// });
  /// ```
  /// {@endtemplate}
  Future<T> synchronizedAsync<T>(FutureOr<T> Function() action) {
    final completer = Completer<T>();

    // Handle reentrancy: if the current zone already holds the lock, execute immediately.
    if (_isLocked && _currentLockingZone == Zone.current) {
      _reentrantCount++;
      try {
        completer.complete(action());
      } catch (e, s) {
        completer.completeError(e, s); // Propagate original error
      } finally {
        _reentrantCount--;
        // The lock is not released here; it's released by the original acquiring task.
      }
      return completer.future;
    }

    // If not reentrant, or if lock is not held by current zone, queue the request.
    final request = _LockRequest<T>(action, completer);
    _queue.add(request);
    _tryAcquireLockAndRun(); // Attempt to run immediately if lock is free
    return completer.future;
  }

  /// {@template synchronized_lock_synchronized_sync}
  /// Executes the [action] within a synchronous synchronized block.
  ///
  /// This function attempts to acquire the lock immediately.
  /// If the lock is already held by a *different* [Zone], it will throw
  /// a [ReentrantSynchronizedException] as it cannot wait asynchronously.
  /// Reentrant calls from the same [Zone] are allowed and execute immediately.
  ///
  /// Example:
  /// ```dart
  /// lock.synchronized(() {
  ///   // Do something synchronous
  /// });
  /// ```
  /// {@endtemplate}
  T synchronized<T>(T Function() action) {
    // Handle reentrancy: if the current zone already holds the lock, execute immediately.
    if (_isLocked && _currentLockingZone == Zone.current) {
      _reentrantCount++;
      try {
        return action();
      } catch (e) {
        rethrow; // Re-throw the original exception
      } finally {
        _reentrantCount--;
        if (_reentrantCount == 0) {
          _currentLockingZone = null;
          _isLocked = false; // Release the lock
        }
      }
    } else { // Not reentrant, or lock is free
      // If lock is held by another zone, throw an error for synchronous call
      if (_isLocked) {
        throw ReentrantSynchronizedException('Synchronized lock is held by another zone. Cannot acquire synchronously.');
      }

      // Acquire lock and run immediately
      _isLocked = true;
      _currentLockingZone = Zone.current;
      _reentrantCount = 1; // First acquisition for this zone
      try {
        return action();
      } catch (e) {
        rethrow; // Re-throw the original exception
      } finally {
        _reentrantCount--;
        if (_reentrantCount == 0) {
          _currentLockingZone = null;
          _isLocked = false; // Release the lock
        }
      }
    }
  }

  // Attempts to acquire the lock and run the first queued task if available.
  void _tryAcquireLockAndRun() {
    if (_isLocked || _queue.isEmpty) return;

    _isLocked = true; // Acquire the lock
    final _LockRequest request = _queue.removeAt(0); // Dequeue the first task

    // Run the task in a new Zone to capture its context for reentrancy
    runZoned(() async {
      try {
        _currentLockingZone = Zone.current; // Set the zone that acquired this lock
        _reentrantCount = 1; // This is the first acquisition for this zone
        final result = await request.action(); // Execute the user's action
        request.completer.complete(result);
      } catch (e, s) {
        request.completer.completeError(e, s); // Propagate original error
      } finally {
        _reentrantCount = 0; // Reset reentrant count for this lock acquisition
        _currentLockingZone = null;
        _isLocked = false; // Release the lock
        _runNext(); // Try to run the next queued task
      }
    }, zoneValues: {
      // Optionally, you could pass some context here if needed for the action
    });
  }

  // Called when a task completes to try and run the next one.
  void _runNext() {
    // This method is called after a task completes and releases the lock.
    // It should only try to run the next task if the lock is truly free.
    if (!_isLocked && _queue.isNotEmpty) {
      _tryAcquireLockAndRun();
    }
  }
}

/// {@template lock_request}
/// Wraps a function call to be queued by [SynchronizedLock].
///
/// It stores a `Future<void>`-returning callback and provides
/// a simple `.run()` call used by the lock queue.
/// {@endtemplate}
@Generic(_LockRequest)
class _LockRequest<T> {
  /// The actual logic to execute.
  final FutureOr<T> Function() action;
  final Completer<T> completer;

  /// {@macro lock_request}
  _LockRequest(this.action, this.completer);
}