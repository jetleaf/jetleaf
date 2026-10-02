// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';

import '../base/generator.dart';
import '../base/object_mapper.dart';
import '../base/parser.dart';
import '../json/adapter/json_adapter.dart';
import '../json/generator/json_generator.dart';
import '../serialization/deserialization_context.dart';
import '../serialization/object_serialization_adapter.dart';
import '../serialization/serialization_context.dart';

/// {@template datetime_serialization_adapter}
/// Adapter to serialize and deserialize [DateTime] objects to and from
/// their string representations using ISO8601 format or a configured timezone.
///
/// Supports both serialization via a [Generator] and deserialization via a [Parser].
///
/// ### Features
/// - Serializes [DateTime] to ISO8601 string or zoned string if a timezone is configured.
/// - Deserializes ISO8601 string to [DateTime], applying timezone conversion if specified.
/// - Works with Jetson's generic [SerializationContext] and [DeserializationContext].
///
/// ### Usage Example
/// ```dart
/// final adapter = DateTimeSerializationAdapter<JsonGenerator, JsonParser, DeserializationContext, SerializationContext>();
///
/// // Serialization
/// adapter.serialize(DateTime.now(), generator, serializerContext);
///
/// // Deserialization
/// final date = adapter.deserialize(parser, deserializationContext, Class<DateTime>());
/// ```
///
/// ### See also
/// - [JsonSerializationAdapter]
/// - [ZonedDateTime]
/// - [ObjectMapper]
/// - [DeserializationContext]
/// {@endtemplate}
@Generic(DateTimeSerializationAdapter)
final class DateTimeSerializationAdapter<
  G extends Generator,
  P extends Parser,
  DC extends DeserializationContext,
  SC extends SerializationContext
> extends ObjectSerializationAdapter<DateTime, G, P, DC, SC> {
  /// Creates a new [DateTimeSerializationAdapter].
  ///
  /// {@macro datetime_serialization_adapter}
  DateTimeSerializationAdapter();

  @override
  bool canDeserialize(Class type) => type == Class<DateTime>() || type.getType() == DateTime;

  @override
  bool canSerialize(Class type) => canDeserialize(type);

  @override
  void serialize(DateTime value, G generator, SC serializer) {
    final timezone = serializer.getEnvironment().getProperty(ObjectMapper.TIMEZONE_PROPERTY)
      ?? serializer.getEnvironment().getProperty(AbstractApplicationContext.APPLICATION_TIMEZONE);

    if (timezone != null) {
      generator.writeString(ZonedDateTime.fromDateTime(value, ZoneId.of(timezone)).toString());
    } else {
      generator.writeString(value.toUtc().toIso8601String());
    }
  }

  @override
  DateTime? deserialize(P parser, DC ctxt, Class toClass) {
    final raw = parser.getCurrentValue();

    if (raw == null) {
      return null;
    }

    final timezone = ctxt.getEnvironment().getProperty(ObjectMapper.TIMEZONE_PROPERTY)
      ?? ctxt.getEnvironment().getProperty(AbstractApplicationContext.APPLICATION_TIMEZONE);

    if (raw is String) {
      if (timezone != null) {
        return ZonedDateTime.fromDateTime(DateTime.parse(raw), ZoneId.of(timezone)).toDateTime();
      }
    }

    try {
      final converter = ctxt.getConversionService();
      return converter.convert(raw, Class<DateTime>());
    } catch (_) {
      if (raw is String) {
        return DateTime.parse(raw).toLocal();
      }
    }

    throw InvalidFormatException('Expected ISO8601 string for DateTime, got $raw');
  }

  @override
  Class<DateTime> toClass() => Class<DateTime>(null, PackageNames.DART);
}

// -------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------
// DURATION
// -------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------

/// {@template duration_serialization_adapter}
/// Serializes and deserializes Dart `Duration` values to and from JSON-compatible representations.
///
/// The [DurationSerializationAdapter] provides a unified adapter for handling
/// `Duration` objects in both serialization and deserialization processes,
/// including JSON-specific and generic generators/parsers.
///
/// ### Serialization Rules
/// - For [JsonGenerator], the duration is serialized as the total number of
///   microseconds using `writeNumber()`.
/// - For non-JSON generators, the duration is serialized as a string via
///   `toString()`.
///
/// ### Deserialization Rules
/// - Accepts numeric JSON values (int, double) and converts them into
///   `Duration` via microseconds.
/// - Accepts string representations of numbers and converts them to `Duration`.
/// - If conversion fails, throws an [InvalidFormatException].
///
/// ### Example
/// ```dart
/// final adapter = DurationSerializationAdapter();
///
/// final duration = Duration(seconds: 5);
/// adapter.serialize(duration, generator, context);
/// // JSON output: 5000000 (microseconds)
///
/// final parsed = adapter.deserialize(parser, context, Class.forType(Duration));
/// // parsed is a Duration instance
/// ```
///
/// ### Notes
/// - Uses the context's [ConversionService] when possible for flexible type
///   conversion.
/// - Ensures consistent behavior across JSON and non-JSON output formats.
/// {@endtemplate}
@Generic(DurationSerializationAdapter)
final class DurationSerializationAdapter<
  G extends Generator,
  P extends Parser,
  DC extends DeserializationContext,
  SC extends SerializationContext
> extends ObjectSerializationAdapter<Duration, G, P, DC, SC> {
  /// Creates a new [DurationSerializationAdapter].
  ///
  /// {@macro duration_serialization_adapter}
  DurationSerializationAdapter();

  @override
  bool canDeserialize(Class type) => type == Class<DateTime>() || type.getType() == DateTime;

  @override
  bool canSerialize(Class type) => canDeserialize(type);

  @override
  void serialize(Duration value, G generator, SC serializer) {
    if (generator is JsonGenerator) {
      generator.writeNumber(value.inMicroseconds);
    } else {
      generator.writeString(value.toString());
    }
  }

  @override
  Duration? deserialize(P parser, DC ctxt, Class toClass) {
    final raw = parser.getCurrentValue();

    if (raw == null) {
      return null;
    }

    try {
      final converter = ctxt.getConversionService();
      return converter.convert(raw, Class<Duration>());
    } catch (_) {
      if (raw is num) {
        return Duration(microseconds: raw.toInt());
      }

      if (raw is String) {
        int? resolved = int.tryParse(raw);

        if (resolved != null) {
          return Duration(milliseconds: resolved);
        }
      }
    }

    throw InvalidFormatException('Expected numeric value for Duration, got $raw');
  }

  @override
  Class<Duration> toClass() => Class<Duration>(null, PackageNames.DART);
}

// -------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------
// LOCAL DATE
// -------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------

/// {@template local_date_serialization_adapter}
/// Serializes and deserializes Dart `LocalDate` values to and from ISO-8601 strings.
///
/// The [LocalDateSerializationAdapter] provides a unified adapter for handling
/// `LocalDate` objects in both serialization and deserialization processes,
/// including JSON and generic generators/parsers.
///
/// ### Serialization Rules
/// - Converts the `LocalDate` to an ISO-8601 string (e.g., `"2025-10-28"`) using `toString()`.
/// - Writes the value using `generator.writeString()`.
///
/// ### Deserialization Rules
/// - Accepts ISO-8601 formatted strings and converts them to `LocalDate`.
/// - Uses the context's [ConversionService] if available for type conversion.
/// - Throws [InvalidFormatException] if the input is not a valid ISO-8601 date string.
///
/// ### Example
/// ```dart
/// final adapter = LocalDateSerializationAdapter();
///
/// final date = LocalDate(2025, 10, 28);
/// adapter.serialize(date, generator, context);
/// // JSON output: "2025-10-28"
///
/// final parsed = adapter.deserialize(parser, context, Class.forType(LocalDate));
/// // parsed is a LocalDate instance
/// ```
///
/// ### Notes
/// - This adapter only handles the date portion; time is ignored.
/// - For non-ISO formats, use a custom `JsonConverter`.
/// {@endtemplate}
@Generic(LocalDateSerializationAdapter)
final class LocalDateSerializationAdapter<
  G extends Generator,
  P extends Parser,
  DC extends DeserializationContext,
  SC extends SerializationContext
> extends ObjectSerializationAdapter<LocalDate, G, P, DC, SC> {
  /// Creates a new [LocalDateSerializationAdapter].
  ///
  /// {@macro local_date_serialization_adapter}
  LocalDateSerializationAdapter();

  @override
  bool canDeserialize(Class type) => type == Class<DateTime>() || type.getType() == DateTime;

  @override
  bool canSerialize(Class type) => canDeserialize(type);

  @override
  void serialize(LocalDate value, G generator, SC serializer) {
    // Writes the LocalDate as an ISO-8601 string, e.g. "2025-10-28"
    generator.writeString(value.toString());
  }

  @override
  LocalDate? deserialize(P parser, DC ctxt, Class toClass) {
    final raw = parser.getCurrentValue();

    if (raw == null) {
      return null;
    }

    try {
      return ctxt.getConversionService().convert(raw, Class<LocalDate>());
    } catch (_) {
      if (raw is String) {
        return LocalDate.parse(raw);
      }

      throw InvalidFormatException('Invalid LocalDate format. Expected ISO-8601 (e.g. "2025-10-28") but received $raw');
    }
  }

  @override
  Class<LocalDate> toClass() => Class<LocalDate>(null, PackageNames.LANG);
}

// -------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------
// LOCAL DATE TIME
// -------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------

/// {@template local_date_time_serialization_adapter}
/// Serializes and deserializes Dart `LocalDateTime` values to and from ISO-8601 strings.
///
/// The [LocalDateTimeSerializationAdapter] provides a unified adapter for
/// handling `LocalDateTime` objects in both serialization and deserialization,
/// supporting JSON and generic generators/parsers.
///
/// ### Serialization Rules
/// - Converts the `LocalDateTime` to an ISO-8601 string using `toString()`.
/// - Writes the string using `generator.writeString()`.
///
/// ### Deserialization Rules
/// - Accepts ISO-8601 formatted strings and converts them to `LocalDateTime`.
/// - Uses the context's [ConversionService] if available for type conversion.
/// - Throws [InvalidFormatException] if the input string is invalid.
///
/// ### Example
/// ```dart
/// final adapter = LocalDateTimeSerializationAdapter();
///
/// final dateTime = LocalDateTime(2025, 6, 27, 8, 15, 30, 123);
/// adapter.serialize(dateTime, generator, context);
/// // JSON output: "2025-06-27T08:15:30.123"
///
/// final parsed = adapter.deserialize(parser, context, Class.forType(LocalDateTime));
/// // parsed is a LocalDateTime instance
/// ```
///
/// ### Notes
/// - This adapter preserves both date and time information, but does not handle time zones.
/// - For non-ISO formats or custom time zone handling, use a dedicated `JsonConverter`.
/// {@endtemplate}
@Generic(LocalDateTimeSerializationAdapter)
final class LocalDateTimeSerializationAdapter<
  G extends Generator,
  P extends Parser,
  DC extends DeserializationContext,
  SC extends SerializationContext
> extends ObjectSerializationAdapter<LocalDateTime, G, P, DC, SC> {
  /// Creates a new [LocalDateTimeSerializationAdapter].
  ///
  /// {@macro local_date_time_serialization_adapter}
  LocalDateTimeSerializationAdapter();

  @override
  bool canDeserialize(Class type) => type == Class<DateTime>() || type.getType() == DateTime;

  @override
  bool canSerialize(Class type) => canDeserialize(type);

  @override
  void serialize(LocalDateTime value, G generator, SC serializer) {
    generator.writeString(value.toString());
  }

  @override
  LocalDateTime? deserialize(P parser, DC ctxt, Class toClass) {
    final raw = parser.getCurrentValue();

    if (raw == null) {
      return null;
    }

    try {
      return ctxt.getConversionService().convert(raw, Class<LocalDateTime>());
    } catch (_) {
      if (raw is String) {
        return LocalDateTime.parse(raw);
      }

      throw InvalidFormatException(
        'Cannot deserialize LocalDateTime: expected a zoned ISO-8601 formatted string '
        '(e.g. "2025-06-27T08:15:30.123"), '
        'but received value "$raw" of type ${raw.runtimeType}.'
      );
    }
  }

  @override
  Class<LocalDateTime> toClass() => Class<LocalDateTime>(null, PackageNames.LANG);
}

// -------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------
// URI
// -------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------

/// {@template uri_serialization_adapter}
/// Serializes and deserializes Dart `Uri` values to and from strings.
///
/// The [UriSerializationAdapter] provides a unified adapter for handling
/// `Uri` objects in both serialization and deserialization, supporting JSON
/// and generic generators/parsers.
///
/// ### Serialization Rules
/// - Converts the `Uri` to its string representation using `toString()`.
/// - Writes the value using `generator.writeString()`.
///
/// ### Deserialization Rules
/// - Accepts string values and converts them to `Uri` using `Uri.parse()`.
/// - Uses the context's [ConversionService] if available for type conversion.
/// - Throws [FormatException] if the input is not a valid string.
///
/// ### Example
/// ```dart
/// final adapter = UriSerializationAdapter();
///
/// final uri = Uri.parse("https://example.com/path");
/// adapter.serialize(uri, generator, context);
/// // JSON output: "https://example.com/path"
///
/// final parsed = adapter.deserialize(parser, context, Class.forType(Uri));
/// // parsed is a Uri instance
/// ```
///
/// ### Notes
/// - This adapter expects valid URI strings; malformed strings will result
///   in a runtime exception.
/// {@endtemplate}
@Generic(UriSerializationAdapter)
final class UriSerializationAdapter<
  G extends Generator,
  P extends Parser,
  DC extends DeserializationContext,
  SC extends SerializationContext
> extends ObjectSerializationAdapter<Uri, G, P, DC, SC> {
  /// Creates a new [UriSerializationAdapter].
  ///
  /// {@macro uri_serialization_adapter}
  UriSerializationAdapter();

  @override
  bool canDeserialize(Class type) => type == Class<DateTime>() || type.getType() == DateTime;

  @override
  bool canSerialize(Class type) => canDeserialize(type);

  @override
  void serialize(Uri value, G generator, SC serializer) {
    generator.writeString(value.toString());
  }

  @override
  Uri? deserialize(P parser, DC ctxt, Class toClass) {
    final raw = parser.getCurrentValue();
    
    if (raw == null) {
      return null;
    }

    try {
      return ctxt.getConversionService().convert(raw, Class<Uri>());
    } catch (_) {
      if (raw is String) {
        return Uri.parse(raw);
      }

      throw FormatException('Expected string value for Uri, got $raw');
    }
  }

  @override
  Class<Uri> toClass() => Class<Uri>(null, PackageNames.DART);
}

// -------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------
// URL
// -------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------

/// {@template url_serialization_adapter}
/// Serializes and deserializes Dart `Url` values to and from strings.
///
/// The [UrlSerializationAdapter] provides a unified adapter for handling
/// `Url` objects in both serialization and deserialization, supporting JSON
/// and generic generators/parsers.
///
/// ### Serialization Rules
/// - Converts the `Url` to its string representation using `toString()`.
/// - Writes the value using `generator.writeString()`.
///
/// ### Deserialization Rules
/// - Accepts string values and converts them to `Url` using `Uri.parse(raw).toUrl()`.
/// - Uses the context's [ConversionService] if available for type conversion.
/// - Throws [FormatException] if the input is not a valid string.
///
/// ### Example
/// ```dart
/// final adapter = UrlSerializationAdapter();
///
/// final url = Url.parse("https://example.com/path");
/// adapter.serialize(url, generator, context);
/// // JSON output: "https://example.com/path"
///
/// final parsed = adapter.deserialize(parser, context, Class.forType(Url));
/// // parsed is a Url instance
/// ```
///
/// ### Notes
/// - This adapter expects valid URL strings; malformed strings will result
///   in a runtime exception.
/// {@endtemplate}
@Generic(UrlSerializationAdapter)
final class UrlSerializationAdapter<
  G extends Generator,
  P extends Parser,
  DC extends DeserializationContext,
  SC extends SerializationContext
> extends ObjectSerializationAdapter<Url, G, P, DC, SC> {
  /// Creates a new [UrlSerializationAdapter].
  ///
  /// {@macro url_serialization_adapter}
  UrlSerializationAdapter();

  @override
  bool canDeserialize(Class type) => type == Class<DateTime>() || type.getType() == DateTime;

  @override
  bool canSerialize(Class type) => canDeserialize(type);

  @override
  void serialize(Url value, G generator, SC serializer) {
    generator.writeString(value.toString());
  }

  @override
  Url? deserialize(P parser, DC ctxt, Class toClass) {
    final raw = parser.getCurrentValue();
    
    if (raw == null) {
      return null;
    }

    try {
      return ctxt.getConversionService().convert(raw, Class<Url>());
    } catch (_) {
      if (raw is String) {
        return Uri.parse(raw).toUrl();
      }

      throw FormatException('Expected string value for Url, got $raw');
    }
  }

  @override
  Class<Url> toClass() => Class<Url>(null, PackageNames.LANG);
}

// -------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------
// ZONED DATE TIME
// -------------------------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------

/// {@template datetime_serialization_adapter}
/// Serializes and deserializes Dart `ZonedDateTime` values to and from strings.
///
/// The [ZonedDateTimeSerializationAdapter] provides a unified adapter for handling
/// `ZonedDateTime` objects in both serialization and deserialization, supporting JSON
/// and generic generators/parsers.
///
/// ### Serialization Rules
/// - Converts the `ZonedDateTime` to its ISO-8601 string representation using `toString()`.
/// - Writes the value using `generator.writeString()`.
///
/// ### Deserialization Rules
/// - Accepts string values and converts them to `ZonedDateTime` using `ZonedDateTime.parse(raw)`.
/// - Uses the context's [ConversionService] if available for type conversion.
/// - Throws [InvalidFormatException] if the input is not a valid ISO-8601 zoned string.
///
/// ### Example
/// ```dart
/// final adapter = ZonedDateTimeSerializationAdapter();
///
/// final zonedDateTime = ZonedDateTime.parse("2023-12-25T15:30:45-05:00[America/New_York]");
/// adapter.serialize(zonedDateTime, generator, context);
/// // JSON output: "2023-12-25T15:30:45-05:00[America/New_York]"
///
/// final parsed = adapter.deserialize(parser, context, Class.forType(ZonedDateTime));
/// // parsed is a ZonedDateTime instance
/// ```
///
/// ### Notes
/// - This adapter expects valid ISO-8601 zoned strings; malformed strings will result
///   in a runtime exception.
/// {@endtemplate}
@Generic(ZonedDateTimeSerializationAdapter)
final class ZonedDateTimeSerializationAdapter<
  G extends Generator,
  P extends Parser,
  DC extends DeserializationContext,
  SC extends SerializationContext
> extends ObjectSerializationAdapter<ZonedDateTime, G, P, DC, SC> {
  /// Creates a new [ZonedDateTimeSerializationAdapter].
  ///
  /// {@macro datetime_serialization_adapter}
  ZonedDateTimeSerializationAdapter();

  @override
  bool canDeserialize(Class type) => type == Class<DateTime>() || type.getType() == DateTime;

  @override
  bool canSerialize(Class type) => canDeserialize(type);

  @override
  void serialize(ZonedDateTime value, G generator, SC serializer) {
    generator.writeString(value.toString());
  }

  @override
  ZonedDateTime? deserialize(P parser, DC ctxt, Class toClass) {
    final raw = parser.getCurrentValue();

    if (raw == null) {
      return null;
    }

    try {
      return ctxt.getConversionService().convert(raw, Class<ZonedDateTime>());
    } catch (_) {
      if (raw is String) {
        return ZonedDateTime.parse(raw);
      }

      throw InvalidFormatException(
        'Cannot deserialize ZonedDateTime: expected a zoned ISO-8601 formatted string '
        '(e.g. "2023-12-25T15:30:45-05:00[America/New_York]"), '
        'but received value "$raw" of type ${raw.runtimeType}.'
      );
    }
  }

  @override
  Class<ZonedDateTime> toClass() => Class<ZonedDateTime>(null, PackageNames.LANG);
}