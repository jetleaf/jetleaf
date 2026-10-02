part of 'thread.dart';

/// {@template thread_active_threads}
/// Internal map storing active [Thread] instances, keyed by their [Isolate].
///
/// This map is used to track all running threads. When a new [Thread] is started,
/// it is registered here with its associated [Isolate] as the key.
///
/// This allows the static method `Thread.currentThread()` to correctly return
/// the [Thread] instance corresponding to the currently executing isolate.
///
/// ### Usage (internal)
/// This is not intended for public use. Instead, use `Thread.currentThread()`
/// for safe access:
///
/// ```dart
/// final thread = Thread.currentThread();
/// print('Running in thread: ${thread.name}');
/// ```
/// {@endtemplate}
final Map<Isolate, Thread> _activeThreads = {};