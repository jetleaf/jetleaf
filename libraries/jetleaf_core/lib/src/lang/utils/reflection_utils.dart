import '../runtime/provider/runtime_provider.dart';

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
/// Pure Dart runtime reflection and type-inspection utility.
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
/// {@endtemplate}
final class ReflectionUtils {
  /// Private constructor to prevent instantiation.
  const ReflectionUtils._();

  /// {@template reflection_utils.keyword}
  /// Fallback keyword used when reflection metadata cannot be resolved.
  ///
  /// This constant represents a **sentinel value** returned by reflection
  /// utilities when a library URI, source location, or symbol origin
  /// cannot be determined.
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
  /// {@endtemplate}
  static String findQualifiedName(Object instance) {
    if (Runtime.isPopulated) {
      try {
        final decl = Runtime.findClassByType(instance.runtimeType);
        return decl.getQualifiedName();
      } catch (_) {}
    }
    return buildQualifiedName(instance.runtimeType.toString(), KEYWORD);
  }

  /// Checks if the given [instance] represents a **record type**.
  ///
  /// {@template reflection_utils.is_this_a_record}
  /// This method inspects the runtime type of the provided object
  /// to determine whether it is a Dart 3 record type.
  /// {@endtemplate}
  static bool isThisARecord(Object instance) {
    return instance is Record;
  }

  /// Checks if the given [instance] represents a **function type**.
  ///
  /// {@template reflection_utils.is_this_a_function}
  /// This method inspects the runtime type of the provided object
  /// to determine whether it represents a Dart function.
  /// {@endtemplate}
  static bool isThisAFunction(Object instance) {
    return instance is Function;
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
  /// {@endtemplate}
  static String findQualifiedNameFromType(Type type) {
    if (Runtime.isPopulated) {
      try {
        final decl = Runtime.findClassByType(type);
        return decl.getQualifiedName();
      } catch (_) {}
    }
    return buildQualifiedName(type.toString(), KEYWORD);
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
    if (lastDotIndex == -1) return qualifiedName;
    return qualifiedName.substring(0, lastDotIndex);
  }
}