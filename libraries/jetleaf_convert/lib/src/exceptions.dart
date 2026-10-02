import 'package:jetleaf_lang/lang.dart';

/// {@template conversion_exception}
/// Exception thrown when a type conversion fails in a [ConversionService].
///
/// This typically occurs when attempting to convert an object from one type to another
/// and no suitable [Converter] or [GenericConverter] exists, or the conversion logic
/// throws an error due to invalid data or incompatible types.
///
/// ---
///
/// ### ❗ Example:
/// ```dart
/// try {
///   final value = conversionService.convert<String>(42, String);
/// } catch (e) {
///   if (e is ConversionException) {
///     print('Conversion failed: ${e.message}');
///   }
/// }
/// ```
///
/// Use this to catch and handle specific conversion failures during property binding,
/// message deserialization, or data mapping.
/// {@endtemplate}
class ConversionException extends RuntimeException {
  /// {@macro conversion_exception}
  ConversionException(super.message);

  @override
  String toString() => 'ConversionException: $message';
}

/// {@template conversion_failed_exception}
/// Exception thrown when an actual type conversion attempt fails.
///
/// This typically occurs when a matching converter exists, but the conversion logic
/// encounters an error (e.g., due to incompatible values or invalid data).
///
/// ---
///
/// ### Example:
/// ```dart
/// throw ConversionFailedException(
///   sourceType: Class.forObject(input),
///   targetType: Class.forType(String),
///   value: input,
///   cause: FormatException('Invalid number format'),
/// );
/// ```
///
/// {@endtemplate}
class ConversionFailedException extends ConversionException {
  /// The source type from which we tried to convert.
  final Class? sourceType;

  /// The target type we attempted to convert to.
  final Class targetType;

  /// The actual value that failed to convert.
  final Object? value;

  /// The cause of the failure.
  final Object? point;

  /// {@macro conversion_failed_exception}
  ConversionFailedException({
    this.sourceType,
    required this.targetType,
    this.value,
    this.point,
  }) : super(
    'Failed to convert from type [${sourceType?.getName() ?? "unknown"}] '
    'to type [${targetType.getName()}] for value [${_describe(value)}]. $point',
  );

  static String _describe(Object? obj) {
    if (obj == null) return 'null';
    try {
      return obj.toString();
    } catch (_) {
      return 'object of type ${obj.runtimeType}';
    }
  }

  @override
  String toString() => 'ConversionFailedException: $message';
}

/// {@template converter_not_found_exception}
/// Exception thrown when no suitable converter can be found for a given source and target type.
///
/// This typically occurs when a user attempts to convert between two types that have
/// no registered [Converter] or [GenericConverter] in the current [ConversionService].
///
/// ---
///
/// ### Example:
/// ```dart
/// throw ConverterNotFoundException(
///   sourceType: Class.forType(DateTime),
///   targetType: Class.forType(Uri),
/// );
/// ```
///
/// {@endtemplate}
class ConverterNotFoundException extends ConversionException {
  /// The source type requested to convert from.
  final Class? sourceType;

  /// The target type requested to convert to.
  final Class targetType;

  /// {@macro converter_not_found_exception}
  ConverterNotFoundException({
    this.sourceType,
    required this.targetType,
  }) : super(
    'No converter found capable of converting from type '
    '[${sourceType ?? "unknown"}] to type [$targetType]',
  );

  @override
  String toString() => 'ConverterNotFoundException: $message';
}