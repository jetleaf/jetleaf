import 'package:jetleaf_lang/lang.dart';

import '../exceptions.dart';
import '../core/conversion_service.dart';
import '../helpers/_commons.dart';
import '../helpers/convertible_pair.dart';

/// {@template object_to_list_converter}
/// A [Converter] that converts an [Object] to a [List].
///
/// Example:
/// ```dart
/// final converter = ObjectToListConverter();
/// print(converter.convert('1, 2, 3')); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class ObjectToListConverter extends CommonPairedConditionalConverter {
  final ConversionService _conversionService;

  ObjectToListConverter(this._conversionService);

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(Class<Object>(null, PackageNames.DART), Class<List>(null, PackageNames.DART))
  };

  @override
  bool matches(Class sourceType, Class targetType) => !sourceType.isArray() && targetType.isArray();

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final targetElementType = targetType.componentType();

    if (targetElementType != null && targetElementType.isInstance(source)) {
      return [source];
    }

    if (targetElementType != null) {
      final convertedElement = _conversionService.convertTo(source, sourceType, targetElementType);
      return [convertedElement];
    }

    return [source];
  }
}

/// {@template object_to_set_converter}
/// A [Converter] that converts an [Object] to a [Set].
///
/// Example:
/// ```dart
/// final converter = ObjectToSetConverter();
/// print(converter.convert('1, 2, 3')); // prints: {1, 2, 3}
/// ```
/// {@endtemplate}
class ObjectToSetConverter extends CommonPairedConditionalConverter {
  final ConversionService _conversionService;

  ObjectToSetConverter(this._conversionService);

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(Class<Object>(null, PackageNames.DART), Class<Set>(null, PackageNames.DART))
  };

  @override
  bool matches(Class sourceType, Class targetType) => !sourceType.isArray() && targetType.isAssignableTo(Class<Set>());

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final targetElementType = targetType.componentType();
    if (targetElementType != null) {
      final convertedElement = _conversionService.convertTo(source, sourceType, targetElementType);
      return {convertedElement};
    }

    return {source};
  }
}

/// {@template list_to_object_converter}
/// A [Converter] that converts a [List] to an [Object] (extracts single element).
///
/// Example:
/// ```dart
/// final converter = ListToObjectConverter();
/// print(converter.convert([1, 2, 3])); // prints: 1
/// ```
/// {@endtemplate}
class ListToObjectConverter extends CommonPairedConditionalConverter {
  final ConversionService _conversionService;

  ListToObjectConverter(this._conversionService);

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(Class<List>(null, PackageNames.DART), Class<Object>(null, PackageNames.DART))
  };

  @override
  bool matches(Class sourceType, Class targetType) => sourceType.isArray() && !targetType.isArray();

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final sourceList = source as List;
    final component = sourceType.componentType();
    if (component == null) {
      throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source);
    }

    if (sourceList.isEmpty) return null;
    if (sourceList.length == 1) {
      return _conversionService.convertTo(sourceList.first, targetType, component);
    }

    if(targetType.getType() == String) {
      return sourceList.map((element) => _conversionService.convertTo<String>(element, component, targetType)).join(",");
    }

    // Check int and add all items in the list
    if(component.getType() == int) {
      return sourceList.map((element) => _conversionService.convertTo<int>(element, component, targetType)).reduce((a, b) => (a as int) + (b as int));
    }

    throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source);
  }
}

/// {@template set_to_object_converter}
/// A [Converter] that converts a [Set] to an [Object] (extracts single element).
///
/// Example:
/// ```dart
/// final converter = SetToObjectConverter();
/// print(converter.convert({1, 2, 3})); // prints: 1
/// ```
/// {@endtemplate}
class SetToObjectConverter extends CommonPairedConditionalConverter {
  final ConversionService _conversionService;

  SetToObjectConverter(this._conversionService);

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(Class<Set>(null, PackageNames.DART), Class<Object>(null, PackageNames.DART))
  };

  @override
  bool matches(Class sourceType, Class targetType) => sourceType.isAssignableTo(Class<Set>()) && !targetType.isArray();

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final sourceSet = source as Set;
    if (sourceSet.isEmpty) return null;
    if (sourceSet.length == 1) {
      return _conversionService.convertTo(sourceSet.first, targetType, sourceType.componentType());
    }

    throw ConversionFailedException(sourceType: sourceType, targetType: targetType, value: source);
  }
}

// Fallback Converters

/// {@template fallback_object_to_string_converter}
/// A [Converter] that converts any object to string using toString().
///
/// Example:
/// ```dart
/// final converter = FallbackObjectToStringConverter();
/// print(converter.convert('1, 2, 3')); // prints: '1, 2, 3'
/// ```
/// {@endtemplate}
class FallbackObjectToStringConverter extends CommonPairedConditionalConverter {
  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(Class<Object>(null, PackageNames.DART), Class<String>(null, PackageNames.DART))
  };

  @override
  bool matches(Class sourceType, Class targetType) => targetType.getType() == String;

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) => source?.toString();
}

/// {@template object_to_object_converter}
/// A [Converter] that converts an [Object] to another [Object] using reflection.
///
/// Example:
/// ```dart
/// final converter = ObjectToObjectConverter();
/// print(converter.convert('1, 2, 3')); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class ObjectToObjectConverter extends CommonPairedConditionalConverter {
  /// Cache for the latest to-method, static factory method, or factory constructor resolved on a given Class
  static final Map<Class, Executable> conversionExecutableCache = {};

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => null;

  @override
  bool matches(Class sourceType, Class targetType) {
    if (sourceType.getType() == targetType.getType()) return false;
    if (targetType.getType() == Map) return true;
    if (sourceType.isPrimitive()) return false;
    // Lightweight check for Map→Object: source is Map, target is not Map and not raw Object.
    // The actual fromMap constructor lookup happens in convert() via determineMapFromMethod(),
    // which calls getConstructors() — but only when the converter is actually selected.
    if (sourceType.getType() == Map && targetType.getType() != Map && targetType.getType() != Object) return true;
    return hasConversionMethodOrConstructor(targetType, sourceType);
  }

  bool hasConversionMethodOrConstructor(Class targetClass, Class sourceClass) {
		return (getValidatedExecutable(targetClass, sourceClass) != null);
	}

  bool hasMapBasedConversion(Class targetClass) {
    return determineMapConstructor(targetClass) != null || determineMapFromMethod(targetClass) != null;
  }

  Executable? getValidatedExecutable(Class targetClass, Class sourceClass) {
    Executable? executable = conversionExecutableCache.get(targetClass);
		if (executable != null && isApplicable(executable, sourceClass)) {
			return executable;
		}

    executable = determineToMethod(targetClass, sourceClass);
		if (executable == null) {
			executable = determineFactoryMethod(targetClass, sourceClass);
			if (executable == null) {
				executable = determineFactoryConstructor(targetClass, sourceClass);
				if (executable == null) {
					return null;
				}
			}
		}

		conversionExecutableCache.put(targetClass, executable);
		return executable;
  }

  bool isApplicable(Executable executable, Class sourceClass) {
    if(executable is Method) {
      if(executable.isStatic()) {
        return ClassUtils.isAssignable(executable.getDeclaringClass(), sourceClass);
      } else {
        return executable.getParameterTypes().elementAt(0).getType() == sourceClass.getType();
      }
    } else if(executable is Constructor) {
      return executable.getParameterTypes().elementAt(0).getType() == sourceClass.getType();
    }

    return false;
  }

  Method? determineToMethod(Class targetClass, Class sourceClass) {
    if(Class<String>().getType() == targetClass.getType() || Class<String>().getType() == sourceClass.getType()) {
      // Do not accept a toString() method or any to methods on String itself
			return null;
    }

    Method? method = ClassUtils.getMethodIfAvailable(sourceClass, "to${targetClass.getSimpleName()}");
		return (method != null && !method.isStatic() && ClassUtils.isAssignable(targetClass, method.getReturnClass()) ? method : null);
  }

  Method? determineFactoryMethod(Class targetClass, Class sourceClass) {
    if(Class<String>().getType() == targetClass.getType()) {
      // Do not accept the String.valueOf(Object) method
			return null;
    }

    Method? method = ClassUtils.getStaticMethod(targetClass, "valueOf");
		if (method == null) {
			method = ClassUtils.getStaticMethod(targetClass, "of");
			method ??= ClassUtils.getStaticMethod(targetClass, "from");
		}

		return (method != null && areRelatedTypes(targetClass, method.getReturnClass()) ? method : null);
  }

  bool areRelatedTypes(Class type1, Class type2) {
		return (ClassUtils.isAssignable(type1, type2) || ClassUtils.isAssignable(type2, type1));
	}

  Constructor? determineFactoryConstructor(Class targetClass, Class sourceClass) {
    return targetClass.getConstructorBySignature([sourceClass]);
  }

  Constructor? determineMapConstructor(Class targetClass) {
    final constructors = targetClass.getConstructors();
    for (final ctor in constructors) {
      final params = ctor.getParameters();
      if (params.length == 1) {
        final param = params.elementAt(0);
        if (param.getReturnClass().getType() == Map) {
          return ctor;
        }
      }
    }
    return null;
  }

  Constructor? determineMapFromMethod(Class targetClass) {
    final constructors = targetClass.getConstructors();
    for (final ctor in constructors) {
      final name = ctor.getName();
      if (name == 'fromMap' || name == 'from') {
        final params = ctor.getParameters();
        if (params.length == 1 && params.elementAt(0).getReturnClass().getType() == Map) {
          return ctor;
        }
      }
    }
    return null;
  }

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    if (sourceType.getType() == targetType.getType()) {
      return source;
    }

    if (ClassUtils.isProxyClass(sourceType)) {
      if (sourceType.getSuperClass() case final superClass?) {
        if (superClass == targetType || superClass.isInstance(targetType)) {
          return source;
        }
      }
    }

    if (ClassUtils.isProxyClass(targetType)) {
      if (targetType.getSuperClass() case final superClass?) {
        if (superClass == sourceType || superClass.isInstance(sourceType)) {
          return source;
        }
      }
    }

    if (targetType.getType() == Map) {
      try {
        final map = <String, dynamic>{};
        for (final member in sourceType.getDeclaredMembers()) {
          if (member is Field && !member.isStatic()) {
            try {
              final value = member.getValue(source);
              map[member.getName()] = value;
            } catch (_) {}
          }
        }
        return map;
      } on Throwable catch(e) {
        throw ConversionFailedException(targetType: targetType, sourceType: sourceType, value: source, point: e.getCause());
      } catch (e) {
        throw ConversionFailedException(targetType: targetType, sourceType: sourceType, value: source, point: e);
      }
    }

    if (source is Map) {
      final map = Map<String, dynamic>.from(source);
      final executable = determineMapConstructor(targetType) ?? determineMapFromMethod(targetType);
      if (executable != null) {
        try {
          final params = executable.getParameters();
          final isPositional = params.isNotEmpty && !params.elementAt(0).isNamed();
          if (isPositional) {
            return executable.newInstance(null, [map]);
          } else {
            return executable.newInstance({'map': map});
          }
        } on Throwable catch(e) {
          throw ConversionFailedException(targetType: targetType, sourceType: sourceType, value: source, point: e.getCause());
        } catch (e) {
          throw ConversionFailedException(targetType: targetType, sourceType: sourceType, value: source, point: e);
        }
      }
    }

    if (getValidatedExecutable(targetType, sourceType) case final executable?) {
      try {
        if(executable is Method) {
          if(!executable.isStatic()) {
            return executable.invoke(source);
          } else {
            final map = source is Map ? Map<String, dynamic>.from(source) : null;
            if (map != null) {
              return executable.invoke(null, map);
            } else {
              return executable.invoke(source);
            }
          }
        } else if(executable is Constructor) {
          final map = source is Map ? Map<String, dynamic>.from(source) : null;
          final params = executable.getParameters();
          final isPositional = params.isNotEmpty && !params.elementAt(0).isNamed();
          if (isPositional) {
            if (map != null) {
              return executable.newInstance(null, <dynamic>[map]);
            } else {
              return executable.newInstance(null, <dynamic>[source]);
            }
          } else {
            return executable.newInstance(map ?? {'value': source});
          }
        }
      } on Throwable catch(e) {
        throw ConversionFailedException(targetType: targetType, sourceType: sourceType, value: source, point: e.getCause());
      } catch (e) {
        throw ConversionFailedException(targetType: targetType, sourceType: sourceType, value: source, point: e);
      }
    }

    throw IllegalStateException("No constructive method ${sourceType.getName()} exists on ${targetType.getName()}");
  }
}