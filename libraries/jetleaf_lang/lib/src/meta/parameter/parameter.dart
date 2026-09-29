import 'package:jetleaf_build/jetleaf_build.dart';

import '../../commons/version.dart';
import '../../utils/lang_utils.dart';
import '../annotation/annotation.dart';
import '../class/class.dart';
import '../constructor/constructor.dart';
import '../field/field.dart';
import '../core.dart';
import '../method/method.dart';
import '../protection_domain/protection_domain.dart';

part '_parameter.dart';

/// {@template parameter_interface}
/// Provides reflective access to method/constructor parameter metadata.
///
/// This interface enables inspection of:
/// - Parameter types and positions
/// - Optional/required status
/// - Named vs positional parameters
/// - Default values
/// - Annotations
///
/// {@template parameter_interface_features}
/// ## Key Features
/// - Type-safe parameter type access
/// - Default value inspection
/// - Parameter kind detection (named/positional)
/// - Signature generation
/// - Annotation support
///
/// ## Implementation Notes
/// Concrete implementations typically wrap platform-specific reflection objects
/// while providing this uniform interface.
/// {@endtemplate}
///
/// {@template parameter_interface_example}
/// ## Example Usage
/// ```dart
/// // Get parameter metadata
/// final params = method.getParameters();
/// final firstParam = params[0];
///
/// // Inspect parameter properties
/// print('Name: ${firstParam.getName()}');
/// print('Type: ${firstParam.getType<dynamic>().getName()}');
/// print('Optional: ${firstParam.isOptional()}');
///
/// // Check for default value
/// if (firstParam.hasDefaultValue()) {
///   print('Default: ${firstParam.getDefaultValue()}');
/// }
/// ```
/// {@endtemplate}
/// {@endtemplate}
abstract final class Parameter extends Source {
  @override
  ParameterDeclaration getDeclaration();

  /// Gets the type of the parameter with proper generics.
  ///
  /// {@template parameter_get_type}
  /// Returns:
  /// - A [Class] instance representing the parameter type
  ///
  /// Example:
  /// ```dart
  /// final type = param.getReturnClass(); // Class<String>
  /// ```
  /// {@endtemplate}
  Class<Object> getReturnClass();

  /// Gets the type of the parameter.
  ///
  /// {@template parameter_get_type}
  /// Returns:
  /// - The parameter type as a [Type]
  ///
  /// Example:
  /// ```dart
  /// final type = param.getType(); // Type
  /// ```
  /// {@endtemplate}
  Type getType();
  
  /// Gets the parameter's position in the parameter list.
  ///
  /// {@template parameter_get_index}
  /// Returns:
  /// - Zero-based index in the method's parameter list
  ///
  /// Note:
  /// Named parameters typically appear after positional parameters
  /// in the index order.
  /// {@endtemplate}
  int getIndex();
  
  /// Checks if this parameter is optional.
  ///
  /// {@template parameter_is_optional}
  /// Returns:
  /// - `true` if either:
  ///   - Positional parameter in square brackets `[param]`
  ///   - Named parameter in curly braces `{param}`
  /// - `false` for required parameters
  /// {@endtemplate}
  bool isOptional();
  
  /// Checks whether the parameter type is nullable.
  ///
  /// {@template parameter_is_nullable}
  /// Returns:
  /// - `true` if the parameter's static type is nullable  
  ///   (e.g., `int?`, `String?`, or a generic type with a nullable bound)
  /// - `false` if the type is strictly non-nullable  
  ///
  /// ## Notes
  /// - This reflects the Dart null-safety type system.
  /// - A parameter can be *required* but still *nullable*, and vice-versa.
  ///
  /// ## Example
  /// ```dart
  /// void example(int? value) {}
  ///
  /// final param = method.getParameters().first;
  /// print(param.isNullable()); // true
  /// ```
  /// {@endtemplate}
  bool isNullable();

  /// Checks whether the parameter's type is a function type.
  ///
  /// {@template parameter_is_function}
  /// Returns:
  /// - `true` if the parameter's declared type is a function type, such as:
  ///   - `void Function(int)`
  ///   - `T Function(T)`
  ///   - `Future<void> Function()`
  /// - `false` if the parameter is not a function type.
  ///
  /// ## Notes
  /// - This does **not** check whether the parameter *evaluates to* a function,
  ///   only whether its *static type* is a function type.
  /// - Useful when generating invocation wrappers, proxies, or stubs.
  ///
  /// ## Example
  /// ```dart
  /// void example(void Function() callback) {}
  ///
  /// final param = method.getParameters().first;
  /// print(param.isFunction()); // true
  /// ```
  /// {@endtemplate}
  bool isFunction();

  /// Gets the underlying link-time declaration for this parameter.
  ///
  /// {@template parameter_get_link_declaration}
  /// Returns:
  /// - A [LinkDeclaration] representing the parameter's static declaration
  ///   in the compile-time model.
  ///
  /// ## What This Represents
  /// - The original source-level declaration from build-time metadata.
  /// - Type, name, and annotation information *before* any runtime resolution.
  ///
  /// ## Why This Matters
  /// - Enables tooling that must operate on compile-time structure:
  ///   - Code generation
  ///   - Static analysis
  ///   - AOP weaving
  ///   - Symbolic evaluation
  ///
  /// ## Example
  /// ```dart
  /// final link = param.getLinkDeclaration();
  /// print(link.name);     // Parameter name
  /// print(link.typeName); // Source-level type
  /// ```
  ///
  /// ## Notes
  /// - This does not consider runtime modifications from mirrors or proxies.
  /// {@endtemplate}
  LinkDeclaration getLinkDeclaration();
  
  /// Checks if this is a named parameter.
  ///
  /// {@template parameter_is_named}
  /// Returns:
  /// - `true` if declared in curly braces `{param}`
  /// - `false` for positional parameters
  /// {@endtemplate}
  bool isNamed();
  
  /// Checks if this is a positional parameter.
  ///
  /// {@template parameter_is_positional}
  /// Returns:
  /// - `true` if declared without braces or in square brackets `[param]`
  /// - `false` for named parameters
  /// {@endtemplate}
  bool isPositional();
  
  /// Checks if this parameter is required.
  ///
  /// {@template parameter_is_required}
  /// Returns:
  /// - `true` if declared with `required` keyword
  /// - `false` for optional parameters
  ///
  /// Note:
  /// Differs from [isNullable] as some named parameters may be required.
  /// {@endtemplate}
  bool isRequired();
  
  /// Checks if this parameter has a default value.
  ///
  /// {@template parameter_has_default}
  /// Returns:
  /// - `true` if parameter has a default value
  /// - `false` if required or optional without default
  ///
  /// See also:
  /// - [getDefaultValue] to retrieve the value
  /// {@endtemplate}
  bool hasDefaultValue();

  /// Indicates whether this parameter **must be explicitly resolved** at call time.
  ///
  /// This property is used by the invocation engine to determine whether a
  /// parameter *must* receive a value during reflection-based method or
  /// constructor calls, even if its signature might otherwise suggest that
  /// providing a value is optional.
  ///
  /// ### When a parameter "must be resolved"
  /// A parameter is considered *must-resolve* when:
  /// - The parameter is marked `required` but the reflective call path may not
  ///   enforce that automatically.
  /// - The parameter has no default value and cannot be null.
  /// - The underlying platform reflection metadata is incomplete or ambiguous
  ///   (e.g., due to external/native declarations).
  /// - Skipping this parameter would cause the invocation to throw at runtime
  ///   (common in code generation, proxying, and AOP scenarios).
  ///
  /// ### Typical Use Cases
  /// - **Runtime invocation frameworks**: to ensure required arguments are
  ///   provided before evaluating a reflected call.
  /// - **Code generation**: to emit correct invocation stubs for constructors
  ///   and methods.
  /// - **Cross-isolate or proxy method calls**: where incomplete metadata can
  ///   cause invocation failures.
  ///
  /// ### Example
  /// ```dart
  /// void example({required int count}) {}
  ///
  /// final param = Class(Example).getMethod('example').getParameters().first;
  ///
  /// if (param.mustBeResolved()) {
  ///   // Ensure a value for `count` is supplied
  /// }
  /// ```
  ///
  /// ### Returns
  /// `true` if the parameter must be supplied with an explicit value during
  /// invocation; otherwise `false`.
  bool mustBeResolved();
  
  /// Gets the default value of the parameter.
  ///
  /// {@template parameter_get_default}
  /// Returns:
  /// - The default value if specified
  /// - `null` if no default exists
  ///
  /// Example:
  /// ```dart
  /// void method([int param = 42]) {}
  /// // getDefaultValue() returns 42
  /// ```
  /// {@endtemplate}
  dynamic getDefaultValue();

  /// Gets the member that this parameter belongs to.
  /// 
  /// Can be a [Method], [Constructor], or [Field].
  ///
  /// {@template parameter_get_member}
  /// Returns:
  /// - The member that this parameter belongs to
  ///
  /// Example:
  /// ```dart
  /// void method(int param) {}
  /// // getMember() returns method
  /// ```
  /// {@endtemplate}
  Member getMember();
  
  /// Creates a Parameter instance from reflection metadata.
  ///
  /// {@template parameter_factory}
  /// Parameters:
  /// - [declaration]: The parameter reflection metadata
  /// - [domain]: The protection domain for security
  ///
  /// Returns:
  /// - A concrete [Parameter] implementation
  ///
  /// Typical implementation:
  /// ```dart
  /// static Parameter declared(ParameterDeclaration d, ProtectionDomain p) {
  ///   return _ParameterImpl(d, p);
  /// }
  /// ```
  /// {@endtemplate}
  factory Parameter.declared(ParameterDeclaration declaration, Member member, ProtectionDomain domain) = _Parameter;
}