import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta_meta.dart';

/// Defines the structural strategies available for formatting and parsing [Duration] string representations.
enum DurationFormatStyle {
  /// Standard corporate machine-to-machine exchange format following the structural ISO-8601 duration contract specification.
  /// 
  /// Representation patterns begin with the designated sequence designator `P`, followed by specific chronological segment periods 
  /// prefixed with individual time designator tags `T`.
  /// 
  /// * **Example Value Object Mapping:** `Duration(hours: 1, minutes: 30)` prints as `"PT1H30M"`.
  iso8601,

  /// A compact, single-token atomic format pairing a scalar numeric magnitude with a singular trailing alphabetic unit suffix token.
  /// 
  /// * **Example Value Object Mapping:** `Duration(seconds: 45)` prints as `"45s"`.
  simple,

  /// A multi-segment composite string layout decomposing total duration properties down across an ordered chain of structural 
  /// unit chunks from largest to smallest values, leaving out empty or zero segments.
  /// 
  /// * **Example Value Object Mapping:** `Duration(hours: 1, minutes: 12, seconds: 27)` prints as `"1h12m27s"`.
  composite,
}

/// A comprehensive structural enumeration mapping out the supported execution units for duration parsing, formatting, and mathematical conversion layers.
/// 
/// Beyond storing immutable string suffix mappings, this component encapsulates lower-level precision transformations and parsing logic to shield 
/// conversion engines from manual scaling mistakes.
enum DurationFormatUnit {
  /// Nanosecond time interval resolution.
  nanos('ns'),

  /// Microsecond time interval resolution.
  micros('us'),

  /// Millisecond time interval resolution.
  millis('ms'),

  /// Second time interval resolution.
  seconds('s'),

  /// Minute time interval resolution.
  minutes('m'),

  /// Hour time interval resolution.
  hours('h'),

  /// Day time interval resolution.
  days('d');

  /// The standardized alphabetic textual suffix tracking identifier assigned to this unique chronological step.
  final String suffix;

  /// Internal private generative constructor mapping literal text codes to chronological units.
  const DurationFormatUnit(this.suffix);

  /// Extrapolates the mathematical magnitude of the incoming [Duration] object, returning a long integer 
  /// scaled exactly to the precision requirements of this active structural unit.
  /// 
  /// ### Precision Degradation Warning
  /// Native Dart execution environments operate on microsecond temporal boundaries. Because nanosecond tracking 
  /// exceeds this structural platform layer, evaluating [DurationFormatUnit.nanos] computes a synthesized scale factor extrapolation 
  /// ($1\,\text{microsecond} = 1000\,\text{nanoseconds}$).
  int longValue(Duration value) {
    return switch (this) {
      DurationFormatUnit.nanos => value.inMicroseconds * 1000,
      DurationFormatUnit.micros => value.inMicroseconds,
      DurationFormatUnit.millis => value.inMilliseconds,
      DurationFormatUnit.seconds => value.inSeconds,
      DurationFormatUnit.minutes => value.inMinutes,
      DurationFormatUnit.hours => value.inHours,
      DurationFormatUnit.days => value.inDays,
    };
  }

  /// Transforms a raw, unstructured scalar character string into an isolated [Duration] value object 
  /// calculated according to this active unit's coordinate system rule constraints.
  /// 
  /// ### Failures & Boundary Safety
  /// Throws a [FormatException] if the underlying [value] string token contains non-numeric structural characters 
  /// that fail standard mathematical primitive parsing routines.
  Duration parse(String value) {
    final parsedInt = int.parse(value);

    return switch (this) {
      DurationFormatUnit.nanos => Duration(microseconds: parsedInt ~/ 1000),
      DurationFormatUnit.micros => Duration(microseconds: parsedInt),
      DurationFormatUnit.millis => Duration(milliseconds: parsedInt),
      DurationFormatUnit.seconds => Duration(seconds: parsedInt),
      DurationFormatUnit.minutes => Duration(minutes: parsedInt),
      DurationFormatUnit.hours => Duration(hours: parsedInt),
      DurationFormatUnit.days => Duration(days: parsedInt),
    };
  }

  /// Formats the raw numeric snapshot value derived from the incoming [Duration] instance, appending 
  /// the active unit's corresponding suffix descriptor immediately after the integer block without padding.
  /// 
  /// * **Example (`DurationFormatUnit.seconds`):** A value tracking 15 seconds returns exactly `"15s"`.
  String print(Duration value) => "${longValue(value)}$suffix";

  /// Scans the internal lookup matrix to resolve the matching [DurationFormatUnit] variant corresponding 
  /// directly to the provided character string [suffix].
  /// 
  /// ### Parameters
  /// - [suffix]: The raw text string identifier extracted from user input strings or configuration files.
  /// 
  /// ### Failures & Edge Cases
  /// Throws an [IllegalArgumentException] if the [suffix] parameter contains unrecognized tokens or empty data characters 
  /// that fail to match any preconfigured value.
  static DurationFormatUnit fromSuffix(String suffix) {
    final normalized = suffix.trim().toLowerCase();
    for (final candidate in DurationFormatUnit.values) {
      if (candidate.suffix == normalized) return candidate;
    }
    throw IllegalArgumentException("'$suffix' is not a valid simple duration Unit");
  }
}

/// {@template duration_format}
/// A declarative aspect-oriented metadata annotation instructing structural type conversion registries, data binders, 
/// and serialization encoders on how to process, format, and reconstruct [Duration] domain model properties.
/// 
/// Placing this annotation on a property decouples structural serialization formats from global defaults. It allows 
/// granular configuration for properties like network interaction timeouts, system thread delay loops, or cache TTL rules.
/// 
/// ### Structural Suffix Evaluation Laws
/// When utilizing [DurationFormatStyle.simple], if an incoming text stream omits a suffix character completely, parsing logic 
/// captures the data by automatically routing the numeric scalar token through the [defaultUnit] property strategy.
/// 
/// ### Target Restrictions
/// Bound explicitly via `@Target`, this metadata annotation is allowed only when attached directly to fields, 
/// method return signatures, or incoming executable method parameters.
/// 
/// ### Architecture Example
/// ```dart
/// class SystemPerformanceConfiguration {
///   // Marshals using standard web API ISO formats: e.g., "PT30M"
///   @DurationFormat(style: DurationFormatStyle.iso8601)
///   final Duration keepAliveTimeout;
/// 
///   // Emits simple format values: e.g., "500ms"
///   @DurationFormat(style: DurationFormatStyle.simple, defaultUnit: DurationFormatUnit.millis)
///   final Duration debounceDelayThreshold;
/// 
///   // Handles composite structured multi-unit intervals: e.g., "2h15m"
///   @DurationFormat(style: DurationFormatStyle.composite)
///   final Duration backupCycleInterval;
/// 
///   const SystemPerformanceConfiguration(
///     this.keepAliveTimeout,
///     this.debounceDelayThreshold,
///     this.backupCycleInterval,
///   );
/// }
/// ```
/// {@endtemplate}
@Target({ TargetKind.method, TargetKind.field, TargetKind.parameter })
final class DurationFormat extends ReflectableAnnotation {
  /// The specific structural formatting style rule configuration applied during text parsing and printing operations.
  final DurationFormatStyle style;

  /// The fallback precision unit strategy applied exclusively when parsing a numeric string that completely lacks a unit suffix identifier.
  final DurationFormatUnit defaultUnit;

  /// Creates a compile-time constant metadata configuration token utilized by framework reflection scanners and serialization engines.
  /// 
  /// {@macro duration_format}
  const DurationFormat({
    this.style = DurationFormatStyle.iso8601,
    this.defaultUnit = DurationFormatUnit.millis,
  });

  @override
  Type get annotationType => DurationFormat;
}