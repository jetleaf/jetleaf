import 'package:jetleaf_build/jetleaf_build.dart';

import '../../commons/version.dart';
import '../../utils/lang_utils.dart';
import '../class/class.dart';
import '../core.dart';
import '../protection_domain/protection_domain.dart';

part '_record_field.dart';

/// {@template record_field}
/// Represents a **field within a Dart record** `(T1, T2, ...)` or `{name1: T1, name2: T2, ...}`
/// as part of the Jetleaf meta-model.
///
/// `RecordField` provides metadata about individual fields of a record,
/// including their type, name, position (for positional fields), and
/// their parent record declaration. This abstraction is **synthetic** and
/// is not tied to a concrete Dart class—fields are created through
/// meta-APIs rather than direct instantiation.
///
/// This allows full inspection of record types when they appear as:
/// - Parameters of a method or constructor
/// - Return types of methods or functions
/// - Fields within another record
///
/// Jetleaf ensures type-safety and complete modeling of record structures
/// via `RecordField` and `RecordClass`.
/// {@endtemplate}
abstract final class RecordField extends PermissionManager {
  /// Gets the **declared type** of the record field as a [Class] object.
  ///
  /// This allows users to inspect the type at a meta-level. For example,
  /// a field `user: User` will return a `Class<User>` representing the type.
  ///
  /// Returns:
  /// - A [Class<Object>] representing the field type
  /// - May return a `FunctionClass` or `RecordClass` if the type is a function or record
  Class<Object> getReturnClass();

  /// Gets the **runtime type** of the record field as a [Type].
  ///
  /// Returns:
  /// - The Dart [Type] object corresponding to the field type
  /// - `void` for void types (if applicable)
  Type getReturnType();

  /// Retrieves the **meta-level declaration** for this field.
  ///
  /// Returns:
  /// - A [LinkDeclaration] that links this field to its parent record and source metadata
  LinkDeclaration getDeclaration();

  /// Indicates whether this field is **positional** within the record.
  ///
  /// Returns:
  /// - `true` if the field is positional `(0, 1, 2, ...)`
  /// - `false` if the field is named `{name: value}`
  bool isPositional();

  /// Returns the **zero-based index** for positional fields.
  ///
  /// For named fields, this may be implementation-dependent (e.g., -1).
  int position();

  /// Returns the **name** of the field.
  ///
  /// For named fields, this is the user-declared name.
  /// For positional fields, this may be a generated name (e.g., `$0`, `$1`).
  String getName();

  /// Returns the **field declaration** object associated with this record field.
  ///
  /// This links back to the original record declaration and allows
  /// inspection of metadata such as annotations or modifiers.
  RecordFieldDeclaration getFieldDeclaration();

  /// Returns the **parent record** to which this field belongs.
  RecordDeclaration getParent();

  /// Links a [RecordFieldDeclaration] and parent [RecordDeclaration] to create
  /// a new `RecordField` instance within the given [ProtectionDomain].
  ///
  /// This is the **primary factory** for creating `RecordField` objects.
  ///
  /// Parameters:
  /// - [declaration]: The declaration describing this field
  /// - [record]: The parent record containing this field
  /// - [pd]: The protection domain in which this field is defined
  ///
  /// Returns a [RecordField] instance.
  /// 
  /// {@macro record_field}
  factory RecordField.linked(RecordFieldDeclaration declaration, RecordDeclaration record, ProtectionDomain pd) = _RecordField;
}