import 'package:jetleaf_core/lang.dart';

/// {@template convertible_pair}
/// Represents a pair of source and target types for type conversion.
///
/// This class is used in conversion frameworks to define mappings between
/// one type and another. It forms the basis for determining whether a specific
/// converter can handle a particular type conversion.
///
/// ---
///
/// ### 🔧 Example:
/// ```dart
/// final pair = ConvertiblePair(Class<String>(), Class<int>());
/// print(pair); // java.lang.String -> int
///
/// if (pair.getSourceType() == Class<String>()) {
///   print("This pair converts from String");
/// }
/// ```
/// {@endtemplate}
final class ConvertiblePair {
  /// The source type of the conversion.
  final Class sourceType;

  /// The target type of the conversion.
  final Class targetType;

  /// {@macro convertible_pair}
  ///
  /// Creates a new [ConvertiblePair] with the given [sourceType] and [targetType].
  ///
  /// This constructor is typically used when registering or querying converters.
  ConvertiblePair(this.sourceType, this.targetType);

  /// Returns the source type of this pair.
  Class getSourceType() => sourceType;

  /// Returns the target type of this pair.
  Class getTargetType() => targetType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    // Type equality, not instance equality: `Class<Object>(List-decl)` and
    // `Class<List>()` denote the same registered type (`Type List`) and must
    // resolve to the same converters. Parameterised instantiations (e.g.
    // `List<int>`) resolve to the same raw-declaration pair as the raw form
    // (`List`) — the reified element/key arguments are not part of converter
    // selection semantics (the registered converters are driven from the
    // reified arguments via `componentType()`).
    return other is ConvertiblePair &&
        _typeBaseName(sourceType) == _typeBaseName(other.sourceType) &&
        _typeBaseName(targetType) == _typeBaseName(other.targetType);
  }

  @override
  int get hashCode => Object.hash(_typeBaseName(sourceType), _typeBaseName(targetType));

  /// Strips generic instantiations, mapping everything with the same
  /// non-parameterized root (`List<int>` → `List`, `Map<String, int>` → `Map`)
  /// to the same comparison key.
  static String _typeBaseName(Class type) {
    final name = type.getType().toString();
    final open = name.indexOf('<');
    return open == -1 ? name : name.substring(0, open);
  }

  @override
  String toString() => 'Pair[(${sourceType.getName()}:${sourceType.getType()}) -> (${targetType.getName()}:${targetType.getType()})]';

  /// Creates a new [ConvertiblePair] with reversed source and target types.
  /// 
  /// {@macro convertible_pair}
  ConvertiblePair reverse() => ConvertiblePair(targetType, sourceType);
}