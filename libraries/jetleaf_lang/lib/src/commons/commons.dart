import 'dart:async' show FutureOr;

import 'package:jetleaf_build/jetleaf_build.dart';

import '../io/base.dart';
import '../extensions/others/t.dart';
import '../meta/class/class.dart';

/// {@template jetleaf_provider}
/// A generic provider interface for supplying instances of type [T].
///
/// [Provider] abstracts the creation or retrieval of an object, allowing
/// flexible, lazy, or pre-configured provisioning of dependencies or values.
///
/// ### Responsibilities
/// - Supply instances of type [T] to consumers.
/// - Decouple object creation from object usage.
/// - Can be implemented for lazy, singleton, or dynamic provisioning.
///
/// ### Example
/// ```dart
/// final provider = SimpleProvider<int>(42);
/// print(provider.get()); // 42
/// ```
///
/// ### See Also
/// - [SimpleProvider]
/// {@endtemplate}
@Generic(Provider)
abstract interface class Provider<T> with EqualsAndHashCode {
  /// Returns an instance of type [T].
  ///
  /// ### Example
  /// ```dart
  /// final value = provider.get();
  /// ```
  T get();
}

/// {@template jetleaf_simple_provider}
/// Simple, immutable implementation of [Provider] that always returns
/// a pre-defined, constant value.
///
/// Useful for testing, configuration values, or stateless provisioning
/// where a fixed object should be returned every time.
///
/// ### Example
/// ```dart
/// final provider = SimpleProvider<String>("Hello, Jetleaf!");
/// print(provider.get()); // "Hello, Jetleaf!"
/// ```
///
/// ### Characteristics
/// - Immutable: the value cannot be changed after construction.
/// - Thread-safe by default due to immutability.
/// {@endtemplate}
@Generic(SimpleProvider)
final class SimpleProvider<T> implements Provider<T> {
  /// The value to be supplied by this provider.
  final T _value;

  /// Constructs a new [SimpleProvider] with the given [_value].
  ///
  /// ### Example
  /// ```dart
  /// final provider = SimpleProvider<int>(123);
  /// print(provider.get()); // 123
  /// ```
  const SimpleProvider(this._value);

  @override
  T get() => _value;

  @override
  List<Object?> equalizedProperties() => [_value];
}

// ---------------------------------------------------------------------------------------------------------------
// INSTANCE
// ---------------------------------------------------------------------------------------------------------------

/// {@template instance}
/// A utility class for type checking, similar to Java's `instanceof`.
/// It also provides additional methods for type checking.
/// 
/// {@endtemplate}
final class Instance {
  /// {@macro instance}
  Instance();

  /// Checks whether [value] is of type [T].
  ///
  /// Example:
  /// ```dart
  /// bool isString = Instance.of<String>("Hello"); // true
  /// bool isInt = Instance.of<int>(42); // true
  /// ```
  static bool of<T>(dynamic value) {
    return value is T || value == T;
  }

  /// Checks whether [value] is of type [type].
  ///
  /// Example:
  /// ```dart
  /// bool isString = Instance.isType("Hello", String); // true
  /// bool isInt = Instance.isType(42, int); // true
  /// ```
  static bool isType(dynamic value, Type type) {
    if(value.runtimeType == type) {
      return true;
    }

    if(value.runtimeType.toString() == type.toString()) {
      return true;
    }

    if(type.toString().startsWith("Map")) {
      return value is Map;
    }

    return value.runtimeType.toString().replaceAll("_", "") == type.toString().replaceAll("_", "");
  }

  /// Checks if [value] is a numeric type (`int` or `double`).
  ///
  /// Example:
  /// ```dart
  /// bool isNumeric = Instance.isNumeric(42); // true
  /// ```
  static bool isNumeric(dynamic value) {
    return value is num || value == num;
  }

  /// Checks if [value] is a list.
  ///
  /// Example:
  /// ```dart
  /// bool isList = Instance.isList([1, 2, 3]); // true
  /// ```
  static bool isList(dynamic value) {
    return value is List || value == List;
  }

  /// Checks if [value] is a map.
  ///
  /// Example:
  /// ```dart
  /// bool isMap = Instance.isMap({"key": "value"}); // true
  /// ```
  static bool isMap(dynamic value) {
    return value is Map || value == Map;
  }

  /// This allows a value of type T or T?
  /// to be treated as a value of type T?.
  ///
  /// We use this so that APIs that have become
  /// non-nullable can still be used with `!` and `?`
  /// to support older versions of the API as well.
  static T? ambiguate<T>(T? value) => value;

  /// Checks if [value] is null.
  ///
  /// Example:
  /// ```dart
  /// bool isNull = Instance.nullable(null); // true
  /// bool isNotNull = Instance.nullable("Hello"); // false
  /// ```
  static bool nullable<T>(T? id) {
    return id == null;
  }

  /// Converts [value] to a string.
  ///
  /// Example:
  /// ```dart
  /// String str = TypeUtils.valueOf(100); // "100"
  /// ```
  static String valueOf(dynamic value) => "$value";

  /// Converts a dynamic value into a boolean.
  ///
  /// - Strings: `"true"` (case-insensitive) → `true`, `"false"` → `false`
  /// - Integers: `1` → `true`, `0` → `false`
  /// - Booleans: Returns the value itself.
  /// - Other values: Defaults to `false`
  static bool toBoolean<T>(T? value) {
    if(value.isNotNull) {
      if(value.instanceOf<String>() || Instance.of<String>(value)) {
        String result = (value as String).trim();

        return bool.tryParse(result.toLowerCase()) ?? false;
      } else if(value.instanceOf<int>() || Instance.of<int>(value)) {
        int result = value as int;

        return result.equals(1);
      } else if(value.instanceOf<bool>() || Instance.of<bool>(value)) {
        bool result = value as bool;

        return result;
      }
    }

    return false;
  }
}

// ---------------------------------------------------------------------------------------------------------------
// NULL
// ---------------------------------------------------------------------------------------------------------------

/// {@template null_placeholder}
/// A minimal placeholder class representing a **null-like object**.
///
/// This class provides a concrete type that can be instantiated where an
/// object reference is required, but no actual data or behavior is needed.
/// It acts as a sentinel or marker in situations where `null` itself cannot
/// be used (e.g., to avoid nullable type issues or for generic type placeholders).
///
/// ### Typical Use Cases
/// - **Sentinel Values**: Use `Null` to represent a "no-op" or empty value
///   in data structures or function calls where a non-null object is required.
/// - **Generic Placeholders**: Useful in generic programming when a type
///   parameter must be instantiated but no meaningful data exists.
/// - **Testing and Mocking**: Provides a lightweight stand-in object
///   for tests that require an instance but do not need any real behavior.
///
/// ### Example
/// ```dart
/// Object value = Null();
/// if (value is Null) {
///   print("This is a placeholder instance");
/// }
/// ```
///
/// ⚠️ **Important Notes**
/// - This class **does not contain any state**.
/// - It is **different from Dart's built-in `Null` type** but may serve
///   a similar conceptual purpose in certain contexts.
/// - Avoid using this in place of `null` unless specifically needed for
///   type safety or API design constraints.
///
/// {@endtemplate}
final class Null {
  /// The class api of [Null]
  static final Class<Null> CLASS = Class<Null>(null, PackageNames.LANG);
  
  /// {@macro null_placeholder}
  Null();
}

// ---------------------------------------------------------------------------------------------------------------
// TRY WITH
// ---------------------------------------------------------------------------------------------------------------

/// {@template try_with_action}
/// A function that performs an operation using a given [resource].
///
/// It can be synchronous or asynchronous, and is used in conjunction
/// with the `tryWith` utility to ensure proper resource cleanup.
///
/// Example:
/// ```dart
/// Future<void> logToFile(MyFile file) async {
///   await file.write('Hello, world');
/// }
/// ```
/// {@endtemplate}
typedef TryWithAction<T> = FutureOr<void> Function(T resource);

/// {@template try_with}
/// Utility for automatically closing a resource after use.
///
/// Ensures that the [resource] is closed using `resource.close()`
/// regardless of whether the [action] throws or completes normally.
///
/// This is similar in spirit to Java's `try-with-resources` construct.
///
/// Example usage:
/// ```dart
/// class MyFile extends AutoCloseable {
///   Future<void> write(String content) async {
///     print('Writing: $content');
///   }
///
///   @override
///   Future<void> close() async {
///     print('File closed');
///   }
/// }
///
/// void main() async {
///   final file = MyFile();
///   await tryWith(file, (f) async {
///     await f.write('Hello, world');
///   });
///   // Output:
///   // Writing: Hello, world
///   // File closed
/// }
/// ```
/// {@endtemplate}
Future<void> tryWith<T extends Closeable>(T resource, TryWithAction<T> action) async {
  try {
    await action(resource);
  } finally {
    await resource.close();
  }
}

// ---------------------------------------------------------------------------------------------------------------
// THROWING
// ---------------------------------------------------------------------------------------------------------------

/// {@template throwing_supplier}
/// A functional interface that supplies a value and may throw an exception.
///
/// This typedef represents a function that takes no parameters and returns
/// a value of type [T], possibly throwing an exception.
///
/// This is especially useful in APIs where you want to defer the execution
/// of a potentially risky or expensive operation, such as file access,
/// database queries, or complex computations.
///
/// ### Example
/// ```dart
/// final supplier = ThrowingSupplier<String>(() {
///   if (DateTime.now().second % 2 == 0) {
///     throw Exception('Random failure');
///   }
///   return 'Success!';
/// });
///
/// try {
///   final result = supplier.get();
///   print('Result: $result');
/// } catch (e) {
///   print('Error occurred: $e');
/// }
/// ```
/// {@endtemplate}
typedef ThrowingSupplier<T> = T Function();

/// {@macro throwing_supplier}
///
/// This extension provides a `.get()` method to call the supplier
/// in a more expressive and object-oriented way.
///
/// Instead of calling `supplier()`, you can write `supplier.get()`,
/// improving readability in functional or builder-style code.
///
/// ### Example
/// ```dart
/// final supplier = ThrowingSupplier<int>(() => 42);
/// print(supplier.get()); // prints 42
/// ```
extension ThrowingSupplierGet<T> on ThrowingSupplier<T> {
  /// Invokes the supplier and returns the result.
  ///
  /// This method may throw any exception that occurs during execution
  /// of the underlying supplier function.
  T get() => this();
}