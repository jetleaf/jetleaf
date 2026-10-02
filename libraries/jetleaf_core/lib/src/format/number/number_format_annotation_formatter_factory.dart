import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

import '../annotations/number_format.dart';
import '../core.dart';
import '../factory.dart';
import 'formatter.dart';

/// {@template number_format_annotation_formatter_factory}
/// An administrative factory registry responsible for converting [NumberFormat] declarative metadata 
/// annotations into active, localized numeric formatters ([NumberStyleFormatter], [PercentStyleFormatter], [CurrencyStyleFormatter]).
///
/// This factory bridges declarative metadata tags placed on fields, variables, or method signatures 
/// with the system's underlying internationalization engines. It implements [AnnotationFormatterFactory], 
/// allowing dependency injection (DI) or serialization mappers to automatically resolve custom 
/// printing ([getPrinter]) and parsing ([getParser]) mechanics during object instantiation loops.
///
/// ### Resolution Hierarchy & Precedence Rules
/// When a property carries an active [NumberFormat] configuration token, the underlying private configuator 
/// [_configureFormatter] constructs a target formatter architecture matching a strict cascading strategy:
/// 
/// 1. **Custom Structural Masking:** Checks the [NumberFormat.pattern] property first. If it contains a non-empty 
///    string (e.g., `#,##0.00`), it initializes a [NumberStyleFormatter] carrying that precise blueprint mask, 
///    overriding preconfigured style enums entirely.
/// 2. **Predefined Structural Enums:** If no custom mask pattern is defined, the engine runs a switch match over 
///    [NumberFormat.style] to deploy dedicated layout pipelines:
///    * [NumberFormatStyle.currency] $\rightarrow$ Instantiates a financial [CurrencyStyleFormatter].
///    * [NumberFormatStyle.percent] $\rightarrow$ Instantiates a ratio-scaling [PercentStyleFormatter].
///    * All other flags (e.g., [NumberFormatStyle.number], [NumberFormatStyle.defaultStyle]) $\rightarrow$ Defaults 
///      to a standard decimal-fallback [NumberStyleFormatter].
///
/// ### Extensibility and Integration Boundaries
/// Extends [EmbeddedValueResolutionSupport] to inherit contextual placeholder processing utilities. This architecture 
/// allows properties within the annotation framework to eventually receive dynamic structural string enhancements 
/// passed through environmental token pipelines.
///
/// ### Architecture Example
/// ```dart
/// final factory = NumberFormatAnnotationFormatterFactory();
/// 
/// // Mock discovery of a custom percent property annotation tag
/// const metadata = NumberFormat(style: NumberFormatStyle.percent);
/// final Class targetFieldType = Class<double>();
/// 
/// // Fetching parsing and printing mechanics automatically configured by the factory
/// final FormatParser<num> parser = factory.getParser(metadata, targetFieldType);
/// final FormatPrinter<num> printer = factory.getPrinter(metadata, targetFieldType);
/// 
/// print(printer.print(0.325, Locale.en_US)); // Processes layout via PercentStyleFormatter -> "33%"
/// ```
/// {@endtemplate}
class NumberFormatAnnotationFormatterFactory extends EmbeddedValueResolutionSupport implements AnnotationFormatterFactory<NumberFormat, num> {
  
  /// Creates a standard, metadata-driven numerical formatter resolution factory.
  /// 
  /// {@macro number_format_annotation_formatter_factory}
  NumberFormatAnnotationFormatterFactory();

  @override
  Set<Class<dynamic>> getFieldTypes() => NumberUtils.STANDARD_NUMBER_TYPES;

  @override
  FormatParser<num> getParser(NumberFormat annotation, Class fieldType) => _configureFormatter(annotation);

  @override
  FormatPrinter<num> getPrinter(NumberFormat annotation, Class fieldType) => _configureFormatter(annotation);

  /// Internal configuration manager compiling a localized [Formatter] instance matching the discovered annotation parameters.
  Formatter<num> _configureFormatter(NumberFormat annotation) {
    final resolvedPattern = annotation.pattern;

    if (resolvedPattern.isNotEmpty) {
      return NumberStyleFormatter(resolvedPattern);
    }

    return switch (annotation.style) {
      NumberFormatStyle.currency => CurrencyStyleFormatter(),
      NumberFormatStyle.percent => PercentStyleFormatter(),
      _ => NumberStyleFormatter(),
    };
  }
}