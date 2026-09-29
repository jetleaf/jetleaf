import 'package:jetleaf_build/jetleaf_build.dart';

import '../protection_domain/protection_domain.dart';
import '../../commons/version.dart';
import '../class/class.dart';
import '../core.dart';
import '../field/field.dart';

part '_enum_value.dart';

/// {@template enum_value}
/// Represents a single value within an enum type, providing full reflective
/// access to its metadata, declaration details, and runtime behavior.
///
/// This interface abstracts enum value inspection, including:
/// - Declaring enum type access
/// - Field-level metadata such as annotations, documentation, and modifiers
/// - Source position within the enum
/// - Nullability and value extraction
///
/// ## Key Features
/// - Retrieve the declaring enum class
/// - Inspect the enum field declaration (annotations, docs, modifiers)
/// - Determine the positional index of the enum value
/// - Reflectively read the enum value at runtime
/// - Nullability checking
///
/// ## Implementation Notes
/// Concrete implementations typically wrap analyzer- or mirror-based metadata
/// to unify enum reflection across build-time and runtime environments.
/// {@endtemplate}
abstract final class EnumValue extends PermissionManager {
  /// Gets the class that declares this enum value.
  ///
  /// {@template method_declaring_class}
  /// Type Parameters:
  /// - `D`: The expected declaring class type
  ///
  /// Returns:
  /// - The [Class<D>] representing the enum in which this value is defined
  ///
  /// Example:
  /// ```dart
  /// final declaring = value.getDeclaringClass<MyEnum>();
  /// print(declaring.getName()); // "MyEnum"
  /// ```
  /// {@endtemplate}
  Class<D> getDeclaringClass<D>();

  /// Gets the type declaration metadata for the declaring enum.
  ///
  /// {@macro class_get_declaration}
  EnumDeclaration getDeclaration();

  /// Gets the field declaration metadata associated with this enum value.
  ///
  /// {@template enum_value_get_field_declaration}
  /// Returns:
  /// - An [EnumFieldDeclaration] representing the field that defines this
  ///   enum value in source code.
  ///
  /// The returned declaration contains:
  /// - Documentation comments
  /// - Annotations
  /// - Source file location
  /// - Modifiers (e.g., `const`)
  /// - The exact identifier used in the enum declaration
  ///
  /// ## Example
  /// ```dart
  /// enum MyEnum {
  ///   /// Documentation for entry A
  ///   @SomeAnnotation()
  ///   A,
  ///   B,
  /// }
  ///
  /// final value = MyEnum.A.reflect();
  /// final field = value.getFieldDeclaration();
  ///
  /// print(field.getName());          // "A"
  /// print(field.annotations.length); // 1
  /// print(field.documentation);      // "Documentation for entry A"
  /// ```
  ///
  /// ## Notes
  /// - This always corresponds to the actual enum field in the source.
  /// - Never returns `null`; all enum values originate from a field.
  /// {@endtemplate}
  EnumFieldDeclaration getFieldDeclaration();

  /// The position of this enum value as declared in the enum class.
  ///
  /// Returns:
  /// - A zero-based index representing this value's order in the enum.
  ///
  /// Notes:
  /// - Must never be `-1`.
  /// - Reflects the exact source order in the enum declaration.
  int getPosition();

  /// Returns `true` if the enum value's type is nullable.
  ///
  /// ## Example
  /// ```dart
  /// final fields = annotation.getFields();
  /// print(fields.map((f) => f.isNullable())); // [true]
  /// ```
  bool isNullable();

  /// Gets the enum's concrete runtime value.
  ///
  /// {@macro field_get_value}
  dynamic getValue();

    /// Gets the declared name of the source.
  ///
  /// {@template source_get_name}
  /// Returns:
  /// - The source name as declared in source
  /// - Empty string for positional parameters
  /// - The method name as declared in source
  /// - Includes getter/setter prefixes when applicable
  /// - The constructor name as declared in source
  /// - Empty string for default unnamed constructors
  /// - The simple type name (e.g., `String`, `List<int>`)
  /// - May include generic parameters when available
  ///
  /// Example: - Class
  /// ```dart
  /// Class.forType<Map<String, int>>().getName(); // 'Map<String, int>'
  /// ```
  ///
  /// Examples: - Constructor
  /// - `''` for `ClassName()`
  /// - `'fromJson'` for `ClassName.fromJson()`
  ///
  /// Examples: - Method
  /// - `'toString'`
  /// - `'operator=='`
  /// - `'get length'` (for getters)
  /// - `'set items'` (for setters)
  ///
  /// Examples: - Parameter
  /// ```dart
  /// void method(String param1, {int param2}) {}
  /// // getName() returns:
  /// // '' for param1 (positional)
  /// // 'param2' for named param
  /// ```
  /// {@endtemplate}
  String getName();

  /// Gets the executable signature as a string.
  ///
  /// {@template executable_signature}
  /// Format includes:
  /// - Return type (if known)
  /// - Name
  /// - Parameter list with types
  /// - Optional/required markers
  ///
  /// Example outputs:
  /// - `void print(String message)`
  /// - `Map<String, int>.fromEntries(Iterable<MapEntry<String, int>> entries)`
  /// - `{required int timeout, bool retry = false}`
  /// {@endtemplate}
  String getSignature();

  /// Creates a reflective [EnumValue] from its declaration metadata.
  ///
  /// {@template enum_value_declared}
  /// This factory is used internally by Jetleaf’s reflection system to create
  /// runtime representations of enum values based on:
  ///
  /// - The containing enum’s declaration metadata  
  /// - The specific field declaration representing the enum entry  
  /// - An optional [ProtectionDomain] describing security/visibility constraints  
  ///
  /// ## Parameters
  /// - [declaration]: The [EnumDeclaration] describing the enum type.
  /// - [field]: The [EnumFieldDeclaration] describing the specific enum value.
  /// - [pd] *(optional)*: A [ProtectionDomain] used to enforce access rules.
  ///
  /// ## Returns
  /// - A concrete implementation of [EnumValue] that connects the enum’s
  ///   structural metadata with the field that created this value.
  ///
  /// ## Example
  /// ```dart
  /// final enumDecl = Class.forType<MyEnum>().getDeclaration();
  /// final field = enumDecl.getField('A');
  ///
  /// final value = EnumValue.declared(enumDecl, field);
  ///
  /// print(value.getDeclaringClass().getName()); // "MyEnum"
  /// print(value.getFieldDeclaration().getName()); // "A"
  /// print(value.getPosition()); // index of A
  /// ```
  ///
  /// ## Notes
  /// - This is the primary constructor used when enumerating enum values
  ///   via reflection.
  /// - Protection domains allow you to restrict access when reflection is
  ///   executed under different security contexts.
  /// {@endtemplate}
  factory EnumValue.declared(EnumDeclaration declaration, EnumFieldDeclaration field, [ProtectionDomain? pd]) = _EnumValue;
}