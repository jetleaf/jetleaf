import 'package:jetleaf_build/jetleaf_build.dart';

import 'class.dart';

/// {@template class_gettable}
/// Provides a contract for types capable of exposing their associated
/// runtime [Class] metadata representation within the Jetleaf reflection system.
///
/// The [ClassGettable] interface serves as a lightweight abstraction for
/// objects that can describe or resolve their own **type metadata** through
/// the [Class<T>] model. This pattern is central to Jetleaf’s **reflection
/// and dependency injection subsystem**, enabling runtime introspection,
/// metadata lookup, and type-safe dependency graph operations.
///
/// ### Purpose
/// The interface exists to unify access to type descriptors for both:
/// - **Concrete instances** (objects that can report their reflective type)
/// - **Meta-level objects** (such as factories, proxies, or providers that
///   represent or wrap a type)
///
/// By implementing [ClassGettable], any object can seamlessly participate
/// in Jetleaf’s reflection pipeline, allowing for:
/// - Automatic discovery of annotated classes
/// - Type-safe dependency injection lookups
/// - Interceptor resolution and method metadata analysis
///
/// ### Example
/// ```dart
/// class UserRepository implements ClassGettable<UserRepository> {
///   @override
///   Class<UserRepository> toClass() => Class.forType(UserRepository);
/// }
///
/// void main() {
///   final repo = UserRepository();
///   final clazz = repo.toClass();
///
///   print(clazz.getQualifiedName()); // prints "com.example.UserRepository"
/// }
/// ```
///
/// ### Typical Usage in Jetleaf
/// The interface is commonly used in:
/// - **AOP**: To locate metadata for method interception or annotation scanning.
/// - **IoC container**: To resolve and cache dependency metadata.
/// - **Runtime analysis tools**: To retrieve information about constructors,
///   fields, or annotations.
///
/// ### Related References
/// - [Class] — Core Jetleaf reflection type encapsulating metadata about a Dart class.
/// - [Method] — Metadata representation of class methods obtained via [Class.getMethods].
/// - [AnnotationMetadata] — Used in combination with [Class] for annotation-driven logic.
/// - [Reflectable] — Marker for types that participate in Jetleaf’s reflective ecosystem.
///
/// ### Notes
/// - Implementations **must not perform expensive reflection** in `toClass()`.
///   It should ideally return a cached or precomputed instance of [Class].
/// - The returned [Class] should correspond exactly to the generic type parameter `T`.
/// - Implementations are typically registered automatically by Jetleaf’s
///   class scanner during bootstrap.
/// {@endtemplate}
@Generic(ClassGettable)
abstract interface class ClassGettable<T> {
  /// {@macro class_gettable}
  ///
  /// Returns the [Class] metadata object representing the runtime
  /// type associated with this instance or meta-object.
  ///
  /// ### Returns
  /// A [Class<T>] descriptor that exposes reflection metadata for
  /// the type parameter `T`.
  ///
  /// ### Example
  /// ```dart
  /// final clazz = instance.toClass();
  /// print(clazz.getName()); // "UserService"
  /// ```
  ///
  /// ### See Also
  /// - [Class.forType] — Static helper to create a [Class] representation for any Dart type.
  /// - [Reflectable] — For objects designed to expose reflection-based operations.
  Class<T> toClass();
}