import 'package:jetleaf_lang/lang.dart';

import 'converter_registry.dart';
import 'converters.dart';

/// {@template conversion_service}
/// A strategy interface for type conversion.
///
/// Implementations of this interface are responsible for converting values between
/// different types, such as from `String` to `int`, `List<String>` to `Set<int>`, or
/// custom object mappings.
///
/// Typically used in configuration binding, message deserialization, and
/// property resolution pipelines.
///
/// ---
///
/// ### 🔧 Example Usage:
/// ```dart
/// final service = DefaultConversionService();
///
/// if (service.canConvert<String, int>(Class<String>(), Class<int>())) {
///   final value = service.convert<int>('42', Class<int>());
///   print(value + 1); // 43
/// }
/// ```
/// {@endtemplate}
abstract class ConversionService {
  /// {@template conversion_service_can_convert}
  /// Determines whether objects of [sourceType] can be converted to [targetType].
  ///
  /// This allows frameworks to optimize or validate before performing conversions.
  ///
  /// ### Example:
  /// ```dart
  /// if (conversionService.canConvert<String, DateTime>(Class<String>(), Class<DateTime>())) {
  ///   final date = conversionService.convert<DateTime>('2025-01-01', Class<DateTime>());
  /// }
  /// ```
  /// {@endtemplate}
  bool canConvert(Class? sourceType, Class targetType);

  /// {@template conversion_service_convert}
  /// Converts the given [source] object to the specified [targetType].
  ///
  /// Returns `null` if the conversion fails or if [source] is `null`.
  ///
  /// ### Example:
  /// ```dart
  /// final port = conversionService.convert<int>('8080', Class<int>());
  /// final date = conversionService.convert<DateTime>('2025-01-01', Class<DateTime>());
  /// 
  /// final port = conversionService.convert<int>('8080', Class<int>(), 'dart.core.int');
  /// final date = conversionService.convert<DateTime>('2025-01-01', Class<DateTime>(), 'dart.core.DateTime');
  /// ```
  ///
  /// The [T] type parameter represents the expected return type.
  /// {@endtemplate}
  T? convert<T>(Object? source, Class<T> targetType, [String? qualifiedName]);

  /// Converts the [source] object from a known [sourceType] to a [targetType]
  /// using full type metadata via [Class].
  ///
  /// This method provides the most powerful form of type conversion and
  /// supports deep, generic-aware resolution.
  ///
  /// ### Example:
  /// ```dart
  /// final source = {'date': '2025-07-01'};
  ///
  /// final targetType = Class.mapOf(Class<String>(), Class<DateTime>());
  /// final result = service.convertTo(source, Class.forObject(source), targetType);
  /// ```
  Object? convertTo<T>(Object? source, Class targetType, [Class? sourceType]);
}

/// {@template configurable_conversion_service}
/// A configurable conversion service that allows dynamic registration of converters.
///
/// This interface is typically used during application bootstrap or module initialization
/// to register additional [Converter], [ConverterFactory], or [PairedConverter] instances
/// that will be used for type conversion across the framework.
///
/// ---
///
/// ### 🔧 Example Usage:
/// ```dart
/// final service = DefaultConversionService();
///
/// service.addConverter<String, int>(StringToIntConverter());
/// service.addConverterFactory<String, Enum>(StringToEnumConverterFactory());
/// service.addPairedConverter(MyCustomPairedConverter());
/// ```
///
/// See also:
/// - [ConversionService]
/// - [Converter]
/// - [ConverterFactory]
/// - [PairedConverter]
/// - [ListableConverterRegistry]
/// {@endtemplate}
abstract class ConfigurableConversionService implements ConversionService, ListableConverterRegistry {}

/// {@template conversion_service_factory}
/// Utility class for registering a set of converters with a [ConverterRegistry].
///
/// This is used to bulk-register multiple converter objects, whether they
/// implement [Converter], [ConverterFactory], or [PairedConverter].
///
/// All converters are matched by type and registered accordingly. If any object
/// in the provided set does not implement one of the recognized interfaces,
/// an [IllegalArgumentException] is thrown.
///
/// ---
///
/// ### 🔧 Example
/// ```dart
/// final registry = DefaultConverterRegistry();
/// ConversionServiceFactory.registerConverters({
///   StringToIntConverter(),
///   StringToDateTimeConverter(),
///   StringToEnumConverterFactory(),
///   MyGenericConverter(),
/// }, registry);
/// ```
///
/// {@endtemplate}
final class ConversionServiceFactory {
  /// Prevents instantiation of this utility class.
  ConversionServiceFactory._();

  /// {@macro conversion_service_factory}
  ///
  /// Registers each converter in [converters] with the provided [registry].
  ///
  /// - If a converter is a [PairedConverter], it will be registered using [ConverterRegistry.addPairedConverter].
  /// - If it is a [Converter], it will be registered using [ConverterRegistry.addConverter].
  /// - If it is a [ConverterFactory], it will be registered using [ConverterRegistry.addConverterFactory].
  ///
  /// Throws [IllegalArgumentException] if any object in [converters] does not implement one of these types.
  static void registerConverters(Set<dynamic>? converters, ConverterRegistry registry) {
    if (converters != null) {
      for (Object candidate in converters) {
        if (candidate is PairedConverter) {
          registry.addPairedConverter(candidate);
        } else if (candidate is Converter<dynamic, dynamic>) {
          registry.addConverter(candidate);
        } else if (candidate is ConverterFactory<dynamic, dynamic>) {
          registry.addConverterFactory(candidate);
        } else {
          throw IllegalArgumentException(
            "Each converter object must implement one of the "
            "Converter, ConverterFactory, or PairedConverter interfaces",
          );
        }
      }
    }
  }
}