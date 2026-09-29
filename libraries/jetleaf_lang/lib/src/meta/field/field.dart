import 'package:jetleaf_build/jetleaf_build.dart';

import '../../commons/version.dart';
import '../../exceptions.dart';
import '../../utils/lang_utils.dart';
import '../core.dart';
import '../annotation/annotation.dart';
import '../class/class.dart';
import '../protection_domain/protection_domain.dart';

part '_field.dart';

/// {@template field_interface}
/// Provides reflective access to class field metadata and value manipulation.
///
/// This interface enables runtime inspection and modification of class fields,
/// including access to:
/// - Field types and declarations
/// - Modifiers (final, const, etc.)
/// - Value getters/setters
/// - Access permissions
///
/// {@template field_interface_features}
/// ## Key Features
/// - Type-safe field value access
/// - Modifier inspection
/// - Read/write permission checking
/// - Declaring class resolution
/// - Signature generation
///
/// ## Implementation Notes
/// Concrete implementations typically wrap platform-specific reflection objects
/// while providing this uniform interface.
/// {@endtemplate}
///
/// {@template field_interface_example}
/// ## Example Usage
/// ```dart
/// // Get field metadata
/// final nameField = userClass.getField('name');
///
/// // Inspect field properties
/// print('Field type: ${nameField.getType<String>().getName()}');
/// print('Is final: ${nameField.isFinal()}');
///
/// // Access field values
/// final currentName = nameField.getValue(userInstance);
/// nameField.setValue(userInstance, 'New Name');
/// ```
/// {@endtemplate}
/// {@endtemplate}
abstract final class Field extends Source implements Member {
  /// Gets the type of the field.
  ///
  /// {@template field_get_type}
  /// Returns:
  /// - The field type as a [Type]
  ///
  /// Example:
  /// ```dart
  /// final type = field.getType(); // Type
  /// ```
  /// {@endtemplate}
  Type getType();

  /// Returns the annotation field declaration if it is an annotation field declaration, otherwise null.
  /// 
  /// Used when we confidently know that the declaration is an annotation field declaration.
  /// 
  /// Example:
  /// ```dart
  /// final field = field.asAnnotation();
  /// ```
  AnnotationFieldDeclaration? asAnnotation();

  /// Returns the record field declaration if it is a record field declaration, otherwise null.
  /// 
  /// Used when we confidently know that the declaration is a record field declaration.
  /// 
  /// Example:
  /// ```dart
  /// final field = field.asRecord();
  /// ```
  RecordFieldDeclaration? asRecord();

  /// Returns the enum field declaration if it is an enum field declaration, otherwise null.
  /// 
  /// Used when we confidently know that the declaration is an enum field declaration.
  /// 
  /// Example:
  /// ```dart
  /// final field = field.asEnum();
  /// ```
  EnumFieldDeclaration? asEnum();

  /// The position of the enum value as-is in the enum class
  /// 
  /// Cannot be -1
  int getPosition();

  /// Returns true if the field is nullable.
  /// 
  /// ### Example
  /// ```dart
  /// final annotation = ...;
  /// final fields = annotation.getFields();
  /// print(fields.map((f) => f.isNullable())); // [true]
  /// ```
  bool isNullable();
  
  /// Checks if this field is static.
  ///
  /// {@template field_is_static}
  /// Returns:
  /// - `true` if declared with `static` modifier
  /// - `false` for instance fields
  ///
  /// Note:
  /// Static fields can be accessed with a null instance.
  /// {@endtemplate}
  bool isStatic();

  /// Checks if this field is a top-level field.
  ///
  /// {@template field_is_topLevel}
  /// Returns:
  /// - `true` if declared at the top level
  /// - `false` for fields declared in a class
  /// {@endtemplate}
  bool isTopLevel();
  
  /// Checks if this field is final.
  ///
  /// {@template field_is_final}
  /// Returns:
  /// - `true` if declared with `final` modifier
  /// - `false` otherwise
  ///
  /// Note:
  /// Final fields can only be set once (typically during construction).
  /// {@endtemplate}
  bool isFinal();

  /// Checks if this field is const.
  ///
  /// {@template field_is_const}
  /// Returns:
  /// - `true` if declared with `const` modifier
  /// - `false` otherwise
  ///
  /// Note:
  /// Const fields are initialized at compile time.
  /// {@endtemplate}
  bool isConst();
  
  /// Checks if this field is late.
  ///
  /// {@template field_is_late}
  /// Returns:
  /// - `true` if declared with `late` modifier
  /// - `false` otherwise
  ///
  /// Note:
  /// Late fields require null safety and support lazy initialization.
  /// {@endtemplate}
  bool isLate();
  
  /// Checks if this field is abstract.
  ///
  /// {@template field_is_abstract}
  /// Returns:
  /// - `true` if declared in an abstract class without initialization
  /// - `false` for concrete fields
  ///
  /// Note:
  /// Abstract fields cannot be accessed directly.
  /// {@endtemplate}
  bool isAbstract();

  /// Checks if this field is an enum field.
  ///
  /// {@template field_is_enum_field}
  /// Returns:
  /// - `true` if declared with `enum` modifier
  /// - `false` otherwise
  /// {@endtemplate}
  bool isEnumField();

  /// Checks if this field is a record field.
  ///
  /// {@template field_is_record_field}
  /// Returns:
  /// - `true` if declared with `record` modifier
  /// - `false` otherwise
  /// {@endtemplate}
  /// 
  /// **Note**: This method will always return false since v1.0.9
  bool isRecordField();

  /// Checks if this field is an annotation field.
  ///
  /// {@template field_is_annotation_field}
  /// Returns:
  /// - `true` if declared with `annotation` modifier
  /// - `false` otherwise
  /// {@endtemplate}
  bool isAnnotationField();

  /// Checks if this is a named field.
  ///
  /// {@template record_field_is_named}
  /// Returns:
  /// - `true` if declared with a name in curly braces `{namedField}`
  /// - `false` for positional fields
  /// {@endtemplate}
  bool isNamed();
  
  /// Checks if this is a positional field.
  ///
  /// {@template record_field_is_positional}
  /// Returns:
  /// - `true` if declared without a name
  /// - `false` for named fields
  /// {@endtemplate}
  bool isPositional();
  
  /// Gets the field's value from an instance.
  ///
  /// {@template field_get_value}
  /// Parameters:
  /// - [instance]: The object instance (null for static fields)
  ///
  /// Returns:
  /// - The current field value
  ///
  /// Throws:
  /// - [FieldAccessException] if field is not readable
  /// - [PrivateFieldAccessException] if the field is a private field
  /// - [GenericResolutionException] if the field's type cannot be resolved
  ///
  /// Example:
  /// ```dart
  /// final value = field.getValue(instance);
  /// ```
  /// {@endtemplate}
  dynamic getValue([Object? instance]);
  
  /// Sets the field's value on an instance.
  ///
  /// {@template field_set_value}
  /// Parameters:
  /// - [instance]: The object instance (null for static fields)
  /// - [value]: The new value to set
  ///
  /// Throws:
  /// - [FieldMutationException] if field is not writable
  /// - [PrivateFieldAccessException] if the field is a private field
  /// - [GenericResolutionException] if the field's type cannot be resolved
  ///
  /// Example:
  /// ```dart
  /// field.setValue(instance, newValue);
  /// ```
  /// {@endtemplate}
  void setValue(Object? instance, dynamic value);
  
  /// Gets the field's value with type safety.
  ///
  /// {@template field_get_value_as}
  /// Type Parameters:
  /// - `T`: The expected return type
  ///
  /// Parameters:
  /// - [instance]: The object instance
  ///
  /// Returns:
  /// - The field value cast to type T
  /// - `null` if value is null or type conversion fails
  ///
  /// Example:
  /// ```dart
  /// final name = field.getValueAs<String>(instance);
  /// ```
  /// {@endtemplate}
  T? getValueAs<T>([Object? instance]);
  
  /// {@template class_field_is_readable}
  /// Determines whether this field can be read from (i.e., retrieved a value)
  /// through Jetleaf's reflective or dependency injection mechanisms.
  ///
  /// A field is considered **readable** if all of the following are true:
  /// 1. It is **not static** — readable fields must belong to an instance.
  /// 2. It is **not const** — constant fields are compile-time constants.
  /// 3. It is either:
  ///    - **non-final**, meaning it can always be reassigned, or
  ///    - **`late final`**, meaning it can be assigned once after construction.
  ///
  /// ### Examples
  /// ```dart
  /// class Example {
  ///   final User user1;           // ✅ readable (final)
  ///   late final User user2;      // ✅ readable (late final)
  ///   User? user3;                // ✅ readable (mutable)
  ///   static User? user4;         // ❌ not readable (static)
  ///   const String key = 'abc';   // ❌ not readable (const)
  /// }
  ///
  /// final fields = Class.forType(Example).getFields();
  /// for (final field in fields) {
  ///   print('${field.getName()}: ${field.isReadable()}');
  /// }
  /// ```
  ///
  /// Output:
  /// ```
  /// user1: true
  /// user2: true
  /// user3: true
  /// user4: false
  /// key: false
  /// ```
  ///
  /// This method performs an internal access check to ensure the caller has
  /// `DomainPermission.READ_FIELDS` before inspecting the field’s properties.
  /// {@endtemplate}
  bool isReadable();
  
  /// {@template class_field_is_writable}
  /// Determines whether this field can be written to (i.e., assigned a value)
  /// through Jetleaf's reflective or dependency injection mechanisms.
  ///
  /// A field is considered **writable** if all of the following are true:
  /// 1. It is **not static** — writable fields must belong to an instance.
  /// 2. It is **not const** — constant fields are compile-time constants.
  /// 3. It is either:
  ///    - **non-final**, meaning it can always be reassigned, or
  ///    - **`late final`**, meaning it can be assigned once after construction.
  ///
  /// ### Examples
  /// ```dart
  /// class Example {
  ///   final User user1;           // ❌ not writable
  ///   late final User user2;      // ✅ writable (late final)
  ///   User? user3;                // ✅ writable (mutable)
  ///   static User? user4;         // ❌ not writable (static)
  ///   const String key = 'abc';   // ❌ not writable (const)
  /// }
  ///
  /// final fields = Class.forType(Example).getFields();
  /// for (final field in fields) {
  ///   print('${field.getName()}: ${field.isWritable()}');
  /// }
  /// ```
  ///
  /// Output:
  /// ```
  /// user1: false
  /// user2: true
  /// user3: true
  /// user4: false
  /// key: false
  /// ```
  ///
  /// This method performs an internal access check to ensure the caller has
  /// `DomainPermission.READ_FIELDS` before inspecting the field’s properties.
  /// {@endtemplate}
  bool isWritable();

  /// Gets the parent declaration of this field.
  ///
  /// {@template field_get_parent}
  /// Returns:
  /// - The parent declaration of this field
  /// {@endtemplate}
  Declaration getParent();
  
  /// Creates a Field instance from reflection metadata.
  ///
  /// {@template field_factory}
  /// Parameters:
  /// - [declaration]: The field reflection metadata
  /// - [domain]: The protection domain for security
  ///
  /// Returns:
  /// - A concrete [Field] implementation
  ///
  /// Typical implementation:
  /// ```dart
  /// static Field declared(FieldDeclaration d, ProtectionDomain p) {
  ///   return _FieldImpl(d, p);
  /// }
  /// ```
  /// {@endtemplate}
  factory Field.declared(FieldDeclaration declaration, Declaration parent, ProtectionDomain domain) = _Field;
}

/// {@template field_access}
/// Provides reflective access to fields of a class.
///
/// This interface abstracts field metadata access, allowing inspection of:
/// - Field names and types
/// - Field values (both user-provided and defaults)
/// - Protection domains
/// - Actual field instances
///
/// {@template field_access_features}
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
/// {@endtemplate}
abstract interface class FieldAccess {
  /// {@macro field_access}
  const FieldAccess();

  // ---------------------------------------------------------------------------------------------------------
  // === Field Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Gets all fields declared in this class.
  ///
  /// {@template class_get_fields}
  /// Returns:
  /// - List of all fields (instance and static)
  /// - Empty list if no fields exist
  ///
  /// Example:
  /// ```dart
  /// class Person {
  ///   String name;
  ///   static int count = 0;
  /// }
  ///
  /// final fields = Class.forType<Person>().getFields();
  /// print(fields.map((f) => f.name)); // ['name', 'count']
  /// ```
  /// 
  /// Includes:
  /// - Instance fields
  /// - Static fields
  /// - Final fields
  /// - Late fields
  /// 
  /// Excludes:
  /// - Inherited fields
  /// {@endtemplate}
  Iterable<Field> getFields();

  /// Gets a field by its name.
  ///
  /// {@template class_get_field}
  /// Parameters:
  /// - [name]: The field name to look up
  ///
  /// Returns:
  /// - The matching field if found
  /// - `null` if no field with this name exists
  ///
  /// Example:
  /// ```dart
  /// final field = Class.forType<Rectangle>().getField('width');
  /// print(field?.type.getName()); // 'double'
  /// ```
  /// 
  /// Note:
  /// - Only checks directly declared fields
  /// - For inherited fields, traverse class hierarchy
  /// {@endtemplate}
  Field? getField(String name);
}