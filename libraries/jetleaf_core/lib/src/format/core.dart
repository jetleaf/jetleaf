import 'package:jetleaf_lang/lang.dart';

/// {@template format_printer}
/// An abstraction responsible for converting a strongly typed domain object or structural primitive 
/// into a localized, human-readable text string representation.
///
/// `FormatPrinter` separates presentation layout and localization requirements from internal data models. 
/// Implementations decode internal fields and structure them according to the formatting rules 
/// of a given [Locale] (e.g., handling numeric digit groupings, localized decimal points, calendar variant layouts, 
/// or gender/plural agreements).
///
/// ### Determinism and Error Management
/// Implementations should guarantee deterministic output streams based on the input object state and 
/// regional context configuration. If an un-printable object state is encountered, the engine should throw a 
/// structured runtime exception (e.g., `FormatException`) instead of emitting unsafe or corrupted string data.
///
/// ### Architecture Example
/// ```dart
/// class LocalizedCurrencyPrinter implements FormatPrinter<double> {
///   @override
///   String print(double value, Locale locale) {
///     // Evaluates locale coordinates to select currency symbols and placement rules
///     return locale.getNormalizedLanguage() == 'en' ? '\$$value' : '$value €';
///   }
/// }
/// ```
/// {@endtemplate}
@Generic(FormatPrinter)
abstract interface class FormatPrinter<T> {
  /// Transforms the provided typed [value] state instance into a formatted, localized string representation 
  /// matching the specified geographic or cultural [locale] criteria rules.
  ///
  /// ### Parameters
  /// - [value]: The target data structure or primitive element context to be formatted.
  /// - [locale]: The dynamic regional context token containing language, script, and country configuration overrides.
  String print(T value, Locale locale);
}

/// {@template format_parser}
/// An abstraction responsible for parsing a localized text string and reconstructing a 
/// strongly typed domain object or structural primitive.
///
/// `FormatParser` provides type-safe deserialization for user input layers, tabular data sheets, 
/// and boundary network streams that are sensitive to internationalization properties.
///
/// ### Error Handling Invariants
/// Because string input from user interfaces or text files is structurally untrusted, implementations must 
/// perform defensive validation checks. If the text format deviates from expected grammatical patterns 
/// required by the [Locale], the method must throw a type-specific `FormatException` or structural input validation error 
/// to protect downstream systems from processing corrupted or incomplete states.
///
/// ### Architecture Example
/// ```dart
/// class LocalizedIntegerParser implements FormatParser<int> {
///   @override
///   int parse(String text, Locale locale) {
///     // Strip locale-specific grouping separators (e.g., commas or dots) before parsing
///     final sanitized = text.replaceAll(locale.getNormalizedLanguage() == 'en' ? ',' : '.', '');
///     return int.parse(sanitized);
///   }
/// }
/// ```
/// {@endtemplate}
@Generic(FormatParser)
abstract interface class FormatParser<T> {
  /// Scans, tokenizes, and converts the incoming localized [text] sequence into a strongly typed instance 
  /// of structural type [T], applying the rules specified by the target [locale].
  ///
  /// ### Parameters
  /// - [text]: The raw textual representation or user-input string block to be parsed.
  /// - [locale]: The active cultural context token controlling lexical parsing rules.
  T parse(String text, Locale locale);
}

/// {@template formatter}
/// A unified symmetric interface combining both [FormatPrinter] and [FormatParser] contracts 
/// to manage bidirectional type-to-string lifecycle mappings.
///
/// `Formatter` bridges the raw text layers of application interfaces with core backend systems. 
/// It ensures that data translation is reversible and consistent: printing a structured value and immediately 
/// parsing the resulting string under the same [Locale] coordinates must reconstruct an identical data state.
///
/// ### Architectural Position
/// Implementations of this combined contract are commonly deployed inside automated data-binding architectures, 
/// web form field validators, text serialization encoders, and command-line shell interface frameworks.
///
/// ### Architecture Example
/// ```dart
/// class DateTimeFormatter implements Formatter<DateTime> {
///   @override
///   String print(DateTime object, Locale locale) => "...";
/// 
///   @override
///   DateTime parse(String text, Locale locale) => DateTime.parse(...);
/// }
/// ```
/// {@endtemplate}
abstract interface class Formatter<T> implements FormatPrinter<T>, FormatParser<T> {}