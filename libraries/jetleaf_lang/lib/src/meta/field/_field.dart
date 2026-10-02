part of 'field.dart';

final class _Field extends Source with EqualsAndHashCode implements Field {
  final FieldDeclaration _declaration;
  final Declaration _parent;
  final ProtectionDomain _pd;
  
  _Field(this._declaration, this._parent, this._pd);

  @override
  AnnotationFieldDeclaration? asAnnotation() {
    checkAccess('asAnnotation', DomainPermission.READ_FIELDS);

    if(_declaration is AnnotationFieldDeclaration && _parent is AnnotationDeclaration) {
      return _declaration;
    }

    return null;
  }

  @override
  RecordFieldDeclaration? asRecord() {
    checkAccess('asRecord', DomainPermission.READ_FIELDS);

    if(_declaration is RecordFieldDeclaration && _parent is RecordDeclaration) {
      return _declaration;
    }

    return null;
  }

  @override
  EnumFieldDeclaration? asEnum() {
    checkAccess('asEnum', DomainPermission.READ_FIELDS);

    if(_declaration is EnumFieldDeclaration && _parent is EnumDeclaration) {
      return _declaration;
    }

    return null;
  }
  
  @override
  String getName() {
    checkAccess('getName', DomainPermission.READ_FIELDS);
    return _declaration.getName();
  }

  @override
  Type getType() {
    checkAccess('getType', DomainPermission.READ_FIELDS);
    return _declaration.getType();
  }

  @override
  Version getVersion() => getDeclaringClass().getVersion();

  @override
  List<String> getModifiers() {
    checkAccess('getModifiers', DomainPermission.READ_FIELDS);

    return [
      if (isPublic()) 'PUBLIC',
      if (!isPublic()) 'PRIVATE',
      if (isPositional()) 'POSITIONAL',
      if (isNamed()) 'NAMED',
      if (isLate()) 'LATE',
      if (isNullable()) 'NULLABLE',
      if (isStatic()) 'STATIC',
      if (isFinal()) 'FINAL',
    ];
  }
  
  @override
  Class<D> getDeclaringClass<D>() {
    checkAccess('getDeclaringClass', DomainPermission.READ_FIELDS);

    if(_parent case AnnotationDeclaration parent) {
      final declaration = LangUtils.obtainClassFromLink(parent.getLinkDeclaration()).getClassDeclaration();
      return Class<D>.declared(declaration, _pd);
    }

    if (_parent case ClassDeclaration parent) {
      return Class<D>.declared(parent, _pd);
    }

    throw IllegalStateException('Field ${getName()} has no declaring class');
  }
  
  @override
  ProtectionDomain getProtectionDomain() => _pd;

  @override
  Declaration getDeclaration() {
    checkAccess('getDeclaration', DomainPermission.READ_FIELDS);
    return _declaration;
  }

  @override
  Declaration getParent() {
    checkAccess('getParent', DomainPermission.READ_FIELDS);
    return _parent;
  }
  
  @override
  int getPosition() {
    checkAccess('getPosition', DomainPermission.READ_FIELDS);
    
    return asAnnotation()?.getPosition() ?? asRecord()?.getPosition() ?? asEnum()?.getPosition() ?? -1;
  }
  
  @override
  Class<Object> getReturnClass() {
    checkAccess('getDeclaringClass', DomainPermission.READ_FIELDS);

    if(_parent case EnumDeclaration enumClass) {
      return Class.declared(enumClass, _pd);
    }
    
    if(_declaration case AnnotationFieldDeclaration annotationClass) {
      return LangUtils.obtainClassFromLink(annotationClass.getLinkDeclaration());
    }
    
    if(_declaration case RecordFieldDeclaration annotationClass) {
      return LangUtils.obtainClassFromLink(annotationClass.getLinkDeclaration());
    }
    return LangUtils.obtainClassFromLink(_declaration.getLinkDeclaration());
  }
  
  @override
  Type getReturnType() {
    checkAccess('getReturnType', DomainPermission.READ_TYPE_INFO);
    return getType();
  }
  
  @override
  bool isEnumField() {
    checkAccess('isEnumField', DomainPermission.READ_TYPE_INFO);
    return asEnum() != null;
  }
  
  @override
  bool isRecordField() {
    checkAccess('isRecordField', DomainPermission.READ_TYPE_INFO);
    return asRecord() != null;
  }

  @override
  bool isTopLevel() {
    checkAccess('isTopLevel', DomainPermission.READ_TYPE_INFO);
    return _declaration.getIsTopLevel();
  }

  @override
  bool isPublic() {
    checkAccess('isPublic', DomainPermission.READ_TYPE_INFO);
    return _declaration.getIsPublic();
  }

  @override
  bool isAnnotationField() {
    checkAccess('isAnnotationField', DomainPermission.READ_TYPE_INFO);
    return asAnnotation() != null;
  }

  @override
  bool isNullable() {
    checkAccess('isNullable', DomainPermission.READ_FIELDS);
    return _declaration.isNullable();
  }

  @override
  Iterable<Annotation> getAllDirectAnnotations() sync* {
    checkAccess('getAllAnnotations', DomainPermission.READ_ANNOTATIONS);

    for (final annotation in _declaration.getAnnotations()) {
      yield Annotation.declared(annotation, getProtectionDomain());
    }
  }

  @override
  bool isNamed() {
    checkAccess('isNamed', DomainPermission.READ_FIELDS);
    return asRecord()?.getIsNamed() ?? false;
  }
  
  @override
  bool isPositional() {
    checkAccess('isPositional', DomainPermission.READ_FIELDS);
    return asRecord()?.getIsPositional() ?? false;
  }
  
  @override
  bool isStatic() {
    checkAccess('isStatic', DomainPermission.READ_FIELDS);
    return _declaration.getIsStatic();
  }
  
  @override
  bool isFinal() {
    checkAccess('isFinal', DomainPermission.READ_FIELDS);
    return _declaration.getIsFinal();
  }
  
  @override
  bool isConst() {
    checkAccess('isConst', DomainPermission.READ_FIELDS);
    return _declaration.getIsConst();
  }
  
  @override
  bool isLate() {
    checkAccess('isLate', DomainPermission.READ_FIELDS);
    return _declaration.getIsLate();
  }
  
  @override
  bool isAbstract() {
    checkAccess('isAbstract', DomainPermission.READ_FIELDS);
    return _declaration.getIsAbstract();
  }
  
  @override
  dynamic getValue([Object? instance]) {
    checkAccess('getValue', DomainPermission.READ_FIELDS);
    
    if(isEnumField()) {
      return asEnum()?.getEnumValue();
    }
    
    if(isRecordField()) {
      // return asRecord()?.getValue(instance);
      throw UnsupportedOperationException('Record field value getter is not supported at the moment.');
    }
    
    if(isAnnotationField()) {
      return asAnnotation()?.getAnnotationValue();
    }

    final instanceValue = instance ?? (isStatic() ? getDeclaringClass().getType() : null);
    return _declaration.getValue(instanceValue);
  }
  
  @override
  void setValue(Object? instance, dynamic value) {
    checkAccess('setValue', DomainPermission.WRITE_FIELDS);
    
    final instanceValue = instance ?? (isStatic() ? getDeclaringClass().getType() : null);
    _declaration.setValue(instanceValue, value);
  }
  
  @override
  T? getValueAs<T>([Object? instance]) {
    checkAccess('getValueAs', DomainPermission.READ_FIELDS);
    final value = getValue(instance);
    
    try {
      return value is T ? value : null;
    } on TypeError catch (_) {
      throw IllegalArgumentException('Value of type ${value.runtimeType} cannot be assigned to field of type ${T.toString()}');
    }
  }
  
  @override
  bool isReadable() {
    checkAccess('isReadable', DomainPermission.READ_FIELDS);
    
    if (isPublic()) {
      return true;
    }

    return false;
  }

  @override
  bool isWritable() {
    checkAccess('isWritable', DomainPermission.READ_FIELDS);

    if (isPublic()) {
      if (isFinal() && isLate()) {
        return true; // late final String name;
      }

      if (isStatic() && (isConst() || isFinal())) {
        return false; // static const String name | static final String name
      }

      if (isFinal() || isConst()) {
        return false; // final String name | const String name
      }

      return true;
    }

    return false;
  }
  
  @override
  String getSignature() {
    checkAccess('getSignature', DomainPermission.READ_FIELDS);
    final modifiers = <String>[];
    
    if (isStatic()) modifiers.add('static');
    if (isFinal()) modifiers.add('final');
    if (isConst()) modifiers.add('const');
    if (isLate()) modifiers.add('late');
    
    final modifierStr = modifiers.isEmpty ? '' : '${modifiers.join(' ')} ';
    return '$modifierStr${getReturnClass().getName()} ${getName()}';
  }

  @override
  List<Object?> equalizedProperties() {
    return [
      _declaration.getName(),
      getSignature(),
      _declaration.getIsPublic(),
      _declaration.getIsSynthetic(),
      _declaration.getType(),
    ];
  }
  
  @override
  String toString() => 'Field(${getName()})';
}