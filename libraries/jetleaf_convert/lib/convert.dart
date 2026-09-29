/// 🔄 **Jetleaf Convert**
///
/// This library provides a comprehensive type conversion framework
/// for Jetleaf applications, enabling safe and flexible conversion
/// between different data types. It supports core conversion services,
/// predefined converters, collection and object conversions, and
/// extensible registration of custom converters.
///
/// ## 🔑 Core Components
///
/// ### Type Converters
/// Predefined converters for common types:
/// - `service_converter.dart` — converters for service or pod types
/// - `collection_converters.dart` — converters for lists, sets, queues, etc.
/// - `dart_converters.dart` — converters for core Dart types (int, double, String)
/// - `jl_converters.dart` — Jetleaf-specific converters
/// - `map_converters.dart` — converters for maps and key-value structures
/// - `object_converters.dart` — object-to-object converters
/// - `time_converters.dart` — converters for DateTime, Duration, and time-related types
///
/// ### Core Conversion Infrastructure
/// - `converters.dart` — base converter interfaces and abstractions
/// - `conversion_service.dart` — main interface for conversion operations
/// - `converter_registry.dart` — registry for all registered converters
/// - `default_conversion_service.dart` — default implementation of conversion service
/// - `simple_conversion_service.dart` — lightweight implementation for simple use cases
/// - `converting_comparator.dart` — comparator that supports type conversion
///
/// ### Helper Utilities
/// - `conversion_utils.dart` — utility functions for conversion operations
/// - `convertible_pair.dart` — representation of source-target type pairs
/// - `conversion_adapter_utils.dart` — helpers for adapter-based conversions
///
/// ### Exceptions
/// - `exceptions.dart` — conversion-specific exception types
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to perform type-safe conversions across your
/// application:
///
/// ```dart
/// import 'package:jetleaf_convert/convert.dart';
///
/// final conversionService = DefaultConversionService();
/// final result = conversionService.convert<String>(123);
/// print(result); // "123"
/// ```
///
/// Supports collections, objects, primitives, and custom types,
/// providing a consistent framework for type conversion in Jetleaf.
///
/// {@category Conversion}
library;

export 'src/types/service_converter.dart';
export 'src/types/collection_converters.dart';
export 'src/types/dart_converters.dart';
export 'src/types/jl_converters.dart';
export 'src/types/map_converters.dart';
export 'src/types/object_converters.dart';
export 'src/types/time_converters.dart';

export 'src/core/converters.dart';
export 'src/core/conversion_service.dart';
export 'src/core/converter_registry.dart';
export 'src/core/default_conversion_service.dart';
export 'src/core/simple_conversion_service.dart';
export 'src/core/converting_comparator.dart';

export 'src/helpers/conversion_utils.dart';
export 'src/helpers/convertible_pair.dart';
export 'src/helpers/conversion_adapter_utils.dart';

export 'src/exceptions.dart';