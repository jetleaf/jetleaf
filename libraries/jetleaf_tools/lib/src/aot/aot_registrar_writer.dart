import 'dart:io';

import '../cache/jetleaf_paths.dart';
import '../runtime/declaration/declaration.dart';
import '../utils/constant.dart';
import 'aot_annotation_registry_writer.dart';
import 'aot_constructor_registry_writer.dart';
import 'aot_field_registry_writer.dart';
import 'aot_method_registry_writer.dart';
import 'aot_pod_registry_writer.dart';
import 'aot_sub_registrar_writer.dart';
import 'aot_type_registry_writer.dart';

/// {@template aot_registrar_writer}
/// 🏛️ **Master Ahead-Of-Time (AOT) Registry Code Generator**
///
/// Coordinates and orchestrates the generation of the complete modular Ahead-Of-Time (AOT)
/// reflection and pod registration infrastructure under `lib/_jetleaf/` (configured via
/// [Constant.GENERATED_DIR_NAME]).
///
/// In pure Dart AOT execution (such as compiled native executables produced by `dart compile exe`
/// or Flutter production releases), `dart:mirrors` is entirely unavailable. Jetleaf resolves
/// all reflection, dependency injection, lifecycle hooks, and member dispatching through
/// statically generated closures compiled ahead-of-time.
///
/// ## 📐 Modular File Hierarchy
///
/// Rather than generating a single monolithic file that degrades compiler performance and
/// triggers IDE lag, [AotRegistrarWriter] partitions generated code cleanly by package
/// and responsibility:
///
/// ```text
/// lib/_jetleaf/
/// ├── aot_registry.g.dart               <-- Master library file (orchestrator & SPI)
/// ├── registry_annotations.g.dart       <-- Annotation instance deserializer & factory
/// ├── <current_package>/
/// │   ├── registry_pods.g.dart          <-- Direct IoC pod definitions & suppliers
/// │   ├── registry_types.g.dart         <-- Class type tokens & qualified name mapping
/// │   ├── registry_constructors.g.dart  <-- Constructor closures (default, named, enums)
/// │   ├── registry_fields.g.dart        <-- Direct field getters and setters
/// │   └── registry_methods.g.dart       <-- Method invokers with dynamic argument unpacking
/// └── <external_package>/
///     └── ... (mirrored sub-registries for scanned dependencies)
/// ```
///
/// ## 🔄 Bootstrap Lifecycle Pipeline
///
/// When an application boots in AOT mode:
///
/// ```text
/// Application Bootstrap
///        │
///        ▼
/// [registerJetleafAot(factory)]
///        │
///        ├─────────────────────────────────────────────────┐
///        ▼                                                 ▼
/// [_initAotRuntime()]                             [Register Pods]
///        │                                                 │
///        ├─► Register Types (Tokens & Names)               ├─► Register Pod Definitions
///        ├─► Register Constructors (Tear-offs & Closures)  ├─► Bind Instance Suppliers
///        ├─► Register Field Getters/Setters                ├─► Wire Init Hooks (@PostConstruct)
///        ├─► Register Method Invokers                      └─► Wire Destroy Hooks (@PreDestroy)
///        └─► Register Annotation Factories
/// ```
///
/// ## 🎯 Usage Example
///
/// ```dart
/// final writer = AotRegistrarWriter(
///   projectRoot: Directory.current,
///   packageName: 'my_app',
/// );
///
/// final masterFile = await writer.writeAotRegistrar(
///   components: scannedClassDeclarations,
/// );
/// print('Generated master AOT registry: ${masterFile.path}');
/// ```
/// {@endtemplate}
final class AotRegistrarWriter extends AotSubRegistrarWriter {
  /// The root directory of the Dart project being compiled.
  final Directory projectRoot;

  /// The name of the root package being compiled (matches `pubspec.yaml`).
  final String packageName;

  /// Specialized sub-writer for generating IoC pod definitions.
  final AotPodRegistryWriter _podWriter;

  /// Specialized sub-writer for registering runtime class type tokens.
  final AotTypeRegistryWriter _typeWriter;

  /// Specialized sub-writer for registering constructor factories.
  final AotConstructorRegistryWriter _constructorWriter;

  /// Specialized sub-writer for registering field getter/setter accessors.
  final AotFieldRegistryWriter _fieldWriter;

  /// Specialized sub-writer for registering method invocation dispatchers.
  final AotMethodRegistryWriter _methodWriter;

  /// Specialized sub-writer for registering annotation instance deserializers.
  final AotAnnotationRegistryWriter _annotationWriter;

  /// {@macro aot_registrar_writer}
  const AotRegistrarWriter({
    required this.projectRoot,
    required this.packageName,
    AotPodRegistryWriter podWriter = const AotPodRegistryWriter(),
    AotTypeRegistryWriter typeWriter = const AotTypeRegistryWriter(),
    AotConstructorRegistryWriter constructorWriter = const AotConstructorRegistryWriter(),
    AotFieldRegistryWriter fieldWriter = const AotFieldRegistryWriter(),
    AotMethodRegistryWriter methodWriter = const AotMethodRegistryWriter(),
    AotAnnotationRegistryWriter annotationWriter = const AotAnnotationRegistryWriter(),
  })  : _podWriter = podWriter,
        _typeWriter = typeWriter,
        _constructorWriter = constructorWriter,
        _fieldWriter = fieldWriter,
        _methodWriter = methodWriter,
        _annotationWriter = annotationWriter;

  /// Generates the complete modular AOT registry files under `lib/_jetleaf/` from [components].
  ///
  /// ### Orchestration Workflow:
  /// 1. **Component Discovery & Aliasing**: Scans [components] to identify unique library URIs
  ///    and assigns deterministic prefixes (`p0`, `p1`, ...) to prevent naming collisions.
  /// 2. **External Import Extraction**: Scans existing user `lib/*.dart` files for package dependencies.
  /// 3. **Package Partitioning**: Segregates components by their originating package name.
  /// 4. **Sub-Registry Generation**: Invokes [_podWriter], [_typeWriter], [_constructorWriter],
  ///    [_fieldWriter], [_methodWriter], and [_annotationWriter] to output package-scoped `part` files.
  /// 5. **Master File Assembly**: Emits `lib/_jetleaf/aot_registry.g.dart` referencing all parts,
  ///    exposing [registerJetleafAot] and [GeneratedAotApplicationModule].
  /// 6. **Manifest Redirection**: Emits `.jetleaf/generated/jetleaf_aot.g.dart` re-exporting the master file.
  ///
  /// Returns the master registry [File].
  Future<File> writeAotRegistrar({
    required List<ClassDeclaration> components,
    bool forTests = false,
  }) async {
    final baseImports = <String>{
      "import 'package:jetleaf_core/pod.dart';",
      "import 'package:jetleaf_core/lang.dart';",
      "import 'package:jetleaf_core/core.dart';",
      "import 'package:jetleaf_core/context.dart';",
      "import 'package:jetleaf_core/annotation.dart';",
      "import 'package:jetleaf_tools/jetleaf_tools.dart';",
    };

    final libraryAliases = <String, String>{};
    final classToPrefix = <String, String>{};
    final componentsByPackage = <String, List<ClassDeclaration>>{};

    // 1. Discover all libraries, class mappings, and group components by package
    for (final component in components) {
      final rawName = component.getName();
      if (rawName.startsWith('_') || !component.getIsPublic()) continue;
      final libraryUri = component.getLibrary().getUri();
      if (libraryUri.isNotEmpty && !libraryUri.startsWith('dart:') && !libraryUri.startsWith('package:synthetic') && !libraryUri.endsWith('.g.dart') && !libraryUri.contains('/${Constant.JETLEAF_GENERATED_DIR_NAME}/')) {
        if (!libraryAliases.containsKey(libraryUri)) {
          libraryAliases[libraryUri] = 'p${libraryAliases.length}';
        }

        final prefix = '${libraryAliases[libraryUri]}.';
        final cleanName = rawName.split('<').first;
        if (!classToPrefix.containsKey(cleanName) || libraryUri.startsWith('package:$packageName/')) {
          classToPrefix[cleanName] = prefix;
        }

        classToPrefix[component.getQualifiedName()] = prefix;

        final pkg = _extractPackageName(libraryUri, packageName);
        componentsByPackage.putIfAbsent(pkg, () => <ClassDeclaration>[]).add(component);
      }
    }

    // 2. Discover any direct external package imports used in user lib/ files
    final libDir = Directory('${projectRoot.path}/lib');
    if (libDir.existsSync()) {
      try {
        final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart') && !f.path.contains('/${Constant.JETLEAF_GENERATED_DIR_NAME}/'));
        for (final file in dartFiles) {
          try {
            final content = file.readAsStringSync();
            final importMatches = RegExp(r"""^\s*import\s+['"](package:[^'"]+)['"]""", multiLine: true).allMatches(content);
            for (final m in importMatches) {
              final uri = m.group(1);
              if (uri != null && !uri.endsWith('.g.dart') && !uri.contains('/src/') && !uri.contains('/${Constant.JETLEAF_GENERATED_DIR_NAME}/') && !libraryAliases.containsKey(uri)) {
                libraryAliases[uri] = 'p${libraryAliases.length}';
              }
            }
          } catch (_) {}
        }
      } catch (_) {}
    }

    final generatedRootDir = Directory('${projectRoot.path}/${Constant.GENERATED_DIR_NAME}');
    if (generatedRootDir.existsSync()) {
      generatedRootDir.deleteSync(recursive: true);
    }
    generatedRootDir.createSync(recursive: true);

    final partPaths = <String>[];
    final podFns = <String>[];
    final typeFns = <String>[];
    final constructorFns = <String>[];
    final fieldFns = <String>[];
    final methodFns = <String>[];

    final usedPodNames = <String>{};
    final registeredTypes = <String>{};
    final registeredConstructors = <String>{};
    final registeredMembers = <String>{};

    final classByName = <String, ClassDeclaration>{};
    for (final component in components) {
      final name = component.getName();
      if (!classByName.containsKey(name) || component.getLibrary().getUri().startsWith('package:$packageName/')) {
        classByName[name] = component;
      }
    }

    final podMethodByReturnType = <String, String>{};
    for (final component in components) {
      for (final method in component.getMethods()) {
        final isPodMethod = method.getAnnotations().any(
          (a) => _podWriter.matchesOrExtendsAnnotation(a.getName(), const {'Pod'}, classByName),
        );

        if (!isPodMethod) continue;
        final returnTypeName = method.getReturnType().getName();
        
        if (returnTypeName.isEmpty || returnTypeName == 'void' || returnTypeName == 'dynamic') {
          continue;
        }
        var podMethodName = method.getName();
        for (final ann in method.getAnnotations()) {
          final values = ann.getUserProvidedValues();
          if (ann.getName() == 'Pod') {
            final v = values['value'];
            if (v is String && v.isNotEmpty) podMethodName = v;
          } else if (ann.getName() == 'Named') {
            final v = values['name'] ?? values['value'];
            if (v is String && v.isNotEmpty) podMethodName = v;
          }
        }
        podMethodByReturnType.putIfAbsent(returnTypeName, () => podMethodName);
      }
    }

    final sortedPackages = componentsByPackage.keys.toList()
      ..sort((a, b) {
        if (a == packageName && b != packageName) return 1;
        if (b == packageName && a != packageName) return -1;
        return a.compareTo(b);
      });

    for (final pkg in sortedPackages) {
      final pkgComponents = componentsByPackage[pkg]!;
      final pkgDir = Directory('${generatedRootDir.path}/$pkg');

      final podFn = await _podWriter.write(
        packageDir: pkgDir,
        packageName: pkg,
        components: pkgComponents,
        libraryAliases: libraryAliases,
        classToPrefix: classToPrefix,
        usedPodNames: usedPodNames,
        classByName: classByName,
        podMethodByReturnType: podMethodByReturnType,
      );
      if (podFn != null) {
        partPaths.add('$pkg/${Constant.AOT_REGISTRY_PODS_FILE_NAME}');
        podFns.add(podFn);
      }

      final typeFn = await _typeWriter.write(
        packageDir: pkgDir,
        packageName: pkg,
        components: pkgComponents,
        libraryAliases: libraryAliases,
        registeredTypes: registeredTypes,
      );
      if (typeFn != null) {
        partPaths.add('$pkg/${Constant.AOT_REGISTRY_TYPES_FILE_NAME}');
        typeFns.add(typeFn);
      }

      final ctorFn = await _constructorWriter.write(
        packageDir: pkgDir,
        packageName: pkg,
        components: pkgComponents,
        libraryAliases: libraryAliases,
        registeredConstructors: registeredConstructors,
      );
      if (ctorFn != null) {
        partPaths.add('$pkg/${Constant.AOT_REGISTRY_CONSTRUCTORS_FILE_NAME}');
        constructorFns.add(ctorFn);
      }

      final fieldFn = await _fieldWriter.write(
        packageDir: pkgDir,
        packageName: pkg,
        components: pkgComponents,
        libraryAliases: libraryAliases,
        registeredMembers: registeredMembers,
      );
      if (fieldFn != null) {
        partPaths.add('$pkg/${Constant.AOT_REGISTRY_FIELDS_FILE_NAME}');
        fieldFns.add(fieldFn);
      }

      final methodFn = await _methodWriter.write(
        packageDir: pkgDir,
        packageName: pkg,
        components: pkgComponents,
        libraryAliases: libraryAliases,
        registeredMembers: registeredMembers,
      );
      if (methodFn != null) {
        partPaths.add('$pkg/${Constant.AOT_REGISTRY_METHODS_FILE_NAME}');
        methodFns.add(methodFn);
      }
    }

    final annotationFn = await _annotationWriter.write(generatedRootDir: generatedRootDir);
    partPaths.add(Constant.AOT_REGISTRY_ANNOTATIONS_FILE_NAME);

    // 3. Write master library file `lib/_jetleaf/aot_registry.g.dart`
    final buffer = StringBuffer();
    writeGeneratedHeader(buffer, 'AOT Master Registry for [$packageName]');
    for (final imp in baseImports) {
      buffer.writeln(imp);
    }
    for (final entry in libraryAliases.entries) {
      buffer.writeln("import '${entry.key}' as ${entry.value};");
    }
    buffer.writeln();
    for (final partPath in partPaths) {
      buffer.writeln("part '$partPath';");
    }
    buffer.writeln();
    buffer.writeln('bool _aotRuntimeInitialized = false;');
    buffer.writeln();
    buffer.writeln('/// Registers all compile-time AOT declarations, members, and pods into [factory].');
    buffer.writeln('/// Pure Dart closures — zero reflection, 100% native AOT compatible.');
    buffer.writeln('Future<void> registerJetleafAot([DefaultListablePodFactory? factory]) async {');
    buffer.writeln('  _initAotRuntime();');
    buffer.writeln('  if (factory == null) return;');
    for (final fn in podFns) {
      buffer.writeln('  await $fn(factory);');
    }
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('/// Backwards compatibility alias for [registerJetleafAot].');
    buffer.writeln('const registerGeneratedAotPods = registerJetleafAot;');
    buffer.writeln();
    buffer.writeln('/// Registers runtime hints and constructors for AOT execution without mirrors.');
    buffer.writeln('void _initAotRuntime() {');
    buffer.writeln('  if (_aotRuntimeInitialized) return;');
    buffer.writeln('  _aotRuntimeInitialized = true;');
    for (final fn in typeFns) {
      buffer.writeln('  $fn();');
    }
    for (final fn in constructorFns) {
      buffer.writeln('  $fn();');
    }
    for (final fn in fieldFns) {
      buffer.writeln('  $fn();');
    }
    for (final fn in methodFns) {
      buffer.writeln('  $fn();');
    }
    buffer.writeln('  $annotationFn();');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('/// Auto-discovered [ApplicationModule] SPI that installs generated AOT pods.');
    buffer.writeln('final class GeneratedAotApplicationModule implements ApplicationModule {');
    buffer.writeln('  @override');
    buffer.writeln('  Future<void> configure(ApplicationContext context) async {');
    buffer.writeln('    final podFactory = context.getPodFactory();');
    buffer.writeln('    if (podFactory is DefaultListablePodFactory) {');
    buffer.writeln('      await registerJetleafAot(podFactory);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  List<Object?> equalizedProperties() => [];');
    buffer.writeln('}');

    final masterContent = buffer.toString();
    final masterFile = File('${generatedRootDir.path}/${Constant.AOT_REGISTRY_FILE_NAME}');
    await masterFile.writeAsString(masterContent);

    // Also write summary manifest in .jetleaf/generated
    final outDir = JetleafPaths.generatedDir(projectRoot);
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    final targetFile = File('${outDir.path}/jetleaf_aot.g.dart');
    await targetFile.writeAsString(
      "// Generated AOT Registry located at ${Constant.GENERATED_DIR_NAME}/${Constant.AOT_REGISTRY_FILE_NAME}\n"
      "export '../../${Constant.GENERATED_DIR_NAME}/${Constant.AOT_REGISTRY_FILE_NAME}';\n",
    );

    return masterFile;
  }

  /// Extracts the root package name segment from a `package:...` URI string.
  ///
  /// Examples:
  /// - `'package:jetleaf_core/core.dart'` -> `'jetleaf_core'`
  /// - `'file:///some/path/file.dart'` -> [fallbackPackageName]
  String _extractPackageName(String libraryUri, String fallbackPackageName) {
    if (libraryUri.startsWith('package:')) {
      final withoutScheme = libraryUri.substring('package:'.length);
      final slashIndex = withoutScheme.indexOf('/');
      if (slashIndex > 0) {
        return withoutScheme.substring(0, slashIndex);
      }
    }
    return fallbackPackageName;
  }
}
