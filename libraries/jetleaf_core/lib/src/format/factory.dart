import 'package:jetleaf_lang/lang.dart';

import 'core.dart';

/// {@template annotation_formatter_factory}
/// A contextual SPI (Service Provider Interface) factory responsible for dynamically generating 
/// tailored [FormatPrinter] and [FormatParser] instances based on declarative metadata [ReflectableAnnotation]s.
///
/// Rather than binding serialization or presentation logic statically to a class type, this architecture 
/// enables conditional, aspect-oriented formatting tailored to individual fields, record parameters, 
/// or properties.
///
/// ### How It Integrates With The Engine
/// When a reflection utility, dependency injection frame, or data-binding engine processes a domain 
/// model property decorated with an annotation matching generic boundary type [A], it interrogates this factory. 
/// The engine provides the specific target annotation instance context alongside the target property runtime [Class] type token.
///
/// ### Example Use Cases
/// * **Chronological Masks:** Resolving a custom pattern formatter when a property is annotated with `@DateTimeFormat(pattern: "yyyy-MM-dd")`.
/// * **Cryptographic Masking:** Providing redacting printers on fields marked with a sensitive metadata tag like `@SensitiveData(maskChar: "*")`.
/// * **Numeric Scale Control:** Scaling floating point values when processing fields marked with a custom precision token like `@NumberFormat(decimalPlaces: 4)`.
///
/// ### Architecture Example
/// ```dart
/// // A factory configured to process custom currency formats via metadata annotations
/// class CurrencyFormatAnnotationFactory implements AnnotationFormatterFactory<CurrencyFormat, num> {
///   @override
///   Set<Class> getFieldTypes() => { Class.of<double>(), Class.of<Decimal>() };
///
///   @override
///   FormatPrinter<num> getPrinter(CurrencyFormat annotation, Class<num> fieldType) {
///     return CustomSymbolicCurrencyPrinter(symbol: annotation.symbol, precision: annotation.digits);
///   }
///
///   @override
///   FormatParser<num> getParser(CurrencyFormat annotation, Class<num> fieldType) {
///     return CustomSymbolicCurrencyParser(symbol: annotation.symbol);
///   }
/// }
/// ```
/// {@endtemplate}
@Generic(AnnotationFormatterFactory)
abstract interface class AnnotationFormatterFactory<A extends ReflectableAnnotation, T> {
  /// Defines the set of target [Class] reference tokens that this factory is mathematically 
  /// and structurally equipped to handle under annotation [A].
  ///
  /// The central formatter engine queries this restriction matrix before passing execution flow to the 
  /// generation hooks. If a field is decorated with the targeting annotation but its raw data layout type 
  /// is omitted from this verification list, processing skips this factory to prevent execution errors.
  /// 
  /// Returns a [Set] containing the valid classes allowed to travel through this format routing pipeline.
  Set<Class> getFieldTypes();

  /// Compiles or resolves a specialized [FormatPrinter] instance explicitly configured by the properties 
  /// defined on the given [annotation] context block.
  ///
  /// ### Parameters
  /// - [annotation]: The live metadata annotation instance extracted from the evaluated domain model property, containing target parameters (e.g., custom regex patterns or layout flags).
  /// - [fieldType]: The runtime [Class] type representation of the property field target currently undergoing evaluation.
  FormatPrinter<T> getPrinter(A annotation, Class fieldType);

  /// Compiles or resolves a specialized [FormatParser] instance explicitly configured by the properties 
  /// defined on the given [annotation] context block.
  ///
  /// ### Parameters
  /// - [annotation]: The live metadata annotation instance extracted from the evaluated domain model property, containing target parameters (e.g., custom parsing criteria or masking layout blocks).
  /// - [fieldType]: The runtime [Class] type representation of the property field target currently undergoing evaluation.
  FormatParser<T> getParser(A annotation, Class fieldType);
}