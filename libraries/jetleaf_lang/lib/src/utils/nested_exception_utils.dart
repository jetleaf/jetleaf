import 'package:jetleaf_build/jetleaf_build.dart';

/// {@template nested_exception_utils}
/// Utility class providing static methods for working with nested exception hierarchies.
///
/// This class offers helper methods for analyzing and traversing exception chains,
/// particularly useful when working with [NestedRuntimeException] and
/// [NestedCheckedException] instances. It provides a centralized location for
/// common exception analysis operations.
///
/// ## Key Features
///
/// - **Root Cause Detection**: Find the original exception in a chain
/// - **Most Specific Cause**: Get the deepest exception for detailed error information
/// - **Null Safety**: Handles null exceptions gracefully
/// - **Circular Reference Protection**: Prevents infinite loops in malformed exception chains
///
/// ## Usage
///
/// Use these utilities for exception analysis and debugging:
///
/// ```dart
/// try {
///   performComplexOperation();
/// } catch (e) {
///   final rootCause = NestedExceptionUtils.getRootCause(e);
///   final mostSpecific = NestedExceptionUtils.getMostSpecificCause(e);
///   
///   logger.error('Root cause: ${rootCause?.runtimeType}');
///   logger.error('Most specific: ${mostSpecific.runtimeType}');
/// }
/// ```
///
/// ## Exception Chain Analysis
///
/// ```dart
/// void analyzeException(Throwable? exception) {
///   if (exception == null) {
///     print('No exception to analyze');
///     return;
///   }
///   
///   print('Original exception: ${exception.runtimeType}');
///   
///   final rootCause = NestedExceptionUtils.getRootCause(exception);
///   if (rootCause != null && rootCause != exception) {
///     print('Root cause: ${rootCause.runtimeType}');
///   }
///   
///   final mostSpecific = NestedExceptionUtils.getMostSpecificCause(exception);
///   print('Most specific: ${mostSpecific.runtimeType}');
/// }
/// ```
/// {@endtemplate}
abstract class NestedExceptionUtils {
  /// {@macro nested_exception_utils}
  /// 
  /// Retrieves the root cause of an exception by traversing the cause chain.
  /// 
  /// This method follows the chain of exception causes to find the original
  /// exception that initiated the error cascade. It handles null inputs gracefully
  /// and includes protection against circular references in the exception chain.
  /// 
  /// ## Parameters
  /// 
  /// - [original]: The exception to analyze, may be `null`
  /// 
  /// ## Return Value
  /// 
  /// - Returns the root cause exception if a cause chain exists
  /// - Returns `null` if the input is `null` or has no causes
  /// 
  /// ## Example
  /// 
  /// ```dart
  /// // Simple usage
  /// final rootCause = NestedExceptionUtils.getRootCause(exception);
  /// if (rootCause != null) {
  ///   print('Root cause: ${rootCause.runtimeType}');
  /// }
  /// 
  /// // Exception handling based on root cause
  /// try {
  ///   performOperation();
  /// } catch (e) {
  ///   final root = NestedExceptionUtils.getRootCause(e);
  ///   
  ///   if (root is NetworkException) {
  ///     handleNetworkError(root);
  ///   } else if (root is FileSystemException) {
  ///     handleFileSystemError(root);
  ///   } else {
  ///     handleGenericError(e);
  ///   }
  /// }
  /// ```
  /// 
  /// ## Chain Traversal Example
  /// 
  /// ```dart
  /// // Exception chain: ServiceException -> DatabaseException -> NetworkException
  /// try {
  ///   connectToDatabase();
  /// } catch (NetworkException e) {
  ///   throw DatabaseException('Database connection failed', e);
  /// }
  /// 
  /// try {
  ///   userService.createUser(data);
  /// } catch (DatabaseException e) {
  ///   throw ServiceException('User creation failed', e);
  /// }
  /// 
  /// // Later, when handling the ServiceException:
  /// final rootCause = NestedExceptionUtils.getRootCause(serviceException);
  /// // rootCause will be the original NetworkException
  /// ```
  /// 
  /// ## Null Safety
  /// 
  /// ```dart
  /// // Safe to call with null
  /// final rootCause = NestedExceptionUtils.getRootCause(null); // Returns null
  /// 
  /// // Safe to call with exceptions that have null causes
  /// final simpleException = Exception('Simple error');
  /// final rootCause2 = NestedExceptionUtils.getRootCause(simpleException); // Returns null
  /// ```
  /// 
  /// ## Circular Reference Protection
  /// 
  /// The method includes protection against circular references:
  /// 
  /// ```dart
  /// // Even with circular references, this won't cause infinite loops
  /// final e1 = ServiceException('Error 1');
  /// final e2 = ServiceException('Error 2', e1);
  /// e1.cause = e2; // Creates circular reference
  /// 
  /// final rootCause = NestedExceptionUtils.getRootCause(e1); // Still works safely
  /// ```
  static Throwable? getRootCause(Throwable? original) {
    if (original == null) {
      return null;
    }
    Throwable? rootCause;
    Throwable? cause = original;
    while (cause != null && cause != rootCause) {
      rootCause = cause;
      cause = cause.getCause() as Throwable?;
    }
    return rootCause;
  }

  /// Returns the most specific cause of an exception.
  /// 
  /// This method provides a convenient way to get the deepest exception in the
  /// cause chain, which is often the most specific and useful for debugging.
  /// If the exception has no root cause, it returns the original exception.
  /// 
  /// ## Parameters
  /// 
  /// - [original]: The exception to analyze (must not be `null`)
  /// 
  /// ## Return Value
  /// 
  /// - Returns the root cause if one exists
  /// - Returns the original exception if no root cause exists
  /// 
  /// ## Example
  /// 
  /// ```dart
  /// try {
  ///   performComplexOperation();
  /// } catch (e) {
  ///   final mostSpecific = NestedExceptionUtils.getMostSpecificCause(e);
  ///   
  ///   // Log the most specific error for debugging
  ///   logger.error('Most specific error: ${mostSpecific.runtimeType}');
  ///   logger.error('Error message: ${mostSpecific.getMessage()}');
  ///   
  ///   // Handle based on the most specific type
  ///   if (mostSpecific is ValidationException) {
  ///     showValidationErrors(mostSpecific);
  ///   } else if (mostSpecific is NetworkException) {
  ///     showNetworkErrorDialog();
  ///   }
  /// }
  /// ```
  /// 
  /// ## Debugging Usage
  /// 
  /// ```dart
  /// void logExceptionDetails(Throwable exception) {
  ///   print('Exception type: ${exception.runtimeType}');
  ///   print('Exception message: ${exception.getMessage()}');
  ///   
  ///   final mostSpecific = NestedExceptionUtils.getMostSpecificCause(exception);
  ///   if (mostSpecific != exception) {
  ///     print('Most specific type: ${mostSpecific.runtimeType}');
  ///     print('Most specific message: ${mostSpecific.getMessage()}');
  ///   } else {
  ///     print('No nested causes found');
  ///   }
  /// }
  /// ```
  /// 
  /// ## Error Classification
  /// 
  /// ```dart
  /// String classifyError(Throwable exception) {
  ///   final mostSpecific = NestedExceptionUtils.getMostSpecificCause(exception);
  ///   
  ///   switch (mostSpecific.runtimeType) {
  ///     case NetworkException:
  ///       return 'Network Error';
  ///     case ValidationException:
  ///       return 'Validation Error';
  ///     case SecurityException:
  ///       return 'Security Error';
  ///     case FileSystemException:
  ///       return 'File System Error';
  ///     default:
  ///       return 'Unknown Error';
  ///   }
  /// }
  /// ```
  /// 
  /// ## Comparison with getRootCause
  /// 
  /// ```dart
  /// // Both methods often return the same result
  /// final rootCause = NestedExceptionUtils.getRootCause(exception);
  /// final mostSpecific = NestedExceptionUtils.getMostSpecificCause(exception);
  /// 
  /// // The difference: getMostSpecificCause never returns null
  /// if (rootCause != null) {
  ///   assert(rootCause == mostSpecific);
  /// } else {
  ///   assert(mostSpecific == exception); // Falls back to original
  /// }
  /// ```
  static Throwable getMostSpecificCause(Throwable original) {
    final rootCause = getRootCause(original);
    return rootCause ?? original;
  }
}