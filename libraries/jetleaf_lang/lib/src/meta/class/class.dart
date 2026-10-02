import 'dart:async';
import 'dart:collection';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../../commons/version.dart';
import '../../extensions/primitives/iterable.dart';
import '../../extensions/primitives/string.dart';
import '../../exceptions.dart';
import '../../garbage_collector/garbage_collector.dart';
import '../../utils/lang_utils.dart';
import '../annotation/annotation.dart';
import '../constructor/constructor.dart';
import '../enum/enum_value.dart';
import '../field/field.dart';
import '../core.dart';
import '../generic_source.dart';
import '../method/method.dart';
import '../protection_domain/protection_domain.dart';
import '../record/record_field.dart';
import 'class_type.dart';

part '_class.dart';

/// {@template class}
/// Provides a **unified, reflective interface** to access Dart class types
/// and their associated metadata at runtime.
///
/// The [Class] interface abstracts the complexities of runtime reflection and
/// static analysis, allowing developers to:
/// - Inspect class type information and hierarchy
/// - Access constructors and create instances dynamically
/// - Inspect and modify fields and methods
/// - Read annotations and metadata
/// - Resolve and manipulate generic type parameters
///
/// This interface is central to runtime introspection frameworks like Jetleaf,
/// where classes must be analyzed, invoked, or transformed dynamically.
/// 
/// ## Key Features
///
/// 1. **Type-Safe Reflection**
///    Access class members and hierarchy without unsafe casts.
///
/// 2. **Generic Type Support**
///    Resolve type arguments and work with parameterized classes.
///
/// 3. **Class Hierarchy Navigation**
///    Inspect superclasses, subclasses, interfaces, and mixins.
///
/// 4. **Instance Creation**
///    Construct objects dynamically using resolved constructors.
///
/// 5. **Member Inspection**
///    Read or invoke fields and methods at runtime.
///
/// 6. **Annotation Access**
///    Discover metadata attached to classes, fields, and methods.
///
/// ## Implementation Notes
/// - Concrete implementations wrap platform-specific reflection objects
///   (e.g., `dart:mirrors`, analyzer elements, or runtime descriptors).
/// - Provides a **consistent, cross-platform interface** for introspection
///   and code generation pipelines.
/// 
/// ## Example Usage
///
/// ```dart
/// // Obtain reflective metadata for the User class
/// final userClass = Class.forType<User>();
///
/// // Create a new instance using a constructor with named parameters
/// final user = userClass.newInstance({'name': 'Alice', 'age': 30});
///
/// // Access a field dynamically
/// final nameField = userClass.getField('name');
/// print(nameField?.get(user)); // Output: 'Alice'
///
/// // Update field dynamically
/// nameField?.set(user, 'Bob');
/// print(nameField?.get(user)); // Output: 'Bob'
///
/// // Check type hierarchy
/// if (userClass.isSubclassOf(Class.forType<Person>())) {
///   print('User is a subclass of Person');
/// }
///
/// // Iterate over all methods
/// for (final method in userClass.getAllMethods()) {
///   print(method.name);
/// }
///
/// // Access generic type parameters
/// final genericArgs = userClass.getAllGenericArguments();
/// for (final arg in genericArgs) {
///   print(arg.getName());
/// }
///
/// // Discover annotations
/// final serializable = userClass.getAnnotation<Serializable>();
/// if (serializable != null) {
///   print('User class is serializable');
/// }
/// ```
///
/// Type Parameters:
/// - `T`: The concrete Dart type that this [Class] instance represents.
/// {@endtemplate}
@Generic(Class)
abstract final class Class<T> extends Source implements FieldAccess, QualifiedName, GenericSource {
  /// The garbage key identifier used by [Class] in [GC] to store cache and perform any other actions
  /// in the garbage collector
  static const String GARBAGE_KEY = "jl:::class:::declaration";

  @override
  Declaration getDeclaration() {
    checkAccess("getDeclaration", DomainPermission.READ_TYPE_INFO);
    return getClassDeclaration();
  }

  /// Gets the type declaration of this class.
  ///
  /// {@template class_get_type_declaration}
  /// Returns:
  /// - The [ClassDeclaration] representing the class
  /// {@endtemplate}
  ClassDeclaration getClassDeclaration();

  // ---------------------------------------------------------------------------------------------------------
  // === Name Information ===
  // ---------------------------------------------------------------------------------------------------------
  
  /// Gets the simple class name without package or generic information.
  ///
  /// {@template class_simple_name}
  /// Returns:
  /// - The base class name (e.g., `Iterable` for `Iterable<String>`)
  ///
  /// Example:
  /// ```dart
  /// Class.forType<Iterable<String>>().getSimpleName(); // 'Iterable'
  /// ```
  /// {@endtemplate}
  String getSimpleName();

  /// Gets the canonical name with complete generic type information.
  ///
  /// {@template class_canonical_name}
  /// Returns:
  /// - The complete type signature including all generic parameters
  /// - Differs from [getName] by preserving exact generic specifications
  /// - Used for precise type matching and cache keys
  ///
  /// ## Canonical vs Name
  /// - **getName()**: May return simplified or display-friendly names
  /// - **getCanonicalName()**: Always returns complete, unambiguous type signature
  ///
  /// Example:
  /// ```dart
  /// final mapClass = Class.forType<Map<String, Iterable<int>>>();
  /// print(mapClass.getName());          // May return 'Map'
  /// print(mapClass.getCanonicalName()); // Returns 'Map<String, Iterable<int>>'
  /// ```
  ///
  /// ## Use Cases
  /// - Type equality comparisons
  /// - Cache key generation
  /// - Serialization/deserialization
  /// - Generic type preservation
  /// {@endtemplate}
  String getCanonicalName();

  // ---------------------------------------------------------------------------------------------------------
  // === Package Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Retrieves the **package URI** where this class is defined.
  ///
  /// {@template class_package_uri}
  /// This method returns a string identifying the package location of the
  /// class source. It is typically used for diagnostics, reflection, or
  /// resolving resources relative to the package.
  ///
  /// ### Returns
  /// - The package URI as a string, e.g., `package:myapp/models.dart`.
  /// - `dart:core` for Dart core types (e.g., `int`, `String`).
  /// - May be empty for dynamically generated or runtime-only types.
  ///
  /// ### Usage
  /// ```dart
  /// print(myClass.getPackageUri()); // → package:myapp/models.dart
  /// ```
  ///
  /// {@endtemplate}
  String getPackageUri();

  /// Retrieves the **package metadata** object containing this class.
  ///
  /// {@template class_get_package}
  /// Provides access to higher-level package information such as name,
  /// version, and other metadata tracked by Jetleaf’s reflection system.
  ///
  /// ### Returns
  /// - A [Package] object representing the package containing the class.
  /// - `null` if the class belongs to Dart core types or if package
  ///   information is unavailable.
  ///
  /// ### Usage
  /// ```dart
  /// final package = myClass.getPackage();
  /// if (package != null) {
  ///   print(package.getName());
  /// }
  /// ```
  ///
  /// {@endtemplate}
  Package getPackage();

  // ---------------------------------------------------------------------------------------------------------
  // === Type Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Returns the **runtime-resolved Dart type** represented by this [Class].
  ///
  /// {@template class_get_type}
  /// This method exposes the `Type` object as it exists at runtime after
  /// Dart’s generic resolution and potential type erasure have been applied.
  ///
  /// ### Returns
  /// - A Dart [Type] instance corresponding to the resolved runtime type.
  /// - Generic parameters are included *only if* they are preserved by the
  ///   runtime and available through reflection.
  ///
  /// ### Usage
  /// ```dart
  /// final type = clazz.getType();
  /// print(type); // e.g. Iterable<String> or Iterable<dynamic>
  /// ```
  ///
  /// ### Notes
  /// - Due to Dart’s runtime model, generic information may be partially or
  ///   fully erased depending on context.
  /// - This method reflects what Dart itself recognizes as the type at
  ///   runtime, not necessarily the type originally requested by Jetleaf.
  ///
  /// {@endtemplate}
  Type getType();

  /// Returns the **original, Jetleaf-resolved type** requested by this [Class].
  ///
  /// {@template class_get_original}
  /// Unlike [getType], this method exposes the type as **intended and tracked
  /// by Jetleaf’s reflection system**, even when Dart’s runtime has erased or
  /// altered generic information.
  ///
  /// This distinction exists because Jetleaf employs its own strategy for
  /// modeling generic types and mitigating Dart’s type-erasure behavior.
  ///
  /// ### Returns
  /// - The underlying Dart [Type] corresponding to the original generic
  ///   declaration.
  /// - May differ from [getType] when generic parameters are erased or
  ///   normalized by the runtime.
  ///
  /// ### Example
  /// ```dart
  /// final runtimeType = clazz.getType();     // e.g. Iterable<dynamic>
  /// final originalType = clazz.getOriginal(); // e.g. Iterable<String>
  /// ```
  ///
  /// ### Design Notes
  /// - Use [getOriginal] when exact generic intent matters (e.g. dependency
  ///   resolution, serialization, or code generation).
  /// - Use [getType] when interacting with Dart runtime APIs or type checks.
  ///
  /// {@endtemplate}
  Type getOriginal();

  // ---------------------------------------------------------------------------------------------------------
  // === Type Comparators ===
  // ---------------------------------------------------------------------------------------------------------
  
  /// Checks type assignability from another class.
  ///
  /// {@template class_is_assignable}
  /// Parameters:
  /// - [other]: The potential supertype to check
  ///
  /// Returns:
  /// - `true` if this class can be assigned to [other]
  /// - `false` otherwise
  ///
  /// Example:
  /// ```dart
  /// Class.forType<Circle>().isAssignableFrom(Class.forType<Shape>()); // true
  /// ```
  /// 
  /// #### Type Assignability Table:
  /// ```sql
  /// DART TYPE ASSIGNABILITY TABLE
  /// ────────────────────────────────────────────────────────────────────────────
  /// From (B) → To (A)                     A.isAssignableFrom(B)   Valid?   Notes
  /// ────────────────────────────────────────────────────────────────────────────
  /// Object    ← String                   ✅ true                  ✅      String extends Object
  /// String    ← Object                   ❌ false                 ❌      Super not assignable from subclass
  /// num       ← int                      ✅ true                  ✅      int is a subclass of num
  /// int       ← num                      ❌ false                 ❌      num is broader than int
  /// Iterable<int> ← Iterable<int>                ✅ true                  ✅      Same type
  /// Iterable<T>   ← Iterable<S>                  ❌ false                 ❌      Dart generics are invariant
  /// Iterable<dynamic> ← Iterable<int>            ❌ false                 ❌      Still invariant
  /// A         ← B (B extends A)          ✅ true                  ✅      Subclass to superclass is OK
  /// A         ← C (unrelated)            ❌ false                 ❌      No inheritance/interface link
  /// Interface ← Class implements Itf     ✅ true                  ✅      Implements is assignable to interface
  /// Mixin     ← Class with Mixin         ✅ true                  ✅      Mixed-in type present
  /// dynamic   ← anything                 ✅ true                  ✅      dynamic accepts all types
  /// anything  ← dynamic                  ✅ true (unsafe)         ✅      Allowed but unchecked
  /// Never     ← anything                 ❌ false                 ❌      Never can’t accept anything
  /// anything  ← Never                    ✅ true                  ✅      Never fits anywhere (bottom type)
  /// ────────────────────────────────────────────────────────────────────────────
  ///
  /// RULE OF THUMB:
  /// A.isAssignableFrom(B) → Can you do: A a = B();
  /// ✓ Subclass → Superclass: OK
  /// ✗ Superclass → Subclass: Not OK
  /// ✓ Class implements Interface → Interface: OK
  /// ✗ Interface → Class: Not OK
  /// ✓ Identical types: OK
  /// ✗ Unrelated types: Not OK
  /// ```
  ///
  /// Checks if this type is assignable from the given [other] type.
  /// 
  /// Returns `true` if a value of type [other] can be assigned to a variable of this type.
  /// This follows Dart's assignability rules including inheritance, interfaces, and mixins.
  /// {@endtemplate}
  bool isAssignableFrom(Class other);

  /// Checks if this type is assignable to another type.
  ///
  /// {@template class_is_assignable_to}
  /// Parameters:
  /// - [other]: The target type to check assignability to
  ///
  /// Returns:
  /// - `true` if this type can be assigned to [other]
  /// - `false` otherwise
  ///
  /// ## Assignability Rules
  /// This method implements Dart's type assignability rules:
  /// - Subclass to superclass: ✅ Allowed
  /// - Superclass to subclass: ❌ Not allowed
  /// - Class to implemented interface: ✅ Allowed
  /// - Interface to implementing class: ❌ Not allowed
  /// - Identical types: ✅ Allowed
  /// - Unrelated types: ❌ Not allowed
  ///
  /// #### Type Assignability Table:
  /// ```sql
  /// DART TYPE ASSIGNABILITY TABLE
  /// ────────────────────────────────────────────────────────────────────────────
  /// From (A) → To (B)                   A.isAssignableTo(B)   Valid?   Notes
  /// ────────────────────────────────────────────────────────────────────────────
  /// String    → Object                 ✅ true               ✅      String extends Object
  /// Object    → String                 ❌ false              ❌      Superclass to subclass not allowed
  /// int       → num                    ✅ true               ✅      int is a subtype of num
  /// num       → int                    ❌ false              ❌      Can't assign broader to narrower
  /// Iterable<int> → Iterable<int>              ✅ true               ✅      Identical type
  /// Iterable<S>   → Iterable<T>                ❌ false              ❌      Dart generics are invariant
  /// Iterable<int> → Iterable<dynamic>          ❌ false              ❌      Invariant generics
  /// B         → A (B extends A)        ✅ true               ✅      Subclass to superclass: OK
  /// C         → A (no relation)        ❌ false              ❌      Unrelated types
  /// Class     → Interface (implements) ✅ true               ✅      Implements interface
  /// Class     → Mixin (with mixin)     ✅ true               ✅      Class includes mixin
  /// anything  → dynamic                ✅ true               ✅      Everything is assignable to dynamic
  /// dynamic   → anything               ✅ true (unchecked)   ✅      Allowed but unsafe
  /// anything  → Never                  ❌ false              ❌      Can't assign anything to Never
  /// Never     → anything               ✅ true               ✅      Never fits anywhere
  /// ────────────────────────────────────────────────────────────────────────────
  ///
  /// RULE OF THUMB:
  /// A.isAssignableTo(B) → Can you do: B b = A();
  /// ✓ Subclass → Superclass: OK
  /// ✗ Superclass → Subclass: Not OK
  /// ✓ Class → Interface it implements: OK
  /// ✗ Interface → Class: Not OK
  /// ✓ Identical types: OK
  /// ✗ Unrelated types: Not OK
  /// ```
  ///
  /// ## Example
  /// ```dart
  /// final stringClass = Class.forType<String>();
  /// final objectClass = Class.forType<Object>();
  /// 
  /// print(stringClass.isAssignableTo(objectClass)); // true - String → Object
  /// print(objectClass.isAssignableTo(stringClass)); // false - Object → String
  /// ```
  ///
  /// ## Relationship to isAssignableFrom
  /// This is the inverse of [isAssignableFrom]:
  /// - `A.isAssignableTo(B)` ≡ `B.isAssignableFrom(A)`
  /// - Use [isAssignableTo] when asking "Can I assign this to that?"
  /// - Use [isAssignableFrom] when asking "Can that be assigned to this?"
  /// {@endtemplate}
  bool isAssignableTo(Class other);

  /// Indicates whether this class is **synthetic** (framework-generated)
  /// rather than directly declared in user source code.
  ///
  /// {@template class_is_synthetic}
  /// A *synthetic class* is a logical or derived representation created
  /// by Jetleaf to model language constructs that do not have a concrete,
  /// user-declared class definition.
  ///
  /// Synthetic classes commonly arise from:
  /// - Function signatures (e.g. [FunctionClass])
  /// - Record types (future support)
  /// - Parameter or method-derived types
  /// - Internal framework adapters or proxies
  ///
  /// ### Behavior
  /// - `true` if the class is generated or inferred by the framework
  /// - `false` if the class corresponds to a real, user-declared type
  ///
  /// ### Example
  /// ```dart
  /// final param = method.getParameter('callback');
  /// final cls = param.getClass();
  ///
  /// cls.isSynthetic(); // → true for FunctionClass
  /// ```
  ///
  /// ### Notes
  /// - Synthetic classes typically cannot be instantiated directly.
  /// - They may not have a source file, package URI, or constructors.
  /// - This flag is essential for distinguishing *structural types*
  ///   from *runtime types* during reflection and dependency resolution.
  ///
  /// {@endtemplate}
  bool isSynthetic();

  /// {@template method_isAsync}
  /// Determines whether this method is asynchronous.
  ///
  /// A method is considered asynchronous if its declared return type
  /// is either [Future] or [FutureOr]. This check allows AOP or reflection
  /// mechanisms to distinguish between synchronous and asynchronous methods
  /// when performing advice invocation, proxying, or instrumentation.
  ///
  /// ## Example
  /// ```dart
  /// class UserService {
  ///   Future<void> fetchUser() async {}
  ///   void saveUser() {}
  /// }
  ///
  /// final methodFetch = Class(UserService).getMethod('fetchUser');
  /// final methodSave = Class(UserService).getMethod('saveUser');
  ///
  /// print(methodFetch.isAsync()); // true
  /// print(methodSave.isAsync());  // false
  /// ```
  ///
  /// @return `true` if the method's return type is [Future] or [FutureOr],
  ///         `false` otherwise.
  /// {@endtemplate}
  bool isAsync();

  /// Checks if the display name matches the canonical name.
  /// 
  /// {@template class_is_canonical}
  /// Returns:
  /// - `true` if [getName] and [getCanonicalName] return identical values
  /// - `false` if they differ (e.g., simplified vs complete generic names)
  ///
  /// ## Purpose
  /// Determines whether the class name includes complete generic information
  /// or uses a simplified representation. This is important for:
  /// - Type resolution accuracy
  /// - Generic parameter preservation
  /// - Cache key consistency
  ///
  /// ## Example
  /// ```dart
  /// final listClass = Class.forType<Iterable<String>>();
  /// if (!listClass.isCanonical()) {
  ///   // Use getCanonicalName() for precise type information
  ///   final fullName = listClass.getCanonicalName();
  /// }
  /// ```
  ///
  /// ## Implementation Note
  /// Normally, [getName] can return simplified names for display purposes,
  /// while [getCanonicalName] preserves complete generic specifications.
  /// This method helps determine which name format is being used.
  /// {@endtemplate}
  bool isCanonical();

  /// Checks whether this declaration represents a **closure-backed class**.
  ///
  /// A *closure* in Jetleaf is a synthetic class representation created for
  /// anonymous functions, lambdas, or inline function expressions that do not
  /// have an explicit class declaration in source code.
  ///
  /// When `true`, this declaration:
  /// - Represents a runtime **function object** rather than a named class
  /// - Is typically generated from a `ClosureMirror`
  /// - Wraps an executable function via a [ClosureDeclaration]
  ///
  /// ---
  ///
  /// #### What Returns `true`
  ///
  /// - Anonymous functions:
  ///   ```dart
  ///   final fn = () => print('hello');
  ///   ```
  /// - Inline callbacks:
  ///   ```dart
  ///   list.forEach((item) => print(item));
  ///   ```
  /// - Any runtime-reflected function without a concrete class declaration
  ///
  /// ---
  ///
  /// #### What Returns `false`
  ///
  /// - Regular classes
  /// - Mixins
  /// - Enums
  /// - Records or named function types
  ///
  /// ---
  ///
  /// #### Relationship to Other Type Checks
  ///
  /// | Method        | Purpose                         |
  /// |---------------|---------------------------------|
  /// | [isClass]     | Standard class declaration      |
  /// | [isMixin]     | Mixin declaration               |
  /// | [isEnum]      | Enum declaration                |
  /// | **[isClosure]** | Anonymous / function-backed type |
  ///
  /// ---
  ///
  /// #### Example
  ///
  /// ```dart
  /// final callback = () => 42;
  /// final decl = Runtime.obtainClassDeclaration(callback);
  ///
  /// if (decl.isClosure()) {
  ///   print('This declaration represents a closure');
  /// }
  /// ```
  ///
  /// Use this method to distinguish **function-backed runtime types** from
  /// source-defined classes when performing reflection or code generation.
  bool isClosure();

  /// Checks if this class represents a standard class type.
  ///
  /// {@template class_is_class}
  /// Returns:
  /// - `true` for regular class declarations
  /// - `false` for other declaration types (mixin, enum, etc.)
  ///
  /// Example:
  /// ```dart
  /// class User {}
  /// Class<User>().isClass(); // true
  /// ```
  /// {@endtemplate}
  /// 
  /// See: [isMixin], [isEnum]
  /// 
  /// Deprecated
  bool isClass();

  /// Determines whether this class is a **subclass** of [other].
  ///
  /// This checks the inheritance hierarchy to see if this class
  /// directly or transitively extends the given [other] class.
  ///
  /// ---
  ///
  /// ### Parameters
  /// - [other]: The class to test against
  ///
  /// ### Returns
  /// - `true` if this class extends or derives from [other]
  /// - `false` otherwise
  ///
  /// ### Example
  /// ```dart
  /// Class<Admin>().isSubclassOf(Class<User>()); // true
  /// ```
  bool isSubclassOf(Class other);

  /// Checks whether this class represents an **array-like type**.
  ///
  /// Array types include:
  /// - `List<T>`
  /// - `Set<T>`
  /// - Other collection types treated as arrays by the runtime
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if the class is considered array-like
  /// - `false` otherwise
  bool isArray();

  /// Checks whether this class represents a **primitive type**.
  ///
  /// Primitive types typically include:
  /// - `int`, `double`, `num`
  /// - `bool`
  /// - `String`
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if the class is a primitive type
  /// - `false` otherwise
  bool isPrimitive();

  /// Checks whether the given [obj] is an **instance of this class** at runtime.
  ///
  /// This performs a runtime-compatible instance check, accounting for
  /// generics, type erasure, and reflection constraints.
  ///
  /// ---
  ///
  /// ### Parameters
  /// - [obj]: The object to test
  ///
  /// ### Returns
  /// - `true` if [obj] is an instance of this class
  /// - `false` otherwise
  ///
  /// ### Example
  /// ```dart
  /// final user = User();
  /// Class<User>().isInstance(user); // true
  /// ```
  bool isInstance(Object? obj);

  /// Checks whether this class represents a **record type**.
  ///
  /// Record types are modeled using [RecordDeclaration] and correspond
  /// to Dart record syntax.
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if this class represents a record
  /// - `false` otherwise
  bool isRecord();

  /// Checks whether this class represents a **function type**.
  ///
  /// Function types are modeled using [FunctionDeclaration] and include:
  /// - Top-level functions
  /// - Closures
  /// - Callable class types
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if this class represents a function type
  /// - `false` otherwise
  bool isFunction();

  /// Checks whether this class represents a **mixin declaration**.
  ///
  /// Mixins are represented by [MixinDeclaration] and are declared
  /// using the `mixin` keyword.
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if this class is a mixin
  /// - `false` otherwise
  bool isMixin();

  /// Checks whether this class represents an **enum declaration**.
  ///
  /// Enums are represented using [EnumDeclaration].
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if this class is an enum
  /// - `false` otherwise
  bool isEnum();

  /// Checks whether this class is declared as **abstract**.
  ///
  /// Abstract classes cannot be directly instantiated and may contain
  /// abstract members.
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if the class is abstract
  /// - `false` otherwise
  bool isAbstract();

  /// Checks whether this class is declared as **final**.
  ///
  /// Final classes cannot be extended by other classes.
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if the class is final
  /// - `false` otherwise
  bool isFinal();

  /// Checks whether this class is declared as **sealed**.
  ///
  /// Sealed classes restrict which classes may extend them and enable
  /// exhaustive pattern matching.
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if the class is sealed
  /// - `false` otherwise
  bool isSealed();

  /// Checks whether this class represents an **interface**.
  ///
  /// Interfaces are abstract classes that:
  /// - Have no concrete instance members
  /// - Are intended to be implemented, not extended
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if the class is an interface
  /// - `false` otherwise
  bool isInterface();

  /// Checks whether this class is declared as a **base class**.
  ///
  /// Base classes may be extended but cannot be implemented outside
  /// their defining library.
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if the class is a base class
  /// - `false` otherwise
  bool isBase();

  /// Checks whether this class is **invokable**.
  ///
  /// A class is considered invokable if:
  /// - It is not abstract, or
  /// - It is abstract but declares at least one factory constructor
  ///
  /// Invokable classes can be instantiated or executed via the runtime.
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if the class can be invoked
  /// - `false` otherwise
  bool isInvokable();

  /// Checks whether this class represents the **void** type.
  ///
  /// This is commonly represented using the [Void] design abstraction
  /// within Jetleaf.
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if this class represents `void`
  /// - `false` otherwise
  bool isVoid();

  /// Checks whether this class represents the **dynamic** type.
  ///
  /// This is commonly represented using the [Dynamic] design abstraction
  /// within Jetleaf and indicates absence of static typing.
  ///
  /// ---
  ///
  /// ### Returns
  /// - `true` if this class represents `dynamic`
  /// - `false` otherwise
  bool isDynamic();

  // ---------------------------------------------------------------------------------------------------------
  // === Function Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Returns the **declared return type** of the function signature.
  ///
  /// {@template function_class_get_return_type}
  /// This describes what the function *produces* when invoked,
  /// not the type of the parameter holding it.
  ///
  /// ### Example
  /// ```dart
  /// // Parameter type:
  /// // String Function() user
  ///
  /// final param = method.getParameter('user');
  /// final fc = param.getClass() as FunctionClass;
  ///
  /// fc.getReturnType(); // → Class<String>
  /// ```
  ///
  /// This enables precise differentiation between:
  /// - `String user`
  /// - `String Function() user`
  /// 
  /// For non function declarations, this will always return the current class.
  /// {@endtemplate}
  Class<Object> getReturnType();

  /// Indicates whether the function type itself is nullable.
  ///
  /// {@template function_class_get_is_nullable}
  /// This reflects Dart null-safety at the *type-signature* level:
  ///
  /// - `String Function()` → non-nullable
  /// - `String Function()?` → nullable
  ///
  /// This does **not** describe the return type’s nullability.
  /// {@endtemplate}
  bool getIsNullable();

  /// Returns the reflective `call()` method if the function originates
  /// from a callable object.
  ///
  /// {@template function_class_get_method_call}
  /// This is primarily used when a function type is backed by
  /// an object implementing `call()`.
  ///
  /// For pure function signatures, this may be `null`.
  ///
  /// This distinction allows Jetleaf to unify:
  /// - Lambdas
  /// - Function tear-offs
  /// - Callable objects
  /// {@endtemplate}
  Method? getMethodCall();

  /// Returns the ordered list of **parameter types** accepted by the function.
  ///
  /// {@template function_class_get_parameters}
  /// These parameters describe the callable contract itself,
  /// not the surrounding method or constructor.
  ///
  /// ### Example
  /// ```dart
  /// // Parameter type:
  /// // int Function(String name, bool active)
  ///
  /// final fc = param.getClass() as FunctionClass;
  ///
  /// fc.getParameters(); // → [Class<String>, Class<bool>]
  /// ```
  ///
  /// This allows tooling and frameworks to:
  /// - Validate compatibility
  /// - Perform dependency resolution
  /// - Generate adapters or proxies
  /// {@endtemplate}
  Iterable<Class<Object>> getParameters();

  // ---------------------------------------------------------------------------------------------------------
  // === Record Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Returns a list of all fields in this record.
  ///
  /// - Positional fields are listed in order.
  /// - Named fields may appear in any order, but their `RecordField` object
  ///   contains the name for identification.
  Iterable<RecordField> getRecordFields();

  /// Retrieves a single record field by its identifier.
  ///
  /// The [id] can be:
  /// - `int` → for positional fields (zero-based index)
  /// - `String` → for named fields
  ///
  /// Returns the corresponding [RecordField] or `null` if no field matches.
  RecordField? getRecordField(Object id);

  // ---------------------------------------------------------------------------------------------------------
  // === Generic Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Returns the concrete generic type arguments declared on this class.
  ///
  /// {@template class_get_type_arguments}
  /// This method exposes the resolved generic parameters associated with
  /// this [Class] instance.
  ///
  /// For example, given:
  /// ```dart
  /// class Box<T> {}
  /// class StringBox extends Box<String> {}
  /// ```
  /// Calling `getTypeArguments()` on `Class<StringBox>` would return a list
  /// containing `Class<String>`.
  ///
  /// ### Behavior
  /// - Returns an empty list if the class is not generic.
  /// - The order of elements matches the declaration order of the
  ///   type parameters.
  /// - Returned [Class] objects represent the *actual* resolved types,
  ///   not just the formal type variables.
  ///
  /// ### Returns
  /// - A list of [Class<Object>] representing the resolved type arguments.
  /// {@endtemplate}
  Iterable<Class<Object>> getTypeArguments();

  /// Returns metadata links describing how generic type arguments are bound.
  ///
  /// {@template class_get_type_argument_links}
  /// This method provides structural information about the relationship
  /// between declared type parameters and their resolved arguments.
  ///
  /// [LinkDeclaration] instances may encode:
  /// - The source type parameter,
  /// - The target concrete type,
  /// - Variance or positional binding information,
  /// - Indirections through inherited or delegated generic declarations.
  ///
  /// This is primarily intended for advanced reflection, diagnostics,
  /// and framework-level type resolution.
  ///
  /// ### Behavior
  /// - Returns an empty list if no generic linkage information is available.
  /// - The order corresponds to the declaration order of type parameters.
  ///
  /// ### Returns
  /// - A list of [LinkDeclaration] objects describing generic bindings.
  /// {@endtemplate}
  List<LinkDeclaration> getTypeArgumentLinks();

  // ---------------------------------------------------------------------------------------------------------
  // === Super Class Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Returns the direct superclass of this class, if one exists.
  ///
  /// This represents the class specified in the `extends` clause of the
  /// declaration. For `Object` and root-level types, this will return `null`.
  ///
  /// ---
  ///
  /// ### Type Parameters
  /// - `S`: The expected superclass type
  ///
  /// ### Returns
  /// - The superclass declaration if it exists and matches [S]
  /// - `null` if:
  ///   - The class does not extend another class, or
  ///   - The superclass does not match the requested type
  ///
  /// ### Example
  /// ```dart
  /// class Admin extends User {}
  ///
  /// Class<Admin>().getSuperClass<User>(); // → Class<User>
  /// ```
  Class<S>? getSuperClass<S>();

  /// Returns the **generic type arguments** supplied to the superclass.
  ///
  /// This extracts the concrete type arguments used in the `extends` clause
  /// when the superclass is a generic type.
  ///
  /// ---
  ///
  /// ### Returns
  /// - An [Iterable] of superclass generic type arguments
  /// - An empty iterable if:
  ///   - The class has no superclass, or
  ///   - The superclass is non-generic
  ///
  /// ### Example
  /// ```dart
  /// class Box<T> {}
  /// class IntBox extends Box<int> {}
  ///
  /// Class<IntBox>().getSuperClassArguments(); // → [Class<int>]
  /// ```
  Iterable<Class> getSuperClassArguments();

  // ---------------------------------------------------------------------------------------------------------
  // === Sub Class Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Returns all known direct subclasses of this class within the active
  /// reflection runtime.
  ///
  /// A subclass is any class that directly extends this class. Results are
  /// determined from the materialized runtime graph and are scoped to the
  /// currently loaded libraries.
  ///
  /// ---
  ///
  /// ### Returns
  /// - An [Iterable] of subclass declarations
  /// - An empty iterable if no subclasses are known
  ///
  /// ### Notes
  /// - Only direct subclasses are included
  /// - Indirect (transitive) subclasses are not returned
  /// - Results are deterministic after the library is frozen
  ///
  /// ### Example
  /// ```dart
  /// abstract class Shape {}
  /// class Circle extends Shape {}
  /// class Square extends Shape {}
  ///
  /// Class<Shape>().getSubClasses();
  /// // → [Class<Circle>, Class<Square>]
  /// ```
  Iterable<Class> getSubClasses();

  /// Returns a specific direct subclass that matches type [S], if present.
  ///
  /// ---
  ///
  /// ### Type Parameters
  /// - `S`: The subclass type to retrieve
  ///
  /// ### Returns
  /// - The matching subclass declaration
  /// - `null` if no direct subclass of type [S] exists
  ///
  /// ### Notes
  /// - Only direct subclasses are considered
  ///
  /// ### Example
  /// ```dart
  /// Class<Shape>().getSubClass<Circle>(); // → Class<Circle>
  /// ```
  Class<S>? getSubClass<S>();

  // ---------------------------------------------------------------------------------------------------------
  // === Interface Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Returns **all interfaces implemented by this class**, including those
  /// inherited through superclasses.
  ///
  /// ---
  ///
  /// {@template class_get_all_interfaces}
  /// ### Returns
  /// - An [Iterable] of all implemented interfaces (direct + transitive)
  /// - An empty iterable if the class does not implement any interfaces
  ///
  /// ### Notes
  /// - Includes interfaces declared directly on the class
  /// - Includes interfaces inherited from superclasses
  /// - Order is deterministic but implementation-defined
  /// {@endtemplate}
  Iterable<Class> getAllInterfaces();

  /// Returns all implemented interfaces that match the given interface type [I].
  ///
  /// ---
  ///
  /// {@template class_get_interfaces}
  /// ### Type Parameters
  /// - `I`: The interface type to filter for
  ///
  /// ### Returns
  /// - An [Iterable] of interfaces assignable to type [I]
  /// - An empty iterable if no matching interfaces are implemented
  ///
  /// ### Notes
  /// - Matching includes generic interface instantiations
  /// - Inherited interfaces are included
  /// {@endtemplate}
  Iterable<Class<I>> getInterfaces<I>();

  /// Returns the implemented interface that exactly matches type [I], if present.
  ///
  /// ---
  ///
  /// {@template class_get_interface}
  /// ### Type Parameters
  /// - `I`: The exact interface type to retrieve
  ///
  /// ### Returns
  /// - The matching interface declaration if implemented
  /// - `null` if the interface is not implemented
  ///
  /// ### Notes
  /// - If multiple generic instantiations exist, the most specific match
  ///   is returned
  /// {@endtemplate}
  Class<I>? getInterface<I>();

  /// Returns the **generic type arguments** used when implementing
  /// the interface of type [I].
  ///
  /// ---
  ///
  /// {@template class_get_interface_arguments}
  /// ### Type Parameters
  /// - `I`: The interface type whose generic arguments should be extracted
  ///
  /// ### Returns
  /// - An [Iterable] of generic type arguments
  /// - An empty iterable if:
  ///   - The interface is not implemented, or
  ///   - The interface is non-generic
  ///
  /// ### Example
  /// ```dart
  /// class Repo implements Store<User> {}
  ///
  /// Class<Repo>()
  ///   .getInterfaceArguments<Store>(); // → [Class<User>]
  /// ```
  /// {@endtemplate}
  Iterable<Class> getInterfaceArguments<I>();

  /// Returns the **generic type arguments** from all implemented interfaces.
  ///
  /// ---
  ///
  /// {@template class_get_all_interface_arguments}
  /// ### Returns
  /// - A flattened [Iterable] of all generic arguments used by implemented interfaces
  /// - An empty iterable if no implemented interfaces declare generics
  ///
  /// ### Notes
  /// - Includes arguments from inherited interfaces
  /// - Order is deterministic
  /// {@endtemplate}
  Iterable<Class> getAllInterfaceArguments();

  // ---------------------------------------------------------------------------------------------------------
  // === Mixin Constraint Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Returns **all mixin constraints** applied to this mixin.
  ///
  /// Mixin constraints are the interfaces or classes specified using the
  /// `on` clause of a mixin declaration. These constraints define the
  /// minimum required supertype(s) that a class must satisfy in order to
  /// apply the mixin.
  ///
  /// ---
  ///
  /// ### Returns
  /// - An [Iterable] of all mixin constraint types
  /// - An empty iterable if the mixin declares no constraints
  ///
  /// ### Notes
  /// - Only applicable to mixin declarations
  /// - Order reflects the declaration order in the source
  ///
  /// ### Example
  /// ```dart
  /// mixin Logger on Service, Disposable {}
  ///
  /// Class<Logger>().getAllMixinConstraints();
  /// // → [Class<Service>, Class<Disposable>]
  /// ```
  Iterable<Class> getAllMixinConstraints();

  /// Returns all mixin constraints that match the given constraint type [I].
  ///
  /// This allows filtering mixin constraints by a specific interface or
  /// superclass type.
  ///
  /// ---
  ///
  /// ### Type Parameters
  /// - `I`: The constraint type to filter for
  ///
  /// ### Returns
  /// - An [Iterable] of matching mixin constraints
  /// - An empty iterable if no matching constraints are found
  ///
  /// ### Notes
  /// - Matching includes generic instantiations
  /// - Inherited constraints are not considered (only declared `on` clauses)
  Iterable<Class<I>> getMixinConstraints<I>();

  /// Returns the mixin constraint that exactly matches type [I], if present.
  ///
  /// ---
  ///
  /// ### Type Parameters
  /// - `I`: The exact constraint type to retrieve
  ///
  /// ### Returns
  /// - The matching constraint declaration if present
  /// - `null` if the constraint is not declared
  ///
  /// ### Notes
  /// - If multiple generic instantiations exist, the most specific match
  ///   is returned
  Class<I>? getMixinConstraint<I>();

  /// Returns the **generic type arguments** used by the mixin constraint [I].
  ///
  /// This method extracts the concrete type arguments supplied to a generic
  /// constraint in the mixin’s `on` clause.
  ///
  /// ---
  ///
  /// ### Type Parameters
  /// - `I`: The constraint type whose generic arguments should be extracted
  ///
  /// ### Returns
  /// - An [Iterable] of generic type arguments
  /// - An empty iterable if:
  ///   - The constraint is not declared, or
  ///   - The constraint is non-generic
  ///
  /// ### Example
  /// ```dart
  /// mixin Cacheable on Store<User> {}
  ///
  /// Class<Cacheable>()
  ///   .getMixinConstraintArguments<Store>(); // → [Class<User>]
  /// ```
  Iterable<Class> getMixinConstraintArguments<I>();

  /// Returns the **generic type arguments** from all declared mixin constraints.
  ///
  /// ---
  ///
  /// ### Returns
  /// - A flattened [Iterable] of all generic arguments used by mixin constraints
  /// - An empty iterable if none of the constraints declare generics
  ///
  /// ### Notes
  /// - Only constraints declared directly on the mixin are considered
  /// - Order is deterministic and follows declaration order
  Iterable<Class> getAllMixinConstraintArguments();

  // ---------------------------------------------------------------------------------------------------------
  // === Mixin Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Returns all mixins applied to this class or mixin declaration.
  ///
  /// This includes every mixin specified in a `with` clause, in the exact
  /// order they appear in the source declaration.
  ///
  /// ---
  ///
  /// ### Returns
  /// - An [Iterable] of mixin class declarations
  /// - An empty iterable if no mixins are applied
  ///
  /// ### Notes
  /// - Only mixins explicitly declared via `with` are included
  /// - Transitive or inherited mixins are not included
  ///
  /// ### Example
  /// ```dart
  /// class MyService with Logging, Cacheable {}
  ///
  /// Class<MyService>().getAllMixins();
  /// // → [Class<Logging>, Class<Cacheable>]
  /// ```
  Iterable<Class> getAllMixins();

  /// Returns all applied mixins that match the given mixin type [I].
  ///
  /// ---
  ///
  /// ### Type Parameters
  /// - `I`: The mixin type to filter for
  ///
  /// ### Returns
  /// - An [Iterable] of matching mixin declarations
  /// - An empty iterable if no matching mixins are found
  ///
  /// ### Notes
  /// - Matching includes generic instantiations
  /// - Only mixins declared directly on the target are considered
  Iterable<Class<I>> getMixins<I>();

  /// Returns the mixin that exactly matches type [I], if present.
  ///
  /// ---
  ///
  /// ### Type Parameters
  /// - `I`: The exact mixin type to retrieve
  ///
  /// ### Returns
  /// - The matching mixin declaration
  /// - `null` if the mixin is not applied
  ///
  /// ### Notes
  /// - If multiple generic instantiations exist, the most specific match
  ///   is returned
  Class<I>? getMixin<I>();

  /// Returns the **generic type arguments** supplied to the applied mixin [M].
  ///
  /// This extracts the concrete generic arguments used when the mixin was
  /// applied in the `with` clause.
  ///
  /// ---
  ///
  /// ### Type Parameters
  /// - `M`: The mixin type whose generic arguments should be extracted
  ///
  /// ### Returns
  /// - An [Iterable] of generic type arguments
  /// - An empty iterable if:
  ///   - The mixin is not applied, or
  ///   - The mixin is non-generic
  ///
  /// ### Example
  /// ```dart
  /// class Repo with Cacheable<User> {}
  ///
  /// Class<Repo>()
  ///   .getMixinsArguments<Cacheable>(); // → [Class<User>]
  /// ```
  Iterable<Class> getMixinsArguments<M>();

  /// Returns the **generic type arguments** from all applied mixins.
  ///
  /// ---
  ///
  /// ### Returns
  /// - A flattened [Iterable] of all generic arguments used by applied mixins
  /// - An empty iterable if no applied mixins declare generics
  ///
  /// ### Notes
  /// - Order is deterministic and follows mixin application order
  Iterable<Class> getAllMixinsArguments();

  // ---------------------------------------------------------------------------------------------------------
  // === Annotation Information ===
  // ---------------------------------------------------------------------------------------------------------

  // Gets all annotations applied to this element.
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
  /// for (final ann in element.getAllAnnotations()) {
  ///   print('Found annotation: ${ann.getSignature()}');
  /// }
  /// ```
  /// {@endtemplate}
  Iterable<Annotation> getAllAnnotations();
  
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
  /// final deprecated = method.getAnnotation<Deprecated>();
  /// if (deprecated != null) {
  ///   print('Deprecation message: ${deprecated.message}');
  /// }
  /// ```
  /// {@endtemplate}
  A? getAnnotation<A>();
  
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
  /// final routes = method.getAnnotations<Route>();
  /// for (final route in routes) {
  ///   print('Route path: ${route.path}');
  /// }
  /// ```
  /// {@endtemplate}
  Iterable<A> getAnnotations<A>();
  
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
  /// if (field.hasAnnotation<Transient>()) {
  ///   print('Field is transient and will not be serialized');
  /// }
  /// ```
  /// {@endtemplate}
  bool hasAnnotation<A>();

  // ---------------------------------------------------------------------------------------------------------
  // === Constructor Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Gets the default unnamed constructor for this class.
  ///
  /// {@template class_get_default_constructor}
  /// Returns:
  /// - The default constructor if one exists
  /// - `null` if the class has no default constructor
  ///
  /// Example:
  /// ```dart
  /// class User {
  ///   User(this.name);  // Default constructor
  ///   final String name;
  /// }
  ///
  /// final constructor = Class.forType<User>().getDefaultConstructor();
  /// print(constructor?.parameters.length); // 1
  /// ```
  /// {@endtemplate}
  Constructor? getDefaultConstructor();

  /// Gets a constructor by its declared name.
  ///
  /// {@template class_get_constructor}
  /// Parameters:
  /// - [name]: The constructor name (empty string for default constructor)
  ///
  /// Returns:
  /// - The matching constructor if found
  /// - `null` if no matching constructor exists
  ///
  /// Example:
  /// ```dart
  /// class Point {
  ///   Point.origin() : x = 0, y = 0;
  /// }
  ///
  /// final constructor = Class.forType<Point>().getConstructor('origin');
  /// ```
  /// 
  /// For factory constructors, include the 'factory' prefix:
  /// ```dart
  /// getConstructor('factory fromJson');
  /// ```
  /// {@endtemplate}
  Constructor? getConstructor(String name);

  /// Gets a constructor by its parameter types.
  ///
  /// {@template class_get_constructor_by_signature}
  /// Parameters:
  /// - [paramTypes]: List of parameter types in exact order
  ///
  /// Returns:
  /// - The exact constructor match if found
  /// - `null` if no matching signature exists
  ///
  /// Example:
  /// ```dart
  /// class Converter {
  ///   String convert(int value) => value.toString();
  ///   String convert(double value) => value.toString();
  /// }
  ///
  /// final constructor = Class.forType<Converter>()
  ///   .getConstructorBySignature([Class.forType<int>()]);
  /// ```
  /// {@endtemplate}
  Constructor? getConstructorBySignature(List<Class> paramTypes);

  /// Gets the best constructor for the given parameter types.
  ///
  /// {@template class_get_best_constructor}
  /// Parameters:
  /// - [paramTypes]: List of parameter types in exact order
  ///
  /// Returns:
  /// - The best constructor match if found
  /// - `null` if no matching signature exists
  ///
  /// Example:
  /// ```dart
  /// class Converter {
  ///   String convert(int value) => value.toString();
  ///   String convert(double value) => value.toString();
  /// }
  ///
  /// final constructor = Class.forType<Converter>()
  ///   .getBestConstructor([Class.forType<int>()]);
  /// ```
  /// {@endtemplate}
  Constructor? getBestConstructor(List<Class> paramTypes);

  /// {@template get_no_arg_constructor}
  /// Retrieves the no-argument constructor of this [Constructor] instance, if available.
  ///
  /// By default, only constructors with **no parameters** are considered.
  /// However, if [acceptWhenAllParametersAreOptional] is set to `true`, then
  /// constructors whose parameters are *all optional* will also be accepted.
  ///
  /// ### Parameters
  /// - [acceptWhenAllParametersAreOptional] (default: `false`)  
  ///   If `true`, constructors where all parameters are optional will be returned
  ///   even if they are not strictly "no-arg".
  ///
  /// ### Returns
  /// - A [Constructor] representing the no-arg constructor if one exists.
  /// - Otherwise, `null`.
  ///
  /// ### Example
  /// ```dart
  /// final clazz = Class<MyService>();
  /// final ctor = clazz.getConstructors()
  ///     .getNoArgConstructor(true);
  ///
  /// if (ctor != null) {
  ///   final instance = ctor.newInstance();
  ///   print("Created instance: $instance");
  /// } else {
  ///   print("No suitable constructor found.");
  /// }
  /// ```
  /// {@endtemplate}
  Constructor? getNoArgConstructor([bool acceptWhenAllParametersAreOptional = false]);

  /// Gets all constructors declared in this class.
  ///
  /// {@template class_get_constructors}
  /// Returns:
  /// - Iterable of all constructors (both generative and factory)
  /// - Empty list if no constructors exist
  ///
  /// Example:
  /// ```dart
  /// final ctors = Class.forType<MyClass>().getConstructors();
  /// ctors.forEach((c) => print(c.name));
  /// ```
  /// 
  /// Includes:
  /// - Default unnamed constructor
  /// - Named constructors
  /// - Factory constructors
  /// {@endtemplate}
  Iterable<Constructor> getConstructors();

  // ---------------------------------------------------------------------------------------------------------
  // === Enum Value Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Gets all enum values if this is an enum class.
  ///
  /// {@template class_get_enum_values}
  /// Returns:
  /// - Iterable of enum fields with metadata
  /// - Empty list for non-enum types
  ///
  /// Example:
  /// ```dart
  /// enum Status { active, inactive }
  /// final values = Class.forType<Status>().getEnumValuesAsFields();
  /// print(values.map((e) => e.name)); // ['active', 'inactive']
  /// ```
  /// {@endtemplate}
  Iterable<EnumValue> getEnumValues();

  // ---------------------------------------------------------------------------------------------------------
  // === Method Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Gets a method by its name.
  ///
  /// {@template class_get_method}
  /// Parameters:
  /// - [name]: The method name to look up
  ///
  /// Returns:
  /// - The first matching method found
  /// - `null` if no method with this name exists
  ///
  /// Example:
  /// ```dart
  /// class Calculator {
  ///   int add(int a, int b) => a + b;
  /// }
  ///
  /// final method = Class.forType<Calculator>().getMethod('add');
  /// print(method?.returnType.getName()); // 'int'
  /// ```
  /// 
  /// Note:
  /// - Does not consider inheritance hierarchy
  /// - For overloaded methods, use [getMethodBySignature]
  /// {@endtemplate}
  Method? getMethod(String name);

  /// Evaluates whether this context contains a method with a signature that matches 
  /// the provided [method] definition.
  ///
  /// A match requires an exact correspondence in both the method name and the precise 
  /// order and types of its parameters, as resolved by [getMethodBySignature].
  ///
  /// ### Example
  /// ```dart
  /// final standardSave = Class.forType<CrudRepository>().getMethodBySignature('save', [Class.forType<User>()]);
  /// 
  /// if (repositoryFragment.hasMatchingMethod(standardSave!)) {
  ///   print('Target fragment can safely intercept this method execution.');
  /// }
  /// ```
  bool hasMatchingMethod(Method method);

  /// Resolves and returns a local [Method] descriptor that matches the signature of the 
  /// provided external [method].
  ///
  /// This scans the available method layout—including instance methods, static methods, 
  /// operators, and accessors—matching against the method's identifier string and exact 
  /// parameter type sequence.
  ///
  /// Returns the matching local [Method] instance, or `null` if no equivalent signature 
  /// layout can be verified.
  ///
  /// ### Example
  /// ```dart
  /// final inboundInvocation = proxy.interceptedMethod;
  /// final localExecutionTarget = fragment.getMatchingMethod(inboundInvocation);
  /// 
  /// if (localExecutionTarget != null) {
  ///   fragment.invoke(localExecutionTarget, arguments);
  /// }
  /// ```
  Method? getMatchingMethod(Method method);

  /// Gets a method by its name and parameter types.
  ///
  /// {@template class_get_method_by_signature}
  /// Parameters:
  /// - [name]: The method name
  /// - [parameterTypes]: List of parameter types in exact order
  ///
  /// Returns:
  /// - The exact method match if found
  /// - `null` if no matching signature exists
  ///
  /// Example:
  /// ```dart
  /// class Converter {
  ///   String convert(int value) => value.toString();
  ///   String convert(double value) => value.toString();
  /// }
  ///
  /// final method = Class.forType<Converter>()
  ///   .getMethodBySignature('convert', [Class.forType<int>()]);
  /// ```
  /// {@endtemplate}
  Method? getMethodBySignature(String name, List<Class> parameterTypes);

  /// Gets all methods declared in this class.
  ///
  /// {@template class_get_methods}
  /// Returns:
  /// - Iterable of all methods (instance and static)
  /// - Empty list if no methods exist
  ///
  /// Example:
  /// ```dart
  /// final methods = Class.forType<MyService>().getMethods();
  /// methods.forEach((m) => print(m.name));
  /// ```
  /// 
  /// Includes:
  /// - Instance methods
  /// - Static methods
  /// - Operator overloads
  /// - Getters/setters
  /// 
  /// Excludes:
  /// - Inherited methods (use [getMethods] for hierarchy traversal)
  /// {@endtemplate}
  Iterable<Method> getMethods();

  /// Gets all methods declared in this class and its hierarchy.
  ///
  /// {@template class_get_all_methods_in_hierarchy}
  /// Returns:
  /// - Iterable of all methods (instance and static)
  /// - Empty list if no methods exist
  ///
  /// Example:
  /// ```dart
  /// final methods = Class.forType<MyService>().getAllMethodsInHierarchy();
  /// methods.forEach((m) => print(m.name));
  /// ```
  /// 
  /// Includes:
  /// - Instance methods
  /// - Static methods
  /// - Operator overloads
  /// - Getters/setters
  /// 
  /// Excludes:
  /// - Inherited methods (use [getMethods] for hierarchy traversal)
  /// {@endtemplate}
  Iterable<Method> getAllMethodsInHierarchy();

  /// Gets all methods that are overridden in this class.
  ///
  /// {@template class_get_overridden_methods}
  /// Returns:
  /// - Iterable of all methods that are overridden in this class
  /// - Empty list if no methods are overridden
  ///
  /// Example:
  /// ```dart
  /// final overriddenMethods = Class.forType<MyService>().getOverriddenMethods();
  /// overriddenMethods.forEach((m) => print(m.name));
  /// ```
  /// {@endtemplate}
  Iterable<Method> getOverriddenMethods();

  /// Gets all methods with a specific name.
  ///
  /// {@template class_get_methods_by_name}
  /// Parameters:
  /// - [name]: The method name to filter by
  ///
  /// Returns:
  /// - Iterable of all overloads with this name
  /// - Empty list if no matches found
  ///
  /// Example:
  /// ```dart
  /// class Overloader {
  ///   void test(int a) {}
  ///   void test(String s) {}
  /// }
  ///
  /// final overloads = Class.forType<Overloader>().getMethodsByName('test');
  /// print(overloads.length); // 2
  /// ```
  /// {@endtemplate}
  Iterable<Method> getMethodsByName(String name);

  // ---------------------------------------------------------------------------------------------------------
  // === Member Information ===
  // ---------------------------------------------------------------------------------------------------------

  /// Gets all members (fields, methods, constructors) declared in this class.
  ///
  /// {@template class_get_declared_members}
  /// Returns:
  /// - Combined list of all class members
  /// - Empty list if no members exist
  ///
  /// Example:
  /// ```dart
  /// final members = Class.forType<MyClass>().getDeclaredMembers();
  /// members.forEach((m) {
  ///   if (m is Field) print('Field: ${m.name}');
  ///   if (m is Method) print('Method: ${m.name}');
  /// });
  /// ```
  /// 
  /// Ordering:
  /// - Fields appear before methods
  /// - Declaration order is not guaranteed
  /// {@endtemplate}
  Iterable<Member> getDeclaredMembers();

  // ---------------------------------------------------------------------------------------------------------
  // === Instance Creation ===
  // ---------------------------------------------------------------------------------------------------------

  /// Creates an instance using the default constructor.
  ///
  /// {@template class_new_instance}
  /// Parameters:
  /// - [constructorName]: The constructor name
  /// - [arguments]: Optional named arguments for construction
  ///
  /// Returns:
  /// - A new instance of type T
  ///
  /// Throws:
  /// - [ConstructorNotFoundException] if no default constructor exists
  /// - [UnresolvedTypeInstantiationException] if the type is unresolved. Normally represented with `_ClassMirror`.
  /// - [PrivateConstructorInvocationException] if the constructor being invoked is a private constructor
  /// - [InvalidArgumentException] for invalid arguments
  /// - [GenericResolutionException] if the type cannot be resolved by Jetleaf
  ///
  /// Example:
  /// ```dart
  /// final user = userClass.newInstance({'name': 'Alice'}, 'origin');
  /// ```
  /// {@endtemplate}
  T newInstance([Map<String, dynamic>? arguments, String? constructorName]);

  // ---------------------------------------------------------------------------------------------------------
  // === Factory ===
  // ---------------------------------------------------------------------------------------------------------

  /// {@macro class}
  factory Class([ProtectionDomain? domain, String? package, LinkDeclaration? link]) {
    return _Class(T.toString(), domain ?? ProtectionDomain.current(), package, link);
  }

  /// Creates a Class instance for a runtime type.
  ///
  /// {@template class_for_type}
  /// Type Parameters:
  /// - `Type`: The class type to reflect
  ///
  /// Parameters:
  /// - [domain]: Optional protection domain
  /// - [package]: Optional package name to search with
  ///
  /// Returns:
  /// - A [Class] instance for the type
  ///
  /// Example:
  /// ```dart
  /// final listClass = Class.forType(Iterable<String>);
  /// ```
  /// {@endtemplate}
  static Class<C> forType<C>(C type, [ProtectionDomain? domain, String? package, LinkDeclaration? link]) {
    return _Class<C>(type.toString(), domain ?? ProtectionDomain.current(), package, link);
  }

  /// Creates a Class instance for a runtime type name.
  ///
  /// {@template class_for_name}
  /// Type Parameters:
  /// - `C`: The class type to reflect
  ///
  /// Parameters:
  /// - [name]: The class name to reflect
  /// - [domain]: Optional protection domain
  /// - [package]: Optional package name to search with
  ///
  /// Returns:
  /// - A [Class] instance for the named type
  /// {@endtemplate}
  static Class<C> forName<C>(String name, [ProtectionDomain? domain, String? package, LinkDeclaration? link]) {
    return _Class<C>(name, domain ?? ProtectionDomain.current(), package, link);
  }

  /// Creates a Class instance from type declaration metadata.
  /// 
  /// {@template class_declared}
  /// Parameters:
  /// - [declaration]: The type metadata declaration
  /// - [domain]: Protection domain for security
  ///
  /// Returns:
  /// - A new Class instance with resolved metadata
  ///
  /// Used internally by the reflection system.
  /// {@endtemplate}
  factory Class.declared(ClassDeclaration declaration, ProtectionDomain domain) = _Class.declared;

  /// Creates a Class instance from a fully qualified name.
  ///
  /// {@template class_from_qualified_name}
  /// Parameters:
  /// - [qualifiedName]: The complete type path (e.g., "dart:core/string.dart.String")
  /// - [domain]: Optional protection domain
  ///
  /// Returns:
  /// - A Class instance for the named type
  ///
  /// Throws:
  /// - [ClassNotFoundException] if type cannot be resolved
  /// {@endtemplate}
  factory Class.fromQualifiedName(String qualifiedName, [ProtectionDomain? domain, LinkDeclaration? link]) = _Class.fromQualifiedName;

  /// Creates a Class instance for an object's runtime type.
  ///
  /// {@template class_for_object}
  /// Parameters:
  /// - [obj]: The object to reflect
  /// - [domain]: Optional protection domain
  /// - [package]: Optional package name to search with
  ///
  /// Returns:
  /// - A [Class] instance for the object's type
  /// {@endtemplate}
  static Class<Object> forObject(Object obj, [ProtectionDomain? domain, String? package, LinkDeclaration? link]) {
    return LangUtils.obtainClass(obj, package: package, pd: domain, link: link);
  }
}

/// {@template class_extension}
/// Extension providing reflection capabilities to all Dart objects.
///
/// Adds convenient methods for accessing runtime type information
/// through the Jetleaf reflection system.
///
/// {@template class_extension_features}
/// ## Features
/// - Type-safe class reflection access
/// - Shortcut getter for common use cases
/// - Automatic protection domain handling
/// {@endtemplate}
///
/// {@template class_extension_example}
/// ## Example Usage
/// ```dart
/// final myObject = SomeClass();
/// 
/// // Get class metadata
/// final classInfo = myObject.getClass();
/// print('Object type: ${classInfo.getName()}');
///
/// // Shortcut syntax
/// final constructors = myObject.getClass().getConstructors();
/// ```
/// {@endtemplate}
/// {@endtemplate}
extension ClassExtension on Object {
  /// Gets the [Class] metadata for this object's runtime type.
  /// 
  /// Parameters:
  /// - [domain]: Optional protection domain
  /// - [package]: Optional package name to search with
  ///
  /// Returns:
  /// - A [Class<Object>] instance representing the object's type
  /// - Uses the current protection domain for security
  ///
  /// Equivalent to:
  /// ```dart
  /// Class.forType<Object>(runtimeType, ProtectionDomain.current())
  /// ```
  Class getClass([ProtectionDomain? domain, String? package]) => LangUtils.obtainClass(this, pd: domain, package: package);
}