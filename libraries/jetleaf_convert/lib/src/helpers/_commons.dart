import 'package:jetleaf_lang/lang.dart';

import '../core/converters.dart';

/// Base class for common [Converter] implementations that operate
/// between types [S] (source) and [T] (target).
///
/// This ensures that all converters in this family share the
/// standard `PackageNames.CONVERT` namespace.
///
/// Example:
/// ```dart
/// class StringToIntConverter extends CommonConverter<String, int> {
///   @override
///   int convert(String source) => int.parse(source);
/// }
/// ```
@Generic(CommonConverter)
abstract class CommonConverter<S, T> implements Converter<S, T> {
  @override
  String getPackageName() => PackageNames.CONVERT;
}

/// Base class for paired converters (two-way converters).
///
/// A paired converter defines conversion in both directions
/// between two types.
///
/// All implementations are automatically registered under
/// `PackageNames.CONVERT`.
abstract class CommonPairedConverter implements PairedConverter {
  @override
  String getPackageName() => PackageNames.CONVERT;
}

/// Base class for paired converters with conditional conversion logic.
///
/// Unlike [CommonPairedConverter], these converters may only be
/// applicable under certain conditions (runtime checks, format
/// constraints, etc.).
///
/// Still registered under the `PackageNames.CONVERT` namespace.
abstract class CommonPairedConditionalConverter extends PairedConditionalConverter {
  @override
  String getPackageName() => PackageNames.CONVERT;
}

/// Base class for [ConverterFactory] implementations that produce
/// converters from type [S] (source) to type [R] (result).
///
/// Provides consistency by always using the `PackageNames.CONVERT`
/// namespace.
@Generic(CommonConverterFactory)
abstract class CommonConverterFactory<S, R> implements ConverterFactory<S, R> {
  @override
  String getPackageName() => PackageNames.CONVERT;
}

// ---------------------------------------------------------------------------
// Core Type References
// ---------------------------------------------------------------------------

/// Reference to the Dart core [String] type.
final STRING = Class<String>(null, PackageNames.DART);

/// Reference to the Dart core [int] type.
final INT = Class<int>(null, PackageNames.DART);

/// Reference to the Dart core [num] type.
final NUM = Class<num>(null, PackageNames.DART);

/// Reference to the Dart core [double] type.
final DOUBLE = Class<double>(null, PackageNames.DART);

/// Reference to the Dart core [bool] type.
final BOOL = Class<bool>(null, PackageNames.DART);

/// Reference to the Dart core [BigInt] type.
final BIG_INT = Class<BigInt>(null, PackageNames.DART);

/// Reference to the Dart core [Runes] type.
///
/// The Dart VM represents [Runes] through an iterable implementation during
/// mirror inspection. Keeping the framework's canonical type reference here
/// allows built-in Runes converters to register their source and target types
/// explicitly when generic superclass metadata is unavailable.
final RUNES = Class<Runes>(null, PackageNames.DART);

/// Reference to the Dart core [Iterable<int>] type used by the Runes bridge.
///
/// The converter is registered separately from [RUNES] because the Dart VM
/// exposes a [Runes] value as an iterable during reflective type inspection.
final ITERABLE_INT = Class<Iterable<int>>(null, PackageNames.DART);

/// Reference to the Jetleaf [Long] type.
final LONG = Class<Long>(null, PackageNames.LANG);

/// Reference to the Jetleaf [Integer] type.
final INTEGER = Class<Integer>(null, PackageNames.LANG);

/// Reference to the Jetleaf [BigInteger] type.
final BIG_INTEGER = Class<BigInteger>(null, PackageNames.LANG);

/// Reference to the Jetleaf [BigDecimal] type.
final BIG_DECIMAL = Class<BigDecimal>(null, PackageNames.LANG);

/// Reference to the Jetleaf [Float] type.
final FLOAT = Class<Float>(null, PackageNames.LANG);

/// Reference to the Jetleaf [Boolean] type.
final BOOLEAN = Class<Boolean>(null, PackageNames.LANG);

/// Reference to the Jetleaf [Character] type.
final CHARACTER = Class<Character>(null, PackageNames.LANG);
