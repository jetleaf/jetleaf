import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';

/// {@template scopeMetadataResolver}
/// Strategy interface for resolving **scope metadata** for a given class in Jetleaf.
///
/// A `ScopeMetadataResolver` determines the lifecycle scope of a class type 
/// (such as `"singleton"`, `"prototype"`, `"request"`, etc.) during pod registration.
/// This allows the Jetleaf container to decide how and when instances of a class 
/// should be created and managed.
///
/// ### Key Features:
/// - Abstracts scope resolution away from pod registration logic.
/// - Enables custom resolution strategies (e.g., based on annotations, naming conventions).
/// - Centralized entry point for all scope-related decisions.
///
/// ### Example:
/// ```dart
/// final resolver = CustomScopeMetadataResolver();
/// final scope = resolver.resolve(Class<MyService>());
///
/// print(scope); // "singleton"
/// ```
///
/// Typically used in pod scanning and registration phases of the Jetleaf lifecycle.
/// {@endtemplate}
abstract interface class ScopeMetadataResolver {
  /// {@macro scopeMetadataResolver}
  const ScopeMetadataResolver();

  /// Resolves the scope metadata for the given [classType].
  ///
  /// - [classType] represents the runtime type to evaluate.
  /// - Returns a string that defines the lifecycle scope of the class.
  ///
  /// ### Common return values:
  /// - `"singleton"` → Single shared instance.
  /// - `"prototype"` → New instance per request.
  /// - `"request"` → One instance per HTTP request (if web-enabled).
  ///
  /// ### Example:
  /// ```dart
  /// final scope = resolver.resolve(Class<MyRepository>());
  /// assert(scope == "singleton");
  /// ```
  String resolve(Class classType);

  /// Resolves the scope descriptor for the given [classType].
  /// 
  /// - [classType] represents the runtime type to evaluate.
  /// - Returns a [ScopeDesign] that defines the lifecycle scope of the class.
  /// 
  /// ### Example:
  /// ```dart
  /// final scope = resolver.resolveScopeDescriptor(Class<MyRepository>());
  /// assert(scope == ScopeDescriptor(type: ScopeType.SINGLETON, isSingleton: true, isPrototype: false));
  /// ```
  ScopeDesign resolveScopeDescriptor(Class classType);
}