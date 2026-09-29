import 'dart:async';

import 'synchronized_lock.dart';

part '_synchronized.dart';

/// {@template synchronized_async_function}
/// Runs the given [action] in a critical section, ensuring only one
/// execution at a time per [monitor] object.
///
/// This function provides an easy and safe way to serialize access to
/// a shared resource. It retrieves a lock associated with the [monitor]
/// and queues the [action] to be executed when it's safe to do so.
///
/// Reentrant calls from the same Dart [Zone] are allowed (i.e., nested
/// `synchronized()` calls on the same monitor will execute immediately).
///
/// Example:
/// ```dart
/// final lockTarget = Object();
///
/// Future<void> criticalWrite() async {
///   await synchronizedAsync(lockTarget, () async {
///     // only one call at a time per lockTarget
///     await writeToDatabase();
///   });
/// }
/// ```
/// {@endtemplate}
FutureOr<T> synchronizedAsync<T>(Object monitor, FutureOr<T> Function() action) {
  final lock = _lockRegistry.getLock(monitor);
  return lock.synchronizedAsync(action);
}

/// {@template synchronized_function}
/// Runs the given [action] in a critical section, ensuring only one
/// execution at a time per [monitor] object.
///
/// This function provides an easy and safe way to serialize access to
/// a shared resource. It retrieves a lock associated with the [monitor]
/// and queues the [action] to be executed when it's safe to do so.
///
/// Reentrant calls from the same Dart [Zone] are allowed (i.e., nested
/// `synchronized()` calls on the same monitor will execute immediately).
///
/// Example:
/// ```dart
/// final lockTarget = Object();
///
/// void criticalWrite() {
///   synchronized(lockTarget, () {
///     // only one call at a time per lockTarget
///     writeToDatabase();
///   });
/// }
/// ```
/// {@endtemplate}
T synchronized<T>(Object monitor, T Function() action) {
  final lock = _lockRegistry.getLock(monitor);
  return lock.synchronized(action);
}