import 'dart:collection';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../commons/version.dart';
import 'annotation/annotation.dart';
import 'class/class.dart';
import 'parameter/parameter.dart';
import 'protection_domain/protection_domain.dart';

/// {@template member}
/// Abstract base class representing a member of a class that extends [Executable].
///
/// This class provides a default implementation for executable elements that are not
/// actually executable (i.e., they don't accept parameters or arguments). It's typically
/// used as a base class for class members like fields, properties, or other non-method
/// elements that need to implement the [Executable] interface but don't have
/// executable semantics.
///
/// ## Key Characteristics
///
/// - **Non-executable**: All parameter-related methods return empty/false values
/// - **No Arguments**: Cannot accept any positional or named arguments
/// - **No Parameters**: Has no parameter definitions or metadata
/// - **Marker Implementation**: Serves as a marker for non-executable class members
///
/// ## Usage
///
/// Extend this class for class members that implement [Executable] but are not methods:
///
/// ```dart
/// class Field extends Member {
///   final String name;
///   final Class type;
///   final dynamic value;
///   
///   Field(this.name, this.type, [this.value]);
///   
///   @override
///   String getName() => name;
///   
///   @override
///   Class getReturnType() => type;
/// }
/// ```
///
/// ## Property Implementation
///
/// ```dart
/// class Property extends Member {
///   final String propertyName;
///   final Class propertyType;
///   final bool isReadOnly;
///   
///   Property(this.propertyName, this.propertyType, {this.isReadOnly = false});
///   
///   @override
///   String getName() => propertyName;
///   
///   @override
///   Class getReturnType() => propertyType;
///   
///   bool canWrite() => !isReadOnly;
/// }
/// ```
///
/// ## Annotation Support
///
/// ```dart
/// class AnnotatedMember extends Member {
///   final List<Annotation> annotations;
///   
///   AnnotatedMember(this.annotations);
///   
///   bool hasDirectAnnotation<T>() {
///     return annotations.any((a) => a is T);
///   }
///   
///   T? getDirectAnnotation<T>() {
///     return annotations.whereType<T>().firstOrNull;
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class Member {
  /// Gets the class that declares this method.
  ///
  /// {@template method_declaring_class}
  /// Type Parameters:
  /// - `D`: The expected declaring class type
  ///
  /// Returns:
  /// - The [Class<D>] where this method is defined
  ///
  /// Example:
  /// ```dart
  /// final declaringClass = method.getDeclaringClass<MyClass>();
  /// ```
  /// {@endtemplate}
  Class<D> getDeclaringClass<D>();
  
  /// Gets the return type of the method.
  ///
  /// {@template method_return_type}
  /// Type Parameters:
  /// - `R`: The expected return type
  ///
  /// Returns:
  /// - A [Class<R>] representing the return type
  /// - `Class<void>` for void methods
  ///
  /// Example:
  /// ```dart
  /// final returnType = method.getReturnClass<String>();
  /// ```
  /// {@endtemplate}
  Class<Object> getReturnClass();

  /// Gets the return type of the method.
  ///
  /// {@template method_return_type}
  /// Returns:
  /// - The return type as a [Type]
  /// - `Type` for void methods
  ///
  /// Example:
  /// ```dart
  /// final returnType = method.getReturnType();
  /// ```
  /// {@endtemplate}
  Type getReturnType();
}

/// {@template protection_element}
/// Abstract interface for elements that can have protection domains.
///
/// {@template protection_element_features}
/// ## Key Features
/// - Protection domain integration
/// - Permission checking
///
/// ## Implementations
/// Typically implemented by:
/// - [Class] for class-level annotations
/// - [Method] for method annotations
/// - [Field] for field annotations
/// - [Parameter] for parameter annotations
/// {@endtemplate}
/// {@endtemplate}
abstract class PermissionManager {
  /// {@macro protection_element}
  const PermissionManager();

  /// Gets the protection domain governing access to this element.
  ///
  /// {@template source_metadata_protection}
  /// Protection domains control:
  /// - Visibility of the element
  /// - Access to sensitive metadata
  /// - Security constraints
  ///
  /// Returns:
  /// - The [ProtectionDomain] associated with this element
  ///
  /// See also:
  /// - [checkAccess] for permission verification
  /// {@endtemplate}
  ProtectionDomain getProtectionDomain();

  /// Verifies access permissions before performing sensitive operations.
  ///
  /// {@template source_metadata_check_access}
  /// Parameters:
  /// - [operation]: Description of the operation being performed
  /// - [permission]: Required permission level
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   metadata.checkAccess('privateFieldAccess', DomainPermission.high);
  ///   // Perform sensitive operation
  /// } on AccessDeniedError {
  ///   print('Insufficient permissions');
  /// }
  /// ```
  /// {@endtemplate}
  void checkAccess(String operation, DomainPermission permission) {
    getProtectionDomain().checkAccess(operation, permission);
  }

  /// Retrieves the [Author] annotation applied to this element, if present.
  ///
  /// This method inspects the element’s **direct annotations** and returns
  /// the first instance of [Author] found. It does **not** search inherited
  /// annotations from superclasses or interfaces.
  ///
  /// ### Returns
  /// - An [Author] object if the annotation is present directly on this element.
  /// - `null` if no [Author] annotation is applied.
  ///
  /// ### Example
  /// ```dart
  /// @Author(name: "Alice", email: "alice@example.com")
  /// class MyClass {}
  ///
  /// final clazz = Class.forName<MyClass>("MyClass");
  /// final author = clazz.getAuthor();
  /// print(author?.name); // → "Alice"
  /// ```
  ///
  /// ### Notes
  /// - This is a **direct annotation lookup**. Use `getAnnotation<T>()` if
  ///   you want to include inherited annotations.
  Author? getAuthor();

  /// Retrieves the version metadata associated with this declaration, if any.
  ///
  /// {@template declaration_get_version}
  /// This method returns the [Version] annotation directly attached to the
  /// underlying declaration (class, method, field, parameter, etc.).
  ///
  /// Version metadata is commonly used to:
  /// - Track API evolution and semantic versioning
  /// - Signal feature maturity or stability
  /// - Drive compatibility checks and documentation generation
  ///
  /// ### Behavior
  /// - Returns the **direct** [Version] annotation only  
  /// - Does **not** search inherited, overridden, or enclosing declarations  
  /// - Returns `null` if no version metadata is present
  ///
  /// ### Typical Usage
  /// ```dart
  /// final version = declaration.getVersion();
  ///
  /// if (version != null) {
  ///   print('Introduced in version ${version.value}');
  /// }
  /// ```
  ///
  /// ### Notes
  /// - This method is commonly paired with [getAuthor] and other
  ///   metadata-accessor methods.
  /// - Tooling such as documentation generators, API diff tools,
  ///   and compatibility analyzers rely on this method for accurate
  ///   version introspection.
  /// {@endtemplate}
  Version getVersion();
}

/// {@template source_metadata}
/// Abstract base class for all reflection metadata that can be annotated.
///
/// Provides common functionality for working with annotations and protection
/// domains across all reflectable elements (classes, methods, fields, etc.).
///
/// {@template source_metadata_features}
/// ## Key Features
/// - Annotation discovery and filtering by type
/// - Protection domain integration
/// - Type-safe annotation access
/// - Permission checking
///
/// ## Implementations
/// Typically implemented by:
/// - [Class] for class-level annotations
/// - [Method] for method annotations
/// - [Field] for field annotations
/// - [Parameter] for parameter annotations
/// {@endtemplate}
///
/// {@template source_metadata_example}
/// ## Example Usage
/// ```dart
/// // Get class metadata
/// final classMeta = reflector.getClass('MyClass');
///
/// // Check for specific annotation
/// if (classMeta.hasDirectAnnotation<JsonSerializable>()) {
///   // Get annotation instance
///   final jsonAnn = classMeta.getDirectAnnotation<JsonSerializable>();
///   print('Uses JSON serialization');
/// }
///
/// // Get all controller annotations
/// final controllers = classMeta.getDirectAnnotations<RestController>();
/// ```
/// {@endtemplate}
/// {@endtemplate}
abstract class Source extends PermissionManager {
  /// {@macro source_metadata}
  const Source();

  // ---------------------------------------------------------------------------------------------------------
  // === Declaration Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Gets the type declaration metadata for this class.
  ///
  /// {@template class_get_declaration}
  /// Returns:
  /// - Complete type metadata including:
  ///   - Annotations
  ///   - Modifiers
  ///   - Source location
  ///   - Documentation comments
  ///
  /// Example:
  /// ```dart
  /// final declaration = Class.forType<MyClass>().getDeclaration();
  /// print(declaration.annotations.length);
  /// print(declaration.sourceFile);
  /// ```
  /// 
  /// Typical metadata includes:
  /// - IsAbstract
  /// - IsFinal
  /// - IsSealed
  /// - Source file location
  /// - Documentation comments
  /// - All annotations
  /// {@endtemplate}
  Declaration getDeclaration();

  // ---------------------------------------------------------------------------------------------------------
  // === Name Information ===
  // ---------------------------------------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------------------------------------
  // === Annotation Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Gets all annotations applied to this element.
  ///
  /// {@template source_metadata_all_annotations}
  /// Returns:
  /// - A list of all [Annotation] instances on this element
  /// - Empty list if no annotations exist
  ///
  /// Note:
  /// Includes both runtime-retained and source-only annotations
  /// when available in the reflection environment.
  ///
  /// Example:
  /// ```dart
  /// for (final ann in element.getAllDirectAnnotations()) {
  ///   print('Found annotation: ${ann.getSignature()}');
  /// }
  /// ```
  /// {@endtemplate}
  Iterable<Annotation> getAllDirectAnnotations();
  
  /// Gets a single annotation by type, if present.
  ///
  /// {@template source_metadata_get_annotation}
  /// Type Parameters:
  /// - `A`: The annotation type to look for
  ///
  /// Returns:
  /// - The annotation instance of type `A` if found
  /// - `null` if no matching annotation exists
  ///
  /// Example:
  /// ```dart
  /// final deprecated = method.getDirectAnnotation<Deprecated>();
  /// if (deprecated != null) {
  ///   print('Deprecation message: ${deprecated.message}');
  /// }
  /// ```
  /// {@endtemplate}
  A? getDirectAnnotation<A>() {
    checkAccess('getDirectAnnotation', DomainPermission.READ_ANNOTATIONS);

    final annotations = getAllDirectAnnotations();
    for (final annotation in annotations) {
      if (annotation.matches<A>()) {
        try {
          return annotation.getInstance<A>();
        } catch (_) {
          return null;
        }
      }
    }

    return null;
  }
  
  /// Gets all annotations of a specific type.
  ///
  /// {@template source_metadata_get_annotations}
  /// Type Parameters:
  /// - `A`: The annotation type to filter for
  ///
  /// Returns:
  /// - A list of all matching annotation instances
  /// - Empty list if none found
  ///
  /// Note:
  /// Useful for repeatable annotations that may appear multiple times.
  ///
  /// Example:
  /// ```dart
  /// final routes = method.getDirectAnnotations<Route>();
  /// for (final route in routes) {
  ///   print('Route path: ${route.path}');
  /// }
  /// ```
  /// {@endtemplate}
  Iterable<A> getDirectAnnotations<A>() {
    checkAccess('getDirectAnnotations', DomainPermission.READ_ANNOTATIONS);
    final annotations = getAllDirectAnnotations();
    return UnmodifiableListView(annotations.where((a) => a.matches<A>()).map((a) => a.getInstance<A>()));
  }
  
  /// Checks if this element has a specific annotation.
  ///
  /// {@template source_metadata_has_annotation}
  /// Type Parameters:
  /// - `A`: The annotation type to check for
  ///
  /// Returns:
  /// - `true` if the annotation is present
  /// - `false` otherwise
  ///
  /// Example:
  /// ```dart
  /// if (field.hasDirectAnnotation<Transient>()) {
  ///   print('Field is transient and will not be serialized');
  /// }
  /// ```
  /// {@endtemplate}
  bool hasDirectAnnotation<A>() {
    checkAccess('hasDirectAnnotation', DomainPermission.READ_ANNOTATIONS);
    return getDirectAnnotation<A>() != null;
  }

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

  /// Checks if this element is public.
  /// 
  /// Returns:
  /// - `true` if the element is public
  /// - `false` otherwise
  bool isPublic();

  /// {@template source_get_modifiers}
  /// Returns the list of **modifiers** associated with this source element.
  ///
  /// A *modifier* in Jetleaf represents a keyword that alters the behavior,
  /// visibility, or semantics of a language element — similar to modifiers in
  /// Dart such as `public`, `private`, `static`, `final`, `abstract`.
  ///
  /// ### Jetleaf Context
  /// Every reflective entity (`Class`, `Field`, `Method`, `Parameter`,
  /// or `Constructor`) inherits from [Source] and therefore supports querying
  /// modifiers for meta-analysis and dynamic weaving.
  ///
  /// Modifiers are typically derived from parsed annotations, metadata, or
  /// language-level declarations available via Jetleaf’s reflection system.
  ///
  /// ### Example
  /// ```dart
  /// void inspectModifiers(Source source) {
  ///   final modifiers = source.getModifiers();
  ///
  ///   print('Source name: ${source.getName()}');
  ///   print('Modifiers: ${modifiers.join(', ')}');
  ///
  ///   if (modifiers.contains('static')) {
  ///     print('This element is static.');
  ///   }
  ///
  ///   if (modifiers.contains('final')) {
  ///     print('This element cannot be reassigned.');
  ///   }
  /// }
  ///
  /// final field = Class<MyService>().getField('repository');
  /// inspectModifiers(field);
  /// // Output:
  /// // Source name: repository
  /// // Modifiers: private, final
  /// // This element cannot be reassigned.
  /// ```
  ///
  /// ### Return
  /// A list of modifier names as strings, in declaration order.  
  /// Returns an empty list if the element has no explicit modifiers.
  ///
  /// ### Usage Notes
  /// - For classes, modifiers may include: `abstract`, `final`, `sealed`, `base`.
  /// - For methods: `async`, `override`, `static`, `final`.
  /// - For fields: `const`, `static`, `late`, `final`, or visibility modifiers.
  /// - For constructors: `factory`, `const`, `private`.
  /// - For parameters: `required`, `named`, `positional`, etc.
  ///
  /// {@endtemplate}
  List<String> getModifiers();

  @override
  Author? getAuthor() {
    checkAccess("getAuthor", DomainPermission.READ_TYPE_INFO);
    return getDirectAnnotation<Author>();
  }
}

/// {@template executable_element}
/// Abstract base class for executable elements (methods, constructors, functions).
///
/// Provides common functionality for inspecting and working with callable elements
/// including parameters, invocation validation, and signature generation.
///
/// {@template executable_element_features}
/// ## Key Features
/// - Parameter inspection and validation
/// - Signature generation
/// - Invocation argument checking
/// - Const/var/final determination
///
/// ## Implementations
/// Typically implemented by:
/// - [Method] for class methods
/// - [Constructor] for constructors
/// - [ExecutableFunction] for standalone functions
/// {@endtemplate}
///
/// {@template executable_element_example}
/// ## Example Usage
/// ```dart
/// // Get executable element from reflection
/// final methodElement = classElement.getMethod('calculate');
///
/// // Check parameters
/// if (methodElement.getParameterCount() > 0) {
///   final firstParam = methodElement.getParameterAt(0);
///   print('First parameter: ${firstParam.getName()}');
/// }
///
/// // Validate arguments
/// if (methodElement.canAcceptArguments({'x': 1, 'y': 2})) {
///   print('Method can accept these named arguments');
/// }
/// ```
/// {@endtemplate}
/// {@endtemplate}
abstract class Executable extends Source {
  /// Gets all parameters of this executable element.
  ///
  /// {@template executable_get_parameters}
  /// Returns:
  /// - An ordered list of [Parameter] objects
  /// - Empty list if no parameters exist
  ///
  /// Order matches the declaration order in source.
  ///
  /// Example:
  /// ```dart
  /// void method(int a, String b) {}
  /// // Returns [Parameter(a), Parameter(b)]
  /// ```
  /// {@endtemplate}
  Iterable<Parameter> getParameters();

  /// Gets all **positional parameters** declared by this executable.
  ///
  /// {@template executable_get_positional_parameters}
  /// Returns:
  /// - A list of positional [Parameter] objects in **declaration order**
  /// - Includes both:
  ///   - Required positional parameters (`void f(int a, String b)`)
  ///   - Optional positional parameters (`void f([int a])`)
  ///
  /// Excludes:
  /// - Named parameters (`void f({int x})`)
  ///
  /// Example:
  /// ```dart
  /// void method(int a, [String? b], {bool flag = false});
  ///
  /// // getPositionalParameters() → [a, b]
  /// ```
  ///
  /// Notes:
  /// - Order always mirrors the source declaration.
  /// - Optional positional parameters appear after required positional ones.
  /// {@endtemplate}
  Iterable<Parameter> getPositionalParameters() => getParameters().where((p) => p.isPositional()).toList();

  /// Gets all **named parameters** declared by this executable.
  ///
  /// {@template executable_get_named_parameters}
  /// Returns:
  /// - A list of named [Parameter] objects
  /// - Empty list if the executable declares no named parameters
  ///
  /// Includes:
  /// - Required named parameters (`void f({required int id})`)
  /// - Optional named parameters (`void f({String? name})`)
  ///
  /// Example:
  /// ```dart
  /// void method(int a, {String? label, bool flag = false});
  ///
  /// // getNamedParameters() → [label, flag]
  /// ```
  ///
  /// Notes:
  /// - Named parameters do **not** have a stable order requirement in Dart,
  ///   but implementations typically return them in source order.
  /// - For lookup by name, see [getParameter].
  /// {@endtemplate}
  Iterable<Parameter> getNamedParameters() => getParameters().where((p) => p.isNamed()).toList();

  /// Gets the total number of parameters.
  ///
  /// {@template executable_parameter_count}
  /// Returns:
  /// - The count of all parameters (required and optional)
  ///
  /// Equivalent to `getParameters().length` but more efficient.
  /// {@endtemplate}
  int getParameterCount();

  /// Gets a parameter by name.
  ///
  /// {@template executable_get_parameter}
  /// Parameters:
  /// - [name]: The parameter name to look up
  ///
  /// Returns:
  /// - The [Parameter] if found (named parameters only)
  /// - `null` if no matching named parameter exists
  ///
  /// Note:
  /// Positional parameters cannot be retrieved by name.
  /// {@endtemplate}
  Parameter? getParameter(String name);

  /// Gets a parameter by index.
  ///
  /// {@template executable_get_parameter_at}
  /// Parameters:
  /// - [index]: Zero-based parameter position
  ///
  /// Returns:
  /// - The [Parameter] at the given index
  /// - `null` if index is out of bounds
  ///
  /// Example:
  /// ```dart
  /// // For method(int a, String b)
  /// getParameterAt(1) // Returns Parameter(b)
  /// ```
  /// {@endtemplate}
  Parameter? getParameterAt(int index);

  /// Gets the types of all parameters.
  ///
  /// {@template executable_parameter_types}
  /// Returns:
  /// - A list of [Class] objects representing parameter types
  /// - Order matches parameter declaration order
  ///
  /// Example:
  /// ```dart
  /// // For method(int a, String b)
  /// // Returns [Class<int>, Class<String>]
  /// ```
  /// {@endtemplate}
  Iterable<Class> getParameterTypes();

  /// Checks if named arguments can be accepted.
  ///
  /// {@template executable_can_accept_arguments}
  /// Parameters:
  /// - [arguments]: Map of argument names to values
  ///
  /// Returns:
  /// - `true` if:
  ///   - All required parameters are provided
  ///   - No extra unknown parameters exist
  ///   - Types are compatible
  /// - `false` otherwise
  ///
  /// Example:
  /// ```dart
  /// canAcceptArguments({'name': 'Alice', 'age': 30})
  /// ```
  /// {@endtemplate}
  bool canAcceptArguments(Map<String, dynamic> arguments);

  /// Checks if positional arguments can be accepted.
  ///
  /// {@template executable_can_accept_positional}
  /// Parameters:
  /// - [args]: List of positional arguments
  ///
  /// Returns:
  /// - `true` if:
  ///   - Minimum required count is met
  ///   - Optional parameters are within bounds
  ///   - Types are compatible
  /// - `false` otherwise
  ///
  /// Example:
  /// ```dart
  /// canAcceptPositionalArguments([1, 'hello'])
  /// ```
  /// {@endtemplate}
  bool canAcceptPositionalArguments(List<dynamic> args);

  /// Checks if named arguments can be accepted.
  ///
  /// {@template executable_can_accept_named}
  /// Parameters:
  /// - [arguments]: Map of argument names to values
  ///
  /// Returns:
  /// - `true` if:
  ///   - All required parameters are provided
  ///   - No extra unknown parameters exist
  ///   - Types are compatible
  /// - `false` otherwise
  ///
  /// Example:
  /// ```dart
  /// canAcceptNamedArguments({'name': 'Alice', 'age': 30})
  /// ```
  /// {@endtemplate}
  bool canAcceptNamedArguments(Map<String, dynamic> arguments);

  /// Checks if this executable is declared as const.
  ///
  /// {@template executable_is_const}
  /// Returns:
  /// - `true` if declared with `const` modifier
  /// - `false` otherwise
  ///
  /// Note:
  /// Differs from `isFinal` as const implies compile-time constant.
  /// {@endtemplate}
  bool isConst();
}