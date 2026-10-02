part of 'class.dart';

@Generic(_Class)
final class _Class<T> extends Source with EqualsAndHashCode implements Class<T> {
  String _name;
  final String? _package;
  final ProtectionDomain _pd;
  final LinkDeclaration? _link;

  late final ClassDeclaration _declaration;
  
  _Class(this._name, this._pd, this._package, this._link) {
    if (_name != T.toString()) {
      try {
        _declaration = Runtime.findClassByName(_name, _package);
      } on ClassNotFoundException catch (_) {
        _declaration = Runtime.findClass<T>(_package);
      }
    } else {
      try {
        _declaration = Runtime.findClass<T>(_package);
      } on ClassNotFoundException catch (_) {
        _declaration = Runtime.findClassByName(_name, _package);
      }
    }
  }

  _Class.fromQualifiedName(this._name, [ProtectionDomain? pd, this._link]) : _package = null, _pd = pd ?? ProtectionDomain.current() {
    _declaration = Runtime.findClassByQualifiedName(_name);
    _name = _declaration.getName();
  }

  _Class.declared(this._declaration, this._pd) : _link = null, _name = _declaration.getName(), _package = null;

  @override
  Declaration getDeclaration() {
    checkAccess('getDeclaration', DomainPermission.READ_TYPE_INFO);
    return _declaration;
  }
  
  @override
  ClassDeclaration getClassDeclaration() {
    checkAccess('getDeclaration', DomainPermission.READ_TYPE_INFO);
    return _declaration;
  }

  @override
  String getSignature() {
    checkAccess('getSignature', DomainPermission.READ_TYPE_INFO);

    // Handle enums
    if (_declaration is EnumDeclaration) {
      final values = _declaration.getValues().map((v) => v.getName()).join(', ');
      return 'enum ${_declaration.getName()} { $values }';
    }

    // Handle mixins
    if (_declaration is MixinDeclaration) {
      final typeParams = getTypeArgumentLinks().isNotEmpty
          ? '<${getTypeArgumentLinks().join(', ')}>'
          : '';

      final onClause = _declaration.getConstraints().isNotEmpty
          ? ' on ${_declaration.getConstraints().map((t) => t.getName()).join(', ')}'
          : '';

      final interfaces = _declaration.getInterfaces().isNotEmpty
          ? ' implements ${_declaration.getInterfaces().map((i) => i.getName()).join(', ')}'
          : '';

      return 'mixin ${_declaration.getName()}$typeParams$onClause$interfaces';
    }

    final typeParams = getTypeArgumentLinks().isNotEmpty
        ? '<${getTypeArgumentLinks().join(', ')}>'
        : '';

    final superType = _declaration.getSuperClass() != null
        ? ' extends ${_declaration.getSuperClass()!.getName()}'
        : '';

    final interfaces = _declaration.getInterfaces().isNotEmpty
        ? ' implements ${_declaration.getInterfaces().map((i) => i.getName()).join(', ')}'
        : '';

    final mixins = _declaration.getMixins().isNotEmpty
        ? ' with ${_declaration.getMixins().map((m) => m.getName()).join(', ')}'
        : '';

    return 'class ${_declaration.getName()}$typeParams$superType$mixins$interfaces';
  }

  @override
  Author? getAuthor() => super.getAuthor() ?? getAnnotation<Author>();

  // ---------------------------------------------------------------------------------------------------------
  // === Name Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  String getQualifiedName() {
    checkAccess('getQualifiedName', DomainPermission.READ_TYPE_INFO);
    return _declaration.getQualifiedName();
  }
  
  @override
  String getSimpleName() {
    checkAccess('getSimpleName', DomainPermission.READ_TYPE_INFO);
    return _declaration.getSimpleName();
  }

  @override
  String getPackageUri() {
    checkAccess('getPackageUri', DomainPermission.READ_TYPE_INFO);
    return _declaration.getPackageUri();
  }

  @override
  String getName() {
    checkAccess('getName', DomainPermission.READ_TYPE_INFO);
    return _declaration.getName();
  }

  @override
  String getCanonicalName() {
    checkAccess('getCanonical', DomainPermission.READ_TYPE_INFO);
    return _name;
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Type Comparators ===
  // ---------------------------------------------------------------------------------------------------------
  
  @override
  bool isCanonical() {
    checkAccess("isCanonical", DomainPermission.READ_TYPE_INFO);

    if (_declaration case FunctionDeclaration declaration) {
      return declaration.getIsCanonical();
    }

    if (_declaration case RecordDeclaration declaration) {
      return declaration.getIsCanonical();
    }

    return getName() == getCanonicalName();
  }

  @override
  bool isInvokable() => !isAbstract() || getConstructors().any((c) => c.isFactory());

  @override
  bool isInstance(Object? obj) {
    checkAccess("isInstance", DomainPermission.READ_TYPE_INFO);

    if (obj == null) return false;

    if (getQualifiedName() == Dynamic.getQualifiedName()) {
      return true;
    }

    if (getQualifiedName() == Void.getQualifiedName()) {
      return true;
    }

    if(obj is Class) {
      if (obj.getClassDeclaration() is FunctionDeclaration) {
        return isAssignableFrom(obj);
      }

      if (obj.getClassDeclaration() is RecordDeclaration) {
        return isAssignableFrom(obj);
      }

      if (obj.getQualifiedName() == Dynamic.getQualifiedName() || obj == DYNAMIC_CLASS) {
        return true;
      }

      if (obj.getQualifiedName() == Void.getQualifiedName() || obj == VOID_CLASS) {
        return true;
      }

      if(obj.getQualifiedName() == getQualifiedName()) {
        if (obj.hasGenerics()) {
          final comp = obj.componentType();
          final thisComp = componentType();
          final key = obj.keyType();
          final thisKey = keyType();

          if (key == null && thisKey == null) {
            if (comp != null && thisComp != null) {
              if (comp == thisComp) {
                return true;
              }

              if (thisComp.isInstance(comp)) {
                return true;
              }
            }
          }

          if (key != null && thisKey != null && comp != null && thisComp != null) {
            if (key == thisKey && comp == thisComp) {
              return true;
            }

            if (thisKey.isInstance(key) && thisComp.isInstance(comp)) {
              return true;
            }
          }
        }

        return true;
      }

      if(obj.getDeclaration() == getDeclaration()) {
        return true;
      }

      if(obj.getQualifiedName() == getQualifiedName()) {
        return true;
      }

      return isAssignableFrom(obj) || obj.isAssignableTo(this);
    }

    final clazz = obj.getClass();

    if(isInstance(clazz)) {
      return true;
    }

    return isAssignableFrom(clazz) || clazz.isAssignableTo(this);
  }
  
  @override
  bool isAssignableFrom(Class other) {
    checkAccess("isAssignableFrom", DomainPermission.READ_TYPE_INFO);

    if (_declaration is FunctionDeclaration && other.getClassDeclaration() is FunctionDeclaration) {
      bool isAssignableFrom = true;
      final params = getParameters();
      final otherParams = other.getParameters();

      if (params.length != otherParams.length) return false;

      for (int i = 0; i < params.length; i++) {
        final thisParam = params.elementAt(i);
        final otherParam = otherParams.elementAt(i);

        if (!thisParam.isAssignableFrom(otherParam)) {
          isAssignableFrom = false;
        }
      }

      return getReturnType().isAssignableFrom(other.getReturnType()) && isAssignableFrom;
    }

    if (_declaration is RecordDeclaration && other.getClassDeclaration() is RecordDeclaration) {
      return true; // Support for assignability checks for record is not yet available.
    }

    return other.isAssignableTo(this);
  }

  @override
  bool isAssignableTo(Class other) {
    checkAccess("isAssignableTo", DomainPermission.READ_TYPE_INFO);

    if (_declaration is FunctionDeclaration && other.getClassDeclaration() is FunctionDeclaration) {
      return other.isAssignableFrom(this);
    }

    if (_declaration is RecordDeclaration && other.getClassDeclaration() is RecordDeclaration) {
      return true; // Support for assignability checks for record is not yet available.
    }

    if(getQualifiedName() == other.getQualifiedName()) {
      return true;
    }

    if(isSubclassOf(other)) {
      return true;
    }

    if(getAllInterfaces().contains(other) || getAllInterfaces().any((i) => i.isSubclassOf(other) || i.getQualifiedName() == other.getQualifiedName())) {
      return true;
    }

    return false;
  }
  
  @override
  bool isSubclassOf(Class other) {
    if (_declaration is FunctionDeclaration && other.getClassDeclaration() is FunctionDeclaration) {
      return false; // Support for sub class checks for function is not yet available.
    }

    if (_declaration is RecordDeclaration && other.getClassDeclaration() is RecordDeclaration) {
      return false; // Support for sub class checks for record is not yet available.
    }

    if(this == other) return true;

    if(getQualifiedName() == other.getQualifiedName()) return true;

    if (getSuperClass() case final superClass?) {
      if(superClass.isSubclassOf(other)) return true;
    }

    final interfaces = getAllInterfaces();
    for (final interface in interfaces) {
      if(interface.isSubclassOf(other)) return true;
    }

    return false;
  }

  @override
  bool isAsync() {
    checkAccess('isAsync', DomainPermission.READ_TYPE_INFO);

    if (Class<Future>(null, "dart").isAssignableFrom(this) || Class<FutureOr>(null, "dart").isAssignableFrom(this)) {
      return true;
    }

    return false;
  }

  @override
  bool isAbstract() {
    checkAccess('isAbstract', DomainPermission.READ_TYPE_INFO);
    return _declaration.getIsAbstract();
  }

  @override
  bool isPublic() {
    checkAccess('isPublic', DomainPermission.READ_TYPE_INFO);
    return _declaration.getIsPublic();
  }
  
  @override
  bool isBase() {
    checkAccess('isBase', DomainPermission.READ_TYPE_INFO);
    return _declaration.getIsBase();
  }

  @override
  bool isClosure() {
    checkAccess('isClosure', DomainPermission.READ_TYPE_INFO);
    return _declaration is ClosureDeclaration;
  }
  
  @override
  bool isEnum() {
    checkAccess('isEnum', DomainPermission.READ_TYPE_INFO);
    return _declaration is EnumDeclaration;
  }
  
  @override
  bool isFinal() {
    checkAccess('isFinal', DomainPermission.READ_TYPE_INFO);
    return _declaration.getIsFinal();
  }

  @override
  bool isFunction() {
    checkAccess('isFunction', DomainPermission.READ_TYPE_INFO);
    return _declaration is FunctionDeclaration;
  }
  
  @override
  bool isInterface() {
    checkAccess('isInterface', DomainPermission.READ_TYPE_INFO);
    return _declaration.getIsInterface();
  }
  
  @override
  bool isMixin() {
    checkAccess('isMixin', DomainPermission.READ_TYPE_INFO);
    return _declaration is MixinDeclaration;
  }
  
  @override
  bool isRecord() {
    checkAccess('isRecord', DomainPermission.READ_TYPE_INFO);
    return _declaration is RecordDeclaration;
  }

  @override
  bool isVoid() {
    checkAccess('isVoid', DomainPermission.READ_TYPE_INFO);
    return this == VOID_CLASS || getQualifiedName() == Void.getQualifiedName();
  }

  @override
  bool isDynamic() {
    checkAccess('isDynamic', DomainPermission.READ_TYPE_INFO);
    return this == DYNAMIC_CLASS || getQualifiedName() == Dynamic.getQualifiedName();
  }
  
  @override
  bool isSealed() {
    checkAccess('isSealed', DomainPermission.READ_TYPE_INFO);
    return _declaration.getIsSealed();
  }

  @override
  bool isClass() {
    checkAccess('isClass', DomainPermission.READ_TYPE_INFO);
    return !isEnum() || !isMixin() || !isRecord() || !isFunction() || !isClosure();
  }

  @override
  bool isSynthetic() {
    checkAccess('isSynthetic', DomainPermission.READ_TYPE_INFO);
    return _declaration.getIsSynthetic();
  }

  @override
  bool hasGenerics() {
    checkAccess('hasGenerics', DomainPermission.READ_TYPE_INFO);
    return _declaration.isGeneric() || GenericTypeParser.isGeneric(T.toString()) || GenericTypeParser.isGeneric(_name);
  }

  @override
  bool isArray() {
    checkAccess('isArray', DomainPermission.READ_TYPE_INFO);
    return _declaration.getKind() == TypeKind.listType 
      || (getTypeArgumentLinks().isNotEmpty && getTypeArgumentLinks().length == 1)
      || T.toString().startsWith("List<") || T.toString().startsWith("Iterable")
      || T is List || T is Iterable || T == List || T == Set || T == Iterable 
      || isAssignableTo(Class<List>())
      || isAssignableTo(Class<Set>()) 
      || isAssignableTo(Class<Iterable>());
  }

  @override
  bool isKeyValuePaired() {
    checkAccess('isKeyValuePaired', DomainPermission.READ_TYPE_INFO);
    return (getTypeArgumentLinks().isNotEmpty && getTypeArgumentLinks().length >= 2) 
      || _declaration.getKind() == TypeKind.mapType
      || T == Map 
      || T == MapEntry
      || isAssignableTo(Class<Map>()) 
      || isAssignableTo(Class<MapEntry>());
  }

  @override
  bool isPrimitive() {
    checkAccess('isPrimitive', DomainPermission.READ_TYPE_INFO);

    // If underlying declaration knows it's primitive, accept it.
    if (_declaration.getKind() == TypeKind.primitiveType) return true;

    // Resolve the non-nullable "base" type.
    final Type baseType = getType();

    // Common Dart built-ins we treat as primitives:
    if (baseType == Class<bool>().getType()) return true;
    if (baseType == Class<int>().getType()) return true;
    if (baseType == Class<double>().getType()) return true;
    if (baseType == Class<String>().getType()) return true;
    if (baseType == Class<Symbol>().getType()) return true;
    if (baseType == Class<Null>().getType()) return true;

    // Also consider 'num' as a builtin primitive-like type
    if (baseType == Class<num>().getType()) return true;

    return false;
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Type Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Type getType() {
    checkAccess('getType', DomainPermission.READ_TYPE_INFO);
    return _declaration.getType();
  }

  @override
  Type getOriginal() {
    checkAccess('getOriginal', DomainPermission.READ_TYPE_INFO);
    return T;
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Package Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Package getPackage() {
    checkAccess('getPackage', DomainPermission.READ_TYPE_INFO);
    return _declaration.getLibrary().getPackage();
  }

  @override
  Version getVersion() {
    checkAccess("getVersion", DomainPermission.READ_TYPE_INFO);

    if (getAnnotation<Version>() case final version?) {
      return version;
    }
    
    return Version.parse(getPackage().getVersion());
  }

  @override
  ProtectionDomain getProtectionDomain() => _pd;

  @override
  List<String> getModifiers() {
    checkAccess('getModifiers', DomainPermission.READ_TYPE_INFO);

    return [
      if (isPublic()) 'PUBLIC',
      if (!isPublic()) 'PRIVATE',
      if (isBase()) 'BASE',
      if (isAbstract()) 'ABSTRACT',
      if (isEnum()) 'ENUM',
      if (isFinal()) 'FINAL',
      if (isInterface()) 'INTERFACE',
      if (isMixin()) 'MIXIN',
      if (isRecord()) 'RECORD',
      if (isSealed()) 'SEALED',
      if (isClass()) 'CLASS',
    ];
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Function Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Class<Object> getReturnType() {
    checkAccess("getReturnType", DomainPermission.READ_TYPE_INFO);

    if (_declaration case FunctionDeclaration declaration) {
      return LangUtils.obtainClassFromLink(declaration.getReturnType());
    }

    return Class.fromQualifiedName(getQualifiedName(), _pd);
  }

  @override
  bool getIsNullable() {
    checkAccess("isNullable", DomainPermission.READ_TYPE_INFO);

    if (_declaration case FunctionDeclaration declaration) {
      return declaration.isNullable();
    }

    if (_declaration case RecordDeclaration declaration) {
      return declaration.getIsNullable();
    }

    return false;
  }

  @override
  Method? getMethodCall() {
    checkAccess("getMethodCall", DomainPermission.READ_METHODS);

    if (_declaration case FunctionDeclaration declaration) {
      if (declaration.getMethodCall() case final method?) {
        return Method.declared(method, _pd);
      }
    }
    
    return null;
  }

  @override
  Iterable<Class<Object>> getParameters() sync* {
    checkAccess("getParameters", DomainPermission.READ_TYPE_INFO);

    if (_declaration case FunctionDeclaration declaration) {
      final parameterDeclarations = declaration.getParameters();
      
      if (parameterDeclarations.isNotEmpty) {
        for (final link in parameterDeclarations) {
          yield LangUtils.obtainClassFromLink(link.getLinkDeclaration());
        }
      } else {
        for (final link in declaration.getLinkParameters()) {
          yield LangUtils.obtainClassFromLink(link);
        }
      }
    }
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Record Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  RecordField? getRecordField(Object id) {
    checkAccess("getRecordField", DomainPermission.READ_FIELDS);

    if (_declaration case RecordDeclaration declaration) {
      if (id is String) {
        final field = declaration.getRecordField(id);
        return field != null ? RecordField.linked(field, declaration, _pd) : null;
      }

      if (id is int) {
        final field = declaration.getPositionalField(id);
        return field != null ? RecordField.linked(field, declaration, _pd) : null;
      }
    }

    return null;
  }

  @override
  Iterable<RecordField> getRecordFields() sync* {
    checkAccess("getRecordFields", DomainPermission.READ_FIELDS);

    if (_declaration case RecordDeclaration declaration) {
      for (final field in declaration.getRecordFields()) {
        yield RecordField.linked(field, declaration, _pd);
      }
    }
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Generic Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  List<LinkDeclaration> getTypeArgumentLinks() {
    checkAccess("getTypeArgumentLinks", DomainPermission.READ_TYPE_INFO);
    return UnmodifiableListView(_link?.getTypeArguments() ?? _declaration.getTypeArguments());
  }

  @override
  Iterable<Class<Object>> getTypeArguments() sync* {
    checkAccess("getTypeArguments", DomainPermission.READ_TYPE_INFO);
    
    for (final link in getTypeArgumentLinks()) {
      yield LangUtils.obtainClassFromLink(link, _pd);
    }
  }

  @override
  Iterable<Class> getTypeParameters() sync* {
    checkAccess('getTypeParameters', DomainPermission.READ_TYPE_INFO);
    
    for (final link in getTypeArgumentLinks()) {
      yield LangUtils.obtainClassFromLink(link, _pd);
    }
  }

  @override
  Class<K>? keyType<K>() {
    checkAccess('keyType', DomainPermission.READ_TYPE_INFO);

    if (!isKeyValuePaired()) return null;

    final typeArgs = _link?.getTypeArguments() ?? _declaration.getTypeArguments();

    if (typeArgs.length >= 2) {
      final link = typeArgs[0];

      if (Dynamic.isDynamic<K>()) {
        return Class.declared(LangUtils.obtainTypedClassFromLink(link, _pd).getClassDeclaration(), _pd);
      }

      return Class<K>.declared(LangUtils.obtainTypedClassFromLink(link, _pd).getClassDeclaration(), _pd);
    }

    if (isKeyValuePaired() && (Dynamic.isDynamic<K>() || K.toString() == "Object")) {
      return Class<Object>() as Class<K>;
    }

    return null;
  }
  
  @override
  Class<C>? componentType<C>() {
    checkAccess('componentType', DomainPermission.READ_TYPE_INFO);

    final typeArgs = _link?.getTypeArguments() ?? _declaration.getTypeArguments();
    LinkDeclaration? link;
    
    if (typeArgs.isNotEmpty && typeArgs.length == 1) {
      link = typeArgs.first;
    } else if (typeArgs.length >= 2) {
      link = typeArgs[1];
    }

    if (link != null) {
      if (Dynamic.isDynamic<C>()) {
        return Class.declared(LangUtils.obtainTypedClassFromLink(link, _pd).getClassDeclaration(), _pd);
      }

      return Class<C>.declared(LangUtils.obtainTypedClassFromLink(link, _pd).getClassDeclaration(), _pd);
    }

    if (isArray() && (Dynamic.isDynamic<C>() || C.toString() == "Object")) {
      return Class<Object>() as Class<C>;
    }

    return null;
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Super Class Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Class<S>? getSuperClass<S>() {
    checkAccess('getSuperclass', DomainPermission.READ_TYPE_INFO);

    final superLink = _declaration.getSuperClass();
    if (superLink == null) return null;

    final declaration = LangUtils.obtainClassFromLink(superLink).getClassDeclaration();
    final superClass = Class<S>.declared(declaration, _pd);

    // If S is dynamic, or the direct superclass matches, return it
    try {
      if (S.toString() == 'dynamic' || _linkMatches(superLink, Class<S>())) {
        return Class<S>.declared(declaration, _pd);
      }
    } on ClassNotFoundException catch (_) {
      return Class<S>.declared(declaration, _pd);
    }

    // Otherwise, walk up the hierarchy
    return superClass.getSuperClass<S>();
  }

  /// Compare [LinkDeclaration] with [Class] api
  /// 
  /// The comparison happens with these:
  /// - [LinkDeclaration.getType] - [Class.getType]
  /// - [LinkDeclaration.getPointerType] - [Class.getType]
  /// - [LinkDeclaration.getPointerQualifiedName] - [Class.getQualifiedName]
  /// - [LinkDeclaration.getType] - [Class.getOriginal]
  /// - [LinkDeclaration.getPointerType] - [Class.getOriginal] 
  bool _linkMatches(LinkDeclaration decl, Class check) => decl.getPointerQualifiedName() == check.getQualifiedName()
    || decl.getType() == check.getType()
    || decl.getPointerType() == check.getType()
    || decl.getType() == check.getOriginal()
    || decl.getPointerType() == check.getOriginal();
  
  @override
  Iterable<Class> getSuperClassArguments() sync* {
    checkAccess('getSuperClassArguments', DomainPermission.READ_TYPE_INFO);

    if (_declaration.getSuperClass() case final superClass?) {
      for (final arg in superClass.getTypeArguments()) {
        yield LangUtils.obtainClassFromLink(arg, _pd);
      }
    }
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Sub Class Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Iterable<Class> getSubClasses() sync* {
    checkAccess('getSubClasses', DomainPermission.READ_TYPE_INFO);
    
    for (final declaration in Runtime.getSubClasses(_declaration)) {
      yield Class.declared(declaration, _pd);
    }
  }

  @override
  Class<S>? getSubClass<S>() {
    checkAccess('getSubClass', DomainPermission.READ_TYPE_INFO);

    final classes = getSubClasses();
    final check = Class<S>();

    for (final cls in classes) {
      if (cls.getQualifiedName() == check.getQualifiedName()) {
        return Class<S>.declared(cls.getClassDeclaration(), _pd);
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Interface Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Iterable<Class> getAllInterfaces() sync* {
    checkAccess('getInterfaces', DomainPermission.READ_TYPE_INFO);
    
    for (final item in _declaration.getInterfaces()) {
      yield LangUtils.obtainClassFromLink(item, _pd);
    }
  }

  @override
  Iterable<Class<I>> getInterfaces<I>() sync* {
    checkAccess('getInterfaces', DomainPermission.READ_TYPE_INFO);
    
    if (Dynamic.isDynamic<I>()) {
      for (final item in _declaration.getInterfaces()) {
        final cls = LangUtils.obtainClassFromLink(item, _pd);
        yield Class<I>.declared(cls.getClassDeclaration(), _pd);
      }
    } else {
      final check = Class<I>();

      for (final item in _declaration.getInterfaces()) {
        if (_linkMatches(item, check)) {
          final cls = LangUtils.obtainClassFromLink(item, _pd);
          yield Class<I>.declared(cls.getClassDeclaration(), _pd);
        }
      }
    }
  }

  @override
  Class<I>? getInterface<I>() {
    checkAccess('getInterface', DomainPermission.READ_TYPE_INFO);
    
    final list = getInterfaces<I>();
    if (list.isEmpty) {
      return null;
    }

    return list.first;
  }

  @override
  Iterable<Class> getInterfaceArguments<I>() sync* {
    checkAccess('getInterfaceArguments', DomainPermission.READ_TYPE_INFO);
    
    if (Dynamic.isDynamic<I>()) {
      final arguments = _declaration.getInterfaces().flatMap((i) => i.getTypeArguments());

      for (final item in arguments) {
        yield LangUtils.obtainClassFromLink(item, _pd);
      }
    } else {
      final check = Class<I>();

      for (final item in _declaration.getInterfaces()) {
        if (_linkMatches(item, check)) {
          for (final arg in item.getTypeArguments()) {
            yield LangUtils.obtainClassFromLink(arg, _pd);
          }
        }
      }
    }
  }

  @override
  Iterable<Class> getAllInterfaceArguments() sync* {
    checkAccess('getAllInterfaceArguments', DomainPermission.READ_TYPE_INFO);
    
    final arguments = _declaration.getInterfaces().flatMap((i) => i.getTypeArguments());
    
    for (final item in arguments) {
      yield LangUtils.obtainClassFromLink(item, _pd);
    }
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Mixin Constraint Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Iterable<Class> getAllMixinConstraints() sync* {
    checkAccess('getMixinConstraints', DomainPermission.READ_TYPE_INFO);
    
    if (_declaration case MixinDeclaration declaration) {
      for (final item in declaration.getConstraints()) {
        yield LangUtils.obtainClassFromLink(item, _pd);
      }
    }
  }

  @override
  Iterable<Class<I>> getMixinConstraints<I>() sync* {
    checkAccess('getMixinConstraints', DomainPermission.READ_TYPE_INFO);
    
    if (_declaration case MixinDeclaration declaration) {
      if (Dynamic.isDynamic<I>()) {
        for (final item in declaration.getConstraints()) {
          final cls = LangUtils.obtainClassFromLink(item, _pd);
          yield Class<I>.declared(cls.getClassDeclaration(), _pd);
        }
      } else {
        final check = Class<I>();

        for (final item in declaration.getConstraints()) {
          if (_linkMatches(item, check)) {
            final cls = LangUtils.obtainClassFromLink(item, _pd);
            yield Class<I>.declared(cls.getClassDeclaration(), _pd);
          }
        }
      }
    }
  }

  @override
  Class<I>? getMixinConstraint<I>() {
    checkAccess('getMixinConstraint', DomainPermission.READ_TYPE_INFO);
    
    final list = getMixinConstraints<I>();
    if (list.isEmpty) {
      return null;
    }

    return list.first;
  }

  @override
  Iterable<Class> getMixinConstraintArguments<I>() sync* {
    checkAccess('getMixinConstraintArguments', DomainPermission.READ_TYPE_INFO);
    
    if (_declaration case MixinDeclaration declaration) {
      if (Dynamic.isDynamic<I>()) {
        final arguments = declaration.getConstraints().flatMap((i) => i.getTypeArguments());

        for (final item in arguments) {
          yield LangUtils.obtainClassFromLink(item, _pd);
        }
      } else {
        final check = Class<I>();

        for (final item in declaration.getConstraints()) {
          if (_linkMatches(item, check)) {
            for (final arg in item.getTypeArguments()) {
              yield LangUtils.obtainClassFromLink(arg, _pd);
            }
          }
        }
      }
    }
  }

  @override
  Iterable<Class> getAllMixinConstraintArguments() sync* {
    checkAccess('getAllMixinConstraintArguments', DomainPermission.READ_TYPE_INFO);
    
    if (_declaration case MixinDeclaration declaration) {
      final arguments = declaration.getConstraints().flatMap((i) => i.getTypeArguments());
    
      for (final item in arguments) {
        yield LangUtils.obtainClassFromLink(item, _pd);
      }
    }
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Mixin Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Iterable<Class> getAllMixins() sync* {
    checkAccess('getAllMixins', DomainPermission.READ_TYPE_INFO);
    
    for (final item in _declaration.getMixins()) {
      yield LangUtils.obtainClassFromLink(item, _pd);
    }
  }
  
  @override
  Iterable<Class> getMixinsArguments<M>() sync* {
    checkAccess('getMixinsArguments', DomainPermission.READ_TYPE_INFO);
    
    if (Dynamic.isDynamic<M>()) {
      final arguments = _declaration.getMixins().flatMap((i) => i.getTypeArguments());

      for (final item in arguments) {
        yield LangUtils.obtainClassFromLink(item, _pd);
      }
    } else {
      final check = Class<M>();

      for (final item in _declaration.getMixins()) {
        if (_linkMatches(item, check)) {
          for (final arg in item.getTypeArguments()) {
            yield LangUtils.obtainClassFromLink(arg, _pd);
          }
        }
      }
    }
  }
  
  @override
  Iterable<Class> getAllMixinsArguments() sync* {
    checkAccess('getAllMixinsArguments', DomainPermission.READ_TYPE_INFO);
    
    final arguments = _declaration.getMixins().flatMap((i) => i.getTypeArguments());
    
    for (final item in arguments) {
      yield LangUtils.obtainClassFromLink(item, _pd);
    }
  }

  
  @override
  Iterable<Class<I>> getMixins<I>() sync* {
    checkAccess('getMixins', DomainPermission.READ_TYPE_INFO);
    
    if (Dynamic.isDynamic<I>()) {
      for (final item in _declaration.getMixins()) {
        final cls = LangUtils.obtainClassFromLink(item, _pd);
        yield Class<I>.declared(cls.getClassDeclaration(), _pd);
      }
    } else {
      final check = Class<I>();

      for (final item in _declaration.getMixins()) {
        if (_linkMatches(item, check)) {
          final cls = LangUtils.obtainClassFromLink(item, _pd);
          yield Class<I>.declared(cls.getClassDeclaration(), _pd);
        }
      }
    }
  }

  @override
  Class<I>? getMixin<I>() {
    checkAccess('getMixin', DomainPermission.READ_TYPE_INFO);

    final list = getMixins<I>();
    if (list.isEmpty) {
      return null;
    }

    return list.first;
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Annotation Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Iterable<Annotation> getAllDirectAnnotations() sync* {
    checkAccess('getAllAnnotations', DomainPermission.READ_ANNOTATIONS);

    for (final annotation in _declaration.getAnnotations()) {
      yield Annotation.declared(annotation, getProtectionDomain());
    }
  }

  @override
  Iterable<Annotation> getAllAnnotations() sync* {
    checkAccess('getAllAnnotations', DomainPermission.READ_ANNOTATIONS);

    final visited = <Class>{};

    // Local generator to allow passing visited set recursively
    Iterable<Annotation> generateAll(Class cls) sync* {
      // Avoid cycles
      if (!visited.add(cls)) return;

      // Yield direct annotations
      for (final annotation in cls.getAllDirectAnnotations()) {
        yield annotation;
      }

      // Yield from superclass
      if (getSuperClass() case final superClass?) {
        yield* generateAll(superClass);
      }

      // Yield from interfaces
      for (final interface in cls.getInterfaces()) {
        yield* generateAll(interface);
      }
    }

    yield* generateAll(this);
  }

  @override
  A? getAnnotation<A>() {
    checkAccess('getAnnotation', DomainPermission.READ_ANNOTATIONS);

    final annotations = getAllAnnotations();
    for (final annotation in annotations) {
      if (annotation.getDeclaringClass().getType() == A) {
        return annotation.getInstance<A>();
      }
    }

    return null;
  }
  
  @override
  Iterable<A> getAnnotations<A>() sync* {
    checkAccess('getAnnotations', DomainPermission.READ_ANNOTATIONS);
    
    final annotations = getAllAnnotations();
    for (final annotation in annotations) {
      if (annotation.matches<A>()) {
        yield annotation.getInstance<A>();
      }
    }
  }

  @override
  bool hasAnnotation<A>() {
    checkAccess('hasAnnotation', DomainPermission.READ_ANNOTATIONS);
    return getAnnotation<A>() != null;
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Member Information ===
  // ---------------------------------------------------------------------------------------------------------
  
  @override
  Iterable<Member> getDeclaredMembers() sync* {
    checkAccess('getDeclaredMembers', DomainPermission.READ_TYPE_INFO);

    yield* getMethods();
    yield* getConstructors();
    yield* getFields();
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Field Information ===
  // ---------------------------------------------------------------------------------------------------------
  
  @override
  Field? getField(String name) {
    checkAccess('getField', DomainPermission.READ_TYPE_INFO);
    return getFields().firstWhereOrNull((f) => f.getName().equals(name));
  }
  
  @override
  Iterable<Field> getFields() sync* {
    checkAccess('getFields', DomainPermission.READ_FIELDS);

    for (final field in _declaration.getFields()) {
      yield Field.declared(field, _declaration, _pd);
    }

    if (getSuperClass() case final superClass?) {
      yield* superClass.getFields();
    }

    final interfaces = getInterfaces();
    for (final interface in interfaces) {
      yield* interface.getFields();
    }

    if (_declaration case EnumDeclaration enumDeclaration) {
      for (final field in enumDeclaration.getValues()) {
        yield Field.declared(field, _declaration, _pd);
      }
    }
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Enum Value Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Iterable<EnumValue> getEnumValues() sync* {
    checkAccess('getEnumValues', DomainPermission.READ_TYPE_INFO);

    if (_declaration case EnumDeclaration declaration) {
      for (final value in declaration.getValues()) {
        yield EnumValue.declared(declaration, value, _pd);
      }
    }

    if (getSuperClass() case final superClass?) {
      yield* superClass.getEnumValues();
    }
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Method Information ===
  // ---------------------------------------------------------------------------------------------------------
  
  @override
  Method? getMethod(String name) {
    checkAccess('getMethod', DomainPermission.READ_METHODS);
    return getMethods().firstWhereOrNull((m) => m.getName().equals(name));
  }
  
  @override
  Method? getMethodBySignature(String name, List<Class> parameterTypes) {
    checkAccess('getMethodBySignature', DomainPermission.READ_METHODS);

    final methods = getMethods();
    
    for (final method in methods) {
      if (method.getName() == name) {
        final params = method.getParameters();

        if (params.length == parameterTypes.length) {
          bool matches = true;

          for (int i = 0; i < params.length; i++) {
            final param = params.elementAt(i);
            final parameterType = parameterTypes[i];

            if (!param.getReturnClass().isInstance(parameterType) || param.getReturnClass() != parameterType || param.getReturnClass().getType() != parameterType.getType()) {
              matches = false;
              break;
            }
          }

          if (matches) {
            return method;
          }
        }
      }
    }
    
    return null;
  }
  
  @override
  Iterable<Method> getMethods() sync* {
    checkAccess('getMethods', DomainPermission.READ_METHODS);

    for (final method in _declaration.getMethods()) {
      yield Method.declared(method, _pd, _declaration);
    }
    
    if (getSuperClass() case final superClass?) {
      yield* superClass.getMethods();
    }

    final interfaces = getInterfaces();
    for (final interface in interfaces) {
      yield* interface.getMethods();
    }
  }

  @override
  Iterable<Method> getAllMethodsInHierarchy() sync* {
    checkAccess('getAllMethodsInHierarchy', DomainPermission.READ_METHODS);
    
    final visited = <String>{};

    Iterable<Method> generateMethods(ClassDeclaration clazz) sync* {
      final className = clazz.getQualifiedName();
      if (!visited.add(className)) return; // avoid cycles

      // Yield methods from current class
      for (final method in clazz.getMethods()) {
        yield Method.declared(method, _pd, clazz);
      }

      // If it's a mixin, yield methods from constraints
      if (clazz case MixinDeclaration mixin) {
        for (final constraint in mixin.getConstraints()) {
          final type = Class.fromQualifiedName(constraint.getPointerQualifiedName(), ProtectionDomain.system());
          yield* generateMethods(type.getClassDeclaration());
        }
      }

      // Yield methods from superclass
      final supertype = clazz.getSuperClass();
      if (supertype != null) {
        final superclass = Class.fromQualifiedName(supertype.getPointerQualifiedName(), ProtectionDomain.system());
        yield* generateMethods(superclass.getClassDeclaration());
      }

      // Yield methods from interfaces
      for (final interfaceType in clazz.getInterfaces()) {
        final type = Class.fromQualifiedName(interfaceType.getPointerQualifiedName(), ProtectionDomain.system());
        yield* generateMethods(type.getClassDeclaration());
      }

      // Yield methods from mixins
      for (final mixinType in clazz.getMixins()) {
        final type = Class.fromQualifiedName(mixinType.getPointerQualifiedName(), ProtectionDomain.system());
        if (type.isMixin()) {
          yield* generateMethods(type.getClassDeclaration());
        }
      }
    }

    yield* generateMethods(_declaration);
  }
  
  @override
  Iterable<Method> getOverriddenMethods() sync* {
    checkAccess('getOverriddenMethods', DomainPermission.READ_METHODS);
    yield* getMethods().where((m) => m.isOverride());
  }
  
  @override
  Iterable<Method> getMethodsByName(String name) sync* {
    checkAccess('getMethodsByName', DomainPermission.READ_METHODS);
    yield* getMethods().where((m) => m.getName() == name);
  }

  @override
  bool hasMatchingMethod(Method method) {
    checkAccess('hasMatchingMethod', DomainPermission.READ_METHODS);
    return getMatchingMethod(method) != null;
  }

  @override
  Method? getMatchingMethod(Method method) {
    checkAccess('getMatchingMethod', DomainPermission.READ_METHODS);
    
    final parameterTypes = method
        .getParameters()
        .map((param) => param.getReturnClass())
        .toList();

    return getMethodBySignature(method.getName(), parameterTypes);
  }

  // =========================================== CONSTRUCTOR METHODS ===========================================
  
  @override
  Constructor? getConstructor(String name) {
    checkAccess('getConstructor', DomainPermission.READ_CONSTRUCTORS);
    final constructors = getConstructors();
    return constructors.firstWhereOrNull((c) => c.getName().equals(name));
  }

  @override
  Constructor? getConstructorBySignature(List<Class> parameterTypes) {
    checkAccess('getConstructorBySignature', DomainPermission.READ_CONSTRUCTORS);

    final constructors = getConstructors();
    
    for (final constructor in constructors) {
      final params = constructor.getParameters();

      if (params.length == parameterTypes.length) {
        bool matches = true;

        for (int i = 0; i < params.length; i++) {
          final param = params.elementAt(i);
          final parameterType = parameterTypes[i];

          if (!param.getReturnClass().isInstance(parameterType) || param.getReturnClass() != parameterType || param.getReturnClass().getType() != parameterType.getType()) {
            matches = false;
            break;
          }
        }

        if (matches) {
          return constructor;
        }
      }
    }
    
    return null;
  }

  @override
  Constructor? getBestConstructor(List<Class> parameterTypes) {
    checkAccess('getBestConstructor', DomainPermission.READ_CONSTRUCTORS);

    final constructors = getConstructors();
    Constructor? best;
    int bestScore = -1;

    for (final constructor in constructors) {
      final positionalParams = constructor.getPositionalParameters();
      final namedParams = constructor.getNamedParameters();

      // Now try to match provided positional types to positionalParams in-order
      bool fits = true;
      int score = 0;
      for (int i = 0; i < parameterTypes.length; i++) {
        if (i >= positionalParams.length) {
          // Provided more positional args than positional params -> not a fit
          fits = false;
          break;
        }
        final param = positionalParams.elementAt(i);
        final providedType = parameterTypes[i];

        // Accept if providedType is assignable to param type (or exact)
        // Prefer exact matches with higher score
        try {
          final paramClass = param.getReturnClass();
          if (paramClass == providedType) {
            score += 3; // exact
          } else if (paramClass.isAssignableFrom(providedType)) {
            score += 2; // assignable (subclass)
          } else {
            // If param is nullable (type allows null), still accept but lower score if provided is null-type?
            if (param.isNullable() || param.isPositional() && !param.isRequired()) {
              // optional positional with non-matching type — reject for type mismatch
              fits = false;
              break;
            } else {
              fits = false;
              break;
            }
          }
        } catch (e) {
          // If we can't resolve classes (fallback), perform name-based or raw type equality fallback
          // conservative: treat as mismatch
          fits = false;
          break;
        }
      }

      if (!fits) continue;

      // Check remaining constructor parameters (those not covered by provided positional args)
      for (int j = parameterTypes.length; j < positionalParams.length; j++) {
        final param = positionalParams.elementAt(j);
        // if leftover param is required -> cannot accept
        if (param.mustBeResolved() && !param.hasDefaultValue()) {
          fits = false;
          break;
        }
        // optional/nullable/default -> acceptable, minor score
        score += 1;
      }

      if (!fits) continue;

      // Named params: if they are all optional/have defaults or nullable then acceptable
      for (final p in namedParams) {
        if (p.mustBeResolved() && !p.hasDefaultValue()) {
          fits = false;
          break;
        }
        score +=  (p.hasDefaultValue() ? 1 : 1);
      }
      if (!fits) continue;

      final params = constructor.getParameters();

      // Prefer constructor with higher score, tie-break with fewer required missing params and fewer params overall
      if (score > bestScore || (score == bestScore && (best == null || params.length < best.getParameters().length))) {
        bestScore = score;
        best = constructor;
      }
    }

    return best;
  }
  
  @override
  Iterable<Constructor> getConstructors() sync* {
    checkAccess('getConstructors', DomainPermission.READ_CONSTRUCTORS);
    final constructors = _declaration.getConstructors();

    for (final constructor in constructors) {
      yield Constructor.declared(constructor, _pd);
    }
  }

  @override
  Constructor? getDefaultConstructor() {
    checkAccess('getDefaultConstructor', DomainPermission.READ_CONSTRUCTORS);

    final constructors = getConstructors();
    return constructors.firstWhereOrNull((c) => c.getName().isEmpty);
  }

  @override
  Constructor? getNoArgConstructor([bool acceptWhenAllParametersAreOptional = false]) {
    checkAccess('getNoArgConstructor', DomainPermission.READ_CONSTRUCTORS);

    final constructors = getConstructors();
    Constructor? constructor = constructors.firstWhereOrNull((c) => c.getParameters().isEmpty);

    if(acceptWhenAllParametersAreOptional && constructor == null) {
      constructor = constructors.find((c) => c.getParameters().all((p) => p.isNullable()));
    }

    return constructor;
  }

  // ============================================ INSTANCE METHODS ===========================================
  
  @override
  T newInstance([Map<String, dynamic>? arguments, String? constructorName]) {
    checkAccess('newInstance', DomainPermission.CREATE_INSTANCES);

    // Try with constructor name, if provided
    if(constructorName != null) {
      final constructor = getConstructor(constructorName);
      if (constructor == null) {
        throw ConstructorNotFoundException(getName(), constructorName);
      }
      
      return constructor.newInstance<T>(arguments ?? {});
    }

    // If arguments is not null, try to determine constructor to use.
    if(arguments case final arguments?) {
      final constructors = getConstructors();
      final constructor = constructors.firstWhereOrNull((c) => c.canAcceptArguments(arguments));
      if (constructor case final constructor?) {
        return constructor.newInstance<T>(arguments);
      }
    }

    // Resort to last option of default constructor.
    final constructor = getDefaultConstructor();
    if (constructor == null) {
      throw ConstructorNotFoundException(getName(), "");
    }
    
    return constructor.newInstance<T>(arguments ?? {});
  }

  @override
  List<Object?> equalizedProperties() => [
    _declaration.getName(),
    _declaration.getSimpleName(),
    _declaration.getQualifiedName(),
    _declaration.getPackageUri(),
    _declaration.getKind(),
    _declaration.getDebugIdentifier(),
    _declaration.getType(),
    _declaration.getIsPublic(),
    _declaration.isGeneric()
  ];
  
  @override
  String toString() => 'Class<${getName()}>:Class<${getType()}>:${getQualifiedName()}';
}