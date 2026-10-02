import 'package:jetleaf_lang/lang.dart';

import '../exceptions.dart';
import '../helpers/conversion_utils.dart';
import '../helpers/convertible_pair.dart';
import '../helpers/_commons.dart';
import 'conversion_service.dart';
import 'converters.dart';

/// Handles nullability conversion
/// 
/// This function is used to convert a null value to a non-null value.
typedef _NullSourceConverter = Object? Function(Class? sourceType, Class targetType);

/// {@template simple_conversion_service}
/// A configurable and extensible **conversion service** that provides a central
/// mechanism for converting between types in Jetleaf applications.
///
/// [SimpleConversionService] supports:
/// - Generic type conversion with caching
/// - Paired converters and converter factories
/// - Null source handling
/// - URI validation
/// - Optional protection domains for security/validation contexts
///
/// This service is intended to be subclassed (e.g., [DefaultConversionService])
/// or used directly for applications that require custom conversion behavior.
///
/// ### Features
/// 1. **Converters and Converter Factories**
///    - Add custom converters using [addConverter] or [addPairedConverter].
///    - Support for generic and parameterized types via type inference.
///    - Add converter factories using [addConverterFactory].
///    - Caching of converters for repeated conversions.
///
/// 2. **Null Source Handling**
///    - Converts `null` to target types using registered [GenericNullConverter]s.
///    - Defaults to [_DefaultNullConverter] if no custom converter exists.
///
/// 3. **Conversion Caching**
///    - Converter lookup results are cached to improve performance.
///    - Cache is invalidated whenever a new converter or factory is added.
///
/// 4. **URI Validation**
///    - Maintains a list of [UriValidator] instances for validating URI inputs.
///
/// 5. **Type-Safety and Primitive Handling**
///    - Automatically checks that source objects are instances of the expected type.
///    - Prevents assigning `null` to primitive target types.
///
/// ### Example
/// ```dart
/// final service = SimpleConversionService();
///
/// // Add a custom converter
/// service.addConverter<String, int>(MyStringToIntConverter(), sourceType: Class.forType(String), targetType: Class.forType(int));
///
/// // Convert a value
/// int result = service.convert('123', Class.forType(int))!;
///
/// // Convert a nullable source
/// int? nullableResult = service.convert<int>(null, Class.forType(int)); // throws ConversionFailedException if int is primitive
/// ```
///
/// ### Notes
/// - Internal caching ensures repeated conversions are fast.
/// - `canConvert` and `canBypassConvert` allow pre-checking conversion capabilities.
/// - `_NoOpConverter` and `_NoMatchConverter` are used internally for cache markers
///   and bypassing conversions when source and target types are compatible.
///
/// {@endtemplate}
class SimpleConversionService implements ConfigurableConversionService {
  /// {@template no_op_converter}
  /// Singleton instance representing a no-operation converter.
  ///
  /// Used when source and target types are the same or compatible without conversion.
  /// {@endtemplate}
  static final PairedConverter _NO_OP_CONVERTER = _NoOpConverter("NO_OP");

  /// {@template no_match_converter}
  /// Singleton instance representing no matching converter.
  ///
  /// Used as a cache marker when no converter is found.
  /// {@endtemplate}
  static final PairedConverter _NO_MATCH_CONVERTER = _NoOpConverter("NO_MATCH");

  /// {@template converters}
  /// A collection of registered converters and converter factories.
  ///
  /// This collection is used to find and cache converters for type conversion.
  /// {@endtemplate}
  final _Converters _converters = _Converters();

  /// {@template uri_validators}
  /// A list of URI validators used for validating URIs.
  ///
  /// This list is used to validate URIs before conversion.
  /// {@endtemplate}
  final List<UriValidator> _uriValidators = [];

  /// {@template null_converters}
  /// A list of generic null converters used for converting null values.
  ///
  /// This list is used to convert null values to other types.
  /// {@endtemplate}
  final List<GenericNullConverter> _nullConverters = [];

  /// {@template converter_cache}
  /// A cache of converters used for type conversion.
  ///
  /// This cache is used to store converters for type conversion.
  /// {@endtemplate}
  final Map<_ConverterCacheKey, PairedConverter> _converterCache = <_ConverterCacheKey, PairedConverter>{};

  /// {@template protection_domain}
  /// The protection domain used for type conversion.
  ///
  /// This protection domain is used to validate types before conversion.
  /// {@endtemplate}
  final ProtectionDomain _pd;

  /// {@template simple_conversion_service_constructor}
  /// Creates a new SimpleConversionService.
  ///
  /// Parameters:
  /// - [pd]: Optional protection domain for security (defaults to current)
  ///
  /// Example:
  /// ```dart
  /// // Basic instantiation
  /// final service = SimpleConversionService();
  ///
  /// // With custom protection domain
  /// final secureService = SimpleConversionService(myProtectionDomain);
  /// ```
  /// {@endtemplate}
  /// 
  /// {@macro simple_conversion_service}
  SimpleConversionService([ProtectionDomain? pd]) : _pd = pd ?? ProtectionDomain.system() {
    _nullConverters.add(_DefaultNullConverter());
  }

  // ============================================= CONVERTERS ===============================================

  @override
  void addConverter<S, T>(Converter<S, T> converter, {Class<S>? sourceType, Class<T>? targetType}) {
    if(sourceType != null && targetType != null) {
      addPairedConverter(_PairedConverterAdapter(converter, sourceType, targetType, _pd, _convertNullableSource));
    } else if(sourceType == null && targetType == null) {
      final clazz = converter.getClass(null, converter.getPackageName());

      // We'll try to access the [Converter] class as an interface first
      Iterable<Class> types = clazz.getInterface<Converter>()?.getTypeParameters() ?? [];
      
      // If it fails, we'll try to access it as a superclass
      if(types.isEmpty) {
        types = clazz.getSuperClass()?.getTypeParameters() ?? [];
      }

      // If we only got raw type parameters (e.g., Object, Object), try type arguments
      // which hold the actual concrete types from the parameterized superclass
      if(types.isEmpty || types.length.isLessThan(2) || _isRawTypeParams(types)) {
        final typeArgs = clazz.getSuperClassArguments().toList();
        if(typeArgs.length >= 2) {
          types = typeArgs;
        }
      }
      
      if (types.isEmpty || types.length.isLessThan(2)) {
        throw ConversionException(
          'Unable to determine source type and target type for your '
          'Converter [${converter.runtimeType}]; does the class parameterize those types? If '
          'you are using a generic converter, make sure to explicitly specify the source '
          'and target types.'
        );
      }
      addPairedConverter(_PairedConverterAdapter(converter, types.getFirst(), types.getLast(), _pd, _convertNullableSource));
    }
  }

  @override
  void addPairedConverter(PairedConverter converter) {
    _converters.add(converter);
    _invalidateCache();
  }

  /// {@template _invalidate_cache}
  /// Invalidates the cache of converters.
  ///
  /// Clears the cache of converters.
  /// {@endtemplate}
  void _invalidateCache() {
    _converterCache.clear();
  }

  /// Checks if the given type parameters are raw (unparameterized) types.
  /// This happens when the v2 mirror system returns the superclass type parameters
  /// instead of the actual type arguments from the concrete parameterized class.
  static bool _isRawTypeParams(Iterable<Class> types) {
    if (types.length < 2) return false;
    final list = types.toList();
    // Raw Object type parameters have getName() == OBJECT_CLASS.getName()
    return list[0].getName() == OBJECT_CLASS.getName() && list[1].getName() == OBJECT_CLASS.getName();
  }

  @override
  void addConverterFactory(ConverterFactory<dynamic, dynamic> factory) {
    final clazz = factory.getClass(null, factory.getPackageName());
    // We'll try to access the [ConverterFactory] class as an interface first
    Iterable<Class> types = clazz.getInterface<ConverterFactory>()?.getTypeParameters() ?? [];
    
    // If it fails, we'll try to access it as a superclass
    if(types.isEmpty) {
      types = clazz.getSuperClass()?.getTypeParameters() ?? [];
    }

    // If we only got raw type parameters (e.g., Object, Object), try type arguments
    // which hold the actual concrete types from the parameterized superclass
    if(types.isEmpty || types.length.isLessThan(2) || _isRawTypeParams(types)) {
      final typeArgs = clazz.getSuperClassArguments().toList();
      if(typeArgs.length >= 2) {
        types = typeArgs;
      }
    }
    
    if (types.isEmpty || types.length.isLessThan(2)) {
      throw ConversionException('Unable to determine source type and target type for your '
          'ConverterFactory [${factory.runtimeType}]; does the class parameterize those types?');
    }
    addPairedConverter(_PairedConverterFactoryAdapter(factory, ConvertiblePair(types.getFirst(), types.getLast()), _pd, _convertNullableSource));
  }

  @override
  void remove(Class sourceType, Class targetType) {
    _converters.remove(sourceType, targetType);
    _invalidateCache();
  }

  // ========================================== HANDLING CONVERSION ===========================================

  @override
  bool canConvert(Class? sourceType, Class targetType) {
    if (sourceType == null) return true;
    return _getConverter(sourceType, targetType) != null;
  }

  /// Return whether conversion between the source type and the target type can be bypassed.
  /// More precisely, this method will return true if objects of sourceType can be
  /// converted to the target type by returning the source object unchanged.
  /// 
  /// -- Parameters --
  /// @param sourceType context about the source type to convert from
  /// @param targetType context about the target type to convert to (required)
  /// 
  /// -- Returns --
  /// @return true if conversion can be bypassed; false otherwise
  bool canBypassConvert(Class? sourceType, Class targetType) {
    if (sourceType == null) return true;
    return _getConverter(sourceType, targetType) == _NO_OP_CONVERTER;
  }

  @override
  T? convert<T>(Object? source, Class<T> targetType, [String? qualifiedName]) {
    Class? fromQualified = qualifiedName != null ? Class.fromQualifiedName(qualifiedName) : null;
    Class? fromSource = source != null ? _getSourceType(source) : null;
    final sourceType = fromQualified ?? fromSource;
    final result = convertTo<T>(source, targetType, sourceType);

    if(result != null) {
      return result as T;
    } else {
      return result as T?;
    }
  }

  Class _getSourceType(Object source) {
    if(source is Class) {
      return source;
    } else {
      return source.getClass();
    }
  }

  @override
  Object? convertTo<T>(Object? source, Class targetType, [Class? sourceType]) {
    sourceType ??= (source != null ? _getSourceType(source) : null);
    if (sourceType == null) {
      if (source != null) {
        throw ConversionException('Source must be [null] if source type == [null]');
      }
      return _handleResult<T>(null, targetType, _convertNullableSource(null, targetType));
    }

    if (source != null && !sourceType.isInstance(source)) {
      throw ConversionException('Source to convert from must be an instance of [$sourceType]; instead it was a [${source.runtimeType}]');
    }

    final converter = _getConverter(sourceType, targetType);
    if (converter != null) {
      final result = ConversionUtils.invoke<T>(converter, source, sourceType, targetType);
      return _handleResult<T>(sourceType, targetType, result);
    }

    return _handleConverterNotFound<T>(source, sourceType, targetType);
  }

  /// {@template _get_converter}
  /// Internal method to find a converter with caching.
  ///
  /// First checks cache, then searches the converter registry.
  /// Returns null if no converter is found.
  /// {@endtemplate}
  PairedConverter? _getConverter(Class sourceType, Class targetType) {
    final key = _ConverterCacheKey(sourceType, targetType);
    PairedConverter? converter = _converterCache[key];

    if (converter != null) {
      return converter != _NO_MATCH_CONVERTER ? converter : null;
    }

    converter = _converters.find(sourceType, targetType);
    converter ??= _getDefaultConverter(sourceType, targetType);

    if (converter != null) {
      _converterCache[key] = converter;
      return converter;
    }

    _converterCache[key] = _NO_MATCH_CONVERTER;
    return null;
  }

  /// {@template _get_default_converter}
  /// Internal method to find a default converter.
  ///
  /// Returns null if no converter is found.
  /// {@endtemplate}
  PairedConverter? _getDefaultConverter(Class sourceType, Class targetType) {
    return sourceType.isAssignableTo(targetType) ? _NO_OP_CONVERTER : null;
  }

  /// {@template _convert_null_source}
  /// Converts a null source to a target type.
  ///
  /// If the target type is an Optional, returns an empty Optional.
  /// Otherwise, returns null.
  /// {@endtemplate}
  Object? _convertNullableSource(Class? sourceType, Class targetType) {
    return _genericNullConverter(sourceType, targetType).convert(sourceType, targetType);
  }

  /// {@template _generic_null_converter}
  /// Internal method to find a generic null converter.
  ///
  /// Returns a null converter if no converter is found.
  /// {@endtemplate}
  GenericNullConverter _genericNullConverter(Class? sourceType, Class targetType) {
    // 1. Check user-registered null converters
    final converter = _nullConverters.find((c) => c.matches(sourceType ?? Class<Object>(null, PackageNames.DART), targetType));

    // 2. Default fallback
    return converter ?? _DefaultNullConverter();
  }

  /// {@template _handle_converter_not_found}
  /// Handles cases when no converter is found.
  ///
  /// Either returns the source directly (if types are compatible)
  /// or throws a ConverterNotFoundException.
  /// {@endtemplate}
  Object? _handleConverterNotFound<T>(Object? source, Class? sourceType, Class targetType) {
    if (source == null) {
      _assertNotAPrimitiveTargetType(sourceType, targetType);
      return null;
    }

    if ((sourceType == null || targetType.isAssignableFrom(sourceType)) && targetType.isInstance(source)) {
      return source;
    }

    throw ConverterNotFoundException(sourceType: sourceType, targetType: targetType);
  }

  /// {@template _handle_result}
  /// Handles the result of a conversion.
  ///
  /// Asserts that the result is not null for primitive target types.
  /// {@endtemplate}
  Object? _handleResult<T>(Class? sourceType, Class targetType, Object? result) {
    if (result == null) {
      _assertNotAPrimitiveTargetType(sourceType, targetType);
    }
    return result;
  }

  /// {@template _assert_not_primitive_target_type}
  /// Asserts that the target type is not primitive.
  ///
  /// Throws a ConversionFailedException if the target type is primitive.
  /// {@endtemplate}
  void _assertNotAPrimitiveTargetType(Class? sourceType, Class targetType) {
    if (targetType.isPrimitive() && targetType.getType() != String) {
      throw ConversionFailedException(
        sourceType: sourceType,
        targetType: targetType,
        value: null,
        point: ConversionException('A null value cannot be assigned to a primitive type')
      );
    }
  }

  // ======================================= NULL SOURCE CONVERTER ========================================

  @override
  void addNullSourceConverter(GenericNullConverter converter) {
    _nullConverters.add(converter);
  }

  @override
  void removeNullSourceConverter(GenericNullConverter converter) {
    _nullConverters.remove(converter);
  }

  // =========================================== URI VALIDATOR ==================================================

  @override
  List<UriValidator> getUriValidators() => _uriValidators;

  @override
  void addUriValidator(UriValidator validator) {
    _uriValidators.add(validator);
  }

  @override
  void removeUriValidator(UriValidator validator) {
    _uriValidators.remove(validator);
    _uriValidators.removeWhere((v) => v.errorMessage == validator.errorMessage);
  }

  @override
  String toString() => "$runtimeType(${_converters.toString()})";
}

/// {@template converter_cache_key}
/// A key used to cache converter lookups.
/// 
/// ---
/// 
/// ### 🔧 Example:
/// ```dart
/// final key = _ConverterCacheKey(Class<String>(), Class<int>());
/// ```
/// {@endtemplate}
@Generic(_ConverterCacheKey)
class _ConverterCacheKey implements Comparable<_ConverterCacheKey> {
  /// The source type of the conversion pair.
  ///
  /// This represents the type from which a value will be converted.
  final Class sourceType;

  /// The target type of the conversion pair.
  ///
  /// This represents the type to which a value will be converted.
  final Class targetType;

  /// {@macro converter_cache_key}
  _ConverterCacheKey(this.sourceType, this.targetType);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is _ConverterCacheKey &&
            sourceType == other.sourceType &&
            targetType == other.targetType);
  }

  @override
  int get hashCode => sourceType.hashCode * 29 + targetType.hashCode;

  @override
  String toString() => 'ConverterCacheKey [sourceType = $sourceType, targetType = $targetType]';

  @override
  int compareTo(_ConverterCacheKey other) {
    int result = sourceType.getName().compareTo(other.sourceType.getName());
    if (result == 0) {
      result = targetType.getName().compareTo(other.targetType.getName());
    }
    return result;
  }
}

/// {@template converters_for_pair}
/// A container for converters that can be used to convert between two types.
/// 
/// ---
/// 
/// ### 🔧 Example:
/// ```dart
/// final converters = _ConvertersForPair();
/// converters.add(PairedConverter());
/// ```
/// {@endtemplate}
@Generic(_ConvertersForPair)
class _ConvertersForPair {
  /// A queue of paired converters, maintained in insertion order.
  ///
  /// New converters are added to the front of the queue so that
  /// the most recently added converters have higher precedence
  /// during lookup and matching.
  final LinkedQueue<PairedConverter> _converters = LinkedQueue<PairedConverter>();

  /// Adds a new [PairedConverter] to the queue.
  ///
  /// The converter is inserted at the front to give it higher
  /// priority when performing type conversion lookups.
  void add(PairedConverter converter) {
    _converters.addFirst(converter);
  }

  /// Attempts to find a [PairedConverter] capable of converting from [sourceType] to [targetType].
  ///
  /// The method performs a two-stage search:
  /// 1. **Direct match**: Returns the first converter that either is not conditional or
  ///    whose `matches` method returns `true` for the given types.
  /// 2. **Fallback match**: Checks for adapters (`_PairedConverterAdapter`) that can
  ///    handle the conversion as a fallback, using `matchesFallback`.
  ///
  /// Returns:
  /// - The first matching [PairedConverter] if found.
  /// - `null` if no suitable converter exists.
  PairedConverter? getConverter<S, T>(Class<S> sourceType, Class<T> targetType) {
    // Stage 1: direct or conditional match
    for (final converter in _converters) {
      if (converter is! PairedConditionalConverter || converter.matches(sourceType, targetType)) {
        return converter;
      }
    }

    // Stage 2: fallback converters (adapter-based)
    for (final converter in _converters) {
      if (converter is _PairedConverterAdapter && converter.matchesFallback(sourceType, targetType)) {
        return converter;
      }
    }

    return null;
  }

  @override
  String toString() => _converters.join(', ');
}

/// {@template converters}
/// A container for converters that can be used to convert between two types.
/// 
/// ---
/// 
/// ### 🔧 Example:
/// ```dart
/// final converters = _Converters();
/// converters.add(PairedConverter());
/// ```
/// {@endtemplate}
class _Converters {
  /// Global converters that do not declare specific convertible types.
  ///
  /// These are usually [ConditionalConverter]s that perform dynamic type matching.
  final Set<PairedConverter> _globalConverters = <PairedConverter>{};

  /// Map of specific type pairs to their registered converters.
  final Map<ConvertiblePair, _ConvertersForPair> _converters = <ConvertiblePair, _ConvertersForPair>{};

  /// Registers a new [PairedConverter].
  ///
  /// - If [converter.getConvertibleTypes] returns `null`, the converter is treated as
  ///   global and added to [_globalConverters].
  /// - Otherwise, it is associated with each declared convertible type pair.
  ///
  /// Throws [IllegalStateException] if a non-conditional converter returns null types.
  void add(PairedConverter converter) {
    final convertibleTypes = converter.getConvertibleTypes();
    if (convertibleTypes == null) {
      if (converter is! ConditionalConverter) {
        throw IllegalStateException('Only conditional converters may return null convertible types');
      }
      _globalConverters.add(converter);
    } else {
      for (final pair in convertibleTypes) {
        _getMatchingConverters(pair).add(converter);
      }
    }
  }

  /// Retrieves the [_ConvertersForPair] associated with the given [pair].
  ///
  /// If no converters are registered yet for this [ConvertiblePair], a new
  /// [_ConvertersForPair] instance is created, stored, and returned.
  ///
  /// Parameters:
  /// - [pair]: The [ConvertiblePair] representing the source and target types
  ///   for which converters are being requested.
  ///
  /// Returns:
  /// - The [_ConvertersForPair] containing all converters registered for
  ///   the given type pair. This may be an existing collection or a newly
  ///   created one if none existed previously.
  ///
  /// ### Example
  /// ```dart
  /// final pair = ConvertiblePair(String.toClass(), int.toClass());
  /// final convertersForPair = _getMatchableConverters(pair);
  /// convertersForPair.add(StringToIntConverter());
  /// ```
  _ConvertersForPair _getMatchingConverters(ConvertiblePair pair) {
    return _converters.putIfAbsent(pair, () => _ConvertersForPair());
  }

  /// Removes all converters registered for a specific source/target type pair.
  void remove(Class sourceType, Class targetType) {
    _converters.remove(ConvertiblePair(sourceType, targetType));
  }

  /// Finds a suitable [PairedConverter] to convert from [sourceType] to [targetType].
  ///
  /// This method attempts to locate a converter in two steps:
  /// 1. **Exact match**: Looks for a converter registered specifically for the
  ///    exact `[sourceType, targetType]` pair.
  /// 2. **Class hierarchy match**: If no exact match is found, it iterates over
  ///    the class hierarchies of [sourceType] and [targetType], checking for
  ///    converters registered for any ancestor or interface pair combination.
  ///
  /// Type parameters:
  /// - `S`: The source type being converted from.
  /// - `T`: The target type being converted to.
  ///
  /// Parameters:
  /// - [sourceType]: The [Class] representing the source type.
  /// - [targetType]: The [Class] representing the target type.
  ///
  /// Returns:
  /// - A [PairedConverter] if a suitable converter is found (exact or via hierarchy).
  /// - `null` if no converter is available for the given types.
  ///
  /// ### Example
  /// ```dart
  /// final converter = registry.find<String, int>(String.toClass(), int.toClass());
  /// if (converter != null) {
  ///   final result = converter.convert("42");
  /// }
  /// ```
  PairedConverter? find<S, T>(Class<S> sourceType, Class<T> targetType) {
    // First try exact match
    final pair = ConvertiblePair(sourceType, targetType);
    final converter = _getRegisteredConverter<S, T>(sourceType, targetType, pair);
    if (converter != null) {
      return converter;
    }

    // Then try class hierarchy
    final sourceCandidates = ClassUtils.getClassHierarchy(sourceType);
    final targetCandidates = ClassUtils.getClassHierarchy(targetType);

    for (final sourceCandidate in sourceCandidates) {
      for (final targetCandidate in targetCandidates) {
        final pair = ConvertiblePair(sourceCandidate, targetCandidate);
        final converter = _getRegisteredConverterForCandidate(sourceCandidate, targetCandidate, pair);
        if (converter != null) {
          return converter;
        }
      }
    }

    // Last resort: check global conditional converters (ObjectToObjectConverter, etc.)
    for (final globalConverter in _globalConverters) {
      if ((globalConverter as ConditionalConverter).matches(sourceType, targetType)) {
        return globalConverter;
      }
    }

    return null;
  }

  /// Retrieves a registered [PairedConverter] for the specified [sourceType] and [targetType],
  /// checking both specific type pairs and global conditional converters.
  ///
  /// This method performs the following steps:
  /// 1. **Specific converters**: Looks up [_converters] for the exact [ConvertiblePair] provided by [pair].
  ///    - If a converter is found in the map, it is returned immediately.
  /// 2. **Conditional converters**: Iterates through [_globalConverters], which are usually [ConditionalConverter]s
  ///    that determine applicability at runtime via their `matches` method.
  /// 3. **Fallback**: Returns `null` if no suitable converter is found.
  ///
  /// Type parameters:
  /// - `S`: The source type being converted from.
  /// - `T`: The target type being converted to.
  ///
  /// Parameters:
  /// - [sourceType]: The class representing the source type.
  /// - [targetType]: The class representing the target type.
  /// - [pair]: A [ConvertiblePair] representing the source-target type pair to look up.
  ///
  /// Returns:
  /// - A [PairedConverter] if a suitable converter is found (either specific or conditional).
  /// - `null` if no converter is available.
  PairedConverter? _getRegisteredConverter<S, T>(Class<S> sourceType, Class<T> targetType, ConvertiblePair pair) {
    // Check specifically registered converters
    final convertersForPair = _converters[pair];
    if (convertersForPair != null) {
      final converter = convertersForPair.getConverter<S, T>(sourceType, targetType);
      if (converter != null) {
        return converter;
      }
    }

    return null;
  }

  PairedConverter? _getRegisteredConverterForCandidate(Class sourceType, Class targetType, ConvertiblePair pair) {
    final convertersForPair = _converters[pair];
    if (convertersForPair != null) {
      final converter = convertersForPair.getConverter(sourceType, targetType);
      if (converter != null) {
        return converter;
      }
    }

    return null;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('ConversionService converters =');
    for (final converterString in _getConverterStrings()) {
      buffer.write('\t');
      buffer.write(converterString);
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Returns a sorted list of string representations for all registered converters.
  ///
  /// Iterates over all [_ConvertersForPair] entries in [_converters], collects
  /// their string representations, sorts them alphabetically, and returns the list.
  ///
  /// This can be useful for debugging, logging, or inspecting which converters
  /// are currently registered in the system.
  ///
  /// Returns:
  /// - A [List<String>] containing the string representations of all converters,
  ///   sorted in ascending order.
  ///
  /// ### Example
  /// ```dart
  /// final converterDescriptions = _getConverterStrings();
  /// converterDescriptions.forEach(print);
  /// ```
  List<String> _getConverterStrings() {
    final converterStrings = <String>[];
    for (final convertersForPair in _converters.values) {
      converterStrings.add(convertersForPair.toString());
    }
    converterStrings.sort();
    return converterStrings;
  }
}

/// {@template no_op_converter}
/// A converter that does nothing.
/// 
/// ---
/// 
/// ### 🔧 Example:
/// ```dart
/// final converter = _NoOpConverter('no_op_converter');
/// ```
/// {@endtemplate}
@Generic(_NoOpConverter)
class _NoOpConverter extends CommonPairedConverter {
  /// The name of this element, converter, or property.
  ///
  /// This is typically used for identification, logging, or
  /// error reporting purposes in the conversion or validation context.
  final String name;

  _NoOpConverter(this.name);

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => null;

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) => source;

  @override
  String toString() => name;
}

/// {@template paired_converter_adapter}
/// A converter adapter that adapts a converter to a paired converter.
/// 
/// ---
/// 
/// ### 🔧 Example:
/// ```dart
/// final converter = _PairedConverterAdapter(converter, sourceType, targetType, domain, convertNullSource);
/// ```
/// {@endtemplate}
@Generic(_PairedConverterAdapter)
class _PairedConverterAdapter extends CommonPairedConditionalConverter {
  /// The specific converter instance responsible for converting values
  /// from the source type to the target type.
  final Converter _converter;

  /// Represents the pair of source and target types that this converter
  /// can handle.
  final ConvertiblePair _typeInfo;

  /// Special converter used when the source value is `null`.
  /// Ensures that `null` values are safely handled without errors.
  final _NullSourceConverter _convertNullSource;

  /// {@macro paired_converter_adapter}
  _PairedConverterAdapter(
    Converter converter,
    Class sourceType,
    Class targetType,
    ProtectionDomain domain,
    _NullSourceConverter convertNullSource,
  )  : _converter = converter, _typeInfo = ConvertiblePair(sourceType, targetType), _convertNullSource = convertNullSource;

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {_typeInfo};

  @override
  bool matches(Class sourceType, Class targetType) {
    final target = _typeInfo.getTargetType();
    final source = _typeInfo.getSourceType();

    bool canApplyToSource = source.getType() == sourceType.getType() || source.isAssignableFrom(sourceType);
    bool canApplyToTarget = target.getType() == targetType.getType() || target.isAssignableFrom(targetType);

    if(canApplyToSource && canApplyToTarget) {
      return true;
    }
    
    // Improved matching logic
    if (target.getType() != targetType.getType()) {
      return false;
    }

    if (target.getType() != targetType.getType() && !target.isAssignableFrom(targetType)) {
      return false;
    }

    if(ConvertiblePair(source, target) == ConvertiblePair(sourceType, targetType)) {
      return true;
    }

    return _converter is! ConditionalConverter || (_converter as ConditionalConverter).matches(sourceType, targetType);
  }

  /// Determines whether this converter matches the given [sourceType] and [targetType]
  /// when considered as a fallback option.
  ///
  /// The method checks two conditions:
  /// 1. The converter's target type exactly matches [targetType].
  /// 2. If the converter is a [ConditionalConverter], its `matches` method
  ///    must also return `true` for the [sourceType] and [targetType].
  ///
  /// This allows non-conditional converters to match strictly by target type,
  /// while conditional converters may apply additional logic.
  ///
  /// Parameters:
  /// - [sourceType]: The source class type to convert from.
  /// - [targetType]: The target class type to convert to.
  ///
  /// Returns:
  /// - `true` if this converter can be applied as a fallback for the given
  ///   types; otherwise, `false`.
  bool matchesFallback(Class sourceType, Class targetType) {
    return _typeInfo.getTargetType().getType() == targetType.getType() &&
        (_converter is! ConditionalConverter ||
            (_converter as ConditionalConverter).matches(sourceType, targetType));
  }

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) {
      return _convertNullSource(sourceType, targetType);
    }
    return _converter.convert(source);
  }

  @override
  String toString() {
    return '$_typeInfo : $_converter';
  }
}

/// {@template paired_converter_factory_adapter}
/// A converter factory adapter that adapts a converter factory to a paired converter.
/// 
/// ---
/// 
/// ### 🔧 Example:
/// ```dart
/// final converter = _PairedConverterFactoryAdapter(converterFactory, typeInfo, domain, convertNullSource);
/// ```
/// {@endtemplate}
@Generic(_PairedConverterFactoryAdapter)
class _PairedConverterFactoryAdapter extends CommonPairedConditionalConverter {
  /// Factory responsible for creating instances of converters dynamically
  /// for the given source and target types.
  final ConverterFactory<dynamic, dynamic> _converterFactory;

  /// Represents the pair of source and target types that this converter
  /// is capable of handling.
  final ConvertiblePair _typeInfo;

  /// Security or visibility context associated with this converter.
  /// Typically used for classloading or reflective operations in protected scopes.
  final ProtectionDomain domain;

  /// Special converter used when the source value is `null`.
  /// Ensures safe handling of `null` inputs without throwing errors.
  final _NullSourceConverter _convertNullSource;

  /// {@macro paired_converter_factory_adapter}
  _PairedConverterFactoryAdapter(this._converterFactory, this._typeInfo, this.domain, this._convertNullSource);

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {_typeInfo};

  @override
  bool matches(Class sourceType, Class targetType) {
    final source = _typeInfo.getSourceType();
    final target = _typeInfo.getTargetType();

    bool canApplyToSource = source.getType() == sourceType.getType() || source.isAssignableFrom(sourceType);
    bool canApplyToTarget = target.getType() == targetType.getType() || target.isAssignableFrom(targetType);

    if(canApplyToSource && canApplyToTarget) {
      bool matches = true;
      if (_converterFactory is ConditionalConverter) {
        matches = (_converterFactory as ConditionalConverter).matches(sourceType, targetType);
      }

      if (matches) {
        final converter = _converterFactory.getConverter(targetType);
        if (converter is ConditionalConverter) {
          matches = (converter as ConditionalConverter).matches(sourceType, targetType);
        }
      }

      return matches;
    }

    return false;
  }

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) {
      return _convertNullSource(sourceType, targetType);
    }

    final converter = _converterFactory.getConverter(targetType);
    return converter?.convert(source);
  }

  @override
  String toString() => '$_typeInfo : $_converterFactory';
}

/// {@template default_null_converter}
/// A default null converter that converts null to an empty optional.
/// 
/// ---
/// 
/// ### 🔧 Example:
/// ```dart
/// final converter = _DefaultNullConverter();
/// ```
/// {@endtemplate}
class _DefaultNullConverter implements GenericNullConverter {
  /// {@macro default_null_converter}
  _DefaultNullConverter();

  @override
  Object? convert(Class? sourceType, Class targetType) => null;

  @override
  bool matches(Class sourceType, Class targetType) => true;
}