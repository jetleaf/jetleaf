import 'dart:io';

import 'package:jetleaf_build/jetleaf_build.dart';

import 'meta/class/class.dart';
import 'utils/nested_exception_utils.dart';

/// {@template nested_runtime_exception}
/// Abstract base class for runtime exceptions that can wrap other exceptions.
///
/// This class provides a foundation for creating exception hierarchies where
/// exceptions can contain references to their underlying causes. It's particularly
/// useful for framework-level exceptions that need to preserve the original
/// error context while adding additional information.
///
/// ### Key Features:
/// - Maintains a chain of causation through nested exceptions
/// - Provides root cause analysis capabilities
/// - Supports exception type checking throughout the chain
/// - Offers formatted string representation with cause information
///
/// ### Example:
/// ```dart
/// class DatabaseException extends NestedRuntimeException {
///   DatabaseException(String message, [Throwable? cause]) : super(message, cause);
/// }
///
/// // Usage with nested causes
/// try {
///   // Some database operation
/// } catch (e) {
///   throw DatabaseException('Failed to save user', e);
/// }
///
/// // Analyzing the exception chain
/// catch (e) {
///   if (e is NestedRuntimeException) {
///     print('Root cause: ${e.getRootCause()}');
///     print('Most specific: ${e.getMostSpecificCause()}');
///   }
/// }
/// ```
/// {@endtemplate}
abstract class NestedRuntimeException implements Throwable {
  /// The descriptive message for this exception.
  final String? message;
  
  /// The underlying cause of this exception, if any.
  final Throwable? cause;

  /// {@macro nested_runtime_exception}
  NestedRuntimeException([this.message, this.cause]);

  @override
  String getMessage() => message ?? toString();

  @override
  Throwable? getCause() => cause;

  /// Returns the root cause of this exception by traversing the cause chain.
  /// 
  /// Returns `null` if there is no root cause or if the cause chain is circular.
  Throwable? getRootCause() {
    return NestedExceptionUtils.getRootCause(this);
  }

  /// Returns the most specific cause of this exception.
  /// 
  /// This is either the root cause (if available) or this exception itself.
  Throwable getMostSpecificCause() {
    final rootCause = getRootCause();
    return rootCause ?? this;
  }

  /// Checks if this exception or any exception in its cause chain is of the specified type.
  /// 
  /// ### Example:
  /// ```dart
  /// if (exception.contains(Class<IOException>())) {
  ///   print('Contains an IO exception in the chain');
  /// }
  /// ```
  bool contains(Class? exType) {
    if (exType == null) return false;
    if (exType.isInstance(this)) return true;

    Throwable? cause = getCause();
    if (cause == this) return false;

    if (cause is NestedRuntimeException) {
      return cause.contains(exType);
    } else {
      while (cause != null) {
        if (exType.isInstance(cause)) return true;
        if (cause.getCause() == cause) break;
        if(cause.getCause() is Throwable) {
          cause = cause.getCause() as Throwable;
        } else {
          break;
        }
      }
      return false;
    }
  }

  @override
  String toString() {
    final causeStr = cause != null ? "; nested exception is $cause" : "";
    return "$runtimeType: ${message ?? ""}$causeStr";
  }
}

/// {@template nested_checked_exception}
/// Abstract base class for checked exceptions that can wrap other exceptions.
///
/// Similar to [NestedRuntimeException], this class provides exception chaining
/// capabilities for checked exceptions. It maintains the cause chain and provides
/// utilities for analyzing the exception hierarchy.
///
/// ### Key Features:
/// - Exception chaining for checked exceptions
/// - Root cause analysis and traversal
/// - Type checking throughout the exception chain
/// - Consistent string representation with cause information
///
/// ### Example:
/// ```dart
/// class ValidationException extends NestedCheckedException {
///   ValidationException(String message, [Throwable? cause]) : super(message, cause);
/// }
///
/// // Usage in validation scenarios
/// Future<void> validateUser(User user) async {
///   try {
///     await validateEmail(user.email);
///   } catch (e) {
///     throw ValidationException('User validation failed', e);
///   }
/// }
///
/// // Exception analysis
/// try {
///   await validateUser(user);
/// } catch (e) {
///   if (e is NestedCheckedException) {
///     final rootCause = e.getRootCause();
///     if (e.contains(Class<FormatException>())) {
///       print('Validation failed due to format error');
///     }
///   }
/// }
/// ```
/// {@endtemplate}
abstract class NestedCheckedException implements Throwable {
  /// The descriptive message for this exception.
  final String? message;
  
  /// The underlying cause of this exception, if any.
  final Throwable? cause;

  /// {@macro nested_checked_exception}
  NestedCheckedException(this.message, [this.cause]);

  @override
  String getMessage() => message ?? toString();

  @override
  Throwable? getCause() => cause;

  /// Returns the root cause of this exception by traversing the cause chain.
  /// 
  /// Returns `null` if there is no root cause or if the cause chain is circular.
  Throwable? getRootCause() {
    return NestedExceptionUtils.getRootCause(this);
  }

  /// Returns the most specific cause of this exception.
  /// 
  /// This is either the root cause (if available) or this exception itself.
  Throwable getMostSpecificCause() {
    final rootCause = getRootCause();
    return rootCause ?? this;
  }

  /// Checks if this exception or any exception in its cause chain is of the specified type.
  /// 
  /// ### Example:
  /// ```dart
  /// if (exception.contains(Class<ArgumentError>())) {
  ///   print('Contains an argument error in the chain');
  /// }
  /// ```
  bool contains(Class? exType) {
    if (exType == null) return false;
    if (exType.isInstance(this)) return true;

    Throwable? cause = getCause();
    if (cause == this) return false;

    if (cause is NestedCheckedException) {
      return cause.contains(exType);
    } else {
      while (cause != null) {
        if (exType.isInstance(cause)) return true;
        if (cause.getCause() == cause) break;
        if(cause.getCause() is Throwable) {
          cause = cause.getCause() as Throwable;
        } else {
          break;
        }
      }
      return false;
    }
  }

  @override
  String toString() {
    final causeStr = cause != null ? "; nested exception is $cause" : "";
    return "$runtimeType: ${message ?? ""}$causeStr";
  }
}

/// {@template exception_extensions}
/// Extension on [Exception] to provide utility methods such as printing stack traces.
/// {@endtemplate}
extension ExceptionExtensions on Exception {
  /// Prints the exception and optional [StackTrace] if available.
  ///
  /// Usage:
  /// ```dart
  /// try {
  ///   throw FormatException('Invalid format');
  /// } catch (e) {
  ///   (e as Exception).printStackTrace();
  /// }
  /// ```
  void printStackTrace([StackTrace? stacktrace, bool useErrorPrint = false]) {
    if (useErrorPrint) {
      stderr.write(this);
    } else {
      print(this);
    }

    if (stacktrace != null) {
      if (useErrorPrint) {
        stderr.write(stacktrace);
      } else {
        print(stacktrace);
      }
    }
  }
}

/// {@template error_extensions}
/// Extension on [Error] for printing full stack traces conveniently.
/// {@endtemplate}
extension ErrorExtensions on Error {
  /// Prints the error along with its stack trace.
  void printStackTrace([bool useErrorPrint = false]) {
    if (useErrorPrint) {
      stderr.write(this);
    } else {
      print(this);
    }

    if (stackTrace != null) {
      if (useErrorPrint) {
        stderr.write(stackTrace);
      } else {
        print(stackTrace);
      }
    }
  }
}

/// {@template stacktrace_extensions}
/// Extension on [StackTrace] to print itself.
/// {@endtemplate}
extension StackTraceExtensions on StackTrace {
  /// Prints the [StackTrace] to console.
  void printStackTrace([bool useErrorPrint = false]) {
    if (useErrorPrint) {
      stderr.write(this);
    } else {
      print(this);
    }
  }
}

/// {@template runtime_exception_extensions}
/// Extension on [RuntimeException] to support pretty stack trace printing.
///
/// Usage:
/// ```dart
/// try {
///   throw RuntimeException('Oops!');
/// } catch (e) {
///   if (e is RuntimeException) {
///     e.printStackTrace();
///   }
/// }
/// ```
/// {@endtemplate}
extension RuntimeExceptionExtensions on RuntimeException {
  /// {@macro runtime_exception_extensions}
  void printStackTrace([bool useErrorPrint = false]) {
    if (useErrorPrint) {
      Error.safeToString(toString()).split('\n').forEach(print);
    } else {
      print(toString());
    }
  }
}

/// {@template throwable_extensions}
/// Extension on [Throwable] to support printing stack traces in a unified way.
/// 
/// Useful when catching general Jetleaf exceptions:
/// ```dart
/// catch (e) {
///   if (e is Throwable) {
///     e.printStackTrace();
///   }
/// }
/// ```
/// {@endtemplate}
extension ThrowableExtensions on Throwable {
  /// {@macro throwable_extensions}
  void printStackTrace([bool useErrorPrint = false]) {
    if (useErrorPrint) {
      Error.safeToString(toString()).split('\n').forEach(print);
    } else {
      print(toString());
    }
  }
}
