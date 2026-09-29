import 'package:jetleaf_lang/lang.dart';

import 'converters.dart';

/// {@template converter_registry}
/// A registry of converters and converter factories used to perform type
/// conversions at runtime.
///
/// This is a central extension point for registering:
/// - Simple [Converter] instances
/// - [ConverterFactory] instances that produce converters based on target type
/// - [PairedConverter] instances that support complex or multi-type conversion
///
/// All registered converters can later be used by a [ConversionService]
/// to perform conversions between types.
///
/// ---
///
/// ### 🔧 Example
/// ```dart
/// final registry = MyConverterRegistry();
/// registry.addConverter(StringToIntConverter());
/// registry.addConverterWithClass(Class<String>(), Class<DateTime>(), StringToDateTimeConverter());
/// registry.addConverterFactory(StringToEnumConverterFactory());
/// ```
///
/// {@endtemplate}
abstract interface class ConverterRegistry {
  /// {@macro converter_registry}
  const ConverterRegistry();

  /// Registers a simple [Converter] from one specific source type to one target type.
  ///
  /// ---  
  /// ### 🔧 Example
  /// ```dart
  /// registry.addConverter(StringToIntConverter());
  /// 
  /// registry.addConverter(StringToIntConverter(), sourceType: Class<String>(), targetType: Class<int>());
  /// ```
  void addConverter<S, T>(Converter<S, T> converter, {Class<S>? sourceType, Class<T>? targetType});

  /// Registers a [PairedConverter] capable of converting between multiple types.
  ///
  /// A [PairedConverter] typically implements a more flexible contract than [Converter].
  ///
  /// ---  
  /// ### 🔧 Example
  /// ```dart
  /// registry.addGenericConverter(MyFlexibleGenericConverter());
  /// ```
  void addPairedConverter(PairedConverter converter);

  /// Registers a [ConverterFactory] that can produce [Converter] instances for a target type.
  ///
  /// ---  
  /// ### 🔧 Example
  /// ```dart
  /// registry.addConverterFactory(StringToEnumConverterFactory());
  /// ```
  void addConverterFactory(ConverterFactory<dynamic, dynamic> converterFactory);

  /// {@template configurable_conversion_service_add_null_source_converter}
  /// Adds a new [GenericNullConverter] to the list of registered converters.
  ///
  /// This method is used to register additional converters for null source values.
  ///
  /// ### Example:
  /// ```dart
  /// final service = DefaultConversionService();
  /// service.addNullSourceConverter(GenericNullConverter());
  /// ```
  /// {@endtemplate}
  void addNullSourceConverter(GenericNullConverter converter);

  /// {@template configurable_conversion_service_add_uri_validator}
  /// Adds a new [UriValidator] to the list of registered validators.
  ///
  /// This method is used to register additional validators for URI validation.
  ///
  /// ### Example:
  /// ```dart
  /// final service = DefaultConversionService();
  /// service.addUriValidator(UriValidator());
  /// ```
  /// {@endtemplate}
  void addUriValidator(UriValidator validator);

  /// Removes a registered converter between the specified source and target types.
  ///
  /// ---  
  /// ### 🔧 Example
  /// ```dart
  /// registry.removeConvertible(Class<String>(), Class<int>());
  /// ```
  void remove(Class<dynamic> sourceType, Class<dynamic> targetType);

  /// Removes a registered [GenericNullConverter].
  ///
  /// ---
  /// ### 🔧 Example
  /// ```dart
  /// registry.removeNullSourceConverter(GenericNullConverter());
  /// ```
  void removeNullSourceConverter(GenericNullConverter converter);

  /// Removes a registered [UriValidator].
  ///
  /// ---
  /// ### 🔧 Example
  /// ```dart
  /// registry.removeUriValidator(UriValidator());
  /// ```
  void removeUriValidator(UriValidator validator);
}

/// {@template listable_converter_registry}
/// A [ConverterRegistry] that also provides access to registered [UriValidator] instances.
///
/// This interface extends [ConverterRegistry] and adds the capability to retrieve
/// all registered validators for URI validation.
///
/// ---
/// ### 🔧 Example
/// ```dart
/// final validators = conversionService.getUriValidators();
/// validators.forEach((validator) {
///   print(validator.errorMessage);
/// });
/// ```
/// {@endtemplate}
abstract class ListableConverterRegistry extends ConverterRegistry {
  /// {@macro listable_converter_registry}
  const ListableConverterRegistry();

  /// {@template conversion_service_get_uri_validators}
  /// Returns a list of registered [UriValidator] instances.
  ///
  /// This method is used to retrieve all registered validators for URI validation.
  ///
  /// ### Example:
  /// ```dart
  /// final validators = conversionService.getUriValidators();
  /// validators.forEach((validator) {
  ///   print(validator.errorMessage);
  /// });
  /// ```
  /// {@endtemplate}
  List<UriValidator> getUriValidators();
}