import 'package:jetleaf_lang/lang.dart';
import 'package:meta/meta_meta.dart';

/// Defines the structural strategies available for formatting and parsing numerical representations,
/// aligning with localized internationalization standards and enterprise metadata-driven architectures.
enum NumberFormatStyle {
  /// The default format strategy determined implicitly by the runtime type of the annotated property.
  /// 
  /// Typically translates to a standard numeric layout, but automatically resolves to [currency] 
  /// if attached to dedicated monetary or financial wrapper value objects.
  defaultStyle,

  /// General-purpose decimal number layout formatting matching the active evaluation locale.
  /// 
  /// Employs locale-specific digit grouping symbols and decimal markers (e.g., `"1,234,567.89"` in `en_US` 
  /// versus `"1.234.567,89"` in `de_DE`).
  number,

  /// Fractional percent format matching the active evaluation locale.
  /// 
  /// Automatically scales the numeric scalar by multiplying by 100 and appends the locale-specific 
  /// percent symbol (e.g., transforming `0.75` into `"75%"`).
  percent,

  /// Localized currency format matching the active evaluation locale.
  /// 
  /// Formats the scalar value according to regional currency placement rules, fraction constraints, and symbols 
  /// (e.g., transforming `10.5` into `"$10.50"` or `"10,50 €"` depending on the locale state).
  currency,
}

/// {@template number_format}
/// A declarative, aspect-oriented metadata annotation instructing structural type conversion registries, 
/// data binders, and serialization encoders on how to format, print, and parse primitive numerical types 
/// and custom numeric wrapper structures.
/// 
/// Placing this annotation on a property decouples structural presentation requirements from backend business logic. 
/// It allows fine-grained, locale-aware numeric formatting directly on fields, return values, or input parameters.
///
/// ### Precedence & Mutual Exclusivity Laws
/// While this metadata component handles both pre-defined structural styles and custom string masks, they must 
/// be treated as mutually exclusive configurations. When resolving a configuration instance, the formatting engine 
/// follows a strict cascade:
/// 1. **Custom Pattern ([pattern]):** Highest precedence. If [pattern] is assigned a non-empty string mask, it completely 
///    overrides the [style] flag configuration.
/// 2. **Preconfigured Style ([style]):** Lower precedence. Active only if [pattern] remains an empty string. Fallback logic 
///    defaults to [NumberFormatStyle.defaultStyle].
///
/// ### Target Restrictions
/// Bound explicitly via `@Target`, this metadata annotation is allowed only when attached directly to fields, 
/// method return signatures, or incoming executable method parameter variables.
///
/// ### Architecture Example
/// ```dart
/// class FinancialReport {
///   // Marshals formatting using explicit localized currency logic: e.g., "$5,280.00"
///   @NumberFormat(style: NumberFormatStyle.currency)
///   final double quarterlyRevenue;
/// 
///   // Scales fractions directly to percent values: e.g., "12.5%"
///   @NumberFormat(style: NumberFormatStyle.percent)
///   final double growthRate;
/// 
///   // Applies a strict custom mask mapping out explicit digit groupings and precision limits: e.g., "00,342.10"
///   @NumberFormat(pattern: "00,###.00")
///   final double precisionConstant;
/// 
///   const FinancialReport(
///     this.quarterlyRevenue,
///     this.growthRate,
///     this.precisionConstant,
///   );
/// }
/// ```
/// {@endtemplate}
@Target({ TargetKind.method, TargetKind.field, TargetKind.parameter })
final class NumberFormat extends ReflectableAnnotation {
  /// The style rule configuration variant mapping out localized formatting constraints.
  /// 
  /// Defaults to [NumberFormatStyle.defaultStyle].
  final NumberFormatStyle style;

  /// A custom, pattern string mask mapping out literal formatting tokens (for example, `#,###.00` or `0.000`).
  /// 
  /// Defaults to an empty string literal `''`, indicating that no custom formatting mask pattern is active.
  final String pattern;

  /// Creates a compile-time constant metadata configuration token utilized by framework reflection scanners and serialization engines.
  /// 
  /// {@macro number_format}
  const NumberFormat({
    this.style = NumberFormatStyle.defaultStyle,
    this.pattern = '',
  });

  @override
  Type get annotationType => NumberFormat;
}