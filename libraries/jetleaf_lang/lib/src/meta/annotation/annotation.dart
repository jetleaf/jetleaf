import 'dart:collection';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../../commons/version.dart';
import '../../exceptions.dart';
import '../../utils/lang_utils.dart';
import '../class/class.dart';
import '../field/field.dart';
import '../core.dart';
import '../protection_domain/protection_domain.dart';

part '_annotation.dart';

/// {@template annotation_interface}
/// Provides reflective access to annotations applied to declarations.
///
/// This interface abstracts annotation metadata access, allowing inspection of:
/// - Annotation types and signatures
/// - Field values (both user-provided and defaults)
/// - Protection domains
/// - Actual annotation instances
///
/// {@template annotation_interface_features}
/// ## Key Features
/// - Type-safe field value access
/// - Distinction between default and user-provided values
/// - Protection domain awareness
/// - Full metadata inspection
/// - Instance retrieval when available
///
/// ## Implementation Notes
/// Concrete implementations typically wrap platform-specific reflection objects
/// while providing this uniform interface.
/// {@endtemplate}
///
/// {@template annotation_interface_example}
/// ## Example Usage
/// ```dart
/// // Get annotation from a reflected method
/// final annotation = method.getAnnotation<JsonSerializable>();
///
/// // Inspect field values
/// final explicitNulls = annotation?.getFieldValueAs<bool>('explicitToNull');
/// final fieldRename = annotation?.getFieldValue('fieldRename');
///
/// // Check value sources
/// if (annotation?.hasUserProvidedValue('constructor')) {
///   print('Custom constructor specified');
/// }
///
/// // Get all configured values
/// final allValues = annotation?.getAllFieldValues();
/// ```
/// {@endtemplate}
/// {@endtemplate}
abstract final class Annotation extends PermissionManager implements FieldAccess {
  /// Gets the class metadata of the annotation type.
  ///
  /// {@template annotation_get_class}
  /// Returns:
  /// - A [Class] instance representing the annotation's type
  ///
  /// Example:
  /// ```dart
  /// final clazz = annotation.getClass();
  /// print('Annotation type: ${clazz.name}');
  /// ```
  /// {@endtemplate}
  Class getDeclaringClass();

  @Deprecated("This api is deprecated and will be removed in newer versions. Use `getDeclaringClass`")
  Class getClass();

  /// Gets the declaration metadata associated with this annotation.
  ///
  /// {@template annotation_get_declaration}
  /// Returns the full [AnnotationDeclaration] that describes how this
  /// annotation was written in source code, including:
  ///
  /// - The annotation’s constructor and arguments
  /// - Source location (file, line, column)
  /// - Documentation comments (if any)
  /// - Modifiers
  /// - The fully qualified type of the annotation
  ///
  /// This declaration corresponds **exactly** to the annotation expression
  /// appearing in the source. It does **not** evaluate or instantiate the
  /// annotation; for the runtime instance, use:
  ///
  /// ```dart
  /// final instance = annotation.getInstance();
  /// ```
  ///
  /// ## Example
  /// ```dart
  /// @Route(path: "/home")
  /// class HomeController {}
  ///
  /// final clazz = Class.forType<HomeController>();
  /// final annotation = clazz.getAnnotations().first;
  ///
  /// final decl = annotation.getDeclaration();
  ///
  /// print(decl.getName());          // "Route"
  /// print(decl.getArguments());     // {"path": "/home"}
  /// print(decl.sourceFile);         // e.g., ".../home_controller.dart"
  /// print(decl.documentation);      // checks docs on the annotation constructor
  /// ```
  ///
  /// ## Notes
  /// - Always returns a declaration; annotations are guaranteed to originate
  ///   from a concrete annotation expression.
  /// - Use this method when you need metadata for tooling, analyzers,
  ///   documentation generation, or static-structure inspection.
  /// - To reflect on the annotation’s type itself, use:
  ///   ```dart
  ///   final annotationClass = decl.getClass();
  ///   ```
  /// {@endtemplate}
  AnnotationDeclaration getDeclaration();

  /// Gets the runtime type of the annotation.
  ///
  /// {@template annotation_get_type}
  /// Returns:
  /// - The runtime type of the annotation
  ///
  /// Example:
  /// ```dart
  /// final type = annotation.getType();
  /// print('Annotation type: $type');
  /// ```
  /// {@endtemplate}
  Type getType();

  /// {@template annotation_matcher.matches}
  /// Checks whether this annotation instance matches the type parameter [A].
  ///
  /// This is typically used to determine if a particular annotation is present
  /// on a class, method, or field, and if it can be treated as type [A].
  ///
  /// ### Example:
  /// ```dart
  /// @SomeAnnotation()
  /// class MyClass {}
  ///
  /// final annotation = getAnnotation(MyClass);
  /// if (annotation.matches<SomeAnnotation>()) {
  ///   // Do something with the annotation
  /// }
  /// ```
  ///
  /// @return `true` if this annotation is of type [A], `false` otherwise.
  /// {@endtemplate}
  bool matches<A>([Class<A>? type]);

  // ---------------------------------------------------------------------------------------------------------
  // === Field Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Gets all field names declared on this annotation.
  ///
  /// {@template annotation_field_names}
  /// Returns:
  /// - A list of all field names (both default and user-provided values)
  ///
  /// Example:
  /// ```dart
  /// for (final field in annotation.getFieldNames()) {
  ///   print('Field: $field');
  /// }
  /// ```
  /// {@endtemplate}
  List<String> getFieldNames();

  /// Gets the value of a field by name.
  ///
  /// {@template annotation_get_field}
  /// Parameters:
  /// - [fieldName]: The name of the field to retrieve
  ///
  /// Returns:
  /// - The field value (user-provided or default)
  /// - `null` if the field doesn't exist
  ///
  /// Example:
  /// ```dart
  /// final value = annotation.getFieldValue('priority');
  /// ```
  /// {@endtemplate}
  dynamic getFieldValue(String fieldName);

  /// Gets a field value with type conversion.
  ///
  /// {@template annotation_get_typed_field}
  /// Type Parameters:
  /// - `T`: The expected return type
  ///
  /// Parameters:
  /// - [fieldName]: The name of the field to retrieve
  ///
  /// Returns:
  /// - The field value cast to type `T`
  /// - `null` if the field doesn't exist or can't be cast
  ///
  /// Example:
  /// ```dart
  /// final priority = annotation.getFieldValueAs<int>('priority');
  /// ```
  /// {@endtemplate}
  T? getFieldValueAs<T>(String fieldName);

  /// Checks if a field exists on this annotation.
  ///
  /// {@template annotation_has_field}
  /// Parameters:
  /// - [fieldName]: The field name to check
  ///
  /// Returns:
  /// - `true` if the annotation declares this field
  /// - `false` otherwise
  /// {@endtemplate}
  bool hasField(String fieldName);

  /// Checks if a field has a user-provided value.
  ///
  /// {@template annotation_user_provided}
  /// Parameters:
  /// - [fieldName]: The field name to check
  ///
  /// Returns:
  /// - `true` if the field was explicitly set
  /// - `false` if using the default value
  ///
  /// Example:
  /// ```dart
  /// if (annotation.hasUserProvidedValue('name')) {
  ///   print('Name was explicitly configured');
  /// }
  /// ```
  /// {@endtemplate}
  bool hasUserProvidedValue(String fieldName);

  /// Checks if a field has a default value.
  ///
  /// {@template annotation_default_value}
  /// Parameters:
  /// - [fieldName]: The field name to check
  ///
  /// Returns:
  /// - `true` if the field has a declared default
  /// - `false` if the value was user-provided
  /// {@endtemplate}
  bool hasDefaultValue(String fieldName);

  /// Gets the default value of a field.
  ///
  /// {@template annotation_get_default}
  /// Parameters:
  /// - [fieldName]: The field name to retrieve
  ///
  /// Returns:
  /// - The field's default value
  /// - `null` if no default exists
  ///
  /// See also:
  /// - [hasDefaultValue] to check for defaults
  /// {@endtemplate}
  dynamic getDefaultValue(String fieldName);

  /// Gets the user-provided value of a field.
  ///
  /// {@template annotation_get_user_value}
  /// Parameters:
  /// - [fieldName]: The field name to retrieve
  ///
  /// Returns:
  /// - The explicitly configured value
  /// - `null` if using the default
  ///
  /// See also:
  /// - [hasUserProvidedValue] to check for explicit values
  /// {@endtemplate}
  dynamic getUserProvidedValue(String fieldName);

  /// Gets all user-provided values as a map.
  ///
  /// {@template annotation_user_values}
  /// Returns:
  /// - A map of only explicitly set field values
  /// - Empty map if no fields were configured
  ///
  /// Example:
  /// ```dart
  /// final config = annotation.getUserProvidedValues();
  /// ```
  /// {@endtemplate}
  Map<String, dynamic> getUserProvidedValues();

  /// Gets all field values (both user-provided and defaults).
  ///
  /// {@template annotation_all_values}
  /// Returns:
  /// - A complete map of all field values
  ///
  /// Example:
  /// ```dart
  /// final allValues = annotation.getAllFieldValues();
  /// ```
  /// {@endtemplate}
  Map<String, dynamic> getAllFieldValues();

  // ---------------------------------------------------------------------------------------------------------
  // === Instance Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Attempts to retrieve the actual annotation instance.
  ///
  /// {@template annotation_get_instance}
  /// Note: Availability depends on the reflection implementation.
  ///
  /// Returns:
  /// - The original annotation instance if available
  /// - `null` if instance access isn't supported
  ///
  /// Example:
  /// ```dart
  /// final instance = annotation.getInstance();
  /// if (instance is Deprecated) {
  ///   print(instance.message);
  /// }
  /// ```
  /// {@endtemplate}
  Instance getInstance<Instance>();

  /// Gets the annotation's signature string.
  ///
  /// {@template annotation_signature}
  /// The signature typically includes:
  /// - Annotation type
  /// - Field values
  /// - Protection domain
  ///
  /// Returns:
  /// - A string representation of the annotation
  ///
  /// Example output:
  /// `@JsonSerializable(explicitToNull: true, fieldRename: 'kebab')`
  /// {@endtemplate}
  String getSignature();

  /// {@template annotation_factory}
  /// Creates an [Annotation] instance from reflection metadata.
  ///
  /// Parameters:
  /// - [declaration]: The annotation reflection metadata
  /// - [domain]: The protection domain for security
  ///
  /// Returns:
  /// - A concrete [Annotation] implementation
  ///
  /// Typical implementations:
  /// ```dart
  /// static Annotation declared(AnnotationDeclaration d, ProtectionDomain p) {
  ///   return _AnnotationImpl(d, p);
  /// }
  /// ```
  /// {@endtemplate}
  factory Annotation.declared(AnnotationDeclaration declaration, ProtectionDomain domain) = _Annotation;
}