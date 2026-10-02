import 'dart:collection' as col;

import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_lang/lang.dart' as jl;

import '../core/conversion_service.dart';
import '../helpers/_commons.dart';
import '../helpers/conversion_adapter_utils.dart';
import '../helpers/conversion_utils.dart';
import '../helpers/convertible_pair.dart';

/// {@template string_to_map_generic_converter}
/// A converter that transforms a [String] into different types of [Map] implementations.
///
/// This class supports conversion from:
/// - `String` → `Map`
/// - `String` → `HashMap`
/// - `String` → `col.HashMap`
///
/// The expected string format is a comma-separated list of key-value pairs,
/// where each pair is separated by an equals sign (`=`).
///
/// Example:
/// ```dart
/// final service = ConversionService(); // Your implementation
/// final converter = StringToMapGenericConverter(service);
/// 
/// final input = "name=John, age=30, country=USA";
/// final result = converter.convert(
///   input,
///   STRING,
///   Class<Map>(null, PackageNames.DART),
/// );
///
/// print(result); // {name: John, age: 30, country: USA}
/// ```
///
/// ### Key & Value Type Conversion
/// If the target map specifies key and value types, they will be converted
/// using the provided [ConversionService].
/// {@endtemplate}
class StringToMapGenericConverter extends CommonPairedConditionalConverter {
  final ConversionService _conversionService;

  /// {@macro string_to_map_generic_converter}
  StringToMapGenericConverter(this._conversionService);

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(STRING, Class<Map>(null, PackageNames.DART)),
    ConvertiblePair(STRING, Class<HashMap>(null, PackageNames.LANG)),
    ConvertiblePair(STRING, Class<col.HashMap>(null, PackageNames.DART)),
  };

  @override
  bool matches(Class sourceType, Class targetType) {
    return sourceType.getType() == String && _isMapLike(targetType);
  }

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final str = source as String;
    final pairs = str.split(RegExp(r'\s*,\s*')); // split by comma
    final targetMap = <Object, Object>{};

    final keyType = targetType.keyType();
    final valueType = targetType.componentType();

    for (final pair in pairs) {
      if (pair.trim().isEmpty) continue;
      final kv = pair.split('=');
      final rawKey = kv.isNotEmpty ? kv[0].trim() : '';
      final rawValue = kv.length > 1 ? kv.sublist(1).join('=').trim() : '';

      final keyName = keyType?.getName() ?? OBJECT_CLASS.getName();
      final valueName = valueType?.getName() ?? OBJECT_CLASS.getName();
      final validKeyType = keyName != OBJECT_CLASS.getName() && keyName != DYNAMIC_CLASS.getName() && !_isMalformedTypeName(keyName);
      final validValueType = valueName != OBJECT_CLASS.getName() && valueName != DYNAMIC_CLASS.getName() && !_isMalformedTypeName(valueName);

      Object? key = validKeyType ? _conversionService.convertTo(rawKey, keyType!, STRING) : rawKey;
      Object? value = validValueType ? _conversionService.convertTo(rawValue, valueType!, STRING) : rawValue;

      if(key != null && value != null) {
        targetMap[key] = value;
      }
    }

    final mapResult = ConversionAdapterUtils.getMapResult(targetType, targetMap);
    return mapResult;
  }
}

/// {@template map_to_string_generic_converter}
/// A converter that transforms different types of [Map] into a [String].
///
/// This class supports conversion from:
/// - `Map` → `String`
/// - `HashMap` → `String`
/// - `col.HashMap` → `String`
///
/// The resulting string is a comma-separated list of key-value pairs
/// where each pair is joined by an equals sign (`=`).
///
/// Example:
/// ```dart
/// final service = ConversionService(); // Your implementation
/// final converter = MapToStringGenericConverter(service);
///
/// final input = {"name": "John", "age": 30, "country": "USA"};
/// final result = converter.convert(
///   input,
///   Class<Map>(null, PackageNames.DART),
///   STRING,
/// );
///
/// print(result); // name=John, age=30, country=USA
/// ```
///
/// ### Key & Value Conversion
/// If the source map specifies key and value types, they will be converted
/// to `String` using the provided [ConversionService].
/// {@endtemplate}
class MapToStringGenericConverter extends CommonPairedConditionalConverter {
  final ConversionService _conversionService;

  /// {@macro map_to_string_generic_converter}
  MapToStringGenericConverter(this._conversionService);

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(Class<Map>(null, PackageNames.DART), STRING),
    ConvertiblePair(Class<HashMap>(null, PackageNames.LANG), STRING),
    ConvertiblePair(Class<col.HashMap>(null, PackageNames.DART), STRING),
  };

  @override
  bool matches(Class sourceType, Class targetType) {
    return _isMapLike(sourceType) && targetType.getType() == String;
  }

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final map = source as Map;
    // Use the runtime type of the source for accurate key/value types,
    // since the registered sourceType may be a raw type (e.g., Map without type params)
    final runtimeSourceType = source.getClass();
    final sourceKeyType = runtimeSourceType.keyType() ?? sourceType.keyType();
    final sourceValueType = runtimeSourceType.componentType() ?? sourceType.componentType();

    final parts = <String>[];
    map.forEach((key, value) {
      // Skip conversion when source types are Dynamic or Object — just use toString
      final useKeyConversion = sourceKeyType != null && sourceKeyType.getName() != DYNAMIC_CLASS.getName() && sourceKeyType.getName() != OBJECT_CLASS.getName();
      final useValueConversion = sourceValueType != null && sourceValueType.getName() != DYNAMIC_CLASS.getName() && sourceValueType.getName() != OBJECT_CLASS.getName();
      
      Object? keyStr = useKeyConversion ? _conversionService.convertTo(key, sourceKeyType, STRING) : key.toString();
      Object? valueStr = useValueConversion ? _conversionService.convertTo(value, sourceValueType, STRING) : value.toString();

      parts.add('$keyStr=$valueStr');
    });

    return parts.join(', ');
  }
}

/// {@template map_to_map_generic_converter}
/// A converter that transforms a [Map] (or any map-like type) into another
/// [Map] type, optionally converting keys and values.
///
/// This class supports conversions between:
/// - `Map`, `HashMap`, `col.HashMap` → Any of the above
///
/// ### Example
/// ```dart
/// final service = ConversionService(); // Your implementation
/// final converter = MapToMapGenericConverter(service);
///
/// final input = {"name": "John", "age": "30"};
/// final result = converter.convert(
///   input,
///   Class<Map>(null, PackageNames.DART),
///   Class<HashMap>(null, PackageNames.LANG),
/// );
///
/// print(result.runtimeType); // HashMap<dynamic, dynamic>
/// ```
///
/// ### Key & Value Conversion
/// If the source and target maps specify types for keys and values,
/// this converter will use the [ConversionService] to transform them.
/// {@endtemplate}
class MapToMapGenericConverter extends CommonPairedConditionalConverter {
  final ConversionService _conversionService;

  /// {@macro map_to_map_generic_converter}
  MapToMapGenericConverter(this._conversionService);

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(Class<Map>(null, PackageNames.DART), Class<Map>(null, PackageNames.DART)),
    ConvertiblePair(Class<Map>(null, PackageNames.DART), Class<HashMap>(null, PackageNames.LANG)),
    ConvertiblePair(Class<Map>(null, PackageNames.DART), Class<col.HashMap>(null, PackageNames.DART)),
    ConvertiblePair(Class<HashMap>(null, PackageNames.LANG), Class<Map>(null, PackageNames.DART)),
    ConvertiblePair(Class<HashMap>(null, PackageNames.LANG), Class<HashMap>(null, PackageNames.LANG)),
    ConvertiblePair(Class<HashMap>(null, PackageNames.LANG), Class<col.HashMap>(null, PackageNames.DART)),
    ConvertiblePair(Class<col.HashMap>(null, PackageNames.DART), Class<Map>(null, PackageNames.DART)),
    ConvertiblePair(Class<col.HashMap>(null, PackageNames.DART), Class<HashMap>(null, PackageNames.LANG)),
    ConvertiblePair(Class<col.HashMap>(null, PackageNames.DART), Class<col.HashMap>(null, PackageNames.DART)),
  };

  @override
  bool matches(Class sourceType, Class targetType) {
    if (!_isMapLike(sourceType) || !_isMapLike(targetType)) {
      return false;
    }

    final sourceKeyType = sourceType.keyType();
    final sourceValueType = sourceType.componentType();
    final targetKeyType = targetType.keyType();
    final targetValueType = targetType.componentType();
    
    if (sourceKeyType == null || sourceValueType == null || targetKeyType == null || targetValueType == null) {
      return true;
    }
    
    return ConversionUtils.canConvert(sourceKeyType, targetKeyType, _conversionService) 
      && ConversionUtils.canConvert(sourceValueType, targetValueType, _conversionService);
  }

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final sourceMap = source as Map;
    final targetMap = <Object, Object>{};

    final keyType = targetType.keyType();
    final valueType = targetType.componentType();
    // Use the runtime type of the source for accurate key/value types
    final runtimeSourceType = source.getClass();
    final sourceKeyType = runtimeSourceType.keyType() ?? sourceType.keyType();
    final sourceValueType = runtimeSourceType.componentType() ?? sourceType.componentType();

    sourceMap.forEach((k, v) {
      final useKeyConversion = keyType != null && sourceKeyType != null
          && keyType.getName() != OBJECT_CLASS.getName() && keyType.getName() != DYNAMIC_CLASS.getName()
          && sourceKeyType.getName() != OBJECT_CLASS.getName() && sourceKeyType.getName() != DYNAMIC_CLASS.getName();
      final useValueConversion = valueType != null && sourceValueType != null
          && valueType.getName() != OBJECT_CLASS.getName() && valueType.getName() != DYNAMIC_CLASS.getName()
          && sourceValueType.getName() != OBJECT_CLASS.getName() && sourceValueType.getName() != DYNAMIC_CLASS.getName();

      Object? newKey = useKeyConversion
          ? _conversionService.convertTo(k, keyType, sourceKeyType)
          : k;

      Object? newValue = useValueConversion
          ? _conversionService.convertTo(v, valueType, sourceValueType)
          : v;

      if(newKey != null && newValue != null) {
        targetMap[newKey] = newValue;
      }
    });

    return ConversionAdapterUtils.getMapResult(targetType, targetMap);
  }
}

/// Checks if a type name is malformed (e.g., contains dots from unresolved qualified names).
///
/// Valid Dart type names should only contain letters, digits, underscores,
/// and should not contain dots. Names with dots indicate failed type resolution
/// (e.g., `EnumName.name` instead of the actual type).
bool _isMalformedTypeName(String name) {
  return name.contains('.');
}

/// Determines whether the given [type] represents a Map-like structure.
///
/// This method checks if [type] corresponds to one of the common Map implementations
/// such as [Map], [HashMap], or any Dart Map subtype. It also verifies assignability
/// to the generic [Map] class to support custom Map implementations.
///
/// Returns `true` if [type] is a Map or Map subtype; otherwise, `false`.
bool _isMapLike(Class type) {
  final t = type.getType();
  return t == Map ||
         t == HashMap ||
         t == col.HashMap ||
         type.isAssignableTo(Class<Map>(null, PackageNames.DART));
}