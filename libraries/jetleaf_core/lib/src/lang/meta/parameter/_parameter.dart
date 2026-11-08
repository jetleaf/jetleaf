part of 'parameter.dart';

final class _Parameter extends Source with EqualsAndHashCode implements Parameter {
  final ParameterDeclaration _declaration;
  final Member _member;
  final ProtectionDomain _pd;
  
  _Parameter(this._declaration, this._member, this._pd);
  
  @override
  String getName() {
    checkAccess('getName', DomainPermission.READ_METHODS);
    return _declaration.getName();
  }

  @override
  ParameterDeclaration getDeclaration() {
    checkAccess('getDeclaration', DomainPermission.READ_METHODS);
    return _declaration;
  }
  
  @override
  Class<Object> getReturnClass() {
    checkAccess('getType', DomainPermission.READ_METHODS);
    return LangUtils.obtainClassFromLink(_declaration.getLinkDeclaration());
  }

  @override
  Member getMember() {
    checkAccess('getMember', DomainPermission.READ_METHODS);
    return _member;
  }

  @override
  Version getVersion() => _member.getDeclaringClass().getVersion();

  @override
  LinkDeclaration getLinkDeclaration() {
    checkAccess('getLinkDeclaration', DomainPermission.READ_METHODS);
    return _declaration.getLinkDeclaration();
  }

  @override
  Type getType() {
    checkAccess('getType', DomainPermission.READ_METHODS);
    return getReturnClass().getType();
  }
  
  @override
  ProtectionDomain getProtectionDomain() => _pd;

  @override
  Iterable<Annotation> getAllDirectAnnotations() sync* {
    checkAccess('getAllAnnotations', DomainPermission.READ_ANNOTATIONS);

    for (final annotation in _declaration.getAnnotations()) {
      yield Annotation.declared(annotation, getProtectionDomain());
    }
  }
  
  @override
  int getIndex() {
    checkAccess('getIndex', DomainPermission.READ_METHODS);
    return _declaration.getIndex();
  }

  @override
  List<String> getModifiers() {
    checkAccess('getModifiers', DomainPermission.READ_METHODS);

    return [
      if (isPublic()) 'PUBLIC',
      if (!isPublic()) 'PRIVATE',
      if (isOptional()) 'OPTIONAL',
      if (isNamed()) 'NAMED',
      if (isPositional()) 'POSITIONAL',
      if (isRequired()) 'REQUIRED',
    ];
  }
  
  @override
  bool isNullable() {
    checkAccess('isNullable', DomainPermission.READ_METHODS);
    return _declaration.getIsNullable();
  }

  @override
  bool isOptional() {
    checkAccess('isOptional', DomainPermission.READ_METHODS);
    return _declaration.getIsOptional();
  }

  @override
  bool isFunction() {
    checkAccess('isFunction', DomainPermission.READ_METHODS);
    return getLinkDeclaration() is FunctionDeclaration;
  }

  @override
  bool mustBeResolved() {
    checkAccess('mustBeResolved', DomainPermission.READ_METHODS);
    return !_declaration.getIsNullable() && !_declaration.getIsOptional();
  }
  
  @override
  bool isNamed() {
    checkAccess('isNamed', DomainPermission.READ_METHODS);
    return _declaration.getIsNamed();
  }
  
  @override
  bool isPositional() {
    checkAccess('isPositional', DomainPermission.READ_METHODS);
    return !_declaration.getIsNamed();
  }
  
  @override
  bool isRequired() {
    checkAccess('isRequired', DomainPermission.READ_METHODS);
    return _declaration.getIsRequired();
  }

  @override
  bool isPublic() {
    checkAccess('isPublic', DomainPermission.READ_TYPE_INFO);
    return _declaration.getIsPublic();
  }
  
  @override
  bool hasDefaultValue() {
    checkAccess('hasDefaultValue', DomainPermission.READ_METHODS);
    return _declaration.getHasDefaultValue();
  }
  
  @override
  dynamic getDefaultValue() {
    checkAccess('getDefaultValue', DomainPermission.READ_METHODS);
    return _declaration.getDefaultValue();
  }
  
  @override
  String getSignature() {
    checkAccess('getSignature', DomainPermission.READ_METHODS);
    final typeStr = getReturnClass().getName();
    final nameStr = getName();
    
    if (isNamed()) {
      return '{$typeStr $nameStr}';
    } else if (isNullable()) {
      return '[$typeStr $nameStr]';
    } else {
      return '$typeStr $nameStr';
    }
  }

  @override
  List<Object?> equalizedProperties() {
    return [
      _declaration.getName(),
      getSignature(),
      _declaration.getIsNullable(),
      _declaration.getIsNamed(),
      _declaration.getIsSynthetic(),
      _declaration.getIndex(),
      _declaration.getHasDefaultValue(),
      _declaration.getDefaultValue(),
    ];
  }
  
  @override
  String toString() => 'Parameter(${getName()}: ${getReturnClass().getName()})';
}