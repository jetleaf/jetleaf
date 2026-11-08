import 'dart:io';

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
  /// Known stereotype annotation names that qualify a class as an IoC Pod.
  static const Set<String> podStereotypes = {
    'Component',
    'Service',
    'Repository',
    'Controller',
    'RestController',
    'Configuration',
    'AutoConfiguration',
    'Pod',
    'JetleafApplicationStarter',
    'ConfigurationProperty',
  };

  /// Configuration and conditional annotations evaluated dynamically by
  /// configuration class post-processors rather than registered as static AOT singletons.
  static const Set<String> configurationAndConditionalNames = {
    'Configuration',
    'AutoConfiguration',
    'JetleafApplicationStarter',
    'Conditional',
    'ConditionalOnProperty',
    'ConditionalOnClass',
    'ConditionalOnMissingClass',
    'ConditionalOnPod',
    'ConditionalOnMissingPod',
    'ConditionalOnWebApplication',
    'ConditionalOnNotWebApplication',
    'ConditionalOnExpression',
    'Profile',
  };

  /// Supported lifecycle initialization annotation identifiers.
  static const Set<String> postConstructNames = {'PostConstruct', 'OnApplicationReady'};

  /// Supported lifecycle destruction annotation identifiers.
  static const Set<String> preDestroyNames = {'PreDestroy'};

  /// {@macro aot_pod_registry_writer}
  const AotPodRegistryWriter();

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
    if (name == 'ReflectableAnnotation') return true;
    final v = visited ?? <String>{};
    if (!v.add(name)) return false;

    final superClass = component.getSuperClass();
    if (superClass != null) {
      final superName = superClass.getName();
      if (superName == 'ReflectableAnnotation') return true;
      final superDecl = classByName[superName];
      if (superDecl != null && isAnnotationClass(superDecl, classByName, v)) {
        return true;
      }
    }

    for (final iface in component.getInterfaces()) {
      final ifaceName = iface.getName();
      if (ifaceName == 'ReflectableAnnotation') return true;
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
  /// - The component is guarded by conditional or configuration annotations (evaluated at runtime)
  /// - The component lacks a recognized pod stereotype
  bool isPodComponent(ClassDeclaration component, [Map<String, ClassDeclaration> classByName = const {}]) {
    if (component.getIsAbstract()) return false;
    if (isAnnotationClass(component, classByName)) return false;
    if (_isConfigurationOrConditional(component, classByName)) return false;

    for (final annotation in component.getAnnotations()) {
      final name = annotation.getName();
      if (matchesOrExtendsAnnotation(name, podStereotypes, classByName)) {
        return true;
      }
    }
    return false;
  }

  /// Returns `true` if [component] carries `@Conditional` or dynamic configuration markers.
  bool _isConfigurationOrConditional(ClassDeclaration component, Map<String, ClassDeclaration> classByName) {
    for (final annotation in component.getAnnotations()) {
      final name = annotation.getName();
      if (name == 'ConfigurationProperty') {
        continue;
      }

      if (name.startsWith('Conditional') || matchesOrExtendsAnnotation(name, configurationAndConditionalNames, classByName)) {
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

      final isLazy = _hasAnnotation(component, const {'Lazy'}, classByName);
      final isPrimary = _hasAnnotation(component, const {'Primary'}, classByName);

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

    buffer.writeln('}');

    if (!packageDir.existsSync()) {
      packageDir.createSync(recursive: true);
    }
    final file = File('${packageDir.path}/${Constant.AOT_REGISTRY_PODS_FILE_NAME}');
    await file.writeAsString(buffer.toString());
    return fnName;
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
      if (annName == 'Named' || matchesOrExtendsAnnotation(annName, const {'Named'}, classByName)) {
        final v = values['name'] ?? values['value'] ?? values[r'$0'];
        if (v is String && v.isNotEmpty) {
          name = v;
        }
      } else if (matchesOrExtendsAnnotation(annName, const {'Component', 'Service', 'Repository', 'Controller', 'RestController', 'Configuration', 'Pod'}, classByName)) {
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
        if (matchesOrExtendsAnnotation(annotation.getName(), postConstructNames, classByName)) {
          return '(instance) { final res = (instance as dynamic).${method.getName()}(); if (res is Future) return res; }';
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
        if (matchesOrExtendsAnnotation(annotation.getName(), preDestroyNames, classByName)) {
          return '(instance) { final res = (instance as dynamic).${method.getName()}(); if (res is Future) return res; }';
        }
      }
    }
    return null;
  }
}