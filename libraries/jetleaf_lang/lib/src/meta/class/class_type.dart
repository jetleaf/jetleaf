import 'package:jetleaf_build/jetleaf_build.dart';

import 'class.dart';
import 'class_gettable.dart';
import '../protection_domain/protection_domain.dart';

/// Represents the reflective wrapper for Dart's built-in `Object` type.
///
/// This constant is the root of Dart's type hierarchy. Every class in Dart
/// implicitly extends `Object`, making this the universal supertype for all
/// non-nullable reference types.
///
/// The underlying mirror is `null` because `Object` is a built-in type that
/// does not require explicit class loading. It is registered under the
/// Dart core package namespace.
///
/// Typically used in:
/// - Type hierarchy resolution
/// - Supertype analysis
/// - Generic type constraints
final Class<Object> OBJECT_CLASS = Class<Object>(null, PackageNames.DART);

/// Represents the reflective wrapper for Dart's built-in `dynamic` type.
///
/// This constant is used internally by the reflection system whenever a
/// method, parameter, or field explicitly or implicitly declares a `dynamic`
/// type.  
///
/// Since `dynamic` does not correspond to an actual class at runtime,
/// this instance uses a `null` underlying mirror and is registered under the
/// build-system package namespace.
///
/// Typically used in:
/// - Method return-type resolution  
/// - Parameter type analysis  
/// - Dynamic invocation systems  
final Class<Dynamic> DYNAMIC_CLASS = Class<Dynamic>(null, PackageNames.BUILD);

/// Represents the reflective wrapper for Dart's `void` return type.
///
/// Unlike normal types, `void` is a compile-time type marker and does not
/// represent a concrete class.  
///
/// This placeholder `Class<Void>` instance allows the reflection system to
/// uniformly represent `void` return types in method metadata, type
/// resolution, and signature analysis.
///
/// It is used whenever a method declares:
/// ```dart
/// void foo() {}
/// ```
/// or, for asynchronous methods:
/// ```dart
/// Future<void> bar() async {}
/// ```
///
/// Like [DYNAMIC_CLASS], the underlying mirror is `null` because `void` is
/// not an instantiable runtime type.
final Class<Void> VOID_CLASS = Class<Void>(null, PackageNames.BUILD);

/// {@template class_type}
/// The `ClassType` class in **Jetleaf** represents a reference to a Dart
/// class, optionally including metadata such as package, protection domain,
/// or type declaration.
///
/// It provides a convenient way to convert a class reference into a [Class]
/// instance used by the Jetleaf framework for reflection, conditional
/// processing, or pod registration. ClassType serves as a bridge between
/// compile-time type information and runtime class metadata in Jetleaf's
/// type system infrastructure.
///
/// ### Key Features:
/// - Supports optional class [name], [package], [ProtectionDomain], and [ClassDeclaration].
/// - Can convert itself into a [Class] instance using [toClass].
/// - Integrates with Jetleaf's type system for dynamic class handling.
/// - Provides multiple factory constructors for flexible class reference creation.
/// - Supports equality and hash code operations for use in collections.
///
/// ### Usage Example:
/// ```dart
/// import 'package:jetleaf/jetleaf.dart';
///
/// // Create a ClassType by name
/// final simpleClass = ClassType(name: 'UserService');
///
/// // Convert to a Jetleaf Class instance
/// final userClass = simpleClass.toClass();
///
/// // Create a ClassType with a ClassDeclaration
/// final declaredClass = ClassType(declaration: someTypeDeclaration);
/// final declaredClassInstance = declaredClass.toClass();
///
/// // Use in pod registration
/// @Pod
/// class ServiceConfiguration {
///   @Provide
///   UserService userService() => UserService();
///
///   @Provide
///   ClassType<UserService> userServiceType() => ClassType<UserService>();
/// }
/// ```
/// {@endtemplate}
@Generic(ClassType)
class ClassType<T> with EqualsAndHashCode implements ClassGettable {
  /// {@template class_type_name}
  /// The simple name of the class.
  ///
  /// Optional. If not provided, the [toClass] method will use the declaration
  /// or create a generic class instance. The name should match the actual
  /// class name as declared in Dart source code.
  ///
  /// ## Example
  /// ```dart
  /// final classType = ClassType(name: 'UserService');
  /// ```
  /// {@endtemplate}
  final String? name;

  /// {@template class_type_package}
  /// The package the class belongs to, if any.
  ///
  /// Optional. Used by [toClass] to resolve the fully qualified class name.
  /// This should follow Dart's package URI format (e.g., 'package:example/services').
  ///
  /// ## Example
  /// ```dart
  /// final classType = ClassType(
  ///   name: 'UserService',
  ///   package: 'package:example/services'
  /// );
  /// ```
  /// {@endtemplate}
  final String? package;

  /// {@template class_type_pd}
  /// The [ProtectionDomain] associated with this class reference.
  ///
  /// If not provided, defaults to [ProtectionDomain.current] when calling [toClass].
  /// The protection domain controls access permissions and security context
  /// for class loading and reflection operations.
  ///
  /// ## Example
  /// ```dart
  /// final secureDomain = ProtectionDomain.secure();
  /// final classType = ClassType(
  ///   name: 'SecureService',
  ///   pd: secureDomain
  /// );
  /// ```
  /// {@endtemplate}
  final ProtectionDomain? pd;

  /// {@template class_type_declaration}
  /// Optional [ClassDeclaration] that represents the class declaration.
  ///
  /// If provided, [toClass] will use this declaration to create a [Class]
  /// instance. This is the most precise way to reference a class as it
  /// includes complete declaration metadata.
  ///
  /// ## Example
  /// ```dart
  /// final declaration = ClassDeclaration.from(UserService);
  /// final classType = ClassType(declaration: declaration);
  /// ```
  /// {@endtemplate}
  final ClassDeclaration? declaration;

  /// {@template class_type_qualifiedName}
  /// Contains the full URI of the class with the class name.
  ///
  /// This follows the format: `package:example/src/user.dart.User`
  /// where the URI points to the source file and includes the class name.
  /// This provides complete location information for the class definition.
  ///
  /// ## Example
  /// ```dart
  /// final classType = ClassType.qualified(
  ///   'package:example/services/user_service.dart.UserService'
  /// );
  /// ```
  /// {@endtemplate}
  final String? qualifiedName;

  /// {@macro class_type}
  ///
  /// Creates a ClassType with optional components for flexible class referencing.
  ///
  /// @param package The package URI containing the class
  /// @param name The simple name of the class
  /// @param pd The protection domain for class access
  /// @param declaration The type declaration metadata
  /// @param qualifiedName The fully qualified class name with URI
  const ClassType([this.package, this.name, this.pd, this.declaration, this.qualifiedName]);

  /// {@template class_type_fromQualifiedName}
  /// Creates a ClassType from a fully qualified class name.
  ///
  /// This constructor is ideal when you have complete location information
  /// for a class, including both package URI and class name in a single string.
  ///
  /// ## Example
  /// ```dart
  /// final classType = ClassType.qualified(
  ///   'package:example/services/user_service.dart.UserService'
  /// );
  /// ```
  ///
  /// @param qualifiedName The fully qualified class name with URI
  /// @param name Optional simple class name (extracted from qualifiedName if not provided)
  /// @param pd Optional protection domain
  /// @param declaration Optional type declaration
  /// @param package Optional package URI (extracted from qualifiedName if not provided)
  /// {@endtemplate}
  const ClassType.qualified(this.qualifiedName, [this.name, this.pd, this.declaration, this.package]);

  /// {@template class_type_fromDeclaration}
  /// Creates a ClassType from a ClassDeclaration.
  ///
  /// This constructor provides the most precise class reference by using
  /// complete declaration metadata. It's ideal for scenarios where exact
  /// type information is required.
  ///
  /// ## Example
  /// ```dart
  /// final declaration = ClassDeclaration.from(UserService);
  /// final classType = ClassType.declared(declaration);
  /// ```
  ///
  /// @param declaration The type declaration metadata
  /// @param qualifiedName Optional fully qualified name
  /// @param name Optional simple class name
  /// @param pd Optional protection domain
  /// @param package Optional package URI
  /// {@endtemplate}
  const ClassType.declared(this.declaration, [this.qualifiedName, this.name, this.pd, this.package]);

  /// {@template class_type_fromName}
  /// Creates a ClassType from a class name and package.
  ///
  /// This constructor is convenient when you know the class name and its
  /// package location but don't have complete declaration metadata.
  ///
  /// ## Example
  /// ```dart
  /// final classType = ClassType.named(
  ///   'UserService',
  ///   'package:example/services'
  /// );
  /// ```
  ///
  /// @param name The simple name of the class
  /// @param package The package URI containing the class
  /// @param qualifiedName Optional fully qualified name
  /// @param pd Optional protection domain
  /// @param declaration Optional type declaration
  /// {@endtemplate}
  const ClassType.named(this.name, this.package, [this.qualifiedName, this.pd, this.declaration]);

  /// {@template class_type_toClass}
  /// Converts this [ClassType] into a [Class] instance for use by Jetleaf.
  ///
  /// This method resolves the class reference into a concrete [Class] instance
  /// that can be used for reflection, method invocation, and other runtime
  /// operations. The resolution follows a specific priority order to ensure
  /// the most precise class information is used.
  ///
  /// ### Resolution order:
  /// 1. If [declaration] is provided → returns `Class.declared(declaration, pd)`.
  /// 2. Else if [name] is provided → returns `Class.forName(name, pd, package)`.
  /// 3. Else if [qualifiedName] is provided → returns `Class.fromQualifiedName(qualifiedName)`.
  /// 4. Otherwise → returns a generic `Class<T>` with the resolved [ProtectionDomain].
  ///
  /// ### Example:
  /// ```dart
  /// void demonstrateClassResolution() {
  ///   // From declaration (most precise)
  ///   final fromDecl = ClassType.declared(UserService).toClass();
  ///
  ///   // From name and package
  ///   final named = ClassType.named('UserService', 'example').toClass();
  ///
  ///   // From qualified name
  ///   final fromQualified = ClassType.qualified('package:example/services.dart.UserService').toClass();
  ///
  ///   // Generic type parameter
  ///   final fromGeneric = ClassType<UserService>().toClass();
  /// }
  /// ```
  ///
  /// @return A [Class<T>] instance representing the referenced class
  /// @throws ClassNotFoundException if the class cannot be resolved
  /// {@endtemplate}
  @override
  Class<T> toClass() {
    if (declaration != null) {
      return Class<T>.declared(declaration!, pd ?? ProtectionDomain.current());
    }

    if (name != null) {
      return Class.forName<T>(name!, pd ?? ProtectionDomain.current(), package);
    }

    if (qualifiedName != null) {
      return Class<T>.fromQualifiedName(qualifiedName!);
    }

    return Class<T>(pd ?? ProtectionDomain.current(), package);
  }

  /// {@template class_type_getType}
  /// Returns the compile-time generic type parameter [T] of this [ClassType].
  ///
  /// This method provides access to the generic type parameter at runtime,
  /// enabling type-safe operations and generic type resolution in Jetleaf's
  /// type system infrastructure.
  ///
  /// ### Example:
  /// ```dart
  /// void demonstrateTypeAccess() {
  ///   final classRef = ClassType<int>();
  ///   print(classRef.getType()); // int
  ///
  ///   final userClassRef = ClassType<UserService>();
  ///   print(userClassRef.getType()); // UserService
  /// }
  /// ```
  ///
  /// @return The runtime Type representation of the generic parameter T
  /// {@endtemplate}
  Type getType() {
    try {
      return toClass().getType();
    } on ClassNotFoundException catch (_) {
      return T;
    }
  }

  /// {@template class_type_equalizedProperties}
  /// Provides the properties used for equality comparison and hash code generation.
  ///
  /// This method is part of the EqualsAndHashCode mixin and defines which
  /// properties should be considered when comparing two ClassType instances
  /// for equality. Two ClassType instances are considered equal if their
  /// name, package, protection domain, and declaration qualified name match.
  ///
  /// @return List of properties to use for equality and hash code calculations
  /// {@endtemplate}
  @override
  List<Object?> equalizedProperties() => toClass().equalizedProperties();
}