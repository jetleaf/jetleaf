import 'package:jetleaf_build/jetleaf_build.dart';

import '../meta/method/method.dart';
import '../meta/parameter/parameter.dart';
import '../meta/protection_domain/protection_domain.dart';

/// {@template jet_method_utils}
/// Provides reflective utility functions for working with Jetleaf runtime
/// [Method] and [MethodDeclaration] instances.
///
/// This class centralizes common operations such as collecting annotated
/// methods and deduplicating them by identity, helping Jetleaf subsystems
/// like lifecycle management, annotation scanning, and component discovery
/// operate efficiently.
///
/// The static methods of [MethodUtils] are designed to be called by Jetleaf’s
/// internal processors, such as the `LifecycleRunListener`, without requiring
/// direct instantiation.
///
/// ### Example
/// ```dart
/// final annotatedMethods = <Method>{};
/// MethodUtils.collectMethods<OnApplicationReady>(annotatedMethods);
///
/// for (final method in annotatedMethods) {
///   print('Discovered lifecycle method: ${method.getName()}');
/// }
/// ```
///
/// The above example demonstrates scanning for all runtime methods annotated
/// with `@OnApplicationReady` and collecting them into a set for later
/// invocation by Jetleaf’s event system.
///
/// ### See also
/// - [Method]
/// - [ReflectableAnnotation]
/// - [Runtime]
/// - [ProtectionDomain]
/// {@endtemplate}
final class MethodUtils {
  /// {@template jet_method_utils_private_constructor}
  /// Initializes the [MethodUtils] utility by ensuring the global
  /// `_methodDeclarations` list is populated with all methods visible to
  /// the Jetleaf [Runtime].
  ///
  /// This constructor is private because the class exposes only static
  /// utilities; instantiation is not intended for external use.
  ///
  /// When first invoked, it calls `Runtime.getAllMethods()` and caches
  /// the resulting method declarations globally to avoid redundant
  /// reflection scans across Jetleaf components.
  ///
  /// ### Example
  /// ```dart
  /// // Not meant to be called directly; triggered implicitly when methods are collected.
  /// final _ = MethodUtils._();
  /// ```
  /// {@endtemplate}
  MethodUtils._();

  /// {@template jet_method_utils_collect_methods}
  /// Lazily collects all methods annotated with a Jetleaf annotation type `T`.
  ///
  /// This method performs a **single, streaming reflective traversal** over the
  /// globally cached list returned by [RuntimeProvider.getAllMethods]. Each method
  /// declaration is inspected for the presence of an annotation of type `T`
  /// (which must extend [ReflectableAnnotation]).
  ///
  /// Matching declarations are wrapped into Jetleaf [Method] instances using
  /// [Method.declared] and **yielded incrementally** as part of the returned
  /// [Iterable]. No intermediate collections are created.
  ///
  /// ### Deduplication
  ///
  /// Deduplication is performed **inline during iteration**. A method is yielded
  /// only once per traversal, identified by the combination of:
  ///
  /// ```text
  /// <declaring-class-qualified-name>#<method-name>
  /// ```
  ///
  /// This ensures stability in environments where reflective discovery may
  /// surface inherited, redeclared, or duplicated method declarations.
  ///
  /// ### Type Parameter
  /// - `T` — The annotation type extending [ReflectableAnnotation] to match.
  ///
  /// ### Returns
  /// An [Iterable] of unique [Method] instances annotated with `T`.
  /// The iterable is **lazy and single-use**: evaluation begins on first
  /// iteration and proceeds incrementally.
  ///
  /// ### Example
  /// ```dart
  /// for (final method in MethodUtils.collectMethods<OnApplicationStarted>()) {
  ///   invoke(method);
  /// }
  /// ```
  ///
  /// In this example, all methods annotated with `@OnApplicationStarted` are
  /// discovered and invoked without blocking or allocating intermediate lists.
  ///
  /// ### Performance Characteristics
  /// - Single reflective pass
  /// - No intermediate allocations
  /// - Deduplication performed during traversal
  /// - Safe against reflective resolution failures
  ///
  /// ### See also
  /// - [ReflectableAnnotation]
  /// - [Method.declared]
  /// - [ProtectionDomain]
  /// {@endtemplate}
  static Iterable<Method> collectMethods<T extends ReflectableAnnotation>([bool inJetleaf = true]) sync* {
    for (final method in Runtime.collectAnnotatedMethods<T>(inJetleaf)) {
      yield Method.declared(method, ProtectionDomain.current());
    }
  }

  /// Returns a list of method names that are considered *default* or
  /// *framework-intrinsic* and should typically be ignored when scanning
  /// for repository operations.
  ///
  /// These methods originate from `Object` or the Dart runtime and are not
  /// user-defined behaviors relevant to repository processing.
  ///
  /// ### Returned method names:
  /// - `"=="` – Equality operator
  /// - `"hashCode"` – Hash code getter
  /// - `"toString"` – String representation
  /// - `"noSuchMethod"` – Fallback for missing invocations
  /// - `"runtimeType"` – Reflective access to the object's type
  ///
  /// ### Use Cases
  /// - Filtering out non-repository methods when building repository
  ///   definitions.
  /// - Avoiding accidental interception of built-in Dart object methods.
  ///
  /// ### Example
  /// ```dart
  /// final ignored = getDefaultMethodNames();
  /// if (!ignored.contains(method.name)) {
  ///   processRepositoryMethod(method);
  /// }
  /// ```
  static List<String> getDefaultMethodNames() => [
    "==",
    "hashCode",
    "toString",
    "noSuchMethod",
    "runtimeType",
  ];

  /// Checks whether a set of arguments can be applied to a list of parameters.
  ///
  /// This method validates that all required parameters—both positional
  /// and named—are provided in the given [arguments] map. It does not
  /// perform type checking.
  ///
  /// ### Parameters
  /// - [arguments]: A map of parameter names to their corresponding values.
  /// - [parameters]: The list of [Parameter] objects representing the target
  ///   method or constructor signature.
  ///
  /// ### Returns
  /// `true` if all required parameters are present in [arguments]; otherwise `false`.
  ///
  /// ### Example
  /// ```dart
  /// final parameters = method.getParameters();
  /// final args = {'name': 'Alice', 'age': 30};
  ///
  /// if (MethodUtils.canAcceptArguments(args, parameters)) {
  ///   method.invoke(instance, args);
  /// }
  /// ```
  static bool canAcceptArguments(Map<String, dynamic> arguments, Iterable<Parameter> parameters) {
    // Check required positional parameters
    final positionalParams = parameters.where((p) => !p.isNamed());
    for (int i = 0; i < positionalParams.length; i++) {
      final param = positionalParams.elementAt(i);
      if (param.mustBeResolved() && !arguments.containsKey(param.getName())) {
        return false; // Required positional missing
      }
    }

    // Check required named parameters
    final namedParams = parameters.where((p) => p.isNamed());
    for (final param in namedParams) {
      if (param.mustBeResolved() && !arguments.containsKey(param.getName())) {
        return false; // Required named missing
      }
    }

    return true;
  }

  /// Checks whether a list of positional arguments can be applied to a method's
  /// positional parameters.
  ///
  /// Validates that the number of arguments satisfies the required and optional
  /// positional parameters.
  ///
  /// ### Parameters
  /// - [args]: List of runtime argument values.
  /// - [parameters]: List of [Parameter] objects representing the method's parameters.
  ///
  /// ### Returns
  /// `true` if the number of arguments is within the allowed range of required
  /// and optional positional parameters; otherwise `false`.
  ///
  /// ### Example
  /// ```dart
  /// final parameters = method.getParameters();
  /// final args = [1, 'hello'];
  ///
  /// if (MethodUtils.canAcceptPositionalArguments(args, parameters)) {
  ///   method.invokeWithArgs(instance, null, args);
  /// }
  /// ```
  static bool canAcceptPositionalArguments(List<dynamic> args, Iterable<Parameter> parameters) {
    final positionalParams = parameters.where((p) => !p.isNamed());
    final requiredPositionalCount = positionalParams.where((p) => p.mustBeResolved()).length;

    return args.length >= requiredPositionalCount && args.length <= positionalParams.length;
  }

  /// Checks whether a set of named arguments can be applied to a method's
  /// named parameters.
  ///
  /// Validates that all required named parameters are provided and ignores
  /// extra arguments.
  ///
  /// ### Parameters
  /// - [arguments]: Map of argument names to values.
  /// - [parameters]: List of [Parameter] objects representing the method's parameters.
  ///
  /// ### Returns
  /// `true` if all required named parameters are present in [arguments]; otherwise `false`.
  ///
  /// ### Example
  /// ```dart
  /// final parameters = method.getParameters();
  /// final args = {'count': 10, 'name': 'Alice'};
  ///
  /// if (MethodUtils.canAcceptNamedArguments(args, parameters)) {
  ///   method.invoke(instance, args);
  /// }
  /// ```
  static bool canAcceptNamedArguments(Map<String, dynamic> arguments, Iterable<Parameter> parameters) {
    final namedParams = parameters.where((p) => p.isNamed());

    for (final param in namedParams) {
      if (param.mustBeResolved() && !arguments.containsKey(param.getName())) {
        return false;
      }
    }

    return true;
  }
}