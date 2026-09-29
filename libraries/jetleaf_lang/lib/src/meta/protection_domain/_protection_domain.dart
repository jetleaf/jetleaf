part of 'protection_domain.dart';

/// Represents a protection domain that controls access to reflection APIs.
/// 
/// This provides fine-grained access control over reflection operations,
/// allowing different parts of the system to have different levels of access
/// to reflection capabilities.
/// 
/// Example:
/// ```dart
/// final domain = ProtectionDomain.create('my-app', permissions: [
///   DomainPermission.READ_FIELDS,
///   DomainPermission.INVOKE_METHODS,
/// ]);
/// 
/// final clazz = Class.forType(MyClass, domain);
/// ```
class _ProtectionDomain implements ProtectionDomain {
  @override
  final String name;

  @override
  final Set<DomainPermission> permissions;
  
  @override
  final Map<String, dynamic> properties;
  
  @override
  final ProtectionDomain? parent;
  
  static _ProtectionDomain? _current;
  static final _ProtectionDomain _system = _ProtectionDomain._internal('system', DomainPermission.values.toSet(), {}, null);
  
  _ProtectionDomain._internal(this.name, this.permissions, this.properties, this.parent);
  
  /// Creates a new protection domain with the specified name and permissions.
  factory _ProtectionDomain.create(
    String name, {
    Set<DomainPermission>? permissions,
    Map<String, dynamic>? properties,
    ProtectionDomain? parent,
  }) {
    return _ProtectionDomain._internal(name, permissions ?? <DomainPermission>{}, properties ?? <String, dynamic>{}, parent);
  }
  
  /// Returns the system protection domain with all permissions.
  static _ProtectionDomain system() => _system;
  
  /// Returns the current protection domain.
  static _ProtectionDomain current() => _current ?? _system;
  
  /// Sets the current protection domain.
  static void setCurrent(_ProtectionDomain domain) {
    _current = domain;
  }
  
  @override
  T runWithDomain<T>(T Function() fn) {
    final previous = _current;
    _current = this;
    try {
      return fn();
    } finally {
      _current = previous;
    }
  }
  
  @override
  bool hasPermission(DomainPermission permission) {
    if (permissions.contains(permission)) {
      return true;
    }
    
    return parent?.hasPermission(permission) ?? false;
  }
  
  @override
  bool hasAllPermissions(Set<DomainPermission> requiredPermissions) {
    return requiredPermissions.every((p) => hasPermission(p));
  }

  @override
  void checkAccess(String operation, [DomainPermission? permission]) {
    if (permission != null && !hasPermission(permission)) {
      throw SecurityException('Access denied: $operation requires $permission in domain $name');
    }
    
    // Map common operations to permissions
    final requiredPermission = _getRequiredPermission(operation);
    if (requiredPermission != null && !hasPermission(requiredPermission)) {
      throw SecurityException('Access denied: $operation requires $requiredPermission in domain $name');
    }
  }
  
  DomainPermission? _getRequiredPermission(String operation) {
    switch (operation) {
      case 'getFields':
      case 'getField':
      case 'getValue':
        return DomainPermission.READ_FIELDS;
      case 'setValue':
        return DomainPermission.WRITE_FIELDS;
      case 'getMethods':
      case 'getMethod':
        return DomainPermission.READ_METHODS;
      case 'invoke':
        return DomainPermission.INVOKE_METHODS;
      case 'getConstructors':
      case 'getConstructor':
        return DomainPermission.READ_CONSTRUCTORS;
      case 'newInstance':
        return DomainPermission.CREATE_INSTANCES;
      case 'getAnnotations':
      case 'getAnnotation':
        return DomainPermission.READ_ANNOTATIONS;
      case 'getType':
      case 'getRawClass':
      case 'getSuperType':
      case 'getInterfaces':
        return DomainPermission.READ_TYPE_INFO;
      default:
        return DomainPermission.READ_TYPE_INFO;
    }
  }

  @override
  T? getProperty<T>(String key) {
    final value = properties[key];
    if (value != null) {
      return value as T?;
    }
    
    return parent?.getProperty<T>(key);
  }

  @override
  void setProperty(String key, dynamic value) {
    properties[key] = value;
  }
  
  @override
  String toString() => 'ProtectionDomain($name)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ProtectionDomain && other.name == name;
  }
  
  @override
  int get hashCode => name.hashCode;
}