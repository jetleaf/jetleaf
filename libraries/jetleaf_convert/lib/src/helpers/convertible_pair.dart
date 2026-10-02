import 'package:jetleaf_lang/lang.dart';

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
    return other is ConvertiblePair &&
        runtimeType == other.runtimeType &&
        sourceType.getType() == other.sourceType.getType() &&
        targetType.getType() == other.targetType.getType();
  }

  @override
  int get hashCode => Object.hash(runtimeType, sourceType.getType(), targetType.getType());

  @override
  String toString() => 'Pair[(${sourceType.getName()}:${sourceType.getType()}) -> (${targetType.getName()}:${targetType.getType()})]';

  /// Creates a new [ConvertiblePair] with reversed source and target types.
  /// 
  /// {@macro convertible_pair}
  ConvertiblePair reverse() => ConvertiblePair(targetType, sourceType);
}