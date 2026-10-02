import 'package:jetleaf_lang/lang.dart';

import 'conversion_service.dart';
import 'simple_conversion_service.dart';
import 'converter_registry.dart';

import '../types/time_converters.dart';
import '../types/map_converters.dart';
import '../types/jl_converters.dart';
import '../types/collection_converters.dart';
import '../types/object_converters.dart';
import '../types/dart_converters.dart';
import '../helpers/_commons.dart';

/// {@template jetleaf_default_conversion_service}
/// A fully configured, ready-to-use **conversion service** suitable for most
/// Jetleaf environments.
///
/// The [DefaultConversionService] extends [SimpleConversionService] and provides
/// a comprehensive set of built-in converters for scalar, collection, map,
/// Jetleaf-specific, Dart standard library, object, and temporal types.
///
/// ### Purpose
/// This service is intended to:
/// - Provide a central hub for type conversion throughout Jetleaf applications.
/// - Facilitate automatic data transformation for property binding, method
///   argument resolution, serialization, and deserialization.
/// - Support custom converters while providing a robust default setup.
///
/// ### Features
/// - **Singleton shared instance:** via [getCommonInstance] (lazy initialization).
/// - **Default converters:** added on instantiation via [addDefaultConverters].
/// - **Time-aware conversions:** includes `DateTime`, `LocalDateTime`, `ZonedDateTime`,
///   `LocalDate`, `LocalTime`, `Duration`, and epoch milliseconds support.
/// - **Collection conversions:** handles `List`, `Set`, `Queue`, `Stack`, `LinkedList`,
///   `ArrayList`, and base types, with nested collection support.
/// - **Map conversions:** generic map-to-map and string-to-map conversions.
/// - **Jetleaf domain types:** `Uuid`, `Currency`, `Locale`, byte arrays via
///   `ByteMultiConverter`.
/// - **Dart built-in types:** `Runes`, `Symbol`, `Uri`, `RegExp`, `Pattern`.
/// - **Scalar conversions:** numbers, booleans, characters, enums, strings.
///
/// ### Lifecycle and Usage
/// By default, each instance registers converters upon construction. For global
/// access, use [getCommonInstance]:
/// ```dart
/// final shared = DefaultConversionService.getCommonInstance();
/// final date = shared.convert<DateTime>("2025-10-27T15:00:00Z");
/// ```
///
/// Alternatively, create individual instances for custom setups:
/// ```dart
/// final service = DefaultConversionService();
/// service.convert('123', Class.forType(int)); // 123
/// ```
///
/// ### Extensibility
/// - Custom converters can be added via the [ConverterRegistry] API:
/// ```dart
/// DefaultConversionService.addScalarConverters(myRegistry);
/// DefaultConversionService.addTimeConverters(myRegistry);
/// ```
/// - Supports domain-specific and project-specific converters by extending
///   any of the `add*Converters` static methods.
///
/// ### Conversion Categories
/// - **Scalar Converters:** numbers, booleans, characters, enums, strings, symbols.
/// - **Time Converters:** `DateTime`, `LocalDateTime`, `LocalDate`, `LocalTime`,
///   `ZonedDateTime`, `Duration`, epoch milliseconds.
/// - **Collection Converters:** `List`, `Set`, `Queue`, `Stack`, `LinkedList`, `ArrayList`.
/// - **Map Converters:** generic map transformations and string ↔ map.
/// - **Jetleaf Converters:** `Uuid`, `Currency`, `Locale`, byte arrays.
/// - **Dart Built-in Converters:** `Runes`, `Symbol`, `Uri`, `RegExp`, `Pattern`.
///
/// ### Shared Instance Considerations
/// - The shared singleton is lazy-initialized and thread-safe.
/// - For custom or multi-context setups, prefer constructing individual
///   [DefaultConversionService] instances.
///
/// ### See Also
/// - [SimpleConversionService]
/// - [ConversionService]
/// - [ConverterRegistry]
/// - [ApplicationConversionService]
/// - [ApplicationContext]
/// {@endtemplate}
class DefaultConversionService extends SimpleConversionService {
  static DefaultConversionService? _sharedInstance;
  static ZoneId defaultZone = ZoneId.systemDefault();
  
  /// Create a new [DefaultConversionService] with the set of default converters.
  /// 
  /// {@macro jetleaf_default_conversion_service}
  DefaultConversionService([super.protectionDomain]) {
    addDefaultConverters(this);
  }
  
  /// Returns a shared default [ConversionService] instance.
  ///
  /// This method lazily constructs a singleton instance when first accessed.
  ///
  /// **Caution:** We recommend constructing individual [ConversionService] instances
  /// for custom use cases. This shared instance is primarily intended for fallback
  /// scenarios where type conversion is needed but a longer-lived service is unavailable.
  ///
  /// Example:
  /// ```dart
  /// final shared = DefaultConversionService.getCommonInstance();
  /// final date = shared.convert<DateTime>("2025-10-27T15:00:00Z");
  /// ```
  static ConversionService getCommonInstance() {
    DefaultConversionService? cs = _sharedInstance;
    if (cs == null) {
      return synchronized(DefaultConversionService, () {
        cs = _sharedInstance;
        if (cs == null) {
          cs = DefaultConversionService();
          _sharedInstance = cs;
        }

        return cs!;
      });
    }
    return cs;
  }
  
  /// Registers a comprehensive set of converters suitable for most environments.
  ///
  /// This method combines scalar, collection, map, Jetleaf-specific, Dart built-in,
  /// object, and time-related converters into the given [ConverterRegistry].
  ///
  /// It ensures that the registry can handle:
  /// - Primitive types (numbers, booleans, characters)
  /// - Collection types (`List`, `Set`, `Queue`, etc.)
  /// - Map conversions
  /// - Jetleaf domain types (UUID, Currency, Locale, Byte arrays)
  /// - Dart built-in types (Runes, Symbol, URI, RegExp, Pattern)
  /// - Core object conversions (`ObjectToObjectConverter`, `FallbackObjectToStringConverter`)
  /// - Time-related conversions (see [addTimeConverters])
  ///
  /// Example:
  /// ```dart
  /// final registry = ConversionService();
  /// ConversionServiceConfiguration.addDefaultConverters(registry);
  /// ```
  static void addDefaultConverters(ConverterRegistry registry) {
    addScalarConverters(registry);
    addTimeConverters(registry);
    addMapConverters(registry);
    addJetleafConverters(registry);
    addOtherDartConverters(registry);
    
    // Core object converters
    registry.addPairedConverter(ObjectToObjectConverter());
    registry.addPairedConverter(FallbackObjectToStringConverter());

    addCollectionConverters(registry);
  }
  
  /// Registers converters for time-related types into the given [ConverterRegistry].
  ///
  /// Supports conversions between strings, temporal types, epoch milliseconds,
  /// and cross-type conversions such as `DateTime` ↔ `LocalDateTime` or `ZonedDateTime`.
  ///
  /// The following are supported:
  /// - String ↔ temporal objects (`DateTime`, `LocalDateTime`, `LocalDate`, `LocalTime`, `ZoneId`, `Duration`)
  /// - Temporal objects ↔ String
  /// - DateTime ↔ LocalDateTime, LocalDate, LocalTime, ZonedDateTime
  /// - Epoch milliseconds ↔ DateTime, ZonedDateTime, Duration
  /// - Cross-type conversions between `LocalDate`, `LocalTime`, `LocalDateTime`, and `ZonedDateTime`
  ///
  /// Example:
  /// ```dart
  /// final registry = ConversionService();
  /// ConversionServiceConfiguration.addTimeConverters(registry);
  /// ```
  ///
  /// After registration, the conversion service can automatically convert between
  /// most common temporal representations, including support for default zones.
  static void addTimeConverters(ConverterRegistry registry) {
    // String to time object converters
    registry.addConverter(StringToDateTimeConverter());
    registry.addConverter(StringToLocalDateTimeConverter());
    registry.addConverter(StringToLocalDateConverter());
    registry.addConverter(StringToLocalTimeConverter());
    registry.addConverter(StringToZoneIdConverter());
    registry.addConverter(StringToZonedDateTimeConverter());
    registry.addConverter(StringToDurationConverter());
    
    // Time object to string converters
    registry.addConverter(DateTimeToStringConverter());
    registry.addConverter(LocalDateTimeToStringConverter());
    registry.addConverter(LocalDateToStringConverter());
    registry.addConverter(LocalTimeToStringConverter());
    registry.addConverter(LocalTimeToStringConverter());
    registry.addConverter(ZonedDateTimeToStringConverter());
    registry.addConverter(DurationToStringConverter());
    
    // DateTime cross-conversions
    registry.addConverter(DateTimeToLocalDateTimeConverter());
    registry.addConverter(LocalDateTimeToDateTimeConverter());
    registry.addConverter(DateTimeToLocalDateConverter());
    registry.addConverter(LocalDateToDateTimeConverter());
    registry.addConverter(DateTimeToLocalTimeConverter());
    registry.addConverter(DateTimeToZonedDateTimeConverter());
    registry.addConverter(ZonedDateTimeToDateTimeConverter());
    
    // Epoch milliseconds converters
    registry.addConverter(IntToDateTimeConverter());
    registry.addConverter(DateTimeToIntConverter());
    registry.addConverter(IntToZonedDateTimeConverter(defaultZone));
    registry.addConverter(ZonedDateTimeToIntConverter());
    registry.addConverter(IntToDurationConverter());
    registry.addConverter(DurationToIntConverter());
    
    // Cross-type converters
    registry.addConverter(LocalDateTimeToLocalDateConverter());
    registry.addConverter(LocalDateTimeToLocalTimeConverter());
    registry.addConverter(LocalDateAndLocalTimeToLocalDateTimeConverter());
    registry.addConverter(LocalDateTimeToZonedDateTimeConverter(defaultZone));
    registry.addConverter(ZonedDateTimeToLocalDateTimeConverter());
    registry.addConverter(ZonedDateTimeToLocalDateConverter());
    registry.addConverter(ZonedDateTimeToLocalTimeConverter());
    registry.addConverter(ZonedDateTimeToZoneIdConverter());
  }
  
  /// Registers converters for `Map` types into the given [ConverterRegistry].
  ///
  /// This allows automatic conversion between maps and strings, as well as
  /// generic map-to-map transformations, using the provided [ConversionService].
  ///
  /// Example:
  /// ```dart
  /// final registry = ConversionService();
  /// ConversionServiceConfiguration.addMapConverters(registry);
  /// ```
  ///
  /// After this, the conversion service can handle:
  /// - Converting `String` to `Map<K, V>`
  /// - Converting `Map<K, V>` to `String`
  /// - Converting between map types (`Map<K1, V1>` to `Map<K2, V2>`)
  static void addMapConverters(ConverterRegistry registry) {
    final conversionService = registry as ConversionService;
    
    registry.addPairedConverter(StringToMapGenericConverter(conversionService));
    registry.addPairedConverter(MapToStringGenericConverter(conversionService));
    registry.addPairedConverter(MapToMapGenericConverter(conversionService));
  }
  
  /// Registers Jetleaf-specific converters into the given [ConverterRegistry].
  ///
  /// These converters handle domain-specific types commonly used in Jetleaf
  /// applications, such as UUIDs, currencies, and locales. Additionally, it
  /// includes a `ByteMultiConverter` for binary data transformations.
  ///
  /// Example:
  /// ```dart
  /// final registry = ConversionService();
  /// ConversionServiceConfiguration.addJetleafConverters(registry);
  /// ```
  ///
  /// After this, the conversion service can convert between:
  /// - `String` ↔ `Uuid`
  /// - `String` ↔ `Currency`
  /// - `String` ↔ `Locale`
  /// - Byte arrays via `ByteMultiConverter`
  static void addJetleafConverters(ConverterRegistry registry) {
    registry.addConverter(StringToUuidConverter());
    registry.addConverter(UuidToStringConverter());
    registry.addConverter(StringToCurrencyConverter());
    registry.addConverter(CurrencyToStringConverter());
    registry.addConverter(StringToLocaleConverter());
    registry.addConverter(LocaleToStringConverter());
    registry.addPairedConverter(ByteMultiConverter());
  }
  
  /// Registers other Dart built-in type converters into the given [ConverterRegistry].
  ///
  /// These converters support Dart standard library types such as:
  /// - `Runes` ↔ `String`
  /// - `Symbol` ↔ `String`
  /// - `Uri` ↔ `String`
  /// - `RegExp` ↔ `String`
  /// - `Pattern` ↔ `String`
  ///
  /// If the registry implements [ListableConverterRegistry], the `String` → `Uri`
  /// converter is initialized with URI validators from the registry.
  ///
  /// Example:
  /// ```dart
  /// final registry = ConversionService();
  /// ConversionServiceConfiguration.addOtherDartConverters(registry);
  /// ```
  ///
  /// After this, the conversion service can handle conversions for common Dart types.
  static void addOtherDartConverters(ConverterRegistry registry) {
    // Runes converters
    registry.addConverter(
      StringToRunesConverter(),
      sourceType: STRING,
      targetType: RUNES,
    );
    registry.addConverter(
      RunesToStringConverter(),
      sourceType: RUNES,
      targetType: STRING,
    );
    registry.addConverter(
      IterableIntToStringConverter(),
      sourceType: ITERABLE_INT,
      targetType: STRING,
    );
    
    // Symbol converters
    registry.addConverter(StringToSymbolConverter());
    registry.addConverter(SymbolToStringConverter());
    
    // URI converters
    if(registry is ListableConverterRegistry) {
      registry.addConverter(StringToUriConverter(registry.getUriValidators()));
    }

    registry.addConverter(UriToStringConverter());
    
    // RegExp converters
    registry.addConverter(StringToRegExpConverter());
    registry.addConverter(RegExpToStringConverter());
    registry.addConverter(StringToPatternConverter());
    registry.addConverter(PatternToStringConverter());
  }

  /// Registers common converters for collection types into the given [ConverterRegistry].
  ///
  /// This method adds converters that allow the framework to automatically
  /// convert between various collection types, including:
  /// - `List`, `Set`, `Queue`, `Stack`, `LinkedList`, `ArrayList`
  /// - Base collection types (`ListBase`, `SetBase`)
  /// - Generic conversion between collections and `Object`
  ///
  /// This ensures that the [ConversionService] can handle nested or heterogeneous
  /// collection transformations seamlessly.
  ///
  /// Example:
  /// ```dart
  /// final registry = ConversionService();
  /// ConversionServiceConfiguration.addCollectionConverters(registry);
  /// ```
  ///
  /// After this, the conversion service can convert between supported collection types.
  static void addCollectionConverters(ConverterRegistry registry) {
    final conversionService = registry as ConversionService;

    registry.addPairedConverter(StringGenericConverter());
    registry.addPairedConverter(DoubleGenericConverter());
    registry.addPairedConverter(IntGenericConverter());

    // Object converters
    registry.addPairedConverter(ObjectToListConverter(conversionService));
    registry.addPairedConverter(ObjectToSetConverter(conversionService));
    registry.addPairedConverter(ListToObjectConverter(conversionService));
    registry.addPairedConverter(SetToObjectConverter(conversionService));

    registry.addPairedConverter(SetToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(QueueToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(IterableToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(ArrayListToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(SetBaseToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(ListBaseToCollectionConverter(conversionService));
    registry.addPairedConverter(LinkedQueueToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(LinkedListToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(LinkedHashSetToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(HashSetToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(StackToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(LinkedStackToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(IterableToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(ArrayListToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(SetBaseToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(ListBaseToCollectionConverter(conversionService));
    registry.addPairedConverter(LinkedQueueToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(LinkedListToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(LinkedHashSetToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(HashSetToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(StackToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(LinkedStackToCollectionGenericConverter(conversionService));
    registry.addPairedConverter(ListToCollectionConverter(conversionService));
  }
  
  /// Registers common scalar converters into the given [ConverterRegistry].
  ///
  /// This method adds converters that allow automatic conversion between
  /// primitive and boxed types, strings, enums, symbols, and other basic types.
  /// It ensures that the [ConversionService] can:
  /// - Convert numbers (`int`, `double`, `BigInt`, `BigDecimal`, etc.)
  /// - Convert booleans and characters
  /// - Convert strings to/from `Runes`
  /// - Convert enums to/from strings or integers
  /// - Convert symbols to/from strings
  ///
  /// Example:
  /// ```dart
  /// final registry = ConversionService();
  /// ConversionServiceConfiguration.addScalarConverters(registry);
  /// ```
  ///
  /// After this, the conversion service can handle common scalar type transformations.
  static void addScalarConverters(ConverterRegistry registry) {
    registry.addPairedConverter(NumberGenericConverter());
    registry.addPairedConverter(BoolGenericConverter());
    registry.addPairedConverter(BigIntGenericConverter());
    registry.addPairedConverter(IntegerGenericConverter());
    registry.addPairedConverter(LongGenericConverter());
    registry.addPairedConverter(FloatGenericConverter());
    registry.addPairedConverter(BigIntegerGenericConverter());
    registry.addPairedConverter(BigDecimalGenericConverter());
    registry.addPairedConverter(ShortGenericConverter());
    registry.addPairedConverter(DoubledGenericConverter());
    registry.addPairedConverter(BooleanGenericConverter());
    registry.addPairedConverter(CharacterGenericConverter());
    
    // String/Character converters
    registry.addConverter(
      StringToRunesConverter(),
      sourceType: STRING,
      targetType: RUNES,
    );
    registry.addConverter(
      RunesToStringConverter(),
      sourceType: RUNES,
      targetType: STRING,
    );
    registry.addConverter(
      IterableIntToStringConverter(),
      sourceType: ITERABLE_INT,
      targetType: STRING,
    );
    
    // Enum converters
    registry.addConverterFactory(StringToEnumConverterFactory());
    registry.addConverter(EnumToStringConverter());
    registry.addConverterFactory(IntToEnumConverterFactory());
    registry.addConverter(EnumToIntConverter());
    
    // Symbol converters
    registry.addConverter(StringToSymbolConverter());
    registry.addConverter(SymbolToStringConverter());
  }
}
