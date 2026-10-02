import 'package:jetleaf_build/jetleaf_build.dart';

/// {@template thread_interrupted_exception}
/// Exception thrown when an Isolate (thread) is unexpectedly interrupted during
/// execution.
///
/// This typically represents a cancellation or termination signal being sent
/// to an active isolate during processing. Use this exception when modeling
/// thread-like behaviors with Dart Isolates to signal user-defined interruptions.
///
/// Example:
/// ```dart
/// if (isInterrupted) {
///   throw ThreadInterruptedException("Worker isolate was interrupted.");
/// }
/// ```
/// {@endtemplate}
class ThreadInterruptedException extends RuntimeException {
  /// {@macro thread_interrupted_exception}
  ThreadInterruptedException(super.message);

  @override
  String toString() => 'ThreadInterruptedException: $message\n$stackTrace\n$cause';
}

/// {@template thread_spawn_exception}
/// Exception thrown when an Isolate fails to start properly due to
/// issues such as invalid entrypoint, unsupported data, or environment errors.
///
/// This is typically used to wrap failures from `Isolate.spawn()`
/// or similar thread creation operations in Jetleaf or thread libraries.
///
/// Example:
/// ```dart
/// try {
///   await Isolate.spawn(...);
/// } catch (e) {
///   throw ThreadSpawnException("Failed to start isolate", cause: e);
/// }
/// ```
/// {@endtemplate}
class ThreadSpawnException extends RuntimeException {
  /// {@macro thread_spawn_exception}
  ThreadSpawnException(super.message, {super.cause});

  @override
  String toString() => 'ThreadSpawnException: $message\n$stackTrace\n$cause';
}

/// General exception for language related errors.
/// 
/// Example usage:
/// ```dart
/// try {
///   throw LangException('Invalid argument');
/// } catch (e) {
///   print(e); // LangException: Invalid argument
/// }
/// ```
class LangException extends RuntimeException {
  LangException(super.message, {super.cause});
  
  @override
  String toString() => 'LangException: $message\n$stackTrace\n$cause';
}

/// Exception thrown when an invalid argument is provided.
/// 
/// Example usage:
/// ```dart
/// try {
///   throw InvalidArgumentException('Invalid argument');
/// } catch (e) {
///   print(e); // InvalidArgumentException: Invalid argument
/// }
/// ```
class InvalidArgumentException extends LangException {
  InvalidArgumentException(super.message, {super.cause});
  
  @override
  String toString() => 'InvalidArgumentException: $message\n$stackTrace\n$cause';
}

/// Exception thrown when an invalid format is provided.
/// 
/// Example usage:
/// ```dart
/// try {
///   throw InvalidFormatException('Invalid format');
/// } catch (e) {
///   print(e); // InvalidFormatException: Invalid format
/// }
/// ```
class InvalidFormatException extends LangException {
  InvalidFormatException(super.message, {super.cause});
  
  @override
  String toString() => 'InvalidFormatException: $message\n$stackTrace\n$cause';
}

/// Exception thrown when a guarantee is not met. Mostly used to behave like [NoGuaranteeException]
/// 
/// Example usage:
/// ```dart
/// try {
///   throw NoGuaranteeException('No guarantee');
/// } catch (e) {
///   print(e); // NoGuaranteeException: No guarantee
/// }
/// ```
class NoGuaranteeException extends LangException {
  NoGuaranteeException(super.message, {super.cause});
  
  @override
  String toString() => 'NoGuaranteeException: $message\n$stackTrace\n$cause';
}

/// Exception thrown when an I/O operation fails.
/// 
/// This is the base class for all I/O-related exceptions in the streams library.
/// It provides information about what went wrong during an I/O operation.
/// 
/// ## Example Usage
/// ```dart
/// try {
///   final input = FileInputStream('nonexistent.txt');
///   await input.read(buffer);
/// } catch (e) {
///   if (e is IOException) {
///     print('I/O error: ${e.message}');
///     if (e.cause != null) {
///       print('Caused by: ${e.cause}');
///     }
///   }
/// }
/// ```
class IOException extends RuntimeException {
  IOException(super.message, {super.cause});
}

/// Exception thrown when an attempt is made to use a stream that has been closed.
/// 
/// This exception is thrown when operations are attempted on streams that have
/// already been closed and are no longer available for I/O operations.
/// 
/// ## Example Usage
/// ```dart
/// final input = FileInputStream('data.txt');
/// await input.close();
/// 
/// try {
///   await input.read(buffer); // This will throw StreamClosedException
/// } catch (e) {
///   if (e is StreamClosedException) {
///     print('Stream is already closed');
///   }
/// }
/// ```
class StreamClosedException extends IOException {
  /// Creates a new [StreamClosedException] with an optional [message].
  /// 
  /// ## Parameters
  /// - [message]: Optional custom message (defaults to standard message)
  /// 
  /// ## Example
  /// ```dart
  /// throw StreamClosedException('Input stream was closed unexpectedly');
  /// ```
  StreamClosedException([String? message]) : super(message ?? 'Stream has been closed');
}

/// Exception thrown when the end of a stream is reached unexpectedly.
/// 
/// This exception indicates that an operation expected more data but the
/// end of the stream was encountered.
/// 
/// ## Example Usage
/// ```dart
/// try {
///   final data = await input.readFully(1024); // Expects exactly 1024 bytes
/// } catch (e) {
///   if (e is EndOfStreamException) {
///     print('Reached end of stream before reading all expected data');
///   }
/// }
/// ```
class EndOfStreamException extends IOException {
  /// Creates a new [EndOfStreamException] with an optional [message].
  /// 
  /// ## Parameters
  /// - [message]: Optional custom message (defaults to standard message)
  /// 
  /// ## Example
  /// ```dart
  /// throw EndOfStreamException('Expected 1024 bytes but only 512 available');
  /// ```
    EndOfStreamException([String? message]) : super(message ?? 'End of stream reached');
}

/// {@template no_such_element_exception}
/// Thrown when an operation attempts to access an element that does not exist.
///
/// This is commonly used in iteration or stream operations, similar to Java's
/// `NoSuchElementException`.
///
/// ---
///
/// ### ❗ Example:
/// ```dart
/// final list = <int>[];
/// if (list.isEmpty) {
///   throw NoSuchElementException('List is empty');
/// }
/// ```
/// {@endtemplate}
class NoSuchElementException extends IOException {
  /// {@macro no_such_element_exception}
  NoSuchElementException([String? message]) : super(message ?? 'No element found');
}

/// {@template comparator_exception}
/// Exception thrown when a comparator is used with a type that is not comparable.
/// 
/// Example usage:
/// ```dart
/// try {
///   final list = [1, 'a', 2];
///   list.sort(Comparator.naturalOrder());
/// } catch (e) {
///   if (e is ComparatorException) {
///     print(e.message); // "Cannot compare 1 and a. a is not comparable."
///   }
/// }
/// ```
/// 
/// ---
/// {@endtemplate}
class ComparatorException extends LangException {
  /// {@macro comparator_exception}
  ComparatorException(super.message);
}

/// {@template reentrant_synchronized_exception}
/// Exception thrown when a synchronized block is reentered from the same zone.
/// 
/// This exception is thrown when a synchronized block is entered from the same zone
/// multiple times, which is not allowed.
/// 
/// ## Example
/// ```dart
/// try {
///   synchronized(() {
///     // Do something
///   });
/// } catch (e) {
///   if (e is ReentrantSynchronizedException) {
///     print('Synchronized block reentered from the same zone');
///   }
/// }
/// ```
/// 
/// ---
/// {@endtemplate}
class ReentrantSynchronizedException extends LangException {
  /// {@macro reentrant_synchronized_exception}
  ReentrantSynchronizedException([String? message, Object? cause]) : super(
    message ?? 'Synchronized block reentered from the same zone', cause: cause
  );
}

/// {@template malformed_url_exception}
/// Thrown to indicate that a malformed URL has occurred.
///
/// This exception is used when a [Url] or [Uri] string does not conform
/// to expected format or cannot be parsed properly.
///
/// ### Example:
/// ```dart
/// try {
///   final url = Url.parse('ht!tp://::invalid-url');
/// } on MalformedUrlException catch (e) {
///   print(e); // MalformedUrlException: Invalid scheme (URL: ht!tp://::invalid-url)
/// }
/// ```
/// {@endtemplate}
class MalformedUrlException extends RuntimeException {
  /// The offending URI, if available.
  final Uri? uri;

  /// {@macro malformed_url_exception}
  ///
  /// [message] describes the specific error, and [uri] is the invalid URI.
  MalformedUrlException(super.message, {this.uri});

  @override
  String toString() {
    if (uri != null) {
      return 'MalformedUrlException: $message (URL: $uri)';
    }
    return 'MalformedUrlException: $message';
  }
}

/// {@template network_exception}
/// Thrown to indicate an I/O error during network operations.
///
/// This general-purpose exception wraps lower-level errors such as
/// [SocketException], [HttpException], or [HandshakeException] to provide
/// a consistent error type for networking failures.
///
/// ### Example:
/// ```dart
/// try {
///   final connection = HttpUrlConnection(Url.parse('https://example.com'));
///   await connection.connect();
/// } on NetworkException catch (e) {
///   print(e); // NetworkException: Failed to connect...
/// }
/// ```
/// {@endtemplate}
class NetworkException extends RuntimeException {
  /// {@macro network_exception}
  ///
  /// [message] should describe the problem clearly, and [cause] may contain
  /// a wrapped exception (e.g. `SocketException`, `HttpException`).
  NetworkException(super.message, {super.cause});

  @override
  String toString() {
    if (cause != null) {
      return 'NetworkException: $message (Cause: $cause)';
    }
    return 'NetworkException: $message';
  }
}

/// {@template unsupported_operation_exception}
/// Thrown to indicate that a requested operation is not supported.
///
/// This exception extends [RuntimeException] and is typically used
/// when a method or feature is not implemented or intentionally unsupported.
///
/// ## Example
/// ```dart
/// throw UnsupportedOperationException('Removing items is not supported.');
/// ```
///
/// Optionally, a cause can be passed to provide the underlying reason:
/// ```dart
/// throw UnsupportedOperationException(
///   'Serialization not supported',
///   cause: Exception('Missing serializer'),
/// );
/// ```
/// {@endtemplate}

class UnsupportedOperationException extends RuntimeException {
  /// {@macro unsupported_operation_exception}
  UnsupportedOperationException(super.message, {super.cause});

  @override
  String toString() {
    if (cause != null) {
      return 'UnsupportedOperationException: $message (Cause: $cause)';
    }
    return 'UnsupportedOperationException: $message';
  }
}

/// {@template uri_path_matching_exception}
/// Exception thrown when a URI or route path fails to match a defined template
/// in a path matcher.
///
/// Common scenarios include:
/// - Invalid placeholders
/// - Missing required path segments
/// - Mismatched patterns or formats
///
/// Useful for debugging route resolution and pattern-based matching systems.
/// {@endtemplate}
class UriPathMatchingException extends RuntimeException {
  /// {@macro uri_path_matching_exception}
  UriPathMatchingException(super.message);
}

/// {@template illegal_state_exception}
/// Signals that a method has been invoked at an illegal or inappropriate time.
///
/// Often used when a component has not yet been initialized or is already shut down,
/// and a method requiring a valid state is called.
///
/// Example:
/// ```dart
/// throw IllegalStateException('ApplicationContext is not active');
/// ```
/// {@endtemplate}
class IllegalStateException extends RuntimeException {
  /// {@macro illegal_state_exception}
  IllegalStateException(super.message, {super.cause});

  @override
  String toString() {
    if (cause == null) {
      return 'IllegalStateException: $message';
    }
    return 'IllegalStateException: $message (Cause: $cause)';
  }
}

/// {@template security_exception}
/// Exception thrown when a security violation occurs.
///
/// This exception is used to signal that a security policy has been violated,
/// typically during reflection or access control operations.
///
/// ## Example
/// ```dart
/// throw SecurityException('Access denied: Insufficient permissions');
/// ```
/// {@endtemplate}
class SecurityException extends RuntimeException {
  /// {@macro security_exception}
  SecurityException(super.message);
}

/// {@template multiple_source_exception}
/// Exception thrown when multiple class definitions with the same name are found.
///
/// This occurs when the reflection system encounters classes with identical names
/// from different sources/libraries, making type resolution ambiguous.
///
/// {@template multiple_source_exception_usage}
/// ## Resolution
/// Apply the `@Source` annotation to disambiguate:
/// ```dart
/// @Source('MyClass', 'package:myapp/my_class.dart')
/// class MyClass {}
/// ```
/// {@endtemplate}
///
/// {@template multiple_source_exception_example}
/// ## Example
/// ```dart
/// try {
///   reflector.getClass('User');
/// } on MultipleSourceException catch (e) {
///   print('Conflict found: ${e.conflicts}');
///   // Apply @Source annotation to resolve
/// }
/// ```
/// {@endtemplate}
/// {@endtemplate}
class MultipleSourceException extends RuntimeException {
  /// The name of the conflicting class
  final String name;

  /// List of source locations where the class was found
  final List<String> conflicts;

  /// Creates an exception for multiple class definitions
  ///
  /// {@template multiple_source_constructor}
  /// Parameters:
  /// - [name]: The duplicated class name
  /// - [conflicts]: List of source URIs where the class appears
  /// {@endtemplate}
  MultipleSourceException(this.name, this.conflicts) : super(
'''
Multiple classes named '$name' at ${conflicts.join('\n')}. In order to perform better type resolution,
Jetleaf provides alternative solution to dart's limitations. Use `@Source($name, 'package:foo/bar.dart')`
on any of the conflicting classes.
''',
  );
}

/// {@template type_resolution_exception}
/// Exception thrown when type lookup or resolution fails.
///
/// This typically occurs when:
/// - A type cannot be found in the reflection registry
/// - Generic type parameters cannot be resolved
/// - Type information is incomplete or corrupted
///
/// {@template type_resolution_exception_usage}
/// ## Common Causes
/// - Missing reflection metadata
/// - Incorrect type names
/// - Unavailable dependencies
/// - Reflection scope limitations
/// {@endtemplate}
///
/// {@template type_resolution_exception_example}
/// ## Example
/// ```dart
/// try {
///   reflector.getClass('NonExistentType');
/// } on TypeResolutionException catch (e) {
///   print('Type resolution failed: ${e.message}');
/// }
/// ```
/// {@endtemplate}
/// {@endtemplate}
class TypeResolutionException extends RuntimeException {
  /// Creates an exception for type resolution failures
  ///
  /// {@template type_resolution_constructor}
  /// Parameters:
  /// - [message]: Detailed explanation of the resolution failure
  /// {@endtemplate}
  TypeResolutionException(super.message);
}

/// {@template illegalArgumentException}
/// Thrown when a method is passed an illegal or inappropriate argument.
/// 
/// This exception is thrown during reflection operations when the
/// provided arguments don't match the expected types or when invalid
/// values are passed to reflection methods.
/// 
/// {@endtemplate}
class IllegalArgumentException extends RuntimeException {
  /// {@macro illegalArgumentException}
  IllegalArgumentException(super.message);
  
  @override
  String toString() => 'IllegalArgumentException: $message';
}

/// {@template bundler_exception}
/// An exception thrown when an asset cannot be loaded by the Jetleaf bundler.
///
/// This exception typically occurs when trying to read or resolve a file
/// that does not exist, is inaccessible, or fails during the bundling process.
///
/// The [assetPath] provides the full relative or absolute path of the asset
/// that failed to load, and the optional [cause] can point to the underlying
/// exception that triggered the failure.
///
/// Example usage:
/// ```dart
/// throw AssetLoaderException('Failed to load template', 'templates/home.html');
/// ```
/// {@endtemplate}
class AssetLoaderException extends RuntimeException {
  /// The full path to the asset that could not be loaded.
  final String assetPath;

  /// {@macro bundler_exception}
  ///
  /// - [message]: A human-readable error message describing the failure.
  /// - [assetPath]: The relative or absolute path of the asset.
  /// - [cause]: (Optional) The underlying cause of the error.
  AssetLoaderException(super.message, this.assetPath, {super.cause});

  /// Returns a human-readable string representation of the exception,
  /// including the asset path and the underlying cause, if present.
  @override
  String toString() {
    final buffer = StringBuffer('AssetLoaderException: $message');
    buffer.writeln('\nAsset path: $assetPath');
    if (cause != null) {
      buffer.writeln('Caused by: $cause');
    }
    return buffer.toString();
  }
}