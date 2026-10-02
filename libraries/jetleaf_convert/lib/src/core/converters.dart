import 'package:jetleaf_lang/lang.dart';

import '../helpers/convertible_pair.dart';
import '../exceptions.dart';

/// {@template converter}
/// A generic interface for converting an input of type [S] into an output of
/// type [T].
///
/// Converters are commonly used in Jetleaf when transforming data between
/// different layers, formats, or domains. This abstraction allows developers
/// to define reusable transformation logic while keeping code strongly typed.
///
/// - [S] is the source type (input).
/// - [T] is the target type (output).
///
/// ## Example
/// Converting a `String` to an `int`:
/// ```dart
/// class StringToIntConverter implements Converter<String, int> {
///   @override
///   int convert(String source) {
///     return int.parse(source);
///   }
/// }
///
/// void main() {
///   final converter = StringToIntConverter();
///   final number = converter.convert("42");
///   print(number); // 42
/// }
/// ```
///
/// Converting a `Map` into a custom model:
/// ```dart
/// class User {
///   final String name;
///   final int age;
///   User(this.name, this.age);
/// }
///
/// class MapToUserConverter implements Converter<Map<String, Object?>, User> {
///   @override
///   User convert(Map<String, Object?> source) {
///     return User(source['name'] as String, source['age'] as int);
///   }
/// }
///
/// void main() {
///   final converter = MapToUserConverter();
///   final user = converter.convert({'name': 'Alice', 'age': 30});
///   print(user.name); // Alice
/// }
/// ```
/// {@endtemplate}
@Generic(Converter)
abstract interface class Converter<S, T> implements PackageIdentifier {
  /// {@macro converter}
  T convert(S source);
}

/// {@template conditional_converter}
/// A contract for a converter that only matches under certain conditions.
///
/// This is useful in frameworks where type conversion should occur only
/// if some custom logic (e.g., annotations, context, runtime checks) validates it.
///
/// You can implement this interface when you want to provide more
/// granular control over when a converter should be applied.
///
/// ---
///
/// ### 🔧 Example:
/// ```dart
/// class MyConditionalConverter implements ConditionalConverter {
///   @override
///   bool matches(Class sourceType, Class targetType) {
///     return sourceType.getType() == String && targetType.getType() == Uri;
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class ConditionalConverter {
  /// {@macro conditional_converter}
  ///
  /// Determines if the converter should apply for the given [sourceType] and [targetType].
  bool matches(Class sourceType, Class targetType);
}

/// {@template generic_null_converter}
/// A contract for a converter that only matches under certain conditions.
///
/// This is useful in frameworks where type conversion should occur only
/// if some custom logic (e.g., annotations, context, runtime checks) validates it.
///
/// You can implement this interface when you want to provide more
/// granular control over when a converter should be applied.
///
/// ---
///
/// ### 🔧 Example:
/// ```dart
/// class MyGenericNullConverter implements GenericNullConverter {
///   @override
///   Object? convert(Class? sourceType, Class targetType) {
///     return null;
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class GenericNullConverter extends ConditionalConverter {
  /// {@macro generic_null_converter}
  Object? convert(Class? sourceType, Class targetType);

  @override
  bool operator ==(Object other) {
    if(other is GenericNullConverter) {
      return other.runtimeType == runtimeType;
    }
    return false;
  }

  @override
  int get hashCode => runtimeType.hashCode;
}

/// {@template paired_converter}
/// A general-purpose converter that can convert between multiple source–target type pairs.
///
/// This interface allows conversion logic to be shared across multiple type mappings,
/// and optionally exposes the set of convertible type pairs.
///
/// ---
///
/// ### 🔧 Example:
/// ```dart
/// class MyConverter implements PairedConverter {
///   @override
///   Set<ConvertiblePair> getConvertibleTypes() => {
///     ConvertiblePair(Class<String>(), Class<int>())
///   };
///
///   @override
///   Object? convert(Object? source, Class sourceType, Class targetType) {
///     if (source is String && targetType.getType() == int) {
///       return int.tryParse(source);
///     }
///     return null;
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class PairedConverter implements PackageIdentifier {
  /// {@macro paired_converter}
  ///
  /// Returns the set of source–target type pairs that this converter supports.
  /// Can be `null` if the converter is conditional or uses runtime logic instead.
  Set<ConvertiblePair>? getConvertibleTypes();

  /// {@macro paired_converter}
  ///
  /// Converts the [source] object from [sourceType] to [targetType].
  ///
  /// Returns the converted value or `null` if the conversion fails or is unsupported.
  Object? convert<T>(Object? source, Class sourceType, Class targetType);

  @override
  String toString() => '$runtimeType(${getConvertibleTypes()?.map((c) => c)})';
}

/// {@template conditional_paired_converter}
/// A bridge interface combining [PairedConverter] and [ConditionalConverter].
///
/// Use this when writing a paired converter that should only match under specific conditions.
///
/// ---
///
/// ### 🔧 Example:
/// ```dart
/// class ConditionalUriConverter extends ConditionalPairedConverter {
///   @override
///   Set<ConvertiblePair> getConvertibleTypes() => {
///     ConvertiblePair(Class<String>(), Class<Uri>())
///   };
///
///   @override
///   bool matches(TypeDescriptor sourceType, TypeDescriptor targetType) {
///     return sourceType.type == String && targetType.type == Uri;
///   }
///
///   @override
///   Object? convert(Object? source, TypeDescriptor sourceType, TypeDescriptor targetType) {
///     return Uri.tryParse(source as String);
///   }
/// }
/// ```
/// {@endtemplate}
abstract class PairedConditionalConverter extends PairedConverter implements ConditionalConverter {
  @override
  bool matches(Class sourceType, Class targetType) => getConvertibleTypes()?.contains(ConvertiblePair(sourceType, targetType)) ?? false;
}

/// {@template converter_factory}
/// A factory for creating [Converter] instances that convert from a source type [S]
/// to a target type [T], where [T] is a subtype of [R].
///
/// This interface is useful when conversion logic needs to support multiple
/// target types derived from a common base type [R].
///
/// ---
///
/// ### 🔧 Example Usage:
/// ```dart
/// class StringToNumberConverterFactory implements ConverterFactory<String, num> {
///   @override
///   Converter<String, T> getConverter<T extends num>() {
///     if (T == int) {
///       return (IntStringConverter() as Converter<String, T>);
///     } else if (T == double) {
///       return (DoubleStringConverter() as Converter<String, T>);
///     }
///     throw ConversionException('No converter for type $T');
///   }
/// }
/// ```
/// {@endtemplate}
@Generic(ConverterFactory)
abstract interface class ConverterFactory<S, R> implements PackageIdentifier {
  /// {@macro converter_factory}
  ///
  /// Returns a [Converter] from type [S] to [T], where [T] must be a subtype of [R].
  ///
  /// Throws an [ConversionException] if the factory does not support the requested target type.
  Converter<S, T>? getConverter<T>(Class<T> targetType);
}