import 'dart:io';

import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/lang.dart';
import 'aot_sub_registrar_writer.dart';

/// {@template aot_pod_registry_writer}
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
/// part of '../aot_registry.g.dart';
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
/// {@endtemplate}
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
  String get _primaryName => const Primary().runtimeType.toString();
  String get _namedName => const Named('').runtimeType.toString();
  String get _postConstructName => const PostConstruct().runtimeType.toString();
  String get _onApplicationReadyName => const OnApplicationReady().runtimeType.toString();
  String get _preDestroyName => const PreDestroy().runtimeType.toString();
  String get _reflectableName => "ReflectableAnnotation";
  String get _conditionalName => Conditional([]).runtimeType.toString();
  String get _controllerName => 'Controller';
  String get _restController => 'RestController';

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
    _onApplicationReadyName,
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
    final podComponents = components.where((c) => isPodComponent(c, classByName)).toList();
    if (podComponents.isEmpty) return null;

    final fnName = '_registerPods_${sanitizePackageIdentifier(packageName)}';
    final buffer = StringBuffer();
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
      );
      final initInvokerCode = _buildInitInvoker(component, prefix, className, classByName);
      final destroyInvokerCode = _buildDestroyInvoker(component, prefix, className, classByName);

      final isLazy = _hasAnnotation(component, {_lazyName}, classByName);
      final isPrimary = _hasAnnotation(component, {_primaryName}, classByName);
      buffer.writeln('''  if (!factory.containsDefinition('$podName')) {
    await factory.registerDefinition('$podName', RootPodDefinition(
      type: Class<$prefix$className>.fromQualifiedName('${component.getQualifiedName()}'),
      ${supplierCode != null ? 'instanceSupplier: $supplierCode,' : ''}
      ${initInvokerCode != null ? 'initMethodInvoker: $initInvokerCode,' : ''}
      ${destroyInvokerCode != null ? 'destroyMethodInvoker: $destroyInvokerCode,' : ''}
    )
      ..name = '$podName'
      ..design.isPrimary = $isPrimary
      ..lifecycle.isLazy = $isLazy
    );
  }''');
    }

    // Configuration factory methods are pods too.  Emitting them directly is
    // essential in AOT mode, where reflection metadata is not available for
    // ConfigurationClassPostProcessor to discover `@Pod` methods at runtime.
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

        final returnTypeName = method.getReturnType().getName();
        final returnTypePrefix = classToPrefix[returnTypeName];
        final supplierCode = _buildPodMethodSupplier(
          component,
          method,
          configurationPrefix,
          classToPrefix,
          podMethodByReturnType,
        );

        if (returnTypeName.isEmpty || returnTypePrefix == null || supplierCode == null) {
          continue;
        }

        final methodPodName = '$configurationName.${method.getName()}';
        if (usedPodNames.contains(methodPodName)) continue;
        usedPodNames.add(methodPodName);

        buffer.writeln('''  if (!factory.containsDefinition('$methodPodName')) {
      await factory.registerDefinition('$methodPodName', RootPodDefinition(
        type: Class<$returnTypePrefix$returnTypeName>(),
        instanceSupplier: $supplierCode,
      )
        ..name = '$methodPodName'
        ..factoryMethod = FactoryMethodDesign('$configurationName', '${method.getName()}')
      );
    }''');
      }
    }

    buffer.writeln('}');

    if (!packageDir.existsSync()) {
      packageDir.createSync(recursive: true);
    }
    final file = File('${packageDir.path}/${Constant.AOT_REGISTRY_PODS_FILE_NAME}');
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

  String? _buildPodMethodSupplier(
    ClassDeclaration configuration,
    MethodDeclaration method,
    String configurationPrefix,
    Map<String, String> classToPrefix,
    Map<String, String> podMethodByReturnType,
  ) {
    final positionalArgs = <String>[];
    final namedArgs = <String>[];

    for (final parameter in method.getParameters()) {
      final parameterType = parameter.getLinkDeclaration().getName();
      final typePrefix = classToPrefix[parameterType];
      String? lookup;
      if (typePrefix != null && !isPrimitiveType(parameterType)) {
        lookup = 'factory.get(Class<$typePrefix$parameterType>())';
      } else if (podMethodByReturnType.containsKey(parameterType)) {
        lookup = "factory.getPod('${podMethodByReturnType[parameterType]}')";
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
      if (namedQualifier != null && namedQualifier.isNotEmpty) {
        lookup = "factory.getPod('$namedQualifier')";
      } else if (classToPrefix.containsKey(paramTypeName) && !isPrimitiveType(paramTypeName)) {
        final typePrefix = classToPrefix[paramTypeName]!;
        lookup = "factory.get(Class<$typePrefix$paramTypeName>())";
      } else if (podMethodByReturnType.containsKey(paramTypeName)) {
        final podMethodName = podMethodByReturnType[paramTypeName]!;
        lookup = "factory.getPod('$podMethodName')";
      } else {
        return null;
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

  /// Synthesizes a static initialization closure for methods annotated with `@PostConstruct` or `@OnApplicationReady`.
  String? _buildInitInvoker(
    ClassDeclaration component,
    String prefix,
    String className,
    Map<String, ClassDeclaration> classByName,
  ) {
    for (final method in component.getMethods()) {
      for (final annotation in method.getAnnotations()) {
        if (matchesOrExtendsAnnotation(annotation.getName(), _postConstructNames, classByName)) {
          final buffer = StringBuffer('(instance) {\n');
          buffer.writeln('  final result = (instance as dynamic).${method.getName()}();');
          buffer.writeln('  if (result is Future) {');
          buffer.writeln('    return result;');
          buffer.writeln('  }');
          buffer.write('}');
          return buffer.toString();
        }
      }
    }
    return null;
  }

  /// Synthesizes a static disposal closure for methods annotated with `@PreDestroy`.
  String? _buildDestroyInvoker(
    ClassDeclaration component,
    String prefix,
    String className,
    Map<String, ClassDeclaration> classByName,
  ) {
    for (final method in component.getMethods()) {
      for (final annotation in method.getAnnotations()) {
        if (matchesOrExtendsAnnotation(annotation.getName(), _preDestroyNames, classByName)) {
          final buffer = StringBuffer('(instance) {\n');
          buffer.writeln('  final result = (instance as dynamic).${method.getName()}();');
          buffer.writeln('  if (result is Future) {');
          buffer.writeln('    return result;');
          buffer.writeln('  }');
          buffer.write('}');
          return buffer.toString();
        }
      }
    }
    return null;
  }
}