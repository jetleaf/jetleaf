import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';

import 'core.dart';
import 'factory.dart';

/// {@template formatter_registry}
/// A specialized structural registry configuration management subsystem extending [ConverterRegistry]
/// to coordinate, cache, and resolve bidirectional localization formatting abstractions.
///
/// `FormatterRegistry` serves as the central orchestration engine for text parsing and formatting 
/// operations within the framework environment. It maps target domain [Class] structures or declarative 
/// field metadata [ReflectableAnnotation] instances to specific [FormatPrinter], [FormatParser], or unified [Formatter] 
/// handlers. 
///
/// ### Core Resolution Strategy
/// When an application engine, data binder, or serialization framework attempts to print an object or parse 
/// an incoming string payload, it Queries this registry. The engine looks up handlers based on a hierarchical 
/// precedence tree:
/// 1. Direct field-level or type-level explicit metadata [ReflectableAnnotation] mapping definitions.
/// 2. Class-to-type explicit type definitions registered via [addFormatterForFieldType].
/// 3. Global structural defaults registered via [addFormatter], [addPrinter], or [addParser].
///
/// Implementations must guarantee concurrent thread safety or read-optimized thread isolation contexts 
/// when deployed in highly concurrent enterprise application processing environments.
/// {@endtemplate}
abstract interface class FormatterRegistry implements ConverterRegistry {
  /// Registers a global standalone [FormatPrinter] strategy into the active execution cache.
  ///
  /// This printer is automatically applied when converting matching object structures to localized 
  /// strings across type conversion pipelines, provided no explicit type-specific or field-specific 
  /// formatter definitions take precedence.
  void addPrinter(FormatPrinter printer);

  /// Registers a global standalone [FormatParser] strategy into the active execution cache.
  ///
  /// This parser is automatically applied when scanning and converting raw text patterns into matching 
  /// object structures across type data binding pipelines, provided no explicit type-specific or 
  /// field-specific formatter definitions take precedence.
  void addParser(FormatParser parser);

  /// Registers a unified global bidirectional [Formatter] strategy into the active execution cache.
  ///
  /// This registers the underlying implementation simultaneously as both a default global printer 
  /// and parser component within the framework's runtime environment.
  void addFormatter(Formatter formatter);

  /// Binds a specific unified bidirectional [Formatter] to a dedicated [fieldType] class definition.
  ///
  /// Any data-binding operation or structural serialization logic encountering a class target matching 
  /// [fieldType] automatically routes execution to this formatter. This approach isolates type parsing 
  /// and printing layouts globally (e.g., forcing all `DateTime` fields to use a standardized ISO-8601 or 
  /// localized calendar string format layout).
  void addFormatterForFieldType(Class fieldType, Formatter formatter);

  /// Binds an independent, discrete pair of [FormatPrinter] and [FormatParser] components to a 
  /// dedicated [fieldType] class definition.
  ///
  /// This method provides alternative compositional entry routing for specialized type targets 
  /// where printing and parsing logic are implemented across separate tracking structures rather than 
  /// unified within a single [Formatter] object.
  void addFormatterComponentsForFieldType(Class fieldType, FormatPrinter printer, FormatParser parser);

  /// Registers an annotation-driven contextual generation factory to resolve specialized formatters 
  /// based on declarative field or parameter metadata annotations.
  ///
  /// This design enables flexible configuration through standard metadata attributes. For example, applying a 
  /// custom annotation like `@DateTimeFormat(pattern: "yyyy-MM-dd")` on a field triggers the matching 
  /// [AnnotationFormatterFactory] to dynamically compile a specialized pattern-based formatter for that 
  /// specific field.
  void addFormatterForFieldAnnotation(AnnotationFormatterFactory<ReflectableAnnotation, dynamic> annotationFormatterFactory);
}

/// {@template formatter_registrar}
/// An orchestration interface wrapper allowing independent system modules, plugins, or domain packages 
/// to isolate and declare their unique parsing and formatting infrastructure configurations cleanly.
///
/// High-level application engines query and execute the [registerFormatters] routine across all registered 
/// infrastructure modules during the early system startup and dependency injection lifecycle initialization phases.
///
/// ### Architecture Example
/// ```dart
/// class AccountingModuleRegistrar implements FormatterRegistrar {
///   @override
///   void registerFormatters(FormatterRegistry registry) {
///     // Establish custom ledger and financial metric token parsing strategies globally
///     registry.addFormatterForFieldType(CurrencyAmount, LocalizedFinancialFormatter());
///     registry.addFormatterForFieldAnnotation(CustomInvoiceDateAnnotationFactory());
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class FormatterRegistrar {
  /// Inject and declare specialized string conversion, printing, or parsing layout strategies into 
  /// the targeted configuration container [registry].
  void registerFormatters(FormatterRegistry registry);
}