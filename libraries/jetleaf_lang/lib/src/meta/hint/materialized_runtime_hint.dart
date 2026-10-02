import 'package:jetleaf_build/jetleaf_build.dart';

import '../class/class.dart';
import '../class/class_gettable.dart';

/// {@template materialized_runtime_hint}
/// A **materialized runtime hint** that provides a concrete representation
/// of its target type `T` while allowing runtime behavior overrides.
///
/// `MaterializedRuntimeHint<T>` extends [AbstractRuntimeHint<T>] and implements
/// [ClassGettable<T>], combining the benefits of:
/// 
/// 1. **Generic runtime hints** – type-specific hooks for instance creation,
///    method invocation, and field access.
/// 2. **Materialization** – ability to expose type metadata through `Class<T>`,
///    which can be used for reflective-like behavior or optimized runtime logic.
///
///
/// ## Features
///
/// - **Materialized Type Representation**
///   - `toClass()` returns a `Class<T>` representing the type `T`.
///   - `obtainTypeOfRuntimeHint()` returns the original type via `toClass().getOriginal()`.
///
/// - **Default Behavior**
///   - Inherits all default no-op runtime hint behaviors from
///     [AbstractRuntimeHint], e.g., `createNewInstance`, `invokeMethod`,
///     `getFieldValue`, and `setFieldValue`.
///
/// - **Equality**
///   - Overrides `equalizedProperties()` to include both the materialized
///     class and the runtime type, ensuring consistent equality checks
///     between hints.
///
///
/// ## Use Cases
///
/// - Providing **type-aware runtime adapters** in Jetleaf.
/// - Lightweight **instrumentation** or **profiling** hooks that need access
///   to the target type.
/// - Building **compile-time optimized runtime hints** with full knowledge
///   of `T`.
///
///
/// ## Example
///
/// ```dart
/// // Suppose we have a domain model:
/// class User {
///   final String name;
///   final bool isAdmin;
/// 
///   User(this.name, {this.isAdmin = false});
/// }
///
/// // We can create a materialized runtime hint for User:
/// class UserHint extends MaterializedRuntimeHint<User> {
///   @override
///   Hint getFieldValue(User instance, String fieldName) {
///     if (fieldName == 'isAdmin') {
///       // Override the isAdmin field dynamically
///       return Hint.executed(true);
///     }
///     return super.getFieldValue(instance, fieldName);
///   }
/// }
///
/// void main() {
///   final user = User('Alice');
///   final hint = UserHint();
///
///   // Accessing the type metadata
///   print(hint.toClass()); // Class<User>
///   print(hint.obtainTypeOfRuntimeHint()); // User
///
///   // Using the runtime hint to intercept a field
///   final adminValue = hint.getFieldValue(user, 'isAdmin');
///   print(adminValue.value); // true
/// }
/// ```
///
/// ## See Also
/// - [AbstractRuntimeHint]
/// - [RuntimeHint]
/// - [Class]
/// - [ClassGettable]
/// {@endtemplate}
@Generic(MaterializedRuntimeHint)
abstract class MaterializedRuntimeHint<T> extends AbstractRuntimeHint<T> implements ClassGettable<T> {
  /// Creates a new materialized runtime hint for type [T].
  ///
  /// {@macro materialized_runtime_hint}
  const MaterializedRuntimeHint();

  @override
  Type obtainTypeOfRuntimeHint() {
    try {
      return toClass().getOriginal();
    } catch (_) { // Just in case the runtime has not been initialized
      return T;
    }
  }

  @override
  Class<T> toClass() => Class<T>();

  @override
  List<Object?> equalizedProperties() {
    try {
      return [toClass().equalizedProperties(), obtainTypeOfRuntimeHint()];
    } catch (_) { // Just in case the runtime has not been initialized
      return [MaterializedRuntimeHint, AbstractRuntimeHint, obtainTypeOfRuntimeHint()];
    }
  }
}