import 'package:jetleaf_lang/lang.dart';

import '../core/conversion_service.dart';
import '../exceptions.dart';
import '../helpers/_commons.dart';

/// {@template conversion_service_converter}
/// A [Converter] that delegates to a [ConversionService] for converting values.
///
/// This wrapper allows a [ConversionService] to be plugged into APIs
/// that require a [Converter], using a fixed target type.
///
/// ---
///
/// ### 🔧 Example:
/// ```dart
/// final service = DefaultConversionService();
/// final converter = ConversionServiceConverter<String, int>(service, Class<int>());
/// final result = converter.convert("123");
/// print(result); // 123
/// ```
///
/// Throws [ConversionException] if the conversion fails or returns `null`.
/// {@endtemplate}
@Generic(ConversionServiceConverter)
class ConversionServiceConverter<S, T> extends CommonConverter<S, T> {
  final ConversionService _conversionService;
  final Class<T> targetType;

  /// {@macro conversion_service_converter}
  ConversionServiceConverter(this._conversionService, this.targetType);

  @override
  T convert(S source) {
    final result = _conversionService.convert(source, targetType);
    if (result == null) {
      throw ConversionFailedException(targetType: targetType, sourceType: Class.forType(S), value: source);
    }
    return result;
  }
}