// ignore_for_file: unused_field

import 'dart:async';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../extensions/primitives/string.dart';
import '../collections/hash_set.dart';
import '../commons/optional.dart';
import '../extensions/primitives/map.dart';
import '../garbage_collector/garbage_collector.dart';
import '../math/big_integer.dart';
import '../meta/class/class_gettable.dart';
import '../meta/class/class_type.dart';
import '../primitives/boolean.dart';
import '../primitives/character.dart';
import '../primitives/double.dart';
import '../primitives/float.dart';
import '../primitives/integer.dart';
import '../meta/method/method.dart';
import '../meta/class/class.dart';

/// {@template class_utils}
/// A utility class that provides static methods for working with class hierarchies
/// and type relationships in Dart's reflection system.
/// 
/// This class offers functionality to traverse and analyze class inheritance
/// structures, including superclasses, interfaces, and special handling for
/// arrays and enums.
/// 
/// ## Usage
/// 
/// ```dart
/// // Get the complete class hierarchy for a type
/// final hierarchy = ClassUtils.getClassHierarchy(Class<String>());
/// 
/// // The hierarchy will include:
/// // - The original class (String)
/// // - All superclasses up to Object
/// // - All implemented interfaces
/// // - Special handling for arrays and enums
/// 
/// print('Class hierarchy for String:');
/// for (final clazz in hierarchy) {
///   print('  ${clazz.getName()}');
/// }
/// ```
/// 
/// ## Features
/// 
/// - **Complete hierarchy traversal**: Walks up the entire inheritance chain
/// - **Interface inclusion**: Includes all implemented interfaces at each level
/// - **Array support**: Special handling for array component types
/// - **Enum support**: Proper enum hierarchy with Enum base class
/// - **Duplicate prevention**: Ensures no duplicate classes in the hierarchy
/// - **Ordered results**: Returns hierarchy in a logical traversal order
/// {@endtemplate}
final class ClassUtils {
  /// {@macro class_utils}
  ClassUtils._() {
    _ensureInitialized();
  }

  /// Garbage collector key for primitive type to wrapper type cache.
  static const String PRIMITIVE_GARBAGE_KEY = "internal::::class_utils::::key";

  /// Map with primitive wrapper type as key and corresponding primitive
  /// type as value, for example: `Class<Integer>() -> Class<int>()`.
  static Map<Class, Class> get _primitiveWrapperTypeMap => GC.getOrCreate<Map<Class, Class>>(PRIMITIVE_GARBAGE_KEY, {}).getSource();

  /// Garbage collector key for primitive type to wrapper cache.
  static const String PRIMITIVE_TYPE_TO_WRAPPER_GARBAGE_KEY = "internal::::class_utils::::primitive_type_to_wrapper";
  
  /// Map with primitive type as key and corresponding wrapper
  /// type as value, for example: `Class<int>() -> Class<Integer>()`.
  static Map<Class, Class> get _primitiveTypeToWrapperMap => GC.getOrCreate<Map<Class, Class>>(PRIMITIVE_TYPE_TO_WRAPPER_GARBAGE_KEY, {}).getSource();

  /// Garbage collector key for primitive type to name cache.
  static const String PRIMITIVE_TYPE_NAME_GARBAGE_KEY = "internal::::class_utils::::primitive_type_name";
  
  /// Map with primitive type name as key and corresponding primitive
  /// type as value, for example: `'int' -> Class<int>()`.
  static Map<String, Class> get _primitiveTypeNameMap => GC.getOrCreate<Map<String, Class>>(PRIMITIVE_TYPE_NAME_GARBAGE_KEY, {}).getSource();

  /// Garbage collector key for common class cache.
  static const String COMMON_CLASS_CACHE_GARBAGE_KEY = "internal::::class_utils::::common_class_cache";

  /// Map with common Dart language class name as key and corresponding Class as value.
  /// Primarily for efficient deserialization of remote invocations.
  static Map<String, Class> get _commonClassCache => GC.getOrCreate<Map<String, Class>>(COMMON_CLASS_CACHE_GARBAGE_KEY, {}).getSource();

  /// Garbage collector key for class hierarchy cache.
  static const String CLASS_HIERARCHY_GARBAGE_KEY = "internal::::class_utils::::class_hierarchy";

  /// Cache for class hierarchies within a class.
  /// 
  /// A `null` value signals that no class hierarchy was found for the key.
  static Map<Class, List<Class>?> get _classHierarchy => GC.getOrCreate<Map<Class, List<Class>?>>(CLASS_HIERARCHY_GARBAGE_KEY, {}).getSource();

  /// {@template jet_class_utils_ensure_initialized}
  /// Ensures that Jetleaf's primitive and common reflective type caches are
  /// initialized before any type resolution, assignability check, or reflective
  /// lookup occurs.
  ///
  /// This method performs **lazy, one-time initialization** of the internal
  /// type maps and caches used by Jetleaf’s reflection system. It establishes
  /// consistent mappings between **Dart primitive types** and **Jetleaf
  /// language wrapper types**, while also caching common runtime classes to
  /// accelerate reflection and reduce overhead.
  ///
  /// ### Initialization Responsibilities
  ///
  /// 1. **Primitive ↔ Wrapper Bidirectional Mapping**
  ///    - Populates `_primitiveWrapperTypeMap` with Jetleaf → Dart mappings:
  ///      - `Boolean → bool`
  ///      - `Double → double`
  ///      - `Integer → int`
  ///      - `BigInteger → BigInt`
  ///      - `Float → num`
  ///    - Builds the inverse `_primitiveTypeToWrapperMap` for Dart → Jetleaf.
  ///
  /// 2. **Primitive Name Cache**
  ///    - Adds Dart primitive type names to `_primitiveTypeNameMap`
  ///      for fast lookup during deserialization or runtime analysis.
  ///
  /// 3. **Common Class Registration**
  ///    Registers frequently used classes into `_commonClassCache`
  ///    to avoid redundant reflective resolution at runtime.
  ///
  ///    These include:
  ///    - **List and Collection Types:** `List<T>`, `Set<T>`, `Map<K,V>`,
  ///      `Iterable`, `Iterator`, `MapEntry`
  ///    - **Error and Exception Hierarchy:** `Throwable`, `Exception`,
  ///      `Error`, `RuntimeException`, `StackTrace`
  ///    - **Meta and Utility Types:** `Enum`, `Optional`, `Class`, `Object`
  ///
  /// ### Performance Notes
  /// - This method is guarded by the `_initialized` flag, ensuring
  ///   it executes **only once per runtime session**.
  /// - Uses explicit `for` loops instead of higher-order functions
  ///   (e.g., `forEach`) for micro-performance optimization.
  ///
  /// ### Example
  /// ```dart
  /// ClassUtils._ensureInitialized();
  ///
  /// final boolClass = Class<bool>(null, PackageNames.DART);
  /// print(ClassUtils.getWrapperType(boolClass));
  /// // Output: Class<Boolean>(null, PackageNames.LANG)
  /// ```
  ///
  /// ### Returns
  /// Nothing. Once called, Jetleaf’s type reflection maps are guaranteed
  /// to be initialized for all subsequent lookups.
  ///
  /// ### See also
  /// - [_registerCommonClasses]
  /// - [Class.isAssignableFrom]
  /// - [PackageNames]
  /// {@endtemplate}
  static void _ensureInitialized() {
    if (GC.exists(PRIMITIVE_GARBAGE_KEY) && GC.exists(CLASS_HIERARCHY_GARBAGE_KEY) && GC.exists(COMMON_CLASS_CACHE_GARBAGE_KEY) && GC.exists(PRIMITIVE_TYPE_NAME_GARBAGE_KEY) && GC.exists(PRIMITIVE_TYPE_TO_WRAPPER_GARBAGE_KEY)) return;

    // 1. Primitive wrapper type mappings (Jetleaf → Dart)
    _primitiveWrapperTypeMap.put(Class<Boolean>(null, PackageNames.LANG), Class<bool>(null, PackageNames.DART));
    _primitiveWrapperTypeMap.put(Class<Double>(null, PackageNames.LANG), Class<double>(null, PackageNames.DART));
    _primitiveWrapperTypeMap.put(Class<Integer>(null, PackageNames.LANG), Class<int>(null, PackageNames.DART));
    _primitiveWrapperTypeMap.put(Class<BigInteger>(null, PackageNames.LANG), Class<BigInt>(null, PackageNames.DART));
    _primitiveWrapperTypeMap.put(Class<Float>(null, PackageNames.LANG), Class<num>(null, PackageNames.DART));

    // 2. Inverse mapping (Dart → Jetleaf)
    for (MapEntry<Class, Class> entry in _primitiveWrapperTypeMap.entries) {
      _primitiveTypeToWrapperMap.put(entry.value, entry.key);
      _registerCommonClasses([entry.key]);
    }

    // 3. Populate primitive type name map for quick lookup
    Set<Class> primitiveTypes = {};
    primitiveTypes.addAll(_primitiveWrapperTypeMap.values);
    primitiveTypes.addAll([
      Class<bool>(null, PackageNames.DART),
      Class<double>(null, PackageNames.DART),
      Class<int>(null, PackageNames.DART),
      Class<BigInt>(null, PackageNames.DART),
      Class<num>(null, PackageNames.DART),
    ]);

    for (Class primitiveType in primitiveTypes) {
      _primitiveTypeNameMap.put(primitiveType.getName(), primitiveType);
    }

    // 4. Register commonly used collection and object classes
    _registerCommonClasses([
      Class<List<Boolean>>(null, PackageNames.LANG),
      Class<List<double>>(null, PackageNames.DART),
      Class<List<int>>(null, PackageNames.DART),
      Class<List<BigInt>>(null, PackageNames.DART),
      Class<List<num>>(null, PackageNames.DART),
    ]);

    _registerCommonClasses([
      Class<List<String>>(null, PackageNames.DART),
      Class<List<Character>>(null, PackageNames.LANG),
      Class<List<Class>>(null, PackageNames.LANG),
      Class<List<Object>>(null, PackageNames.DART),
    ]);

    _registerCommonClasses([
      Class<Throwable>(null, PackageNames.LANG),
      Class<Exception>(null, PackageNames.DART),
      Class<Error>(null, PackageNames.DART),
      Class<RuntimeException>(null, PackageNames.LANG),
      Class<StackTrace>(null, PackageNames.DART),
    ]);

    _registerCommonClasses([
      Class<Enum>(null, PackageNames.DART),
      Class<Iterable>(null, PackageNames.DART),
      Class<Iterator>(null, PackageNames.DART),
      Class<List>(null, PackageNames.DART),
      Class<Set>(null, PackageNames.DART),
      Class<Map>(null, PackageNames.DART),
      Class<MapEntry>(null, PackageNames.DART),
      Class<Optional>(null, PackageNames.LANG),
    ]);
  }

  /// {@template jet_class_utils_register_common_classes}
  /// Registers the given list of [classes] into Jetleaf’s internal
  /// `_commonClassCache`, making them accessible for rapid reflective lookup.
  ///
  /// This method is typically invoked during static initialization within
  /// [_ensureInitialized], but may also be used by extension modules to
  /// preload additional class references (e.g., domain-specific entities
  /// or framework abstractions).
  ///
  /// ### Example
  /// ```dart
  /// ClassUtils._registerCommonClasses([
  ///   Class<MyCustomAnnotation>(),
  ///   Class<MyService>(),
  /// ]);
  /// ```
  ///
  /// ### Parameters
  /// - `classes`: A list of [Class] instances to register.
  ///
  /// ### Behavior
  /// - Each class name is cached by its qualified name for constant-time
  ///   retrieval.
  ///
  /// ### See also
  /// - [_ensureInitialized]
  /// - [Class.getName]
  /// {@endtemplate}
  static void _registerCommonClasses(List<Class> classes) {
    for (var cls in classes) {
      _commonClassCache.put(cls.getName(), cls);
    }
  }
  
  // ========================================================================
  // Class Hierarchy and Type Analysis
  // ========================================================================

  /// {@template get_class_hierarchy}
  /// Retrieves the complete class hierarchy for the specified type, including
  /// all superclasses, interfaces, and special type relationships.
  /// 
  /// This method performs a comprehensive traversal of the type system to build
  /// a complete hierarchy that includes:
  /// - The original class
  /// - All superclasses (excluding Object initially, added at the end)
  /// - All interfaces implemented by each class in the hierarchy
  /// - Component types for arrays
  /// - Special handling for enums (adds Enum base class)
  /// - Object class as the root (added last if not already present)
  /// 
  /// ## Parameters
  /// 
  /// - `type`: The [Class] to analyze for hierarchy information
  /// 
  /// ## Returns
  /// 
  /// A [List<Class>] containing all classes in the hierarchy, ordered by
  /// traversal sequence. The list maintains insertion order and prevents
  /// duplicates.
  /// 
  /// ## Algorithm
  /// 
  /// 1. **Initial Setup**: Creates empty hierarchy list and visited set
  /// 2. **Breadth-First Traversal**: Processes each class level by level
  /// 3. **Superclass Addition**: Adds direct superclass (if not Object or enum)
  /// 4. **Interface Addition**: Adds all interfaces implemented by current class
  /// 5. **Array Handling**: For arrays, processes component type separately
  /// 6. **Enum Handling**: Adds Enum base class for enum types
  /// 7. **Object Addition**: Ensures Object is included as root class
  /// 
  /// ## Examples
  /// 
  /// ### Basic Class Hierarchy
  /// ```dart
  /// class Animal {}
  /// class Mammal extends Animal {}
  /// class Dog extends Mammal implements Comparable<Dog> {}
  /// 
  /// final hierarchy = ClassUtils.getClassHierarchy(Class<Dog>());
  /// // Result: [Dog, Mammal, Animal, Comparable<Dog>, Object]
  /// ```
  /// 
  /// ### Array Type Hierarchy
  /// ```dart
  /// final hierarchy = ClassUtils.getClassHierarchy(Class<List<String>>());
  /// // Includes both List<String> and String component relationships
  /// ```
  /// 
  /// ### Enum Type Hierarchy
  /// ```dart
  /// enum Color { red, green, blue }
  /// 
  /// final hierarchy = ClassUtils.getClassHierarchy(Class<Color>());
  /// // Result: [Color, Enum, Object] plus any interfaces
  /// ```
  /// 
  /// ## Performance Considerations
  /// 
  /// - Uses visited set to prevent infinite loops in complex hierarchies
  /// - Processes interfaces efficiently without redundant traversal
  /// - Handles deep inheritance chains without stack overflow
  /// {@endtemplate}
  static Iterable<Class> getClassHierarchy(Class type) sync* {
    _ensureInitialized();

    final cached = _classHierarchy[type];
    if (cached != null) {
      yield* cached;
      return;
    }

    final visited = <Type>{};
    final collected = <Class>[];

    Iterable<Class> walk(Class current) sync* {
      if (!visited.add(current.getType())) return;

      collected.add(current);
      yield current;

      // 1️⃣ Superclass first (arrays handled specially below)
      final superClass = current.getSuperClass();
      if (superClass != null && superClass.getType() != Object && !superClass.isEnum()) {
        yield* walk(superClass);
      }

      // 2️⃣ Interfaces
      for (final interface in current.getAllInterfaces()) {
        yield* walk(interface);
      }

      // 3️⃣ Array handling — parent first, THEN component type
      if (current.isArray()) {
        final component = current.componentType();
        if (component != null) {
          yield* walk(component);
        }
      }
    }

    // Start traversal
    yield* walk(type);

    // 4️⃣ Enum base class
    if (type.isEnum()) {
      final enumClass = Class<Enum>();
      if (visited.add(enumClass.getType())) {
        collected.add(enumClass);
        yield enumClass;

        for (final iface in enumClass.getAllInterfaces()) {
          yield* walk(iface);
        }
      }
    }

    // 5️⃣ Object last
    if (!visited.contains(Object)) {
      final objectClass = Class<Object>();
      collected.add(objectClass);
      yield objectClass;
    }

    // Cache materialized result
    _classHierarchy[type] = collected;
  }

  /// {@template get_qualified_name}
  /// Returns the **fully qualified Jetleaf name** of the given [object].
  ///
  /// This utility is commonly used within the **Jetleaf reflection system**
  /// to obtain the canonical identifier of classes, components.
  /// The qualified name typically includes the full package or module
  /// prefix, ensuring uniqueness across the application context.
  ///
  /// ### Behavior
  /// - If [object] is a Jetleaf [Class] instance, the method simply calls
  ///   [Class.getQualifiedName] directly.
  /// - Otherwise, it retrieves the object's reflective class using
  ///   [Object.getClass] and delegates to that class’s qualified name.
  ///
  /// ### Example
  /// ```dart
  /// final myClass = Class<MyService>();
  /// print(getQualifiedName(myClass));
  /// // Output: package:example/example.dart.MyService
  ///
  /// final instance = MyService();
  /// print(getQualifiedName(instance));
  /// // Output: package:example/example.dart.MyService
  /// ```
  ///
  /// ### Jetleaf Context
  /// Qualified names are fundamental in Jetleaf’s reflection model and are used
  /// for:
  /// - Component registration and resolution within the Jetleaf container.
  /// - Identifying pointcut and proxy relationships in AOP.
  /// - Resolving dependencies across packages or pods.
  ///
  /// {@endtemplate}
  static String getQualifiedName(Object object) {
    _ensureInitialized();

    if (object is Class) {
      return object.getQualifiedName();
    }

    return object.getClass().getQualifiedName();
  }

  /// {@template get_package}
  /// Returns the **Jetleaf package** associated with the given [object].
  ///
  /// This method provides reflective access to the [Package] metadata of an
  /// object or class. It supports both direct [Class] instances and regular
  /// Dart objects, delegating to Jetleaf’s reflection API.
  ///
  /// ### Behavior
  /// - If [object] is a [Class], this method calls [Class.getPackage].
  /// - Otherwise, it retrieves the object's reflective class via
  ///   [Object.getClass] and returns its package.
  ///
  /// ### Example
  /// ```dart
  /// final classType = Class<MyService>();
  /// final pkg = ClassUtils.getPackage(classType);
  /// print(pkg?.getName()); // e.g., "jetleaf"
  ///
  /// final instance = MyService();
  /// print(ClassUtils.getPackage(instance)?.getName());
  /// // e.g., "jetleaf"
  /// ```
  ///
  /// ### Jetleaf Context
  /// Packages are used throughout Jetleaf for:
  /// - Component scanning and registration
  /// - Dependency resolution within pods
  /// - Managing AOP pointcut scoping
  ///
  /// {@endtemplate}
  static Package? getPackage(Object object) {
    _ensureInitialized();

    if (object is Class) {
      return object.getPackage();
    }

    return object.getClass().getPackage();
  }

  /// {@template get_package_name}
  /// Returns the **qualified package name** of the given [object].
  ///
  /// This method provides a convenient shorthand for obtaining a package’s
  /// name string without directly accessing the [Package] instance.
  ///
  /// ### Behavior
  /// - If [object] is a [Class], returns [Class.getPackage]?.getName().
  /// - Otherwise, retrieves the object’s reflective class via
  ///   [Object.getClass] and returns its package name.
  ///
  /// ### Example
  /// ```dart
  /// final classType = Class<MyService>();
  /// print(ClassUtils.getPackageName(classType));
  /// // Output: "jetleaf"
  ///
  /// final instance = MyService();
  /// print(ClassUtils.getPackageName(instance));
  /// // Output: "jetleaf"
  /// ```
  ///
  /// ### Jetleaf Context
  /// Useful for logging, diagnostic utilities, and AOP framework integration
  /// when you need a quick textual representation of a component’s package.
  ///
  /// {@endtemplate}
  static String getPackageName(Object object) {
    _ensureInitialized();
    
    if (object is Class) {
      return object.getPackage().getName();
    }

    return object.getClass().getPackage().getName();
  }

  /// Check if the right-hand side type may be assigned to the left-hand side type.
  /// 
  /// Considers primitive wrapper classes as assignable to the corresponding primitive types.
  /// 
  /// - Parameters
  /// left: the target type (left-hand side (LHS) type)
  /// right: the source type (right-hand side (RHS) type)
  /// 
  /// - Returns
  /// `true` if the right-hand side type may be assigned to the left-hand side type; otherwise, `false`.
  static bool isAssignable(Class left, Class right) {
    _ensureInitialized();

    if (left.isAssignableFrom(right)) {
			return true;
		}

    if (left.isPrimitive()) {
			Class? resolvedPrimitive = _primitiveWrapperTypeMap.get(right);
			return (left == resolvedPrimitive);
		}
		else if (right.isPrimitive()) {
			Class? resolvedWrapper = _primitiveTypeToWrapperMap.get(right);
			return (resolvedWrapper != null && left.isAssignableFrom(resolvedWrapper));
		}
		return false;
  }

  /// {@template get_static_method}
  /// Retrieves the static method with the specified name from the given class.
  /// 
  /// - Parameters
  /// target: the class to analyze for static method
  /// methodName: the name of the static method to retrieve
  /// 
  /// - Returns
  /// The static method with the specified name from the given class.
  /// 
  /// - Throws
  /// PodDefinitionValidationException if the specified static method is not found in the given class.
  /// 
  /// - Example
  /// ```dart
  /// final method = ClassUtils.getStaticMethod(Class<UserService>(), 'configure');
  /// ```
  /// {@endtemplate}
  static Method? getStaticMethod(Class target, String methodName) {
    _ensureInitialized();

    Method? method = target.getMethod(methodName);
    if (method != null && method.isStatic()) {
      return method;
    }
    return null;
  }

  /// {@template get_method_if_available}
  /// Retrieves the method with the specified name and parameter types from the given class.
  /// 
  /// - Parameters
  /// clazz: the class to analyze for method
  /// methodName: the name of the method to retrieve
  /// paramTypes: the parameter types of the method to retrieve
  /// 
  /// - Returns
  /// The method with the specified name and parameter types from the given class.
  /// 
  /// - Throws
  /// PodDefinitionValidationException if the specified method is not found in the given class.
  /// 
  /// - Example
  /// ```dart
  /// final method = ClassUtils.getMethodIfAvailable(Class<UserService>(), 'configure', [Class<String>()]);
  /// ```
  /// {@endtemplate}
  static Method? getMethodIfAvailable(Class clazz, String methodName, [List<Class>? paramTypes]) {
    _ensureInitialized();

    if (paramTypes != null) {
			return getMethodOrNull(clazz, methodName, paramTypes);
		} else {
			Set<Method> candidates = findMethodCandidatesByName(clazz, methodName);
			if (candidates.length == 1) {
				return candidates.iterator.moveNext() ? candidates.iterator.current : candidates.single;
			}
			return null;
		}
  }

  /// {@template find_method_candidates_by_name}
  /// Retrieves the set of methods with the specified name from the given class.
  /// 
  /// - Parameters
  /// clazz: the class to analyze for methods
  /// methodName: the name of the methods to retrieve
  /// 
  /// - Returns
  /// The set of methods with the specified name from the given class.
  /// 
  /// - Throws
  /// PodDefinitionValidationException if the specified method name is not found in the given class.
  /// 
  /// - Example
  /// ```dart
  /// final methods = ClassUtils.findMethodCandidatesByName(Class.of<UserService>(), 'configure');
  /// ```
  /// {@endtemplate}
  static Set<Method> findMethodCandidatesByName(Class clazz, String methodName) {
    _ensureInitialized();

    Set<Method> candidates = HashSet();
		final methods = clazz.getMethods();
		for (Method method in methods) {
			if (methodName.equals(method.getName())) {
				candidates.add(method);
			}
		}

		return candidates;
  }

  /// {@template get_method_or_null}
  /// Retrieves the method with the specified name and parameter types from the given class.
  /// 
  /// - Parameters
  /// clazz: the class to analyze for method
  /// methodName: the name of the method to retrieve
  /// paramTypes: the parameter types of the method to retrieve
  /// 
  /// - Returns
  /// The method with the specified name and parameter types from the given class.
  /// 
  /// - Throws
  /// PodDefinitionValidationException if the specified method is not found in the given class.
  /// 
  /// - Example
  /// ```dart
  /// final method = ClassUtils.getMethodOrNull(Class<UserService>(), 'configure', [Class<String>()]);
  /// ```
  /// {@endtemplate}
  static Method? getMethodOrNull(Class clazz, String methodName, List<Class> paramTypes) {
    _ensureInitialized();

    return clazz.getMethodBySignature(methodName, paramTypes);
  }

  /// {@template jet_method_utils_is_assignable_to_error}
  /// Determines whether the given [object] represents or is assignable to a
  /// Dart error type within the Jetleaf runtime type system.
  ///
  /// This method supports both [Class] metadata representations and concrete
  /// runtime instances. It leverages Jetleaf’s reflective [Class] API to
  /// perform safe type compatibility checks against [Throwable],
  /// [Exception], and [Error] — ensuring consistency across Dart’s core
  /// error hierarchy and Jetleaf’s extended reflective model.
  ///
  /// ### Behavior
  /// - If [object] is a [Class], the method directly checks assignability
  ///   using `isAssignableFrom` across the core error types.
  /// - If [object] is an instance, the method retrieves its reflective
  ///   class via `object.getClass()` and recursively re-evaluates assignability.
  ///
  /// This is used internally by Jetleaf’s reflective invocation system
  /// to determine if a method parameter can safely accept a throwable type
  /// (for example, during lifecycle event dispatch or error propagation).
  ///
  /// ### Example
  /// ```dart
  /// final clazz = Class<Exception>(null, PackageNames.DART);
  /// final result = ClassUtils.isAssignableToError(clazz);
  ///
  /// print(result); // true
  /// ```
  ///
  /// In this example, the [Exception] class is recognized as a valid
  /// throwable type by Jetleaf.
  ///
  /// ### Returns
  /// `true` if the provided object (or its reflective class) is assignable to
  /// [Throwable], [Exception], or [Error]; otherwise, `false`.
  ///
  /// ### See also
  /// - [Throwable]
  /// - [Exception]
  /// - [Error]
  /// - [Class.isAssignableFrom]
  /// {@endtemplate}
  static bool isAssignableToError(Object object) {
    _ensureInitialized();

    if (object is Class) {
      return Class<Throwable>(null, PackageNames.LANG).isAssignableFrom(object) ||
          Class<Exception>(null, PackageNames.DART).isAssignableFrom(object) ||
          Class<Error>(null, PackageNames.DART).isAssignableFrom(object);
    }

    final clazz = object.getClass();
    return isAssignableToError(clazz);
  }

  /// {@template jet_method_utils_is_future}
  /// Determines whether the given [object] represents or is assignable to a
  /// Dart [Future] or [FutureOr] type within Jetleaf’s reflective runtime.
  ///
  /// This method provides a unified way to test for asynchronous types across
  /// both reflective [Class] metadata and runtime instances. It is commonly
  /// used within Jetleaf’s task scheduling, dependency injection, and
  /// asynchronous pipeline orchestration subsystems to determine whether a
  /// method or result type requires asynchronous handling.
  ///
  /// ### Behavior
  /// - If [object] is a [Class], it checks assignability against both
  ///   [Future] and [FutureOr].
  /// - If [object] is an instance, it retrieves the reflective class from
  ///   `object.getClass()` and reuses the same check recursively.
  ///
  /// ### Example
  /// ```dart
  /// final asyncClass = Class<Future>(null, PackageNames.DART);
  /// final result = ClassUtils.isAsync(asyncClass);
  ///
  /// print(result); // true
  /// ```
  ///
  /// ### Usage in Jetleaf
  /// This method allows Jetleaf to:
  /// - Detect asynchronous method return types during runtime analysis.
  /// - Manage async tasks in lifecycle methods and scheduling components.
  /// - Correctly unwrap `FutureOr<T>` in reactive pipelines.
  ///
  /// ### Returns
  /// `true` if the provided object (or its reflective class) represents
  /// [Future] or [FutureOr]; otherwise, `false`.
  ///
  /// ### See also
  /// - [Future]
  /// - [FutureOr]
  /// - [Class.isAssignableFrom]
  /// - [isAssignableToError]
  /// {@endtemplate}
  static bool isAsync(Object object) {
    _ensureInitialized();

    if (object is Class) {
      return Class<Future>().isAssignableFrom(object) || Class<FutureOr>(null, PackageNames.DART).isAssignableFrom(object);
    }

    final clazz = object.getClass();
    return isAsync(clazz);
  }

  /// Checks whether the given [type] represents a generated proxy class.
  ///
  /// A proxy class in Jetleaf is identified by its name starting with
  /// the constant prefix defined in [Constant.PROXY_IDENTIFIER].
  ///
  /// - [type]: The [Class] object representing the type to check.
  /// 
  /// Returns `true` if the type's name starts with the proxy prefix,
  /// otherwise returns `false`.
  static bool isProxyClass(Class type) => type.getName().startsWith(Constant.PROXY_IDENTIFIER);

  /// Retrieves the original (non-proxied) [Class] representation for a given proxy type
  /// or instance within the Jetleaf runtime.
  ///
  /// This method is used to resolve the *real* class behind a generated proxy. It ensures
  /// that even when dealing with a proxied instance or type, Jetleaf can correctly
  /// identify and access the underlying class metadata for reflection, interception,
  /// and validation.
  ///
  /// The resolution logic follows this order:
  /// 1. **Instance check** – If [instance] is provided:
  ///    - If the instance is itself a proxy (`runtimeType` starts with
  ///      [Constant.PROXY_IDENTIFIER]) and implements [ClassGettable],
  ///      it directly returns `instance.toClass()`.
  ///    - Otherwise, if it’s a normal runtime object (not `"Type"` and not a proxy),
  ///      it resolves the class using its qualified name derived from
  ///      [ReflectionUtils.findQualifiedNameFromType].
  ///
  /// 2. **Static method check** – If no instance or proxy mapping is found,
  ///    it attempts to invoke the proxy’s static
  ///    [Constant.STATIC_REAL_CLASS_METHOD_NAME] (i.e., `getRealClass`)
  ///    to retrieve the original class reference.
  ///
  /// 3. **Fallback** – If neither of the above applies, it returns
  ///    the declared interface of [proxyClass] (if available), otherwise the
  ///    [proxyClass] itself.
  ///
  /// This method guarantees that Jetleaf always operates on the actual logical
  /// class definition, even when proxies are introduced for interception or lifecycle
  /// management.
  ///
  /// Example:
  /// ```dart
  /// final realClass = ClassUtils.getProxiedClass(proxyClass, instance);
  /// print('Resolved class: ${realClass.getName()}');
  /// ```
  static Class getProxiedClass(Class proxyClass, [Object? instance]) {
    _ensureInitialized();

    if (instance != null) {
      final string = instance.runtimeType.toString();

      if (string.startsWith(Constant.PROXY_IDENTIFIER) && instance is ClassGettable) {
        return instance.toClass();
      }

      if (string.notEqualsIgnoreCase("type") && !string.startsWith(Constant.PROXY_IDENTIFIER)) {
        return Class.fromQualifiedName(ReflectionUtils.findQualifiedNameFromType(instance.runtimeType));
      }
    }

    final method = proxyClass.getMethod(Constant.STATIC_REAL_CLASS_METHOD_NAME);
    if (method != null) {
      return method.invoke(null);
    }

    return proxyClass.getInterface() ?? proxyClass;
  }

  /// Checks whether a class with the given [name] exists and can be loaded.
  ///
  /// This attempts to resolve the class using `Class.fromQualifiedName(name)`.
  /// If the class is found, returns `true`. If any exception occurs (class not found,
  /// invalid name, etc.), returns `false`.
  ///
  /// Example:
  /// ```dart
  /// bool exists = Utils.isClass('dart.core.String'); // true
  /// bool missing = Utils.isClass('non.existent.Class'); // false
  /// ```
  static bool isClass(String name) {
    _ensureInitialized();

    try {
      Class.fromQualifiedName(name);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Attempts to resolve and load a [`Class`] instance from a given [object].
  ///
  /// This utility provides a unified way to dynamically convert different forms
  /// of class references — such as [`ClassType`], Dart [`Type`], or a qualified
  /// class name [`String`] — into a reflectable [`Class`] representation used
  /// within Jetleaf's type system.
  ///
  /// ### Resolution Rules
  ///
  /// The method evaluates the runtime type of [object] in the following order:
  ///
  /// 1. **[`ClassType`]** → Converts directly using [`ClassType.toClass()`].
  /// 2. **[`Type`]** → Resolved reflectively using [`data.getClass()`].
  /// 3. **[`String`]** → If recognized as a qualified class name (via
  ///    [`ClassUtils.isClass()`]), it is converted using
  ///    [`Class.fromQualifiedName()`].
  ///
  /// If [object] does not match any of these recognized types, or if the string
  /// is not a valid qualified class name, the method returns `null`.
  ///
  /// ### Example
  /// ```dart
  /// final c1 = ClassUtils.loadClass(ClassType<UserService>());
  /// final c2 = ClassUtils.loadClass(UserService);
  /// final c3 = ClassUtils.loadClass('package:app/services.dart.UserService');
  ///
  /// // All of the above yield equivalent Class representations.
  /// final c4 = ClassUtils.loadClass('userService'); // → null (not a class name)
  /// ```
  ///
  /// ### Returns
  /// A [`Class`] instance if successfully resolved, otherwise `null`.
  ///
  /// ### See Also
  /// - [`ClassUtils.getClass`] — Resolves from a Dart [Type].
  /// - [`ClassType`] — Type-safe wrapper used in annotation-based metadata.
  /// - [`Class.fromQualifiedName`] — Builds a [`Class`] from a qualified name.
  static Class? loadClass(Object object) {
    try {
      if (object is ClassType) {
        return object.toClass();
      } else if (object is Type) {
        return object.getClass();
      } else if (object is String && ClassUtils.isClass(object)) {
        return Class.fromQualifiedName(object);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  /// Checks whether the given [object] is of type `void`.
  ///
  /// This is useful when dealing with reflective method return types,
  /// to determine if a method returns `void` (i.e., does not return a value).
  ///
  /// ### Parameters
  /// - [object]: The object to inspect. Can be any value or `null`.
  ///
  /// ### Returns
  /// - `true` if the object represents a `void` return type (no value).
  /// - `false` otherwise.
  ///
  /// ### Example
  /// ```dart
  /// void doSomething() {}
  /// int sum(int a, int b) => a + b;
  ///
  /// print(ClassUtils.isVoid(doSomething())); // true
  /// print(ClassUtils.isVoid(sum(1, 2))); // false
  /// ```
  static bool isVoid(dynamic object) {
    try {
      final result = Class.forObject(object);
      return result.getType() == Void;
    } catch (_) {
      return true;
    }
  }
}
