/// 🔄 **Jetleaf Type Conversion Subsystem**
///
/// This library provides the core type conversion infrastructure for Jetleaf applications,
/// enabling safe, bi-directional transformation between disparate Dart types.
///
/// It supports:
/// - Core conversion services and registries.
/// - Built-in converters for Dart primitives, dates, durations, and enums.
/// - Collection and map transformations (`List<S>` -> `List<T>`, `Set<S>` -> `Set<T>`).
/// - Custom converter registration via [Converter<S, T>].
/// - Paired type-safe lookup with generic preservation.
///
/// ---
///
/// ## 🔀 Conversion Resolution Matrix
///
/// ```text
/// ┌─────────────────────────────────────────────────────────────┐
/// │                     Conversion Request                      │
/// │              convert(source, Class<Target>())               │
/// ├─────────────────────────────────────────────────────────────┤
/// │ 1. Exact Match        [ConvertiblePair(Source, Target)]     │
/// │                               │                             │
/// │ 2. Collection Element  List<S> -> List<T> via Converter<S,T>│
/// │                               │                             │
/// │ 3. Enum Mapping       String / Int <-> Enum constant        │
/// │                               │                             │
/// │ 4. Fallback           String parsing / Object stringify     │
/// └─────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### ⚙️ Core Conversion Engine
/// - [ConversionService] — the primary service interface for executing type conversions.
/// - [ConverterRegistry] — registry interface for adding and managing converters.
/// - [DefaultConversionService] — standard, pre-populated production conversion engine.
/// - [SimpleConversionService] — lightweight base conversion service.
/// - [Converter] — fundamental single-method contract (`T convert(S source)`).
/// - [ConvertiblePair] — immutable tuple identifying source and target types.
///
/// ### 📦 Built-In Converters
/// - **Time Converters:** [StringToDurationConverter], [DurationToStringConverter], [StringToDateTimeConverter].
/// - **Primitive Converters:** [StringToIntConverter], [StringToDoubleConverter], [StringToBoolConverter].
/// - **Collection Converters:** List, Set, and Map structural adapters.
///
/// ---
///
/// ## 🎯 Usage Example: Custom Converter Registration & Invocation
///
/// ```dart
/// import 'package:jetleaf_core/convert.dart';
/// import 'package:jetleaf_core/lang.dart';
///
/// class Color {
///   final int hex;
///   const Color(this.hex);
///   @override
///   String toString() => '#${hex.toRadixString(16).padLeft(6, '0')}';
/// }
///
/// class HexToColorConverter implements Converter<String, Color> {
///   @override
///   String getPackageName() => 'my_app';
///
///   @override
///   Color convert(String source) {
///     final clean = source.replaceAll('#', '');
///     return Color(int.parse(clean, radix: 16));
///   }
/// }
///
/// void main() {
///   final service = DefaultConversionService();
///
///   // Register custom converter
///   service.addConverter(
///     HexToColorConverter(),
///     sourceType: Class<String>(),
///     targetType: Class<Color>(),
///   );
///
///   // Execute type-safe conversion
///   final color = service.convert('#FF5733', Class<Color>());
///   print('Converted color: $color (Hex value: ${color?.hex})');
/// }
/// ```
library;

export 'src/convert/types/service_converter.dart';
export 'src/convert/types/collection_converters.dart';
export 'src/convert/types/dart_converters.dart';
export 'src/convert/types/jl_converters.dart';
export 'src/convert/types/map_converters.dart';
export 'src/convert/types/object_converters.dart';
export 'src/convert/types/time_converters.dart';

export 'src/convert/core/converters.dart';
export 'src/convert/core/conversion_service.dart';
export 'src/convert/core/converter_registry.dart';
export 'src/convert/core/default_conversion_service.dart';
export 'src/convert/core/simple_conversion_service.dart';
export 'src/convert/core/converting_comparator.dart';

export 'src/convert/helpers/conversion_utils.dart';
export 'src/convert/helpers/convertible_pair.dart';
export 'src/convert/helpers/conversion_adapter_utils.dart';

export 'src/convert/exceptions.dart';