import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta_meta.dart';

/// Common standard ISO-8601 date-time format patterns supported natively by the [DateTimeFormat] annotation framework.
///
/// These predefined options capture the vast majority of machine-to-machine exchange formats across typical
/// enterprise APIs, database serialization boundaries, and compliance tracking frameworks.
enum DateTimeFormatIso {
  /// Represents the standard ISO-8601 extended calendar date layout format `yyyy-MM-dd`.
  /// 
  /// Example output: `"2026-07-13"`.
  date,

  /// Represents the complete ISO-8601 time tracking layout including milliseconds and timezone offsets: `HH:mm:ss.SSSXXX`.
  /// 
  /// Example output: `"09:04:18.000+01:00"`.
  time,

  /// Represents the combined standard ISO-8601 extended date-time format including milliseconds and timezone offsets: `yyyy-MM-dd'T'HH:mm:ss.SSSXXX`.
  /// 
  /// Example output: `"2026-07-13T09:04:18.000+01:00"`.
  dateTime,

  /// Explicit flag indicating that no predefined ISO pattern strategy is active.
  /// 
  /// When selected, structural resolution logic falls back to inspecting the [DateTimeFormat.pattern] or [DateTimeFormat.style] configuration properties.
  none,
}

/// {@template date_time_format}
/// A declarative metadata annotation instructing type conversion pipelines, object-document mappers (ODMs), 
/// and presentation layer data binders on how to serialize, deserialize, parse, and print chronological properties.
///
/// By placing this annotation on a field, method parameter, or method declaration, developers decouple the domain model 
/// from uniform global formatting rules. It allows fine-grained, property-specific chronological masking tailored to localized requirements.
///
/// ### Precedence & Mutual Exclusivity Rules
/// While the annotation includes fields for standard styles, ISO definitions, and custom masks, these properties are handled 
/// according to a strict cascading precedence hierarchy. Only one formatting archetype should be configured per instance:
/// 1. **Custom Pattern ([pattern]):** Highest precedence. If [pattern] is filled with a non-empty string, it overrides all other flags.
/// 2. **ISO Standard Pattern ([iso]):** Secondary precedence. Active only if [pattern] is empty, overriding the [style] property.
/// 3. **Locale Style Combo ([style]):** Final fallback. Evaluated only if both [pattern] and [iso] are inactive. If the entire annotation is blank, it defaults to the short format style (`'SS'`).
///
/// ### Fault-Tolerant Deserialization (Fallback Parsing)
/// When parsing inbound text payloads (such as scraping unpredictable external API feeds), the configuration engine checks the 
/// [fallbackPatterns] collection if the primary mask fails. This permits grace windows during data migration or varying client payloads.
///
/// ### Target Constraints
/// Bound via `@Target`, this metadata wrapper is valid only when attached to fields, method return signatures, or method parameter declarations.
///
/// ### Architecture Example
/// ```dart
/// class AccountLedger {
///   // Custom mask taking absolute parsing priority
///   @DateTimeFormat(pattern: "yyyy/MM/dd HH:mm")
///   final DateTime closingTimestamp;
/// 
///   // Standard machine-to-machine ISO payload exchange format 
///   @DateTimeFormat(iso: DateTimeFormatIso.dateTime)
///   final DateTime synchronizationHook;
/// 
///   // Graceful processing of historic legacy text formats alongside the primary target layout
///   @DateTimeFormat(
///     pattern: "yyyy-MM-dd",
///     fallbackPatterns: ["MM/dd/yyyy", "dd-MM-yyyy"],
///   )
///   final DateTime userBirthDate;
/// 
///   const AccountLedger(this.closingTimestamp, this.synchronizationHook, this.userBirthDate);
/// }
/// ```
/// {@endtemplate}
@Target({ TargetKind.method, TargetKind.field, TargetKind.parameter })
final class DateTimeFormat extends ReflectableAnnotation {
  /// The structural locale style-pair string representation applied during variable string serialization.
  /// 
  /// Follows double-character shorthand notation conventions where the first letter controls the date mask 
  /// and the second controls time tracking rules (e.g., `'S'` for Short, `'M'` for Medium, `'L'` for Long, `'F'` for Full, or `'-'` to omit).
  /// 
  /// Defaults to `'SS'` (Short Date, Short Time format context).
  final String style;

  /// The standard ISO-8601 formatting enum scheme targeted by this configuration.
  /// 
  /// Defaults to [DateTimeFormatIso.none].
  final DateTimeFormatIso iso;

  /// A custom, pattern string mask mapping out literal formatting tokens (e.g., `"yyyy-MM-dd HH:mm:ss"`).
  /// 
  /// Defaults to an empty string literal `''`, indicating no custom formatting token pattern is active.
  final String pattern;

  /// An ordered list containing secondary array fallback patterns utilized exclusively by parser engines during string conversion loops.
  /// 
  /// These values are ignored when executing printing or serialization routines, serving purely as a buffer network against malformed inbound text payloads.
  final List<String> fallbackPatterns;

  /// Compiles a compile-time constant metadata configuration token used by reflection scanners and injector frames.
  /// 
  /// {@macro date_time_format}
  const DateTimeFormat({
    this.style = 'SS',
    this.iso = DateTimeFormatIso.none,
    this.pattern = '',
    this.fallbackPatterns = const [],
  });

  @override
  Type get annotationType => DateTimeFormat;
}