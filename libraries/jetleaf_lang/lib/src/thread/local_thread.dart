import 'dart:async';
import 'dart:isolate';

import 'package:jetleaf_build/jetleaf_build.dart';
import 'package:meta/meta.dart';

import '../commons/typedefs.dart';

part 'local_thread_key.dart';
part 'local_thread_registry.dart';
part 'local_thread_storage_bucket.dart';

/// {@template thread_local}
/// A Dart equivalent of Java's `ThreadLocal`, scoped to the current [Isolate].
///
/// `ThreadLocal<T>` provides isolate-local storage for values that are only
/// visible within the currently running [Isolate]. This is useful when you
/// want to maintain separate values across isolates, such as request-scoped
/// data in a concurrent server.
///
/// Internally, each isolate maintains its own value store via a
/// [LocalThreadStorageBucket], so values set in one isolate will not affect
/// others.
///
/// ### Example
/// ```dart
/// final threadLocal = ThreadLocal<int>();
///
/// // In isolate A
/// threadLocal.set(42);
/// print(threadLocal.get()); // prints: 42
///
/// // In isolate B (separate execution context)
/// print(threadLocal.get()); // prints: null
/// ```
///
/// This API abstracts away the complexity of isolate-specific data
/// management by allowing you to interact with values as if they were
/// thread-local, even though Dart uses isolates instead of OS threads.
/// {@endtemplate}
@Generic(LocalThread)
final class LocalThread<T> {
  final LocalThreadKey _key;

  /// {@macro thread_local}
  LocalThread() : _key = LocalThreadKey.generate();

  /// {@template thread_local_initial_value}
  /// Returns the initial value for this [LocalThread].
  ///
  /// This method is called when a new [LocalThread] is created and no value
  /// has been set yet. The default implementation returns `null`, but you can
  /// override it to provide a custom initial value.
  /// {@endtemplate}
  @protected
  T? initialValue() {
    return null;
  }

  /// Returns the value associated with this [LocalThread] in the current [Isolate].
  ///
  /// Returns `null` if no value has been set yet.
  ///
  /// ### Example
  /// ```dart
  /// final local = ThreadLocal<String>();
  /// print(local.get()); // null
  ///
  /// local.set('hello');
  /// print(local.get()); // hello
  /// ```
  T? get() {
    final bucket = isolateLocalValueStore.getBucket<T>(Isolate.current, _key);
    return bucket.get();
  }

  /// Returns the current value associated with this [LocalThread],
  /// or stores and returns [value] if no value has been set yet.
  ///
  /// This is a convenient helper that ensures a value always exists for
  /// the current [Isolate].  
  /// If the value is already present, it is returned unchanged.  
  /// If the value is absent, [value] is stored using [set] and then returned.
  ///
  /// ### Example
  /// ```dart
  /// final local = ThreadLocal<int>();
  ///
  /// print(local.get()); // null
  ///
  /// // Sets the value because none exists yet.
  /// final first = local.getOrPut(42);
  /// print(first); // 42
  ///
  /// // Returns the existing value without overwriting it.
  /// final second = local.getOrPut(99);
  /// print(second); // 42
  /// ```
  ///
  /// Returns the existing or newly stored [value].
  T getOrPut(T value) {
    final bucket = isolateLocalValueStore.getBucket<T>(Isolate.current, _key);
    final result = bucket.get();

    if (result != null) {
      return result;
    }

    set(value);
    return value;
  }

  /// Sets a value for this [LocalThread] in the current [Isolate].
  ///
  /// Overwrites any existing value for this isolate.
  ///
  /// ### Example
  /// ```dart
  /// final local = ThreadLocal<int>();
  /// local.set(100);
  /// print(local.get()); // 100
  /// ```
  void set(T value) {
    final bucket = isolateLocalValueStore.getBucket<T>(Isolate.current, _key);
    bucket.set(value);
  }

  /// Removes the value associated with this [LocalThread] in the current [Isolate].
  ///
  /// After removal, `get()` will return `null` until a new value is set.
  ///
  /// ### Example
  /// ```dart
  /// final local = ThreadLocal<String>();
  /// local.set('temp');
  /// print(local.get()); // temp
  ///
  /// local.remove();
  /// print(local.get()); // null
  /// ```
  void remove() {
    final bucket = isolateLocalValueStore.getBucket<T>(Isolate.current, _key);
    bucket.remove();
  }
}

/// {@template named_thread_local}
/// A specialized [LocalThread] that includes a descriptive name for better debugging and identification.
/// 
/// Extends the standard [LocalThread] class by adding a human-readable [name] that helps
/// identify the purpose of the thread-local variable during debugging, logging, and maintenance.
/// 
/// ## Key Features:
/// - Provides meaningful names for thread-local variables
/// - Enhanced toString() output for better debugging
/// - Maintains all functionality of standard ThreadLocal
/// 
/// ## Usage Example:
/// ```dart
/// // Create a named thread-local variable for user session data
/// final userSession = NamedThreadLocal<Map<String, dynamic>>('userSession');
/// 
/// // In each thread, you can set and get values
/// userSession.set({'userId': 123, 'username': 'john_doe'});
/// 
/// // Later retrieve the value
/// final session = userSession.get();
/// print(session); // {'userId': 123, 'username': 'john_doe'}
/// 
/// // toString() shows the descriptive name
/// print(userSession.toString()); // 'userSession'
/// ```
/// 
/// ## When to Use:
/// - When you need multiple thread-local variables and want to distinguish them clearly
/// - For better debugging and logging output
/// - In frameworks where thread-local variables need descriptive identifiers
/// {@endtemplate}
@Generic(NamedLocalThread)
final class NamedLocalThread<T> extends LocalThread<T> {
  /// {@template named_thread_local_name}
  /// The descriptive name of this thread-local variable.
  /// 
  /// This name is used for identification, debugging, and logging purposes.
  /// It should be descriptive enough to understand the purpose of the
  /// thread-local variable.
  /// {@endtemplate}
  final String name;

  /// {@template named_thread_local_constructor}
  /// Creates a [NamedLocalThread] with the given descriptive [name].
  /// 
  /// ## Parameters:
  /// - [name]: A descriptive name for this thread-local variable
  /// 
  /// ## Example:
  /// ```dart
  /// // Create named thread-local variables for different purposes
  /// final transactionContext = NamedThreadLocal<Transaction>('transactionContext');
  /// final securityContext = NamedThreadLocal<SecurityToken>('securityContext');
  /// final requestScope = NamedThreadLocal<Request>('requestScope');
  /// ```
  /// {@endtemplate}
  NamedLocalThread(this.name);

  @override
  String toString() => name;
}

/// {@template supplied_named_thread_local}
/// A [NamedLocalThread] that provides an initial value using a [Supplier] function.
/// 
/// Extends [NamedLocalThread] to include a supplier function that provides
/// the initial value for the thread-local variable when it is first accessed
/// in a thread.
/// 
/// ## Key Features:
/// - Descriptive name for identification
/// - Supplier function for initial values
/// - Thread-safe initialization
/// - Combines naming with convenient initialization
/// 
/// ## Usage Example:
/// ```dart
/// // Create a thread-local with initial value supplier
/// final counter = SuppliedNamedThreadLocal<int>(
///   'requestCounter',
///   () => 0, // Initial value for each thread
/// );
/// 
/// // In each thread, the initial value is automatically set to 0
/// print(counter.get()); // 0 (initial value from supplier)
/// 
/// // Increment the counter
/// counter.set(counter.get()! + 1);
/// print(counter.get()); // 1
/// 
/// // New thread gets fresh initial value
/// await Isolate.run(() {
///   print(counter.get()); // 0 (new thread, new initial value)
/// });
/// ```
/// {@endtemplate}
@Generic(SuppliedNamedLocalThread)
final class SuppliedNamedLocalThread<T> extends NamedLocalThread<T> {
  /// {@template supplied_named_thread_local_supplier}
  /// The supplier function that provides the initial value for each thread.
  /// 
  /// This function is called when the thread-local variable is first accessed
  /// in a thread to provide the initial value.
  /// 
  /// ## Example:
  /// ```dart
  /// // Supplier that creates a new UUID for each thread
  /// final threadId = SuppliedNamedThreadLocal<String>(
  ///   'threadId',
  ///   () => Uuid().v4(), // Different initial value for each thread
  /// );
  /// 
  /// // Supplier that returns a new instance for each thread
  /// final threadLocalService = SuppliedNamedThreadLocal<MyService>(
  ///   'threadService',
  ///   () => MyService(), // New instance for each thread
  /// );
  /// ```
  /// {@endtemplate}
  final Supplier<T> supplier;

  /// {@template supplied_named_thread_local_constructor}
  /// Creates a [SuppliedNamedLocalThread] with the given [name] and [supplier] function.
  /// 
  /// ## Parameters:
  /// - [name]: A descriptive name for this thread-local variable
  /// - [supplier]: A function that provides the initial value for each thread
  /// 
  /// ## Example:
  /// ```dart
  /// // Various initialization patterns
  /// 
  /// // Simple value initialization
  /// final defaultSettings = SuppliedNamedThreadLocal<Map<String, dynamic>>(
  ///   'defaultSettings',
  ///   () => {'theme': 'dark', 'language': 'en'},
  /// );
  /// 
  /// // Complex object initialization
  /// final databaseConnection = SuppliedNamedThreadLocal<Connection>(
  ///   'dbConnection',
  ///   () => Database.connect('thread_local_db'),
  /// );
  /// 
  /// // Stateful initialization with logging
  /// final activityLogger = SuppliedNamedThreadLocal<Logger>(
  ///   'activityLogger',
  ///   () {
  ///     final logger = Logger('ThreadActivity');
  ///     logger.info('Thread-local logger initialized');
  ///     return logger;
  ///   },
  /// );
  /// ```
  /// {@endtemplate}
  SuppliedNamedLocalThread(super.name, this.supplier);

  @override
  T? initialValue() => supplier();
}