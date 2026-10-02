import 'dart:typed_data';

import 'package:jetleaf_lang/lang.dart';

import '../exceptions.dart';
import '../helpers/_commons.dart';
import '../helpers/convertible_pair.dart';

// ============================================= UUID CONVERTER ============================================

/// {@template string_to_uuid_converter}
/// A [Converter] that converts a [String] to a [Uuid].
///
/// Supports standard UUID string formats with or without hyphens.
/// Parsing is case-insensitive and validates UUID format compliance.
///
/// Example:
/// ```dart
/// final converter = StringToUuidConverter();
/// print(converter.convert('550e8400-e29b-41d4-a716-446655440000'));
/// print(converter.convert('550e8400e29b41d4a716446655440000'));
/// print(converter.convert('550E8400-E29B-41D4-A716-446655440000'));
/// ```
/// {@endtemplate}
class StringToUuidConverter extends CommonConverter<String, Uuid> {
  /// {@macro string_to_uuid_converter}
  @override
  Uuid convert(String source) {
    try {
      return Uuid.fromString(source);
    } catch (e) {
      throw ConversionFailedException(sourceType: Class.forType(String), targetType: Class.forType(Uuid), value: source);
    }
  }
}

/// {@template uuid_to_string_converter}
/// A [Converter] that converts a [Uuid] to a [String].
///
/// Example:
/// ```dart
/// final converter = UuidToStringConverter();
/// print(converter.convert(Uuid())); // prints: "550e8400-e29b-41d4-a716-446655440000"
/// ```
/// {@endtemplate}
class UuidToStringConverter extends CommonConverter<Uuid, String> {
  /// {@macro uuid_to_string_converter}
  @override
  String convert(Uuid source) {
    return source.toString();
  }
}

/// {@template byte_multi_converter}
/// A [Converter] that converts between [Byte], [String], [List], and [Uint8List].
///
/// Supports the following conversions:
/// - `Byte` ↔ `String`
/// - `Byte` ↔ `List<int>`
/// - `Byte` ↔ `Uint8List`
/// - `String` ↔ `Byte`
/// - `List<int>` ↔ `Byte`
/// - `Uint8List` ↔ `Byte`
///
/// Example:
/// ```dart
/// final converter = ByteMultiConverter();
/// print(converter.convert(Byte.fromString('Hello'), Class.forType(Byte), Class.forType(String))); // "Hello"
/// print(converter.convert('Hello', Class.forType(String), Class.forType(Byte)).toString()); // "Hello"
/// ```
/// {@endtemplate}
class ByteMultiConverter extends CommonPairedConditionalConverter {
  static final Class BYTE_TYPE      = Class<Byte>(null, PackageNames.LANG);
  static final Class STRING_TYPE    = STRING;
  static final Class LIST_TYPE      = Class<List>(null, PackageNames.DART);
  static final Class UINT8LIST_TYPE = Class<Uint8List>(null, PackageNames.DART);

  ByteMultiConverter();

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(BYTE_TYPE, STRING_TYPE),
    ConvertiblePair(STRING_TYPE, BYTE_TYPE),

    ConvertiblePair(BYTE_TYPE, LIST_TYPE),
    ConvertiblePair(LIST_TYPE, BYTE_TYPE),

    ConvertiblePair(BYTE_TYPE, UINT8LIST_TYPE),
    ConvertiblePair(UINT8LIST_TYPE, BYTE_TYPE),
  };

  @override
  bool matches(Class sourceType, Class targetType) {
    // Byte ↔ String
    if (sourceType.isAssignableTo(BYTE_TYPE) && targetType.isAssignableTo(STRING_TYPE)) return true;
    if (sourceType.isAssignableTo(STRING_TYPE) && targetType.isAssignableTo(BYTE_TYPE)) return true;

    // Byte ↔ List<int>
    if (sourceType.isAssignableTo(BYTE_TYPE) && _isConvertible(targetType)) return true;
    if (_isConvertible(sourceType) && targetType.isAssignableTo(BYTE_TYPE)) return true;

    // Byte ↔ Uint8List
    if (sourceType.isAssignableTo(BYTE_TYPE) && targetType.isAssignableTo(UINT8LIST_TYPE)) return true;
    if (sourceType.isAssignableTo(UINT8LIST_TYPE) && targetType.isAssignableTo(BYTE_TYPE)) return true;

    return false;
  }

  bool _isConvertible(Class type) {
    bool isList = type.isAssignableTo(LIST_TYPE) || type.getType() == LIST_TYPE.getType();
    final child = type.componentType();

    if (isList && child != null && child.getType() == int) {
      return true;
    }

    return false;
  }

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    // Byte → String
    if (sourceType.isAssignableTo(BYTE_TYPE) && targetType.isAssignableTo(STRING_TYPE)) {
      return (source as Byte).toString();
    }

    // String → Byte
    if (sourceType.isAssignableTo(STRING_TYPE) && targetType.isAssignableTo(BYTE_TYPE)) {
      return Byte.fromString(source as String);
    }

    // Byte → List<int>
    if (sourceType.isAssignableTo(BYTE_TYPE) && _isConvertible(targetType)) {
      return (source as Byte).toList();
    }

    // List<int> → Byte
    if (_isConvertible(sourceType) && targetType.isAssignableTo(BYTE_TYPE)) {
      final list = source as List;
      if (list.isEmpty) return Byte.empty();
      return Byte.fromList(list.cast<int>());
    }

    // Byte → Uint8List
    if (sourceType.isAssignableTo(BYTE_TYPE) && targetType.isAssignableTo(UINT8LIST_TYPE)) {
      return (source as Byte).toUint8List();
    }

    // Uint8List → Byte
    if (sourceType.isAssignableTo(UINT8LIST_TYPE) && targetType.isAssignableTo(BYTE_TYPE)) {
      return Byte.fromUint8List(source as Uint8List);
    }

    throw IllegalStateException("Unsupported conversion: $sourceType -> $targetType");
  }
}

// ========================================= LOCALE CONVERTER =============================================

/// {@template string_to_locale_converter}
/// A [Converter] that converts a [String] to a [Locale].
///
/// Supports standard locale formats like "en", "en_US", "en-US".
///
/// Example:
/// ```dart
/// final converter = StringToLocaleConverter();
/// print(converter.convert('en_US')); // prints: Locale('en', 'US')
/// ```
/// {@endtemplate}
class StringToLocaleConverter extends CommonConverter<String, Locale> {
  /// {@macro string_to_locale_converter}
  StringToLocaleConverter();

  @override
  Locale convert(String source) {
    final parts = source.replaceAll('-', '_').split('_');
    
    if (parts.length == 1) {
      return Locale(parts[0]);
    } else if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    } else {
      return Locale.parse(source);
    }
  }
}

class LocaleToStringConverter extends CommonConverter<Locale, String> {
  /// {@macro locale_to_string_converter}
  LocaleToStringConverter();

  @override
  String convert(Locale source) {
    return source.toString();
  }
}

// ========================================= CURRENCY CONVERTER ============================================

/// {@template string_to_currency_converter}
/// A [Converter] that converts a [String] to a [Currency].
///
/// Accepts ISO 4217 currency codes.
///
/// Example:
/// ```dart
/// final converter = StringToCurrencyConverter();
/// print(converter.convert('USD')); // prints: Currency('USD')
/// ```
/// {@endtemplate}
class StringToCurrencyConverter extends CommonConverter<String, Currency> {
  /// {@macro string_to_currency_converter}
  @override
  Currency convert(String source) {
    try {
      return Currency.getInstance(source.toUpperCase());
    } on IllegalArgumentException catch (_) {
      try {
        return Currency.getInstanceFromLocale(Locale(source.toUpperCase()));
      } catch (e) {
        throw ConversionFailedException(sourceType: Class.forType(String), targetType: Class.forType(Currency), value: source);
      }
    } 
  }
}

/// {@template currency_to_string_converter}
/// A [Converter] that converts a [Currency] to a [String].
///
/// Example:
/// ```dart
/// final converter = CurrencyToStringConverter();
/// print(converter.convert(Currency.getInstance('USD'))); // prints: 'USD'
/// ```
/// {@endtemplate}
class CurrencyToStringConverter extends CommonConverter<Currency, String> {
  /// {@macro currency_to_string_converter}
  CurrencyToStringConverter();

  @override
  String convert(Currency source) {
    return source.currencyCode;
  }
}