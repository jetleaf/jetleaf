import 'dart:mirrors' as mirrors;

/// A simple string interning pool for deduplicating identical strings in memory.
///
/// Qualified names are repeated thousands of times across the runtime system.
/// Interning ensures only one copy of each unique string is retained, reducing
/// GC pressure and memory usage.
final class StringInternPool {
  StringInternPool._();

  static final Map<String, String> _pool = {};

  /// Returns the interned version of [value].
  ///
  /// If [value] is already in the pool, returns the existing reference.
  /// Otherwise, stores and returns [value] itself.
  static String intern(String value) {
    return _pool.putIfAbsent(value, () => value);
  }

  /// Returns the number of unique interned strings.
  static int get size => _pool.length;

  /// Clears the intern pool. Call sparingly — existing references remain valid
  /// but future calls to [intern] will re-create pool entries.
  static void clear() => _pool.clear();
}

/// {@template reflection_utils}
/// Lightweight runtime reflection utility built on top of `dart:mirrors`.
///
/// This class provides convenience methods for inspecting runtime types
/// and instances to determine their *qualified names*, i.e. the fully
/// resolved identity of a symbol within its library or package context.
///
/// Qualified names are formatted as:
///
/// ```
/// package:my_app/models/user.dart.User
/// dart:core.String
/// ```
///
/// This utility is used internally within Jetleaf for tasks like
/// class resolution, dependency registration, and annotation scanning.
///
/// > **Note:** Reflection via `dart:mirrors` may not be supported in all
/// runtime environments (e.g. Flutter AOT). This utility is primarily
/// intended for development or server-side usage.
/// {@endtemplate}
final class ReflectionUtils {
  /// Private constructor to prevent instantiation.
  const ReflectionUtils._();

  /// {@template reflection_utils.keyword}
  /// Fallback keyword used when reflection metadata cannot be resolved.
  ///
  /// This constant represents a **sentinel value** returned by reflection
  /// utilities when a library URI, source location, or symbol origin
  /// cannot be determined via `dart:mirrors`.
  ///
  /// ### When is this used?
  /// - The reflected symbol has no associated source location.
  /// - The runtime environment strips or omits mirror metadata.
  /// - Reflection is partially unsupported (e.g. certain AOT contexts).
  ///
  /// ### Example
  /// ```dart
  /// final name = ReflectionUtils.findQualifiedName(myObject);
  /// // → "unknown.MyClass"
  /// ```
  ///
  /// ### Notes
  /// - This value is **not** a real library or package URI.
  /// - Consumers should treat it as a signal that the origin
  ///   could not be reliably inferred.
  /// {@endtemplate}
  static const String KEYWORD = 'unknown';

  // ─────────────────────────────────────────────────────────────
  // Instance Reflection
  // ─────────────────────────────────────────────────────────────

  /// {@template reflection_utils.find_qualified_name}
  /// Returns the **qualified name** of an object instance.
  ///
  /// This method inspects the runtime type of the given [instance]
  /// and constructs a fully-qualified symbol reference including
  /// its originating library URI.
  ///
  /// ### Example
  /// ```dart
  /// final user = User();
  /// print(ReflectionUtils.findQualifiedName(user));
  /// // → "package:my_app/models/user.dart.User"
  /// ```
  ///
  /// ### Returns
  /// A string containing the qualified name, e.g.
  /// `dart:core.String` or `package:jetleaf_core/src/log/log_property.dart.LogProperty`.
  ///
  /// ### Notes
  /// - If the source URI cannot be resolved, `"unknown"` is used as a fallback.
  /// {@endtemplate}
  static String findQualifiedName(Object instance) {
    final mirror = mirrors.reflect(instance);
    final classMirror = mirror.type;

    final className = mirrors.MirrorSystem.getName(classMirror.simpleName);

    // Library URI is taken from owner or type location
    final libraryUri = classMirror.location?.sourceUri.toString() ?? classMirror.owner?.location?.sourceUri.toString() ?? KEYWORD;

    return buildQualifiedName(className, libraryUri);
  }

  /// Checks if the given [instance] or [mirrors.TypeMirror] represents a **record type**.
  ///
  /// {@template reflection_utils.is_this_a_record}
  /// This method inspects the runtime type of the provided object or the
  /// `TypeMirror` to determine whether it is a Dart 3 record type.
  ///
  /// ### Behavior
  /// - If [instance] is a `TypeMirror`, it verifies:
  ///   - The simple name is `"Record"`.
  ///   - The reflected type matches the built-in Dart `Record` type.
  /// - If [instance] is an actual object, it reflects its type and
  ///   recursively applies the same checks.
  ///
  /// ### Example
  /// ```dart
  /// final r = (42, "hello");
  /// print(ReflectionUtils.isThisARecord(r)); // → true (Dart 3+)
  ///
  /// final str = "not a record";
  /// print(ReflectionUtils.isThisARecord(str)); // → false
  /// ```
  ///
  /// ### Returns
  /// - `true` if the object or type is a record.
  /// - `false` otherwise.
  /// {@endtemplate}
  static bool isThisARecord(Object instance) {
    if (instance case mirrors.TypeMirror instance) {
      return mirrors.MirrorSystem.getName(instance.simpleName) == "Record" && instance.hasReflectedType && instance.reflectedType == Record;
    }

    return isThisARecord(mirrors.reflect(instance).type);
  }

  /// Checks if the given [instance] or [mirrors.TypeMirror] represents a **function type**.
  ///
  /// {@template reflection_utils.is_this_a_function}
  /// This method inspects the runtime type of the provided object or the
  /// `TypeMirror` to determine whether it represents a Dart function.
  ///
  /// ### Behavior
  /// - If [instance] is a `TypeMirror`, it checks if it is a
  ///   [mirrors.FunctionTypeMirror].
  /// - If [instance] is an actual object, it reflects its type and
  ///   recursively applies the same check.
  ///
  /// ### Example
  /// ```dart
  /// void myFunction(int x) {}
  /// print(ReflectionUtils.isThisAFunction(myFunction)); // → true
  ///
  /// final str = "not a function";
  /// print(ReflectionUtils.isThisAFunction(str)); // → false
  /// ```
  ///
  /// ### Returns
  /// - `true` if the object or type is a function.
  /// - `false` otherwise.
  ///
  /// ### Notes
  /// - This relies on `dart:mirrors` and may not work in all runtime environments.
  /// - Covers top-level functions, static methods, closures, and function-typed variables.
  /// {@endtemplate}
  static bool isThisAFunction(Object instance) {
    if (instance is mirrors.TypeMirror) {
      return instance is mirrors.FunctionTypeMirror;
    }

    return isThisAFunction(mirrors.reflect(instance).type);
  }

  // ─────────────────────────────────────────────────────────────
  // Type Reflection
  // ─────────────────────────────────────────────────────────────

  /// {@template reflection_utils.find_qualified_name_from_type}
  /// Returns the **qualified name** of a static [Type].
  ///
  /// Unlike [findQualifiedName], this method operates directly on
  /// the type object itself, not an instance.
  ///
  /// ### Example
  /// ```dart
  /// print(ReflectionUtils.findQualifiedNameFromType(String));
  /// // → "dart:core.String"
  /// ```
  ///
  /// ### Returns
  /// A string representing the type’s fully qualified symbol.
  ///
  /// ### Notes
  /// - Falls back to `"unknown"` if the library URI is not available.
  /// {@endtemplate}
  static String findQualifiedNameFromType(Type type) {
    final typeMirror = mirrors.reflectType(type);
    final typeName = mirrors.MirrorSystem.getName(typeMirror.simpleName);
    final libraryUri = typeMirror.location?.sourceUri.toString()
      ?? typeMirror.owner?.location?.sourceUri.toString()
      ?? KEYWORD;

    return buildQualifiedName(typeName, libraryUri);
  }

  // ─────────────────────────────────────────────────────────────
  // Internal Utilities
  // ─────────────────────────────────────────────────────────────

  /// {@template reflection_utils.build_qualified_name}
  /// Builds a fully qualified name from a type [name] and its
  /// associated [libraryUri].
  ///
  /// This is a small helper used internally by both
  /// [findQualifiedName] and [findQualifiedNameFromType].
  ///
  /// Example:
  /// ```dart
  /// ReflectionUtils.buildQualifiedName('User', 'package:my_app/models/user.dart');
  /// // → "package:my_app/models/user.dart.User"
  /// ```
  /// {@endtemplate}
  static String buildQualifiedName(String typeName, String libraryUri) {
    // Ensures there's only one dot between segments
    return StringInternPool.intern('$libraryUri.$typeName'.replaceAll("..", '.'));
  }

  /// Extracts the class name from a fully-qualified name.
  ///
  /// Example:
  /// ```dart
  /// ReflectionUtils.extractClassName("package:my_app/models/user.dart.User");
  /// // → "User"
  ///
  /// ReflectionUtils.extractClassName("dart:core.String");
  /// // → "String"
  /// ```
  static String extractClassName(String qualifiedName) {
    final parts = qualifiedName.split('.');
    return parts.isNotEmpty ? parts.last : qualifiedName;
  }

  /// Extracts the library/package URI from a fully qualified name.
  ///
  /// Example:
  /// ```
  /// package:my_app/models/user.dart.User -> package:my_app/models/user.dart
  /// dart:core.String -> dart:core
  /// ```
  static String extractLibraryUri(String qualifiedName) {
    final lastDotIndex = qualifiedName.lastIndexOf('.');
    if (lastDotIndex == -1) return qualifiedName; // no dot, return as-is
    return qualifiedName.substring(0, lastDotIndex);
  }
}