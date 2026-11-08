part of 'annotation.dart';

final class _Annotation extends PermissionManager implements Annotation {
  final AnnotationDeclaration _declaration;
  final ProtectionDomain _pd;
  Object? _cachedInstance;
  bool _instanceCreated = false;
  
  _Annotation(this._declaration, this._pd);

  // ============================================== COMMON METHODS ========================================

  @override
  AnnotationDeclaration getDeclaration() {
    checkAccess('getType', DomainPermission.READ_ANNOTATIONS);
    return _declaration;
  }
  
  @override
  Type getType() {
    checkAccess('getType', DomainPermission.READ_ANNOTATIONS);
    return _declaration.getType();
  }

  @override
  bool matches<A>([Class<A>? type]) {
    try {
      final aName = '$A';
      final aBase = aName.contains('<') ? aName.split('<').first : aName;
      final declName = _declaration.getName();
      final declBase = declName.contains('<') ? declName.split('<').first : declName;

      if (declName == aName || declBase == aBase) {
        return true;
      }

      final declaringClass = getDeclaringClass();
      final className = declaringClass.getName();
      final classBase = className.contains('<') ? className.split('<').first : className;

      if (className == aName || classBase == aBase) {
        return true;
      }

      if (declaringClass.getQualifiedName().endsWith('.$aName') ||
          declaringClass.getQualifiedName().endsWith('.$aBase')) {
        return true;
      }

      if (declaringClass.getType() == A) {
        return true;
      }

      if (_instanceCreated && _cachedInstance is A) {
        return true;
      }

      if (_declaration.getInstance() case final inst? when inst is A) {
        return true;
      }

      final cls = type ?? Class<A>();
      if (declaringClass.isSubclassOf(cls) || declaringClass.isAssignableTo(cls)) {
        return true;
      }
    } catch (_) { }

    return false;
  }
  
  @override
  Class getDeclaringClass() {
    checkAccess('getType', DomainPermission.READ_ANNOTATIONS);
    return LangUtils.obtainClassFromLink(_declaration.getLinkDeclaration());
  }

  @override
  Class getClass() => getDeclaringClass();
  
  @override
  ProtectionDomain getProtectionDomain() => _pd;
  
  @override
  List<String> getFieldNames() {
    checkAccess('getFieldNames', DomainPermission.READ_ANNOTATIONS);
    return UnmodifiableListView(_declaration.getFieldNames());
  }

  // ========================================= VALUE PROVIDERS ============================================

  @override
  dynamic getDefaultValue(String fieldName) {
    checkAccess('getDefaultValue', DomainPermission.READ_ANNOTATIONS);
    final field = _declaration.getField(fieldName);
    return field?.getDefaultValue();
  }
  
  @override
  dynamic getUserProvidedValue(String fieldName) {
    checkAccess('getUserProvidedValue', DomainPermission.READ_ANNOTATIONS);
    final field = _declaration.getField(fieldName);
    if (field != null && field.hasUserProvidedValue()) {
      return field.getUserProvidedValue();
    }
    return _declaration.getUserProvidedValues()[fieldName];
  }

  @override
  dynamic getFieldValue(String fieldName) {
    checkAccess('getFieldValue', DomainPermission.READ_ANNOTATIONS);
    try {
      final inst = getInstance<Object?>();
      if (inst != null) {
        return Runtime.getRuntimeResolver().getValue(inst, fieldName);
      }
    } catch (_) {}
    final field = _declaration.getField(fieldName);
    return field?.getAnnotationValue();
  }
  
  @override
  T? getFieldValueAs<T>(String fieldName) {
    checkAccess('getFieldValueAs', DomainPermission.READ_ANNOTATIONS);
    final value = getFieldValue(fieldName);
    return value is T ? value : null;
  }

  @override
  Map<String, dynamic> getUserProvidedValues() {
    checkAccess('getUserProvidedValues', DomainPermission.READ_ANNOTATIONS);
    return UnmodifiableMapView(_declaration.getUserProvidedValues());
  }
  
  @override
  Map<String, dynamic> getAllFieldValues() {
    checkAccess('getAllFieldValues', DomainPermission.READ_ANNOTATIONS);
    final values = <String, dynamic>{};
    
    for (final fieldName in getFieldNames()) {
      final field = _declaration.getField(fieldName);
      if (field != null) {
        values[fieldName] = field.getAnnotationValue();
      }
    }
    
    return UnmodifiableMapView(values);
  }

  // ======================================== HELPER METHODS ==============================================
  
  @override
  bool hasField(String fieldName) {
    checkAccess('hasField', DomainPermission.READ_ANNOTATIONS);
    return _declaration.getField(fieldName) != null;
  }
  
  @override
  bool hasUserProvidedValue(String fieldName) {
    checkAccess('hasUserProvidedValue', DomainPermission.READ_ANNOTATIONS);
    final field = _declaration.getField(fieldName);
    return field?.hasUserProvidedValue() ?? false;
  }
  
  @override
  bool hasDefaultValue(String fieldName) {
    checkAccess('hasDefaultValue', DomainPermission.READ_ANNOTATIONS);
    final field = _declaration.getField(fieldName);
    return field?.hasDefaultValue() ?? false;
  }

  @override
  Iterable<Field> getFields() sync* {
    checkAccess('getFields', DomainPermission.READ_ANNOTATIONS);

    for (final field in _declaration.getFields()) {
      yield Field.declared(field, _declaration, _pd);
    }
  }

  @override
  Field getField(String name) {
    checkAccess('getField', DomainPermission.READ_ANNOTATIONS);
    final field = _declaration.getField(name);
    
    if(field == null) {
      throw IllegalArgumentException('Field $name not found');
    }

    return Field.declared(field, _declaration, _pd);
  }

  @override
  String getSignature() {
    checkAccess('getSignature', DomainPermission.READ_ANNOTATIONS);
    final typeName = getDeclaringClass().getName();
    final userValues = getAllFieldValues();
    
    if (userValues.isEmpty) {
      return '@$typeName';
    }
    
    final valueStr = userValues.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    
    return '@$typeName($valueStr)';
  }

  // ============================================= INSTANCE CREATOR ========================================
  
  @override
  Instance getInstance<Instance>() {
    checkAccess('getInstance', DomainPermission.READ_ANNOTATIONS);

    if (_instanceCreated) {
      return _cachedInstance as Instance;
    }

    if (_declaration.getInstance() case final inst?) {
      _cachedInstance = inst;
      _instanceCreated = true;
      return inst as Instance;
    }

    final name = _declaration.getName();
    for (final factory in Annotation._instanceFactories) {
      final created = factory(name, this);
      if (created != null) {
        _cachedInstance = created;
        _instanceCreated = true;
        if (created is Instance) {
          return created as Instance;
        }
      }
    }

    _instanceCreated = true;
    return _declaration.getInstance() as Instance;
  }
  
  @override
  String toString() => 'Annotation(${getDeclaringClass().getName()})';
  
  @override
  Author? getAuthor() {
    checkAccess("getAuthor", DomainPermission.READ_TYPE_INFO);
    return getDeclaringClass().getAuthor();
  }

  @override
  Version getVersion() => getDeclaringClass().getVersion();
}