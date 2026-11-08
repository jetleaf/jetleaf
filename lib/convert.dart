/// 🔄 **Jetleaf Type Conversion Service & Adapter Subsystem**
///
/// This library provides the extensible, strongly-typed data conversion pipeline
/// used across Jetleaf to convert values between disparate Dart types:
/// - **Conversion Engine:** [ConversionService], [GenericConversionService], [DefaultConversionService].
/// - **Converter Contracts:** [Converter], [GenericConverter], [ConditionalConverter], [ConverterRegistry].
/// - **Built-in Adapters:** String to primitives (`int`, `double`, `bool`, `DateTime`, `Uri`), collections, maps, and enums.
///
/// ---
///
/// ## 🔄 Type Conversion Architecture
///
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────┐
/// │                     Jetleaf Conversion Pipeline                        │
/// ├────────────────────────────────────────────────────────────────────────┤
/// │ Source Value (e.g. String "8080")                                      │
/// │                                    │                                   │
/// │                 [ConversionService.convert<S, T>]                      │
/// │                                    │                                   │
/// │ Matches registered [Converter<S, T>] or composite adapter pipeline      │
/// │                                    │                                   │
/// │ Target Value (e.g. int 8080)                                           │
/// └────────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🔄 Conversion Contracts
/// - [ConversionService] — core interface for querying conversion capability and performing conversions.
/// - [ConverterRegistry] — registry for installing custom [Converter] instances.
/// - [Converter] — simple single-direction mapping function `T convert(S source)`.
/// - [GenericConverter] — flexible multi-type converter with access to source/target [TypeDescriptor] metadata.
/// - [ConditionalConverter] — converter that executes conditionally based on attributes of source/target types.
/// - [DefaultConversionService] — production-ready service pre-populated with standard Dart type converters.
///
/// ---
///
/// ## 🎯 Usage Example: Registering a Custom Converter
///
/// ```dart
/// import 'package:jetleaf/convert.dart';
///
/// class GeoPoint {
///   final double latitude;
///   final double longitude;
///   GeoPoint(this.latitude, this.longitude);
///
///   @override
///   String toString() => 'GeoPoint($latitude, $longitude)';
/// }
///
/// // Custom String -> GeoPoint converter
/// class StringToGeoPointConverter implements Converter<String, GeoPoint> {
///   @override
///   GeoPoint convert(String source) {
///     final parts = source.split(',');
///     return GeoPoint(double.parse(parts[0].trim()), double.parse(parts[1].trim()));
///   }
/// }
///
/// void main() {
///   final service = DefaultConversionService();
///   service.addConverter(StringToGeoPointConverter());
///
///   // Check if conversion is supported
///   if (service.canConvert<String, GeoPoint>()) {
///     final point = service.convert<String, GeoPoint>('37.7749, -122.4194');
///     print('Converted point: $point');
///   }
/// }
/// ```
///
/// {@category Jetleaf}
library;

export 'package:jetleaf_core/convert.dart';
