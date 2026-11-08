import 'dart:io';

import '../runtime/declaration/declaration.dart';
import '../utils/constant.dart';
import 'aot_sub_registrar_writer.dart';

/// {@template aot_constructor_registry_writer}
/// 🔨 **Ahead-Of-Time (AOT) Constructor Registry Code Generator**
///
/// Generates package-scoped `registry_constructors.g.dart` sub-registry part files containing
/// statically compiled constructor factory closures registered with `AotRuntimeExecutor.registerNamedConstructor`.
///
/// In pure Dart AOT execution (no `dart:mirrors`), classes cannot be reflectively instantiated
/// by name or qualified token. [AotConstructorRegistryWriter] bridges this gap by generating
/// static closures for:
/// - Unnamed default constructors (`p0.MyClass.new`)
/// - Named constructors (`p0.MyClass.customNamed`)
/// - Parameterized constructors with intelligent argument mapping (supporting positional and named parameters)
/// - Enum constants (`p0.Environment.production`, etc.)
///
/// Both simple short names (`MyService`) and fully qualified URIs (`package:my_app/service.dart/MyService`)
/// are registered to enable exact and qualified resolution during runtime injection and annotation
/// deserialization.
///
/// ## 🎯 Sample Generated Output
///
/// ```dart
/// // Generated in lib/_jetleaf/my_app/registry_constructors.g.dart
/// part of '../aot_registry.g.dart';
///
/// void _registerConstructors_my_app() {
///   // Unnamed zero-argument constructor
///   AotRuntimeExecutor.registerNamedConstructor(
///     'DefaultConfig',
///     ([_]) => p0.DefaultConfig(),
///   );
///
///   // Parameterized constructor with argument unpacking
///   AotRuntimeExecutor.registerNamedConstructor(
///     'DatabaseConfig',
///     ([args]) {
///       final pos = args?.getPositionalArguments() ?? const [];
///       final named = args?.getNamedArguments() ?? const {};
///       final pArgs = <dynamic>[];
///       pArgs.add(pos.length > 0 ? pos[0] : (named['host'] ?? (named.containsKey('value') && 0 == 0 ? named['value'] : null)));
///       final nArgs = <Symbol, dynamic>{};
///       if (named.containsKey('port')) {
///         nArgs[#port] = named['port'];
///       }
///       return Function.apply(p0.DatabaseConfig.new, pArgs, nArgs);
///     },
///   );
///
///   // Enum values
///   for (final v in p0.LogLevel.values) {
///     AotRuntimeExecutor.registerNamedConstructor('LogLevel.${v.name}', ([_]) => v);
///   }
/// }
/// ```
/// {@endtemplate}
final class AotConstructorRegistryWriter extends AotSubRegistrarWriter {
  /// {@macro aot_constructor_registry_writer}
  const AotConstructorRegistryWriter();

  /// Writes `registry_constructors.g.dart` for [packageName] into [packageDir] if any instantiable constructors exist.
  ///
  /// Iterates through [components], filtering out abstract classes, mixins, sealed classes, and private types.
  /// Emits registration entries for both simple and qualified class keys.
  ///
  /// Returns the generated top-level registration function name (e.g. `_registerConstructors_my_package`),
  /// or `null` if no constructors were registered.
  Future<String?> write({
    required Directory packageDir,
    required String packageName,
    required List<ClassDeclaration> components,
    required Map<String, String> libraryAliases,
    required Set<String> registeredConstructors,
  }) async {
    final lines = <String>[];

    for (final component in components) {
      final rawName = component.getName();
      if (rawName.startsWith('_') || rawName.contains(' ') || !component.getIsPublic()) {
        continue;
      }

      final cleanClassName = rawName.split('<').first;
      if (!isValidDartIdentifier(cleanClassName)) continue;

      final libraryUri = component.getLibrary().getUri();
      if (libraryUri.isEmpty || libraryUri.startsWith('dart:') || libraryUri.startsWith('package:synthetic') || libraryUri.endsWith('.g.dart')) {
        continue;
      }

      if (component.getKind() == TypeKind.enumType) {
        final enumKey = component.getQualifiedName();
        if (registeredConstructors.add(enumKey)) {
          final prefix = libraryAliases[libraryUri] != null ? '${libraryAliases[libraryUri]}.' : '';
          lines.add(
            "  for (final v in $prefix$cleanClassName.values) { "
            "AotRuntimeExecutor.registerNamedConstructor('$cleanClassName.\${v.name}', ([_]) => v); "
            "}",
          );
        }
        continue;
      }

      if (component.getIsAbstract() || component.getIsSealed() || component.getIsMixin() || component.getKind() != TypeKind.classType) {
        continue;
      }

      final constructors = component.getConstructors();
      if (constructors.isEmpty) continue;

      final prefix = libraryAliases[libraryUri] != null ? '${libraryAliases[libraryUri]}.' : '';

      for (final ctor in constructors) {
        if (!ctor.getIsPublic()) continue;
        final ctorName = ctor.getName();
        final ctorKey = ctorName.isEmpty ? cleanClassName : '$cleanClassName.$ctorName';
        final qualifiedKey = ctorName.isEmpty ? component.getQualifiedName() : '${component.getQualifiedName()}.$ctorName';

        if (!registeredConstructors.add(qualifiedKey)) continue;

        final params = ctor.getParameters();
        if (params.isEmpty) {
          final invocation = ctorName.isEmpty ? '$prefix$cleanClassName()' : '$prefix$cleanClassName.$ctorName()';
          lines.add('''
  AotRuntimeExecutor.registerNamedConstructor(
    '$ctorKey',
    ([_]) => $invocation,
  );''');
          lines.add('''
  AotRuntimeExecutor.registerNamedConstructor(
    '$qualifiedKey',
    ([_]) => $invocation,
  );''');
        } else {
          final ctorTearOff = ctorName.isEmpty ? '$prefix$cleanClassName.new' : '$prefix$cleanClassName.$ctorName';
          final posParams = params.where((p) => !p.getIsNamed()).toList();
          final namedParams = params.where((p) => p.getIsNamed()).toList();

          final body = StringBuffer();
          body.writeln("      final pos = args?.getPositionalArguments() ?? const [];");
          body.writeln("      final named = args?.getNamedArguments() ?? const {};");
          body.writeln("      final pArgs = <dynamic>[];");

          for (int i = 0; i < posParams.length; i++) {
            final p = posParams[i];
            final pName = p.getName();
            if (p.getIsRequired()) {
              body.writeln("      pArgs.add(pos.length > $i ? pos[$i] : (named['$pName'] ?? (named.containsKey('value') && $i == 0 ? named['value'] : null)));");
            } else {
              body.writeln("      if (pos.length > $i) {");
              body.writeln("        pArgs.add(pos[$i]);");
              body.writeln("      } else if (named.containsKey('$pName')) {");
              body.writeln("        pArgs.add(named['$pName']);");
              body.writeln("      } else if (named.containsKey('value') && $i == 0) {");
              body.writeln("        pArgs.add(named['value']);");
              body.writeln("      }");
            }
          }

          if (namedParams.isNotEmpty) {
            body.writeln("      final nArgs = <Symbol, dynamic>{};");
            for (final p in namedParams) {
              final pName = p.getName();
              if (p.getIsRequired()) {
                body.writeln("      nArgs[#$pName] = named['$pName'] ?? (pos.isNotEmpty ? pos[0] : null);");
              } else if (p.getIsNullable()) {
                body.writeln("      if (named.containsKey('$pName')) {");
                body.writeln("        nArgs[#$pName] = named['$pName'];");
                body.writeln("      } else if (pos.isNotEmpty && '$pName' == 'value') {");
                body.writeln("        nArgs[#$pName] = pos[0];");
                body.writeln("      }");
              } else {
                body.writeln("      if (named.containsKey('$pName') && named['$pName'] != null) {");
                body.writeln("        nArgs[#$pName] = named['$pName'];");
                body.writeln("      } else if (pos.isNotEmpty && '$pName' == 'value' && pos[0] != null) {");
                body.writeln("        nArgs[#$pName] = pos[0];");
                body.writeln("      }");
              }
            }
            body.writeln("      return Function.apply($ctorTearOff, pArgs, nArgs);");
          } else {
            body.writeln("      return Function.apply($ctorTearOff, pArgs);");
          }

          lines.add('''
  AotRuntimeExecutor.registerNamedConstructor(
    '$ctorKey',
    ([args]) {
${body.toString().trimRight()}
    },
  );''');
          lines.add('''
  AotRuntimeExecutor.registerNamedConstructor(
    '$qualifiedKey',
    ([args]) {
${body.toString().trimRight()}
    },
  );''');
        }
      }
    }

    if (lines.isEmpty) return null;

    final fnName = '_registerConstructors_${sanitizePackageIdentifier(packageName)}';
    final buffer = StringBuffer();
    writeNestedPartHeader(buffer, 'AOT Constructors Sub-Registry for [$packageName]');
    buffer.writeln('void $fnName() {');
    
    for (final line in lines) {
      buffer.writeln(line);
    }

    buffer.writeln('}');

    if (!packageDir.existsSync()) {
      packageDir.createSync(recursive: true);
    }

    final file = File('${packageDir.path}/${Constant.AOT_REGISTRY_CONSTRUCTORS_FILE_NAME}');
    await file.writeAsString(buffer.toString());
    return fnName;
  }
}