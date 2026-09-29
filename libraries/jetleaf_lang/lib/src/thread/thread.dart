import 'dart:async';
import 'dart:isolate';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';
import 'local_thread.dart';

part 'thread_registry.dart';
part 'thread_message.dart';

/// {@template thread}
/// Emulates Java's `Thread` class using Dart's `Isolate`.
///
/// A [Thread] represents a separate unit of execution and encapsulates a Dart
/// `Isolate` under the hood. Each [Thread] has its own memory space and runs
/// independently from others.
///
/// This class provides Java-style threading behaviors such as:
/// - `start()`
/// - `join()`
/// - `interrupt()`
/// - static utilities like `sleep()`, `currentThread()`, and `getThreadLocal(id)`
///
/// Example usage:
/// ```dart
/// void entry(ThreadMessage message) {
///   print("Thread started with data: ${message.data}");
///   message.replyPort.send('done');
/// }
///
/// void main() async {
///   final thread = Thread(entry, initialMessage: 'Hello', debugName: 'worker-1');
///   await thread.start();
///   await thread.join();
///   print('Thread completed.');
/// }
/// ```
/// {@endtemplate}
@Generic(Thread)
final class Thread<T> {
  final Function(ThreadMessage) _entryPoint;
  final dynamic initialMessage;
  Isolate? _isolate;
  ReceivePort? _receivePort;
  Completer<void>? _joinCompleter;
  String? _debugName;

  /// {@macro thread}
  Thread(this._entryPoint, {this.initialMessage, String? debugName}) {
    _debugName = debugName ?? 'DartThread-${DateTime.now().microsecondsSinceEpoch}';
  }

  /// {@template dart_thread_start}
  /// Starts execution of this [Thread] in a new Isolate.
  ///
  /// The entry function passed to this thread must be a top-level or static
  /// function. Once started, the Isolate will execute that function with
  /// an internal [ThreadMessage] containing a `SendPort` and optional data.
  ///
  /// Throws [InvalidArgumentException] if called more than once.
  ///
  /// Example:
  /// ```dart
  /// await thread.start();
  /// ```
  /// {@endtemplate}
  Future<void> start() async {
    if (_isolate != null) {
      throw InvalidArgumentException('DartThread already started.');
    }

    _receivePort = ReceivePort();
    _joinCompleter = Completer<void>();

    _isolate = await Isolate.spawn<ThreadMessage>(
      _entryPoint,
      ThreadMessage(_receivePort!.sendPort, initialMessage),
      debugName: _debugName,
      errorsAreFatal: true,
    );

    _activeThreads[_isolate!] = this; // Register the thread instance

    _receivePort!.listen((message) {
      if (message == 'done') {
        _joinCompleter?.complete();
        _receivePort?.close();
        _activeThreads.remove(_isolate); // Unregister on completion
        _isolate = null;
      } else if (message is List && message[0] == 'error') {
        _joinCompleter?.completeError(ThreadSpawnException(message[1], cause: message[2]));
        _receivePort?.close();
        _activeThreads.remove(_isolate); // Unregister on error
        _isolate = null;
      }
    }, onError: (error) {
      _joinCompleter?.completeError(error);
      _receivePort?.close();
      _activeThreads.remove(_isolate); // Unregister on error
      _isolate = null;
    }, onDone: () {
      // This callback is invoked when the ReceivePort is closed.
      // If the completer is not yet completed, it means:
      // 1. The Isolate exited without sending 'done' or an explicit error message.
      // 2. The Isolate was killed by `interrupt()`.
      // In both cases, it's not a successful completion from the perspective of `join()`.
      if (!(_joinCompleter?.isCompleted ?? false)) {
        // If it was killed by interrupt(), interrupt() already called completeError.
        // If it exited unexpectedly, we should complete with an error.
        _joinCompleter?.completeError(ThreadInterruptedException('Isolate $_debugName terminated unexpectedly or was interrupted.'));
      }
      _activeThreads.remove(_isolate); // Ensure unregistration on any done event
    });
  }

  /// {@template dart_thread_join}
  /// Waits for the Isolate to complete execution.
  ///
  /// Equivalent to Java's `thread.join()`. Returns a [Future] that completes
  /// when the Isolate sends a 'done' signal or terminates.
  ///
  /// Throws [InvalidArgumentException] if called before `start()`.
  ///
  /// Example:
  /// ```dart
  /// await thread.join();
  /// ```
  /// {@endtemplate}
  Future<void> join() {
    if (_joinCompleter == null) {
      throw InvalidArgumentException('DartThread has not been started.');
    }
    return _joinCompleter!.future;
  }

  /// {@template dart_thread_is_alive}
  /// Returns `true` if the underlying Isolate is still running.
  ///
  /// Example:
  /// ```dart
  /// if (thread.isAlive) {
  ///   print('Thread is still running');
  /// }
  /// ```
  /// {@endtemplate}
  bool get isAlive => _isolate != null;

  /// {@template dart_thread_interrupt}
  /// Forcefully terminates the underlying Isolate.
  ///
  /// This is the equivalent of Java's `Thread.interrupt()`, but due to Dart's
  /// isolate nature, it forcefully kills the isolate using `Isolate.kill()`.
  ///
  /// Optional [priority] allows setting the urgency of the termination.
  ///
  /// If the thread was not completed, the [ThreadInterruptedException] is thrown.
  ///
  /// Example:
  /// ```dart
  /// thread.interrupt();
  /// ```
  /// {@endtemplate}
  void interrupt({int priority = Isolate.immediate}) {
    if (_isolate != null) {
      _isolate!.kill(priority: priority);
      _activeThreads.remove(_isolate); // Unregister
      _isolate = null;
      _receivePort?.close();
      if (!(_joinCompleter?.isCompleted ?? false)) {
        _joinCompleter?.completeError(ThreadInterruptedException('Isolate $_debugName was interrupted.'));
      }
    }
  }

  /// {@template dart_thread_current_name}
  /// Returns the name of the currently executing isolate.
  ///
  /// Equivalent to Java's `Thread.currentThread().getName()`.
  ///
  /// Example:
  /// ```dart
  /// print(Thread.currentThreadName);
  /// ```
  /// {@endtemplate}
  static String? get currentThreadName => Isolate.current.debugName;

  /// {@template dart_thread_current_isolate}
  /// Returns the [Isolate] object representing the currently executing isolate.
  ///
  /// Equivalent to Java's `Thread.currentThread()`.
  ///
  /// Example:
  /// ```dart
  /// final current = Thread.currentThreadIsolate;
  /// ```
  /// {@endtemplate}
  static Isolate get currentThreadIsolate => Isolate.current;

  /// {@template dart_thread_sleep}
  /// Asynchronous sleep operation for the current isolate.
  ///
  /// Equivalent to Java's `Thread.sleep(Duration)`, but in Dart it's non-blocking.
  ///
  /// Example:
  /// ```dart
  /// await Thread.sleep(Duration(seconds: 2));
  /// ```
  /// {@endtemplate}
  static Future<void> sleep(Duration duration) => Future.delayed(duration);

  /// {@template dart_thread_current_thread}
  /// Returns the [Thread] instance representing the currently executing Isolate.
  ///
  /// This allows code running inside a spawned Isolate to get a reference
  /// back to the `Thread` object that spawned it.
  /// Returns `null` if the current Isolate was not spawned by a `Thread` instance.
  ///
  /// Example:
  /// ```dart
  /// final currentThread = Thread.currentThread();
  /// print('Current Thread Debug Name: ${currentThread?.debugName}');
  /// ```
  /// {@endtemplate}
  static Thread? currentThread() {
    return _activeThreads[Isolate.current];
  }

  /// {@template dart_thread_get_thread_local}
  /// Retrieves a [LocalThread] instance by its unique ID.
  ///
  /// This is useful when you need to access a specific [LocalThread]
  /// from a different part of your application, especially across Isolate boundaries
  /// where you might only have the ID.
  ///
  /// ThreadLocalExample:
  /// ```dart
  /// final myLocal = Thread.getThreadLocal<String>(someId);
  /// final value = myLocal.get();
  /// if (value != null) {
  ///   print(value);
  /// }
  /// ```
  /// {@endtemplate}
  static LocalThread<T> getThreadLocal<T>(int id) {
    return LocalThread<T>();
  }
}