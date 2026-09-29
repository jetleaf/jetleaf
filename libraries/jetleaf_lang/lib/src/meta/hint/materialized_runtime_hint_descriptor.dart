import 'package:jetleaf_build/jetleaf_build.dart';

import '../../collections/array_list.dart';
import '../../extensions/primitives/iterable.dart';
import '../../synchronized/synchronized.dart';
import '../class/class.dart';
import 'materialized_runtime_hint.dart';

/// {@template materialized_runtime_hint_descriptor}
/// A **type-aware runtime hint manager** that maintains a collection of
/// [RuntimeHint] instances and provides mechanisms for **retrieving hints
/// based on type, class, or instance**.  
///
/// `MaterializedRuntimeHintDescriptor` is designed to handle both standard
/// [RuntimeHint] objects and [MaterializedRuntimeHint]s, which provide
/// explicit type metadata via `Class<T>`. This allows for **efficient,
/// type-safe runtime hint resolution** without relying on reflection at every
/// operation.
///
/// The class ensures **thread-safe modifications** to its internal collection,
/// making it suitable for concurrent runtime environments.
///
/// ## Fields
///
/// ### `_hints`
/// ```dart
/// final ArrayList<RuntimeHint> _hints = ArrayList<RuntimeHint>();
/// ```
/// - **Description:**  
///   Stores all runtime hints registered with this descriptor. Both
///   standard [RuntimeHint] and [MaterializedRuntimeHint] instances are
///   included here.  
/// - **Type:** [ArrayList]<[RuntimeHint]>  
/// - **Access & Safety:**  
///   Access to `_hints` is synchronized whenever hints are added or modified
///   to prevent race conditions in multithreaded environments.  
/// - **Usage:**  
///   Internal collection used by methods like [getHint] to resolve the
///   appropriate hint for a given instance, type, or class.
///
/// ## Behavior Overview
///
/// - **Adding Hints:**  
///   Uses `synchronized` to remove duplicates and append the new hint.  
/// - **Retrieving Hints:**  
///   `getHint<T>` resolves hints in the following priority:  
///   1. Exact match with `MaterializedRuntimeHint.toClass()`  
///   2. Assignable match (superclass or interface)  
///   3. Exact match by type from `obtainTypeOfRuntimeHint()`  
///   4. Assignable match by type  
///   5. Fallback to the generic type `T` if no other match is found  
/// - **Iteration:**  
///   Provides an iterator over all registered hints via the `iterator`
///   property.
///
/// ## Design Considerations
///
/// - By differentiating between **materialized** and **generic** hints, the
///   descriptor allows **optimized runtime behavior** for known types.
/// - Thread-safety ensures that hints can be added or updated dynamically
///   without corrupting the collection.
/// - Supports Jetleaf’s **hint-driven execution model**, allowing runtime
///   behaviors (field access, method invocation, instance creation) to be
///   overridden selectively and safely.
///
/// ## See Also
/// - [RuntimeHintDescriptor] – the base interface defining hint management.
/// - [MaterializedRuntimeHint] – type-aware runtime hints with materialized
///   class information.
/// - [RuntimeHint] – base class for runtime behavior overrides.
/// {@endtemplate}
final class MaterializedRuntimeHintDescriptor extends RuntimeHintDescriptor {
  /// Internal, synchronized list of all runtime hints.
  /// 
  /// This collection includes both standard [RuntimeHint] and
  /// [MaterializedRuntimeHint] instances, and is accessed in a
  /// thread-safe manner whenever hints are added or modified.
  final ArrayList<RuntimeHint> _hints = ArrayList<RuntimeHint>();

  /// {@macro materialized_runtime_hint_descriptor}
  MaterializedRuntimeHintDescriptor();

  @override
  void addHint(RuntimeHint hint) => synchronized(_hints, () {
    _hints.remove(hint);
    _hints.add(hint);
  });

  @override
  RuntimeHint? getHint<T>({Object? instance, Type? type}) {
    final classedHints = _hints.whereType<MaterializedRuntimeHint>();
    final resolvedType = type ?? (instance?.runtimeType != Type ? instance.runtimeType : instance) ?? T;
    final targetClass = _getTargetClass<T>(instance, type) ?? (instance?.runtimeType != Type ? _fromType(instance.runtimeType) : null);

    if (targetClass case final targetClass?) {
      return
        classedHints.firstWhereOrNull((h) => h.toClass() == targetClass) ??
        classedHints.firstWhereOrNull((h) => h.toClass().isAssignableFrom(targetClass)) ??
        _hints.firstWhereOrNull((h) => Class.forType(h.obtainTypeOfRuntimeHint()) == targetClass) ??
        _hints.firstWhereOrNull((h) => Class.forType(h.obtainTypeOfRuntimeHint()).isAssignableFrom(targetClass)) ??
        _hints.firstWhereOrNull((h) => h.obtainTypeOfRuntimeHint() == resolvedType);
    }

    return
      classedHints.firstWhereOrNull((h) => h.toClass().getType() == resolvedType) ??
      classedHints.firstWhereOrNull((h) => h.toClass().getOriginal() == resolvedType) ??
      _hints.firstWhereOrNull((h) => Class.forType(h.obtainTypeOfRuntimeHint()).getType() == resolvedType) ??
      _hints.firstWhereOrNull((h) => Class.forType(h.obtainTypeOfRuntimeHint()).getOriginal() == resolvedType) ??
      _hints.firstWhereOrNull((h) => h.obtainTypeOfRuntimeHint() == resolvedType);
  }

  Class? _getTargetClass<T>(Object? instance, Type? type) {
    try {
      return switch ((instance, type)) {
        (Class c?, _) => c,
        (_, Type t?) => _fromType(t) ?? (instance != null ? _fromObject(instance) : null),
        (Object o?, _) => _fromObject(o),
        _ => Class.fromQualifiedName(ReflectionUtils.findQualifiedNameFromType(T)),
      } ?? Class.fromQualifiedName(ReflectionUtils.findQualifiedNameFromType(T));
    } on ClassNotFoundException catch (_) {
      return null;
    }
  }

  /// Attempts to resolve a [Class] instance from a given [Type].
  /// 
  /// This method is used internally by [getHint] to convert a runtime
  /// `Type` into a Jetleaf [Class] object, which represents the materialized
  /// type metadata.  
  /// 
  /// It uses [ReflectionUtils.findQualifiedNameFromType] to obtain the fully
  /// qualified name of the type and then constructs a [Class] via
  /// [Class.fromQualifiedName].
  ///
  /// If the type cannot be resolved (for example, if the class does not exist
  /// or cannot be found), this method catches a [ClassNotFoundException]
  /// and returns `null`, allowing [getHint] to fallback to other resolution
  /// strategies.
  ///
  /// ```dart
  /// final descriptor = MaterializedRuntimeHintDescriptor();
  /// Type myType = User;
  /// Class? clazz = descriptor._fromType(myType);
  /// print(clazz); // Class<User> if User exists, otherwise null
  /// ```
  ///
  /// **Returns:**  
  /// - [Class]? — the materialized class for the given type, or `null` if
  ///   resolution fails.
  Class? _fromType(Type t) {
    try {
      return Class.fromQualifiedName(ReflectionUtils.findQualifiedNameFromType(t));
    } on ClassNotFoundException {
      return null;
    }
  }

  /// Attempts to resolve a [Class] instance from a given object instance.
  ///
  /// This method is used internally by [getHint] to convert a runtime object
  /// into a Jetleaf [Class], by determining its runtime type and then
  /// materializing it.  
  ///
  /// It uses [ReflectionUtils.findQualifiedName] on the object and then
  /// constructs a [Class] via [Class.fromQualifiedName].
  ///
  /// If the class cannot be resolved (for example, if the object's type
  /// cannot be found), this method catches a [ClassNotFoundException]
  /// and returns `null`. This allows [getHint] to continue with alternative
  /// resolution strategies, such as using generic type `T`.
  ///
  /// ```dart
  /// final descriptor = MaterializedRuntimeHintDescriptor();
  /// final user = User('Alice');
  /// Class? clazz = descriptor._fromObject(user);
  /// print(clazz); // Class<User> if User exists, otherwise null
  /// ```
  ///
  /// **Returns:**  
  /// - [Class]? — the materialized class for the object instance, or `null`
  ///   if resolution fails.
  Class? _fromObject(Object o) {
    try {
      return Class.fromQualifiedName(ReflectionUtils.findQualifiedName(o));
    } on ClassNotFoundException {
      return null;
    }
  }

  @override
  Iterator<RuntimeHint> get iterator => _hints.iterator;
}