part of 'annotation.dart';

final class _Annotation extends PermissionManager implements Annotation {
  final AnnotationDeclaration _declaration;
  final ProtectionDomain _pd;
  
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
      if (getDeclaringClass().getType() == A) {
        return true;
      }

      if (getDeclaringClass().getType() is A) {
        return true;
      }

      if (getInstance() is A) {
        return true;
      }

      if (getInstance() == A) {
        return true;
      }

      if (getDeclaringClass().isInstance(A)) {
        return true;
      }

      final cls = type ?? Class<A>();
      if (getDeclaringClass().isInstance(cls)) {
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
    return field?.getUserProvidedValue();
  }

  @override
  dynamic getFieldValue(String fieldName) {
    checkAccess('getFieldValue', DomainPermission.READ_ANNOTATIONS);
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