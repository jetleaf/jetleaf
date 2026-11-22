import 'dart:io';

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/lang.dart';
import 'aot_sub_registrar_writer.dart';

/// 📦 **Ahead-Of-Time (AOT) Pod Registry Code Generator**
///
/// Generates package-scoped `registry_pods.g.dart` sub-registry part files containing statically
/// compiled IoC pod definitions, zero-reflection instance suppliers, constructor dependency lookups,
/// and lifecycle hook invokers (`@PostConstruct` / `@PreDestroy`).
///
/// In pure Dart AOT mode, the runtime IoC container cannot inspect constructor parameters,
/// resolve types dynamically, or reflectively invoke initialization callbacks.
/// [AotPodRegistryWriter] generates high-performance, strongly-typed asynchronous closures
/// that wire dependencies directly via [PodFactory.get] or [PodFactory.getPod].
///
/// ## 🎯 Sample Generated Output
///
/// ```dart
/// // Generated in lib/_jetleaf/my_app/registry_pods.g.dart
/// part of '../registry.g.dart';
///
/// Future<void> _registerPods_my_app(DefaultListablePodFactory factory) async {
///   if (!factory.containsDefinition('userService')) {
///     await factory.registerDefinition('userService', RootPodDefinition(
///       type: Class<p0.UserService>.fromQualifiedName('package:my_app/user_service.dart/UserService'),
///       instanceSupplier: (PodFactory factory) async => p0.UserService(
///         await factory.get(Class<p0.UserRepository>()),
///       ),
///       initMethodInvoker: (instance) {
///         final res = (instance as dynamic).initialize();
///         if (res is Future) return res;
///       },
///       destroyMethodInvoker: (instance) {
///         final res = (instance as dynamic).dispose();
///         if (res is Future) return res;
///       },
///     )
///       ..name = 'userService'
///       ..design.isPrimary = true
///       ..lifecycle.isLazy = false
///     );
///   }
/// }
/// ```
///
/// ## 🔍 Stereotype Recognition & Meta-Annotations
///
/// Components qualify as pods if annotated with standard stereotypes:
/// - `@Component`, `@Service`, `@Repository`, `@Controller`, `@RestController`, `@Configuration`, `@Pod`
///
/// Additionally, custom user annotations that extend or meta-annotate these stereotypes are
/// deeply resolved via [matchesOrExtendsAnnotation].
///
/// Classes carrying conditional annotations (`@ConditionalOnProperty`, `@ConditionalOnClass`, etc.)
/// are deferred from static AOT pod registration and instead evaluated dynamically during context
/// configuration.
/// Maps primitive Dart type names to their `Class<...>()` literal expression.
String? primitiveClassLiteral(String typeName) {
  switch (typeName) {
    case 'String':
      return 'Class<String>()';
    case 'int':
      return 'Class<int>()';
    case 'double':
      return 'Class<double>()';
    case 'num':
      return 'Class<num>()';
    case 'bool':
      return 'Class<bool>()';
  }
  return null;
}

/// Escapes an arbitrary string into a safe single-quoted Dart string literal.
String dartStringLiteral(String value) {
  final escaped = value
    .replaceAll('\\', '\\\\')
    .replaceAll(r'$', r'\$')
    .replaceAll("'", r"\'");
  return "'$escaped'";
}

final class AotPodRegistryWriter extends AotSubRegistrarWriter {
  /// {@macro aot_pod_registry_writer}
  const AotPodRegistryWriter();

  String get _componentName => const Component().runtimeType.toString();
  String get _serviceName => const Service().runtimeType.toString();
  String get _repositoryName => const Repository().runtimeType.toString();
  String get _configurationName => const Configuration().runtimeType.toString();
  String get _autoConfigurationName => const AutoConfiguration().runtimeType.toString();
  String get _podName => const Pod().runtimeType.toString();
  String get _configurationPropertyName => const ConfigurationProperty().runtimeType.toString();
  String get _lazyName => const Lazy().runtimeType.toString();
  String get _scopeName => const Scope('singleton').runtimeType.toString();
  String get _primaryName => const Primary().runtimeType.toString();
  String get _namedName => const Named('').runtimeType.toString();
  String get _postConstructName => const PostConstruct().runtimeType.toString();
  String get _preDestroyName => const PreDestroy().runtimeType.toString();
  String get _reflectableName => "ReflectableAnnotation";
  String get _conditionalName => Conditional([]).runtimeType.toString();
  String get _controllerName => 'Controller';
  String get _restController => 'RestController';
  String get _valueName => const Value('').runtimeType.toString();

  /// Known stereotype annotation names that qualify a class as an IoC Pod.
  Set<String> get _podStereotypes => {
    _componentName,
    _serviceName,
    _repositoryName,
    _controllerName,
    _restController,
    _configurationName,
    _autoConfigurationName,
    _podName,
    'JetleafApplicationStarter',
    _configurationPropertyName,
  };

  /// Conditional annotations whose enclosing definitions are not emitted as
  /// unconditional AOT pods.
  Set<String> get _configurationAndConditionalNames => {
    _conditionalName,
    ConditionalOnProperty().runtimeType.toString(),
    ConditionalOnClass().runtimeType.toString(),
    ConditionalOnMissingClass().runtimeType.toString(),
    ConditionalOnPod().runtimeType.toString(),
    ConditionalOnMissingPod().runtimeType.toString(),
    ConditionalOnExpression(Object()).runtimeType.toString(),
    Profile([]).runtimeType.toString(),
    'ConditionalOnWebApplication',
    'ConditionalOnNotWebApplication',
  };

  /// Supported lifecycle initialization annotation identifiers.
  Set<String> get _postConstructNames => {
    _postConstructName,
  };

  /// Supported lifecycle destruction annotation identifiers.
  Set<String> get _preDestroyNames => {_preDestroyName};

  /// Recursively determines whether [annName] directly matches any name in [targets],
  /// or if its class declaration in [classByName] inherits, implements, or is
  /// meta-annotated with any target in [targets].
  ///
  /// Prevents infinite loops across cyclic meta-annotation graphs via [visited].
  bool matchesOrExtendsAnnotation(
    String annName,
    Set<String> targets,
    Map<String, ClassDeclaration> classByName, [
    Set<String>? visited,
  ]) {
    if (targets.contains(annName)) return true;
    final v = visited ?? <String>{};
    if (!v.add(annName)) return false;

    final decl = classByName[annName];
    if (decl == null) return false;

    final superClass = decl.getSuperClass();
    if (superClass != null) {
      if (matchesOrExtendsAnnotation(superClass.getName(), targets, classByName, v)) {
        return true;
      }
    }

    for (final iface in decl.getInterfaces()) {
      if (matchesOrExtendsAnnotation(iface.getName(), targets, classByName, v)) {
        return true;
      }
    }

    for (final metaAnn in decl.getAnnotations()) {
      if (matchesOrExtendsAnnotation(metaAnn.getName(), targets, classByName, v)) {
        return true;
      }
    }

    return false;
  }

  /// Returns `true` if [component] represents a metadata annotation class
  /// (directly extends or implements `ReflectableAnnotation`).
  ///
  /// Annotation classes are excluded from IoC pod registration.
  bool isAnnotationClass(
    ClassDeclaration component,
    Map<String, ClassDeclaration> classByName, [
    Set<String>? visited,
  ]) {
    final name = component.getName();
    if (name == _reflectableName) return true;
    final v = visited ?? <String>{};
    if (!v.add(name)) return false;

    final superClass = component.getSuperClass();
    if (superClass != null) {
      final superName = superClass.getName();
      if (superName == _reflectableName) return true;
      final superDecl = classByName[superName];
      if (superDecl != null && isAnnotationClass(superDecl, classByName, v)) {
        return true;
      }
    }

    for (final iface in component.getInterfaces()) {
      final ifaceName = iface.getName();
      if (ifaceName == _reflectableName) return true;
      final ifaceDecl = classByName[ifaceName];
      if (ifaceDecl != null && isAnnotationClass(ifaceDecl, classByName, v)) {
        return true;
      }
    }

    return false;
  }

  /// Determines whether [component] qualifies as an instantiable IoC pod component.
  ///
  /// Returns `false` if:
  /// - The component is abstract
  /// - The component is an annotation definition
  /// - The component is guarded by a conditional annotation (evaluated at runtime)
  /// - The component lacks a recognized pod stereotype
  bool isPodComponent(ClassDeclaration component, [Map<String, ClassDeclaration> classByName = const {}]) {
    if (component.getIsAbstract()) return false;
    if (isAnnotationClass(component, classByName)) return false;
    if (_isConfigurationOrConditional(component, classByName)) return false;

    for (final annotation in component.getAnnotations()) {
      final name = annotation.getName();
      if (matchesOrExtendsAnnotation(name, _podStereotypes, classByName)) {
        return true;
      }
    }
    return false;
  }

  /// Returns `true` if [component] carries a conditional marker.
  ///
  /// `@Configuration` and `@AutoConfiguration` are intentionally accepted:
  /// registering their definitions is what lets
  /// `ConfigurationClassPostProcessor` discover and process their pod methods.
  bool _isConfigurationOrConditional(ClassDeclaration component, Map<String, ClassDeclaration> classByName) {
    for (final annotation in component.getAnnotations()) {
      final name = annotation.getName();
      if (name == _configurationPropertyName) {
        continue;
      }

      if (name.startsWith(_conditionalName) || matchesOrExtendsAnnotation(name, _configurationAndConditionalNames, classByName)) {
        return true;
      }
    }

    return false;
  }

  /// Writes `registry_pods.g.dart` for [packageName] into [packageDir] if any pod components exist.
  ///
  /// Scans [components], resolves pod names, constructs asynchronous instance suppliers
  /// with factory lookups, and registers [RootPodDefinition] entries into the container.
  ///
  /// Returns the generated top-level registration function name (e.g. `_registerPods_my_package`),
  /// or `null` if no pod components were discovered in this package.
  Future<String?> write({
    required Directory packageDir,
    required String packageName,
    required List<ClassDeclaration> components,
    required Map<String, String> libraryAliases,
    required Map<String, String> classToPrefix,
    required Set<String> usedPodNames,
    Map<String, ClassDeclaration> classByName = const {},
    Map<String, String> podMethodByReturnType = const {},
  }) async {
    final scanRoots = resolveEffectiveComponentScanRoots(components);
    final podComponents = components.where((c) {
      if (!isPodComponent(c, classByName)) return false;
      // Component scan roots: register only classes in the declared packages.
      if (scanRoots != null && !isComponentScanned(c, scanRoots)) return false;
      return true;
    }).toList();
    if (podComponents.isEmpty) return null;

    final fnName = '_registerPods_${sanitizePackageIdentifier(packageName)}';
    final buffer = StringBuffer();
    final factoryMethodBuffer = StringBuffer();
    var factoryMethodPodsEmitted = 0;

    writeNestedPartHeader(buffer, 'AOT Pods Sub-Registry for [$packageName]');
    buffer.writeln('Future<void> $fnName(DefaultListablePodFactory factory) async {');

    for (final component in podComponents) {
      final className = component.getName();
      final libraryUri = component.getLibrary().getUri();

      String prefix = '';
      if (libraryUri.isNotEmpty && !libraryUri.startsWith('dart:')) {
        prefix = libraryAliases[libraryUri] != null ? '${libraryAliases[libraryUri]}.' : '';
      }

      var podName = _resolvePodName(component, classByName);
      if (usedPodNames.contains(podName)) {
        final aliasName = libraryAliases[libraryUri] ?? 'dup';
        podName = '${aliasName}_$podName';
      }
      usedPodNames.add(podName);

      final supplierCode = _buildInstanceSupplier(
        component,
        prefix,
        className,
        classToPrefix,
        podMethodByReturnType,
        libraryAliases,
      );
      final initInvokerCode = _buildInitInvoker(component, prefix, className, classByName);
      final destroyInvokerCode = _buildDestroyInvoker(component, prefix, className, classByName);

      final isLazy = _hasAnnotation(component, {_lazyName}, classByName);
      final isPrimary = _hasAnnotation(component, {_primaryName}, classByName);
      final scopeDesign = _scopeDesignExpression(component, classByName);
      final definitionArguments = <String>[
        "      type: Class<$prefix$className>.fromQualifiedName('${escapeDartStringLiteral(component.getQualifiedName())}'),",
        if (supplierCode != null) '      instanceSupplier: $supplierCode,',
        if (initInvokerCode != null) '      initMethodInvoker: $initInvokerCode,',
        if (destroyInvokerCode != null) '      destroyMethodInvoker: $destroyInvokerCode,',
      ];
      final definitionCascades = <String>[
        "      ..name = '${escapeDartStringLiteral(podName)}'",
        if (scopeDesign != null) '      ..scope = $scopeDesign',
        '      ..design.isPrimary = $isPrimary',
        '      ..lifecycle.isLazy = $isLazy',
      ];
      buffer.writeln('''  if (!factory.containsDefinition('${escapeDartStringLiteral(podName)}')) {
    await factory.registerDefinition('${escapeDartStringLiteral(podName)}', RootPodDefinition(
${definitionArguments.join('\n')}
    )
${definitionCascades.join('\n')}
    );
  }''');
    }

    // Configuration factory methods are pods too. In pure AOT mode there is no
    // reflection metadata for ConfigurationClassPostProcessor to discover them, so they are emitted statically.
    for (final component in components) {
      if (!_isConfiguration(component, classByName)) continue;

      final configurationName = _resolvePodName(component, classByName);
      final configurationUri = component.getLibrary().getUri();
      final configurationPrefix = libraryAliases[configurationUri] != null
        ? '${libraryAliases[configurationUri]}.'
        : '';

      for (final method in component.getMethods()) {
        if (!method.getAnnotations().any((annotation) => matchesOrExtendsAnnotation(annotation.getName(), {_podName}, classByName))) {
          continue;
        }

        // `@Pod` methods returning `Future<X>` are registered under the
        // completeness type `X` — fall out of `Future` whose runtime value
        // is awaited by the container before the pod is published (matching
        // `isAsync ? componentType() : getReturnClass()` in `AnnotatedPodMethodBuilder`).
        final returnType = method.getReturnType();
        final effectiveReturnType = method.isAsynchronous() && returnType.getTypeArguments().length == 1
          ? returnType.getTypeArguments().first
          : returnType;
        final returnTypeName = effectiveReturnType.getName();
        final returnTypePrefix = _typeReferencePrefix(effectiveReturnType, libraryAliases) ?? classToPrefix[returnTypeName];
        final supplierCode = _buildPodMethodSupplier(
          component,
          method,
          configurationPrefix,
          classToPrefix,
          podMethodByReturnType,
          libraryAliases,
          classByName,
        );

        final canEmitType = returnTypeName.isNotEmpty && (returnTypePrefix != null || effectiveReturnType.getPointerQualifiedName().isNotEmpty);

        if (!canEmitType || supplierCode == null) {
          continue;
        }

        final preferredName = _podMethodPreferredName(method, classByName);
        final qualifiedName = '$configurationName.${method.getName()}';
        if (usedPodNames.contains(preferredName) || usedPodNames.contains(qualifiedName)) continue;
        usedPodNames.add(preferredName);
        usedPodNames.add(qualifiedName);

        final methodIsPrimary = _methodHasAnnotation(method, {_primaryName}, classByName);
        final scopeDesign = _scopeDesignExpressionForMethod(method, classByName);
        final factoryMethodCascades = <String>[
          if (scopeDesign != null) '        ..scope = $scopeDesign',
          "        ..factoryMethod = FactoryMethodDesign('${escapeDartStringLiteral(configurationName)}', '${escapeDartStringLiteral(method.getName())}')",
          '        ..design.isPrimary = $methodIsPrimary',
        ];

        final effectiveReturnTypeRef = returnTypePrefix != null
          ? 'Class<$returnTypePrefix$returnTypeName>()'
          : 'Class.fromQualifiedName(\'${escapeDartStringLiteral(effectiveReturnType.getPointerQualifiedName())}\')';

        factoryMethodBuffer.writeln('''  if (!factory.containsDefinition('${escapeDartStringLiteral(preferredName)}')) {
      await factory.registerDefinition('${escapeDartStringLiteral(preferredName)}', RootPodDefinition(
        type: $effectiveReturnTypeRef,
        instanceSupplier: $supplierCode,
      )
        ..name = '${escapeDartStringLiteral(preferredName)}'
${factoryMethodCascades.join('\n')}
      );
    } else if (!_isSameFactoryMethod('${escapeDartStringLiteral(preferredName)}', '${escapeDartStringLiteral(configurationName)}', '${escapeDartStringLiteral(method.getName())}') && !factory.containsDefinition('${escapeDartStringLiteral(qualifiedName)}')) {
      await factory.registerDefinition('${escapeDartStringLiteral(qualifiedName)}', RootPodDefinition(
        type: $effectiveReturnTypeRef,
        instanceSupplier: $supplierCode,
      )
        ..name = '${escapeDartStringLiteral(qualifiedName)}'
${factoryMethodCascades.join('\n')}
      );
    }''');
        factoryMethodPodsEmitted++;
      }
    }

    if (factoryMethodPodsEmitted > 0) {
      buffer.writeln('''  bool _isSameFactoryMethod(String name, String configPod, String method) {
    try {
      final def = factory.getDefinition(name);
      return def.factoryMethod.podName == configPod && def.factoryMethod.methodName == method;
    } catch (_) {
      return false;
    }
  }
''');
      buffer.write(factoryMethodBuffer.toString());
    }

    buffer.writeln('}');

    if (!packageDir.existsSync()) {
      packageDir.createSync(recursive: true);
    }
    final file = File('${packageDir.path}/${Constant.REGISTRY_PODS_FILE_NAME}');
    await file.writeAsString(buffer.toString());
    return fnName;
  }

  bool _isConfiguration(ClassDeclaration component, Map<String, ClassDeclaration> classByName) {
    for (final annotation in component.getAnnotations()) {
      if (matchesOrExtendsAnnotation(annotation.getName(), {_autoConfigurationName}, classByName)) {
        return true;
      }

      if (matchesOrExtendsAnnotation(annotation.getName(), {_configurationName}, classByName)) {
        return true;
      }
    }

    return false;
  }

  /// Checks whether [method] carries an annotation within [targets] (or extends/meta-annotates to one).
  ///
  /// Used to detect [Primary] (and any future stereotype markers) on factory
  /// `@Pod` methods so that generated AOT pods honour the same semantics as
  /// their reflective counterparts.
  bool _methodHasAnnotation(MethodDeclaration method, Set<String> targets, Map<String, ClassDeclaration> classByName) {
    for (final annotation in method.getAnnotations()) {
      final name = annotation.getName();
      if (matchesOrExtendsAnnotation(name, targets, classByName)) {
        return true;
      }
    }

    return false;
  }

  /// Resolves the user-facing name for a `@Pod`-annotated factory method.
  ///
  /// Matches the historical `AnnotatedPodMethodBuilder` naming policy exactly:
  ///
  /// 1. `@Named('name')` wins outright
  /// 2. `@Pod('value')` wins when non-empty
  /// 3. bare method name wins when no explicit name is given
  ///
  /// If [component] carries an `@Scope` annotation, returns a `ScopeDesign.type('…')`
  /// expression to embed in the generated definition; `null` when absent.
  String? _scopeDesignExpression(ClassDeclaration component, Map<String, ClassDeclaration> classByName) {
    for (final annotation in component.getAnnotations()) {
      final name = annotation.getName();
      if (!matchesOrExtendsAnnotation(name, {_scopeName}, classByName)) continue;
      final values = annotation.getUserProvidedValues();
      return _scopeDesignFromValues(values);
    }

    return null;
  }

  /// If [method] carries an `@Scope` annotation, returns a `ScopeDesign.type('…')`
  /// expression to embed in the generated definition; `null` when absent.
  String? _scopeDesignExpressionForMethod(MethodDeclaration method, Map<String, ClassDeclaration> classByName) {
    for (final annotation in method.getAnnotations()) {
      final name = annotation.getName();
      if (!matchesOrExtendsAnnotation(name, {_scopeName}, classByName)) continue;
      final values = annotation.getUserProvidedValues();
      return _scopeDesignFromValues(values);
    }

    return null;
  }

  String? _scopeDesignFromValues(Map<String, Object?> values) {
    final value = values['value'] ?? values[r'$0'];
    if (value is String && value.trim().isNotEmpty) {
      return "ScopeDesign.type('${value.trim().toLowerCase()}')";
    }

    return null;
  }

  /// Returns an empty result when nothing usable is found so callers can
  /// decide on their own fallback.
  String? _podAnnotationValue(MethodDeclaration method, Set<String> targets, Map<String, ClassDeclaration> classByName) {
    for (final annotation in method.getAnnotations()) {
      final name = annotation.getName();
      if (!matchesOrExtendsAnnotation(name, targets, classByName)) continue;
      final values = annotation.getUserProvidedValues();
      final v = values['name'] ?? values['value'] ?? values[r'$0'];
      if (v is String && v.isNotEmpty) return v;
    }

    return null;
  }

  /// Computes the preferred pod name for a `@Pod`-annotated factory method.
  ///
  /// See [_podAnnotationValue] for the resolution order. Callers should treat
  /// a collision with an existing definition that is *not* this exact factory
  /// method as an error in the caller, not in this helper.
  String _podMethodPreferredName(MethodDeclaration method, Map<String, ClassDeclaration> classByName) {
    final named = _podAnnotationValue(method, {_namedName}, classByName);
    if (named != null) return named;
    final pod = _podAnnotationValue(method, {_podName}, classByName);
    if (pod != null) return pod;
    return method.getName();
  }

  String? _buildPodMethodSupplier(
    ClassDeclaration configuration,
    MethodDeclaration method,
    String configurationPrefix,
    Map<String, String> classToPrefix,
    Map<String, String> podMethodByReturnType,
    Map<String, String> libraryAliases,
    Map<String, ClassDeclaration> classByName,
  ) {
    final positionalArgs = <String>[];
    final namedArgs = <String>[];

    for (final parameter in method.getParameters()) {
      final parameterType = parameter.getLinkDeclaration().getName();

      // Fast path: a registered library prefix for the parameter's written
      // type reference, resolved from the URI the parameter was declared with.
      final referencePrefix = _typeReferencePrefix(parameter.getLinkDeclaration(), libraryAliases);

      // Fall back to the simple-name prefix map for parameters whose link
      // URI carries no useful import prefix.
      final typePrefix = classToPrefix.containsKey(parameterType) && !isPrimitiveType(parameterType)
        ? classToPrefix[parameterType]
        : null;

      var lookup = _buildParameterLookup(
        parameter: parameter,
        referencePrefix: referencePrefix,
        typePrefix: typePrefix,
        parameterType: parameterType,
        podMethodByReturnType: podMethodByReturnType,
        classByName: classByName,
      );

      if (lookup != null && (!parameter.getIsRequired() || parameter.getIsNullable())) {
        lookup = "_optional(factory, () async => $lookup)";
      }

      if (lookup == null) {
        if (parameter.getIsRequired()) return null;
        continue;
      }

      final argument = 'await $lookup';
      if (parameter.getIsNamed()) {
        namedArgs.add('${parameter.getName()}: $argument');
      } else {
        positionalArgs.add(argument);
      }
    }

    final arguments = [...positionalArgs, ...namedArgs];
    final configurationName = configuration.getName();
    final buffer = StringBuffer('(PodFactory factory) async {\n');
    buffer.writeln('  final configuration = await factory.get(Class<$configurationPrefix$configurationName>());');
    buffer.writeln('  return configuration.${method.getName()}(');
    for (final argument in arguments) {
      buffer.writeln('    $argument,');
    }
    buffer.writeln('  );');
    buffer.write('}');
    return buffer.toString();
  }

  /// Resolves the imported library prefix (e.g. `"p3."`) for a written type
  /// reference.
  ///
  /// [link] is the raw type reference the writer sees on parameters or
  /// return types. It may carry either a `referenceUri` (the import where the
  /// type was found) or a `canonicalUri` (where the type is declared). Both
  /// point at a library file, and that file URI is the same key used by
  /// [libraryAliases] to map libraries to generated import prefixes.
  ///
  /// Any fragment is stripped because [LinkDeclaration] URIs routinely include
  /// one (e.g. `package:example/logger.dart#Logger`).
  ///
  /// Returns `null` when the library is not part of the generated import set,
  /// so callers can fall back to the simple-name prefix map.
  String? _typeReferencePrefix(LinkDeclaration? link, Map<String, String> libraryAliases) {
    if (link == null) return null;

    final uri = link.getReferenceUri() ?? link.getCanonicalUri();
    final raw = uri?.toString();
    if (raw == null || raw.isEmpty) return null;

    final alias = libraryAliases[raw.split('#').first];
    return alias == null ? null : '$alias.';
  }

  /// Extracts the literal expression of a `@Value` annotation on [parameter], if any.
  String? _valueExpression(ParameterDeclaration parameter, Map<String, ClassDeclaration> classByName) {
    for (final ann in parameter.getAnnotations()) {
      final annName = ann.getName();
      if (!matchesOrExtendsAnnotation(annName, {_valueName}, classByName)) continue;
      final Map<String, dynamic> values = ann.getUserProvidedValues();
      final Object? raw = values[r'$0'] ?? values['value'] ?? values['expression'];
      if (raw != null) return raw.toString();
    }
    return null;
  }

  /// Returns the written type name to cast to for `@Value`-bound parameters.
  String? _castTarget(String parameterType, String? referencePrefix) {
    if (parameterType.isEmpty || parameterType == 'dynamic' || parameterType == 'Object') {
      return null;
    }
    if (referencePrefix != null && !isPrimitiveType(parameterType)) {
      return '$referencePrefix$parameterType';
    }
    return parameterType;
  }

  /// Builds the supplier lookup expression for an injectable parameter.
  String? _buildParameterLookup({
    required ParameterDeclaration parameter,
    required String? referencePrefix,
    required String? typePrefix,
    required String parameterType,
    required Map<String, String> podMethodByReturnType,
    required Map<String, ClassDeclaration> classByName,
  }) {
    final valueExpression = _valueExpression(parameter, classByName);
    if (valueExpression != null) {
      final castTarget = _castTarget(parameterType, referencePrefix);
      final targetType = primitiveClassLiteral(parameterType) ?? "Class.fromQualifiedName('${parameter.getLinkDeclaration().getPointerQualifiedName()}')";
      return "_resolveConfigValue(factory, ${dartStringLiteral(valueExpression)}, $targetType)${castTarget == null ? '' : ' as $castTarget'}";
    }

    if (referencePrefix != null && !isPrimitiveType(parameterType)) {
      return 'factory.get(Class<$referencePrefix$parameterType>())';
    }

    final q = parameter.getLinkDeclaration().getPointerQualifiedName();
    if (q.isNotEmpty) {
      return "factory.get(Class.fromQualifiedName('$q'))";
    }

    if (podMethodByReturnType.containsKey(parameterType)) {
      return "factory.getPod('${podMethodByReturnType[parameterType]}')";
    }

    if (typePrefix != null) {
      return 'factory.get(Class<$typePrefix$parameterType>())';
    }

    return null;
  }

  /// Resolves the explicit or default pod name for [component].
  ///
  /// Inspects `@Named('customName')` or `@Component('customName')` / `@Service('customName')`
  /// values. If omitted, falls back to the camel-cased class identifier (e.g. `UserRepository` -> `userRepository`).
  String _resolvePodName(ClassDeclaration component, Map<String, ClassDeclaration> classByName) {
    String? name;
    for (final ann in component.getAnnotations()) {
      final annName = ann.getName();
      final values = ann.getUserProvidedValues();
      if (annName == _namedName || matchesOrExtendsAnnotation(annName, {_namedName}, classByName)) {
        final v = values['name'] ?? values['value'] ?? values[r'$0'];
        if (v is String && v.isNotEmpty) {
          name = v;
        }
      } else if (matchesOrExtendsAnnotation(annName, {
        _componentName,
        _serviceName,
        _repositoryName,
        _controllerName,
        _restController,
        _configurationName,
        _podName,
      }, classByName)) {
        final v = values['value'] ?? values['name'] ?? values[r'$0'];
        if (v is String && v.isNotEmpty) {
          name ??= v;
        }
      }
    }

    return (name != null && name.isNotEmpty) ? name : camelCase(component.getName());
  }

  /// Checks if [component] carries any annotation within [targets], considering meta-annotations.
  bool _hasAnnotation(ClassDeclaration component, Set<String> targets, Map<String, ClassDeclaration> classByName) {
    return component.getAnnotations().any(
      (a) => matchesOrExtendsAnnotation(a.getName(), targets, classByName),
    );
  }

  /// Synthesizes a static, strongly-typed asynchronous instance supplier lambda:
  ///
  /// ```dart
  /// (PodFactory factory) async => MyService(await factory.get(Class<Repo>()))
  /// ```
  ///
  /// Automatically resolves positional and named constructor arguments by inspecting
  /// parameter types and `@Named` qualifiers against the container.
  String? _buildInstanceSupplier(
    ClassDeclaration component,
    String prefix,
    String className,
    Map<String, String> classToPrefix,
    Map<String, String> podMethodByReturnType,
    Map<String, String> libraryAliases,
  ) {
    final constructors = component.getConstructors();
    ConstructorDeclaration? targetConstructor;

    if (constructors.isNotEmpty) {
      targetConstructor = constructors.firstWhere(
        (c) => c.getName().isEmpty,
        orElse: () => constructors.first,
      );
    }

    if (targetConstructor == null) {
      return '(PodFactory factory) async => $prefix$className()';
    }

    final positionalArgs = <String>[];
    final namedArgs = <String>[];

    for (final param in targetConstructor.getParameters()) {
      var paramTypeName = param.getLinkDeclaration().getName();
      if (paramTypeName.isEmpty || paramTypeName == 'dynamic' || paramTypeName == 'Object') {
        final field = component.getField(param.getName());
        final fieldTypeName = field?.getLinkDeclaration().getName();
        if (fieldTypeName != null && fieldTypeName.isNotEmpty && fieldTypeName != 'dynamic' && fieldTypeName != 'Object') {
          paramTypeName = fieldTypeName;
        }
      }

      String? namedQualifier;
      for (final ann in param.getAnnotations()) {
        if (ann.getName() == 'Named') {
          namedQualifier = ann.getUserProvidedValues()['value']?.toString() ?? ann.getUserProvidedValues()['name']?.toString();
        }
      }

      String lookup;
      final typePrefix = _typeReferencePrefix(param.getLinkDeclaration(), libraryAliases) ?? classToPrefix[paramTypeName];
      if (namedQualifier != null && namedQualifier.isNotEmpty) {
        lookup = "factory.getPod('$namedQualifier')";
      } else if (typePrefix != null && !isPrimitiveType(paramTypeName)) {
        lookup = "factory.get(Class<$typePrefix$paramTypeName>())";
      } else if (podMethodByReturnType.containsKey(paramTypeName)) {
        final podMethodName = podMethodByReturnType[paramTypeName]!;
        lookup = "factory.getPod('$podMethodName')";
      } else {
        return null;
      }

      if (!param.getIsRequired() || param.getIsNullable()) {
        lookup = "_optional(factory, () async => $lookup)";
      }

      if (param.getIsNamed()) {
        namedArgs.add('${param.getName()}: await $lookup');
      } else {
        positionalArgs.add('await $lookup');
      }
    }

    final argsList = [
      ...positionalArgs,
      ...namedArgs,
    ].join(', ');

    return '(PodFactory factory) async => $prefix$className($argsList)';
  }

  /// Synthesizes a static initialization closure for methods annotated with `@PostConstruct`.
  String? _buildInitInvoker(
    ClassDeclaration component,
    String prefix,
    String className,
    Map<String, ClassDeclaration> classByName,
  ) {
    final matchingMethods = <MethodDeclaration>[];
    for (final method in component.getMethods()) {
      if (method.getParameters().isNotEmpty) continue;
      for (final annotation in method.getAnnotations()) {
        if (matchesOrExtendsAnnotation(annotation.getName(), _postConstructNames, classByName)) {
          matchingMethods.add(method);
          break;
        }
      }
    }
    if (matchingMethods.isEmpty) return null;

    if (matchingMethods.length == 1) {
      final method = matchingMethods.single;
      final buffer = StringBuffer('(instance) {\n');
      buffer.writeln('  final result = (instance as dynamic).${method.getName()}();');
      buffer.writeln('  if (result is Future) {');
      buffer.writeln('    return result;');
      buffer.writeln('  }');
      buffer.write('}');
      return buffer.toString();
    }

    final buffer = StringBuffer('(instance) async {\n');
    for (final method in matchingMethods) {
      buffer.writeln('  final res_${method.getName()} = (instance as dynamic).${method.getName()}();');
      buffer.writeln('  if (res_${method.getName()} is Future) {');
      buffer.writeln('    await res_${method.getName()};');
      buffer.writeln('  }');
    }
    buffer.write('}');
    return buffer.toString();
  }

  /// Synthesizes a static disposal closure for methods annotated with `@PreDestroy`.
  String? _buildDestroyInvoker(
    ClassDeclaration component,
    String prefix,
    String className,
    Map<String, ClassDeclaration> classByName,
  ) {
    final matchingMethods = <MethodDeclaration>[];
    for (final method in component.getMethods()) {
      if (method.getParameters().isNotEmpty) continue;
      for (final annotation in method.getAnnotations()) {
        if (matchesOrExtendsAnnotation(annotation.getName(), _preDestroyNames, classByName)) {
          matchingMethods.add(method);
          break;
        }
      }
    }
    if (matchingMethods.isEmpty) return null;

    if (matchingMethods.length == 1) {
      final method = matchingMethods.single;
      final buffer = StringBuffer('(instance) {\n');
      buffer.writeln('  final result = (instance as dynamic).${method.getName()}();');
      buffer.writeln('  if (result is Future) {');
      buffer.writeln('    return result;');
      buffer.writeln('  }');
      buffer.write('}');
      return buffer.toString();
    }

    final buffer = StringBuffer('(instance) async {\n');
    for (final method in matchingMethods) {
      buffer.writeln('  final res_${method.getName()} = (instance as dynamic).${method.getName()}();');
      buffer.writeln('  if (res_${method.getName()} is Future) {');
      buffer.writeln('    await res_${method.getName()};');
      buffer.writeln('  }');
    }
    buffer.write('}');
    return buffer.toString();
  }
}