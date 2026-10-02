import 'package:jetleaf_lang/lang.dart';

import '../core/converters.dart';
import '../exceptions.dart';
import '../core/conversion_service.dart';

/// {@template conversion_utils}
/// Utility class containing common operations used by conversion infrastructure.
///
/// This class provides static helper methods to:
/// - Safely invoke a [PairedConverter]
/// - Determine if element-wise conversion is possible
/// - Resolve the enum class from a type
///
/// {@endtemplate}
abstract class ConversionUtils {
  /// {@macro conversion_utils}
  ConversionUtils._();

  /// Invokes the provided [converter] with the given [source], [sourceType],
  /// and [targetType] descriptors, handling conversion failures appropriately.
  ///
  /// If a [ConversionFailedException] is thrown during conversion,
  /// it is rethrown directly. For any other [Exception], a new
  /// [ConversionFailedException] is thrown with context.
  ///
  /// ### 🔧 Example
  /// ```dart
  /// final result = ConversionUtils.invokeConverter(
  ///   myConverter,
  ///   '123',
  ///   Class.forType(String),
  ///   Class.forType(int),
  /// );
  /// ```
	static Object? invoke<T>(PairedConverter converter, Object? source, Class sourceType, Class targetType) {
		try {
			return converter.convert<T>(source, sourceType, targetType);
		} on ConversionFailedException catch (_) {
			rethrow;
		} on ConversionException catch (_) {
			rethrow;
		} on Exception catch (ex) {
			throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: ex);
		} on Error catch (ex) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source, point: ex);
    }
	}

  /// Checks if a conversion from [source] to [target]
  /// is possible using the given [conversionService].
  ///
  /// - If [target] is `null`, conversion is considered allowed.
  /// - If [source] is `null`, conversion is potentially allowed.
  /// - Otherwise, it checks:
  ///   - If the conversion service can convert between the two descriptors.
  ///   - Or if the underlying Dart types are assignable.
  ///
  /// ### 🔧 Example
  /// ```dart
  /// bool result = ConversionUtils.canConvertElements(
  ///   Class.forType(String),
  ///   Class.forType(int),
  ///   myConversionService,
  /// );
  /// ```
	static bool canConvert(Class? source, Class? target, ConversionService conversionService) {
		if (target == null) {
			return true;
		}

		if (source == null) {
			return true;
		}

		if (conversionService.canConvert(source, target)) {
			return true;
		}

		if (source.isInstance(target)) {
			return true;
		}
    
		return false;
	}

	/// Resolves the enum class from the given [targetType].
	///
	/// - If [targetType] is an enum, returns it directly.
	/// - Otherwise, searches the superclass chain for an enum type.
	///
	/// Throws an [IllegalArgumentException] if no enum type is found.
	///
	/// ### 🔧 Example
	/// ```dart
	/// Class enumType = ConversionUtils.getEnumType(Class<MyEnum>());
	/// ```
	static Class getEnumType(Class? targetType) {
		while (targetType != null && !targetType.isEnum()) {
			targetType = targetType.getSuperClass();
		}
		assert(targetType != null, "The target type ${targetType?.getName()} does not refer to an enum");
		return targetType!;
	}
}