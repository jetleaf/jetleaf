part of 'method.dart';

final class _Method extends Executable with EqualsAndHashCode implements Method {
  final MethodDeclaration _declaration;
  final ClassDeclaration? _parent;
  final ProtectionDomain _pd;
  
  _Method(this._declaration, this._pd, [this._parent]);

  @override
  String getName() {
    checkAccess('getName', DomainPermission.READ_METHODS);
    return _declaration.getName();
  }

  @override
  ProtectionDomain getProtectionDomain() => _pd;

  @override
  MethodDeclaration getDeclaration() {
    checkAccess('getDeclaration', DomainPermission.READ_METHODS);
    return _declaration;
  }

  @override
  Version getVersion() => getDeclaringClass().getVersion();

  // ---------------------------------------------------------------------------------------------------------
  // === Class Accessing ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Class<D> getDeclaringClass<D>() {
    checkAccess('getDeclaringClass', DomainPermission.READ_METHODS);
    
    if (_parent case final parent?) {
      return Class<D>.declared(parent, _pd);
    }

    if (_declaration.getParentClass() case final parent?) {
      return Class<D>.fromQualifiedName(LangUtils.obtainClassFromLink(parent).getQualifiedName(), _pd, parent);
    }

    throw IllegalStateException('Method ${getName()} has no declaring class');
  }

  @override
  Class<Object> getReturnClass() {
    checkAccess('getReturnType', DomainPermission.READ_METHODS);
    return LangUtils.obtainClassFromLink(_declaration.getReturnType());
  }

  @override
  LinkDeclaration getLinkDeclaration() {
    checkAccess('getLinkDeclaration', DomainPermission.READ_METHODS);
    return _declaration.getReturnType();
  }

  @override
  Type getReturnType() {
    checkAccess('getReturnType', DomainPermission.READ_METHODS);
    return getReturnClass().getType();
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

  // ---------------------------------------------------------------------------------------------------------
  // === Generic Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Class<K>? keyType<K>() {
    checkAccess('keyType', DomainPermission.READ_TYPE_INFO);
    if (!isKeyValuePaired()) return null;

    final args = _declaration.getReturnType().getTypeArguments();
    if (args.isEmpty || args.length < 2) {
      return null;
    } 
    
    final link = args[0];
    final keyDeclaration = LangUtils.obtainClassFromLink(link, _pd);
    return Class<K>.fromQualifiedName(keyDeclaration.getQualifiedName(), _pd, link);
  }
  
  @override
  Class<C>? componentType<C>() {
    checkAccess('componentType', DomainPermission.READ_TYPE_INFO);

    final args = _declaration.getReturnType().getTypeArguments();
    if (args.isEmpty) {
      return null;
    } 
    
    final link = keyType() != null ? args[1] : args[0];
    final keyDeclaration = LangUtils.obtainClassFromLink(link, _pd);
    return Class<C>.fromQualifiedName(keyDeclaration.getQualifiedName(), _pd, link);
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Parameter Information ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  Iterable<Parameter> getParameters() sync* {
    checkAccess('getParameters', DomainPermission.READ_METHODS);

    for (final parameter in _declaration.getParameters()) {
      yield Parameter.declared(parameter, this, _pd);
    }
  }

  @override
  int getParameterCount() {
    checkAccess('getParameterCount', DomainPermission.READ_METHODS);
    return getParameters().length;
  }

  @override
  Parameter? getParameter(String name) {
    checkAccess('getParameter', DomainPermission.READ_METHODS);
    final parameters = getParameters();
    return parameters.where((p) => p.getName() == name).firstOrNull;
  }

  @override
  Parameter? getParameterAt(int index) {
    checkAccess('getParameterAt', DomainPermission.READ_METHODS);
    final parameters = getParameters();
    if (index < 0 || index >= parameters.length) return null;
    return parameters.elementAt(index);
  }

  @override
  Iterable<Class> getParameterTypes() sync* {
    checkAccess('getParameterTypes', DomainPermission.READ_METHODS);

    for (final parameter in _declaration.getParameters()) {
      final link = parameter.getLinkDeclaration();
      yield LangUtils.obtainClassFromLink(link);
    }
  }

  @override
  Iterable<Class> getTypeParameters() sync* {
    checkAccess('getTypeParameters', DomainPermission.READ_TYPE_INFO);

    for (final arg in _declaration.getReturnType().getTypeArguments()) {
      yield LangUtils.obtainClassFromLink(arg);
    }
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Method Accessors ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  bool isStatic() {
    checkAccess('isStatic', DomainPermission.READ_METHODS);
    return _declaration.getIsStatic();
  }

  @override
  bool isAbstract() {
    checkAccess('isAbstract', DomainPermission.READ_METHODS);
    return _declaration.getIsAbstract();
  }

  @override
  bool isVoid() {
    checkAccess('isVoid', DomainPermission.READ_METHODS);

    final type = getReturnClass();
    return type == VOID_CLASS || type.getType() == Void;
  }

  @override
  bool isDynamic() {
    checkAccess('isDynamic', DomainPermission.READ_METHODS);

    final type = getReturnClass();
    return type == DYNAMIC_CLASS || type.getType() == Dynamic;
  }

  @override
  bool isAsync() {
    checkAccess('isAsync', DomainPermission.READ_METHODS);

    if (_declaration.isAsynchronous()) return true;

    final type = getReturnClass();
    return type == Class<Future>(null, PackageNames.DART) || type == Class<FutureOr>(null, PackageNames.DART);
  }

  @override
  bool isFutureVoid() {
    checkAccess('isFutureVoid', DomainPermission.READ_METHODS);

    final type = getReturnClass();

    if (type == Class<Future>(null, PackageNames.DART) || type == Class<FutureOr>(null, PackageNames.DART)) {
      final generic = type.componentType();
      return generic != null && (generic == VOID_CLASS || generic.getType() == Void);
    }
    
    return false;
  }

  @override
  bool isFutureDynamic() {
    checkAccess('isFutureDynamic', DomainPermission.READ_METHODS);

    final type = getReturnClass();

    if (type == Class<Future>(null, PackageNames.DART) || type == Class<FutureOr>(null, PackageNames.DART)) {
      final generic = type.componentType();
      return generic != null && (generic == DYNAMIC_CLASS || generic.getType() == Dynamic);
    }
    
    return false;
  }

  @override
  bool isGetter() {
    checkAccess('isGetter', DomainPermission.READ_METHODS);
    return _declaration.getIsGetter();
  }

  @override
  bool isSetter() {
    checkAccess('isSetter', DomainPermission.READ_METHODS);
    return _declaration.getIsSetter();
  }

  @override
  bool isPublic() {
    checkAccess('isPublic', DomainPermission.READ_METHODS);
    return _declaration.getIsPublic();
  }

  @override
  bool isConst() {
    checkAccess('isConst', DomainPermission.READ_METHODS);
    return _declaration.getIsConst();
  }

  @override
  bool isExternal() {
    checkAccess('isExternal', DomainPermission.READ_METHODS);
    return _declaration.isExternal();
  }

  @override
  bool getIsEntryPoint() {
    checkAccess('getIsEntryPoint', DomainPermission.READ_METHODS);
    return _declaration.getIsEntryPoint();
  }

  @override
  bool getIsTopLevel() {
    checkAccess('getIsTopLevel', DomainPermission.READ_METHODS);
    return _declaration.getIsTopLevel();
  }

  @override
  bool hasNullableReturn() {
    checkAccess('hasNullableReturn', DomainPermission.READ_METHODS);
    return _declaration.hasNullableReturn();
  }

  @override
  bool isFactory() {
    checkAccess('isFactory', DomainPermission.READ_METHODS);
    return _declaration.getIsFactory();
  }

  @override
  bool isKeyValuePaired() {
    checkAccess('isKeyValuePaired', DomainPermission.READ_TYPE_INFO);
    final args = _declaration.getReturnType().getTypeArguments();

    return (args.isNotEmpty && args.length >= 2) 
      || _declaration.getReturnType().getType() == Map 
      || getReturnClass().isAssignableTo(Class<Map>()) 
      || getReturnClass().isAssignableTo(Class<MapEntry>());
  }

  @override
  bool hasGenerics() => _declaration.getReturnType().getTypeArguments().isNotEmpty;

  @override
  bool isFunction() {
    checkAccess('isFunction', DomainPermission.READ_METHODS);
    return getLinkDeclaration() is FunctionDeclaration;
  }

  @override
  bool canAcceptArguments(Map<String, dynamic> arguments) {
    checkAccess('canAcceptArguments', DomainPermission.READ_METHODS);
    return MethodUtils.canAcceptArguments(arguments, getParameters());
  }

  @override
  bool canAcceptPositionalArguments(List<dynamic> args) {
    checkAccess('canAcceptPositionalArguments', DomainPermission.READ_METHODS);
    return MethodUtils.canAcceptPositionalArguments(args, getParameters());
  }

  @override
  bool canAcceptNamedArguments(Map<String, dynamic> arguments) {
    checkAccess('canAcceptNamedArguments', DomainPermission.READ_METHODS);
    return MethodUtils.canAcceptNamedArguments(arguments, getParameters());
  }

  @override
  String getSignature() => _createMethodSignature(_declaration);

  /// Create a method signature for comparison
  String _createMethodSignature(MethodDeclaration method) {
    final parameters = method.getParameters();
    final paramSignatures = <String>[];
    
    for (final param in parameters) {
      final paramName = param.getName();
      final isOptional = param.getIsNullable();
      final isNamed = param.getIsNamed();
      
      String paramSignature = param.getLinkDeclaration().getName();
      
      if (isNamed) {
        paramSignature = '{$paramSignature $paramName}';
      } else if (isOptional) {
        paramSignature = '[$paramSignature $paramName]';
      } else {
        paramSignature = '$paramSignature $paramName';
      }
      
      paramSignatures.add(paramSignature);
    }
    
    final returnType = method.getReturnType().getName();
    final methodName = method.getName();
    final isGetter = method.getIsGetter();
    final isSetter = method.getIsSetter();
    
    String signature = '$returnType $methodName(${paramSignatures.join(', ')})';
    
    if (isGetter) {
      signature = 'get $signature';
    } else if (isSetter) {
      signature = 'set $signature';
    }
    
    return signature;
  }

  @override
  bool isOverride() {
    checkAccess('isOverride', DomainPermission.READ_METHODS);
    
    // Static methods cannot be overridden
    if (isStatic()) {
      return false;
    }
    
    // Constructors cannot be overridden
    if (_declaration.getName().isEmpty || _declaration.getName() == _declaration.getParentClass()?.getName()) {
      return false;
    }
    
    // Check if this method overrides a method from superclass or interfaces
    final overriddenMethod = _findOverriddenMethod();
    return overriddenMethod != null;
  }

  @override
  Method? getOverriddenMethod() {
    checkAccess('getOverriddenMethod', DomainPermission.READ_METHODS);

    // Static methods cannot be overridden
    if (isStatic()) return null;

    // Try to find overridden method
    final overriddenDeclaration = _findOverriddenMethod();
    if (overriddenDeclaration != null) {
      return Method.declared(overriddenDeclaration, _pd);
    }

    return null;
  }

  /// Internal generator to traverse class/interface/mixin hierarchy
  Iterable<MethodDeclaration> _generateOverriddenMethods(ClassDeclaration clazz, String methodName, String methodSignature, [Set<String>? visited]) sync* {
    visited ??= <String>{};

    final className = clazz.getQualifiedName();
    if (!visited.add(className)) return; // avoid cycles

    // Yield matching methods from current class
    for (final method in clazz.getMethods()) {
      if (method.getName() == methodName && !method.getIsStatic() && _createMethodSignature(method) == methodSignature) {
        yield method;
      }
    }

    // Superclass
    if (clazz.getSuperClass() case final supertype?) {
      try {
        final superclass = LangUtils.obtainClassFromLink(supertype).getClassDeclaration();
        yield* _generateOverriddenMethods(superclass, methodName, methodSignature, visited);
      } catch (_) { /* suppress error */ }
    }

    // Interfaces
    for (final interfaceType in clazz.getInterfaces()) {
      try {
        final interfaceClass = LangUtils.obtainClassFromLink(interfaceType).getClassDeclaration();
        yield* _generateOverriddenMethods(interfaceClass, methodName, methodSignature, visited);
      } catch (_) { /* suppress error */ }
    }

    // Mixins
    for (final mixinType in clazz.getMixins()) {
      try {
        final mixinDeclaration = LangUtils.obtainClassFromLink(mixinType).getDeclaration();
        if (mixinDeclaration case MixinDeclaration mixinDeclaration) {
          yield* _generateOverriddenMethods(mixinDeclaration, methodName, methodSignature, visited);
        }
      } catch (_) { /* suppress error */ }
    }
  }

  /// Find the first overridden method declaration
  MethodDeclaration? _findOverriddenMethod() {
    ClassDeclaration? parent;

    if (_parent case final parentClass?) {
      parent = parentClass;
    } else if (_declaration.getParentClass() case final parentClass?) {
      try {
        parent = LangUtils.obtainClassFromLink(parentClass).getClassDeclaration();
      } on ClassNotFoundException catch (_) {}
    }
    
    if (parent == null) return null;

    final methodName = _declaration.getName();
    final methodSignature = _createMethodSignature(_declaration);

    // Return the first method found in the hierarchy
    return _generateOverriddenMethods(parent, methodName, methodSignature).firstOrNull;
  }

  @override
  List<String> getModifiers() {
    checkAccess('getModifiers', DomainPermission.READ_METHODS);

    return [
      if (isPublic()) 'PUBLIC',
      if (!isPublic()) 'PRIVATE',
      if (isStatic()) 'STATIC',
      if (isAbstract()) 'ABSTRACT',
      if (isConst()) 'CONST',
      if (isFactory()) 'FACTORY',
      if (isGetter()) 'GETTER',
      if (isSetter()) 'SETTER',
    ];
  }

  // ---------------------------------------------------------------------------------------------------------
  // === Invocation ===
  // ---------------------------------------------------------------------------------------------------------

  @override
  dynamic invoke(Object? instance, [Map<String, dynamic>? arguments, List<dynamic> args = const []]) {
    checkAccess('invoke', DomainPermission.INVOKE_METHODS);
    
    // 1. Try to invoke with positional arguments if provided
    if(args.isNotEmpty && arguments == null) {
      final parameters = _declaration.getParameters();
      final result = <String, dynamic>{};

      // Map positional arguments to parameter names
      for (int i = 0; i < args.length && i < parameters.length; i++) {
        final param = parameters[i];
        if (!param.getIsNamed()) {
          result[param.getName()] = args[i];
        }
      }

      return _declaration.invoke(instance, result);
    }

    // 2. Try to invoke with both positional and named arguments if both are provided
    if(args.isNotEmpty && arguments != null) {
      final parameters = _declaration.getParameters();
      final result = <String, dynamic>{...arguments};

      // Map positional arguments to parameter names
      for (int i = 0; i < args.length && i < parameters.length; i++) {
        final param = parameters[i];
        if (!param.getIsNamed()) {
          result[param.getName()] = args[i];
        }
      }

      // Map named arguments to parameter names
      for (int i = 0; i < arguments.length && i < parameters.length; i++) {
        final param = parameters[i];
        if (param.getIsNamed()) {
          final name = param.getName();
          result[name] = arguments[name];
        }
      }

      return _declaration.invoke(instance, result);
    }

    // 3. Try to invoke with named arguments if provided, or we assume that the method has no parameters.
    return _declaration.invoke(instance, arguments ?? {});
  }

  @override
  List<Object?> equalizedProperties() {
    return [
      _declaration.getName(),
      _declaration.getIsStatic(),
      _declaration.getIsGetter(),
      _declaration.getIsSetter(),
      _declaration.getIsPublic(),
      _declaration.getIsSynthetic(),
      _declaration.getType(),
    ];
  }

  @override
  String toString() => 'Method(${getName()})';
}