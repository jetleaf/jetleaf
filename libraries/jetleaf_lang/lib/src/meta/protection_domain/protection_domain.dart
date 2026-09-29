import 'dart:core';

import '../../exceptions.dart';

part '_protection_domain.dart';

/// {@template protection_domain}
/// Represents a security boundary for code execution within a container or framework,
/// defining permissions, metadata, and inheritance rules for reflection-based access.
///
/// A `ProtectionDomain` encapsulates:
/// - A name (identity),
/// - A set of granted [DomainPermission]s,
/// - A set of properties (context-specific data),
/// - An optional parent domain (for hierarchical permission models).
///
/// ### Usage Example:
/// ```dart
/// var domain = ProtectionDomain.create(
///   'dev',
///   permissions: {DomainPermission.READ_FIELDS, DomainPermission.INVOKE_METHODS},
/// );
///
/// ProtectionDomain.setCurrent(domain);
///
/// domain.runWithDomain(() {
///   if (domain.hasPermission(DomainPermission.READ_FIELDS)) {
///     print('Can read fields');
///   }
/// });
/// ```
///
/// Protection domains are used internally by reflection frameworks, pod factories,
/// or sandboxed environments like Jetleaf to enforce scoped access control.
/// {@endtemplate}
abstract interface class ProtectionDomain {
  /// {@macro protection_domain}
  String get name;

  /// {@macro protection_domain}
  Set<DomainPermission> get permissions;

  /// {@macro protection_domain}
  Map<String, dynamic> get properties;

  /// {@macro protection_domain}
  ProtectionDomain? get parent;

  /// Returns the root system domain, usually used by the framework itself.
  ///
  /// This domain typically has all permissions and is immutable.
  static ProtectionDomain system() => _ProtectionDomain.system();

  /// Returns the domain currently bound to the executing thread or context.
  ///
  /// If none is explicitly set, a fallback domain may be used.
  static ProtectionDomain current() => _ProtectionDomain.current();

  /// Creates a new custom [ProtectionDomain] with the specified [name], optional [permissions],
  /// [properties], and an optional [parent].
  ///
  /// ### Example:
  /// ```dart
  /// var devDomain = ProtectionDomain.create(
  ///   'development',
  ///   permissions: {DomainPermission.READ_FIELDS, DomainPermission.WRITE_FIELDS},
  /// );
  /// ```
  static ProtectionDomain create(
    String name, {
    Set<DomainPermission>? permissions,
    Map<String, dynamic>? properties,
    ProtectionDomain? parent,
  }) => _ProtectionDomain.create(name, permissions: permissions, properties: properties, parent: parent);

  /// Sets the current executing domain to [domain].
  ///
  /// Typically used to establish context before running privileged operations.
  static void setCurrent(ProtectionDomain domain) => _ProtectionDomain.setCurrent(domain as _ProtectionDomain);

  /// Executes a function [fn] within the scope of this protection domain.
  ///
  /// Temporarily sets this domain as the current one, then restores the previous.
  ///
  /// ### Example:
  /// ```dart
  /// myDomain.runWithDomain(() {
  ///   // Executes in myDomain context
  /// });
  /// ```
  T runWithDomain<T>(T Function() fn);

  /// Returns `true` if this domain grants the specified [permission].
  ///
  /// ### Example:
  /// ```dart
  /// if (domain.hasPermission(DomainPermission.CREATE_INSTANCES)) {
  ///   // proceed with instantiation
  /// }
  /// ```
  bool hasPermission(DomainPermission permission);

  /// Returns `true` if this domain includes *all* of the [requiredPermissions].
  ///
  /// ### Example:
  /// ```dart
  /// if (domain.hasAllPermissions({DomainPermission.READ_FIELDS, DomainPermission.READ_METHODS})) {
  ///   // safe to reflect
  /// }
  /// ```
  bool hasAllPermissions(Set<DomainPermission> requiredPermissions);

  /// Performs an access check for a specific [operation], optionally guarded
  /// by a required [permission]. Throws if the access is not allowed.
  ///
  /// ### Example:
  /// ```dart
  /// domain.checkAccess('setField', DomainPermission.WRITE_FIELDS);
  /// ```
  void checkAccess(String operation, [DomainPermission? permission]);

  /// Retrieves a typed property [T] stored in this domain under the given [key].
  ///
  /// Returns `null` if no value is found or type mismatch occurs.
  ///
  /// ### Example:
  /// ```dart
  /// var env = domain.getProperty<String>('env'); // e.g., 'dev'
  /// ```
  T? getProperty<T>(String key);

  /// Stores a property under the given [key] with a [value].
  ///
  /// Useful for storing contextual metadata such as user roles, environments,
  /// or tenant identifiers.
  ///
  /// ### Example:
  /// ```dart
  /// domain.setProperty('env', 'production');
  /// domain.setProperty('tenantId', 12345);
  /// ```
  void setProperty(String key, dynamic value);
}

/// {@template domain_permission}
/// Enumeration of reflection-based permissions for secure access to class metadata,
/// fields, methods, constructors, and annotations within a container or framework.
///
/// These permissions are used to guard operations during reflection, allowing
/// granular control over what can be read, modified, or invoked at runtime.
///
/// ### Usage Example:
/// ```dart
/// bool canInvoke = permissions.contains(DomainPermission.INVOKE_METHODS);
/// if (canInvoke) {
///   reflectedMethod.invoke(target);
/// }
/// ```
///
/// These permissions are typically used by custom reflection engines,
/// pod containers, or access control modules in frameworks like Jetleaf.
/// {@endtemplate}
enum DomainPermission {
  /// {@macro domain_permission}
  /// Permission to read field metadata and current values on a class or instance.
  READ_FIELDS,

  /// {@macro domain_permission}
  /// Permission to write or modify field values reflectively.
  WRITE_FIELDS,

  /// {@macro domain_permission}
  /// Permission to access method signatures and metadata (return types, parameters, etc.).
  READ_METHODS,

  /// {@macro domain_permission}
  /// Permission to invoke methods reflectively, including private or protected ones.
  INVOKE_METHODS,

  /// {@macro domain_permission}
  /// Permission to access constructor metadata (parameter types, visibility, etc.).
  READ_CONSTRUCTORS,

  /// {@macro domain_permission}
  /// Permission to create new instances using constructors, including private ones.
  CREATE_INSTANCES,

  /// {@macro domain_permission}
  /// Permission to access annotations on fields, methods, parameters, and classes.
  READ_ANNOTATIONS,

  /// {@macro domain_permission}
  /// Permission to inspect type information (e.g., generics, superclasses, interfaces).
  READ_TYPE_INFO,

  /// {@macro domain_permission}
  /// Permission to access private members (fields, methods, constructors).
  /// Usually paired with `SUPPRESS_ACCESS_CHECKS` for full private access.
  ACCESS_PRIVATE,

  /// {@macro domain_permission}
  /// Permission to suppress visibility and access checks when using reflection.
  /// Allows interaction with members that are otherwise inaccessible.
  SUPPRESS_ACCESS_CHECKS,
}