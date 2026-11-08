import 'dart:io';

import '../runtime/declaration/declaration.dart';
import '../utils/constant.dart';
import 'aot_sub_registrar_writer.dart';

/// {@template aot_method_registry_writer}
/// ⚡ **Ahead-Of-Time (AOT) Method Registry Code Generator**
///
/// Generates package-scoped `registry_methods.g.dart` sub-registry part files containing
/// statically compiled method invocation closures registered with `AotRuntimeExecutor.registerMethod`.
///
/// In pure Dart AOT execution (no `dart:mirrors`), classes cannot have their methods dynamically
/// invoked by name. [AotMethodRegistryWriter] generates high-performance invocation closures that
/// safely cast the target instance to its concrete static type and dispatch to the method:
/// - Explicit getters (`(inst, _) => (inst as p0.MyClass).property`)
/// - Explicit setters (`(inst, args) => (inst as p0.MyClass).property = args.getPositionalArguments()[0]`)
/// - Zero-argument methods (`(inst, _) => (inst as p0.MyClass).calculate()`)
/// - Parameterized methods with automated argument unpacking and [Function.apply] invocation
///
/// ## 🎯 Sample Generated Output
///
/// ```dart
/// // Generated in lib/_jetleaf/my_app/registry_methods.g.dart
/// part of '../aot_registry.g.dart';
///
/// void _registerMethods_my_app() {
///   // Getter
///   AotRuntimeExecutor.registerMethod(
///     'Session.isActive',
///     (inst, _) => (inst as p0.Session).isActive,
///   );
///
///   // Setter
///   AotRuntimeExecutor.registerMethod(
///     'Session.isActive',
///     (inst, args) => (inst as p0.Session).isActive = args.getPositionalArguments()[0] as dynamic,
///   );
///
///   // Parameterless method
///   AotRuntimeExecutor.registerMethod(
///     'Session.refresh',
///     (inst, _) => (inst as p0.Session).refresh(),
///   );
///
///   // Multi-argument method with positional and named unpacking
///   AotRuntimeExecutor.registerMethod(
///     'UserService.findUsers',
///     (inst, args) {
///       final pos = args.getPositionalArguments();
///       final named = args.getNamedArguments();
///       final pArgs = <dynamic>[];
///       pArgs.add(pos.length > 0 ? pos[0] : named['role']);
///       final nArgs = <Symbol, dynamic>{};
///       if (named.containsKey('limit')) {
///         nArgs[#limit] = named['limit'];
///       }
///       return Function.apply((inst as p0.UserService).findUsers, pArgs, nArgs);
///     },
///   );
/// }
/// ```
/// {@endtemplate}
final class AotMethodRegistryWriter extends AotSubRegistrarWriter {
  /// {@macro aot_method_registry_writer}
  const AotMethodRegistryWriter();

  /// Writes `registry_methods.g.dart` for [packageName] into [packageDir] if any public methods exist.
  ///
  /// Filters out private methods, static methods, and universal root `Object` methods (like `toString`,
  /// `hashCode`, `noSuchMethod`).
  ///
  /// Returns the generated top-level registration function name (e.g. `_registerMethods_my_package`),
  /// or `null` if no methods were registered.
  Future<String?> write({
    required Directory packageDir,
    required String packageName,
    required List<ClassDeclaration> components,
    required Map<String, String> libraryAliases,
    required Set<String> registeredMembers,
  }) async {
    final lines = <String>[];

    for (final component in components) {
      final rawName = component.getName();
      if (rawName.startsWith('_') || rawName.contains(' ') || !component.getIsPublic() || component.getTypeArguments().isNotEmpty) {
        continue;
      }

      final cleanClassName = rawName.split('<').first;
      if (!isValidDartIdentifier(cleanClassName)) continue;

      final libraryUri = component.getLibrary().getUri();
      if (libraryUri.isEmpty || libraryUri.startsWith('dart:') || libraryUri.startsWith('package:synthetic') || libraryUri.endsWith('.g.dart')) {
        continue;
      }

      final prefix = '${libraryAliases[libraryUri] ?? ""}.';

      for (final method in component.getMethods()) {
        if (!method.getIsPublic() || method.getIsStatic()) continue;
        
        final methodName = method.getName();
        if (!isValidDartIdentifier(methodName) || AotSubRegistrarWriter.skippedMemberNames.contains(methodName)) {
          continue;
        }

        final memberKey = '$cleanClassName.$methodName';
        if (!registeredMembers.add('method:$memberKey')) continue;

        if (method.getIsGetter()) {
          lines.add('''
  AotRuntimeExecutor.registerMethod(
    '$memberKey',
    (inst, _) => (inst as $prefix$cleanClassName).$methodName,
  );''');
        } else if (method.getIsSetter()) {
          lines.add('''
  AotRuntimeExecutor.registerMethod(
    '$memberKey',
    (inst, args) => (inst as $prefix$cleanClassName).$methodName = args.getPositionalArguments()[0] as dynamic,
  );''');
        } else {
          final params = method.getParameters();
          if (params.isEmpty) {
            lines.add('''
  AotRuntimeExecutor.registerMethod(
    '$memberKey',
    (inst, _) => (inst as $prefix$cleanClassName).$methodName(),
  );''');
          } else {
            final posParams = params.where((p) => !p.getIsNamed()).toList();
            final namedParams = params.where((p) => p.getIsNamed()).toList();

            final body = StringBuffer();
            body.writeln("  AotRuntimeExecutor.registerMethod(");
            body.writeln("    '$memberKey',");
            body.writeln("    (inst, args) {");
            body.writeln("      final pos = args.getPositionalArguments();");
            body.writeln("      final named = args.getNamedArguments();");
            body.writeln("      final pArgs = <dynamic>[];");

            for (int i = 0; i < posParams.length; i++) {
              final p = posParams[i];
              final pName = p.getName();
              if (p.getIsRequired()) {
                body.writeln("      pArgs.add(pos.length > $i ? pos[$i] : named['$pName']);");
              } else {
                body.writeln("      if (pos.length > $i) {");
                body.writeln("        pArgs.add(pos[$i]);");
                body.writeln("      } else if (named.containsKey('$pName')) {");
                body.writeln("        pArgs.add(named['$pName']);");
                body.writeln("      }");
              }
            }

            if (namedParams.isNotEmpty) {
              body.writeln("      final nArgs = <Symbol, dynamic>{};");
              for (final p in namedParams) {
                final pName = p.getName();
                if (p.getIsRequired()) {
                  body.writeln("      nArgs[#$pName] = named['$pName'];");
                } else if (p.getIsNullable()) {
                  body.writeln("      if (named.containsKey('$pName')) {");
                  body.writeln("        nArgs[#$pName] = named['$pName'];");
                  body.writeln("      }");
                } else {
                  body.writeln("      if (named.containsKey('$pName') && named['$pName'] != null) {");
                  body.writeln("        nArgs[#$pName] = named['$pName'];");
                  body.writeln("      }");
                }
              }
              body.writeln("      return Function.apply((inst as $prefix$cleanClassName).$methodName, pArgs, nArgs);");
            } else {
              body.writeln("      return Function.apply((inst as $prefix$cleanClassName).$methodName, pArgs);");
            }

            body.writeln("    },");
            body.write("  );");
            lines.add(body.toString());
          }
        }
      }
    }

    if (lines.isEmpty) return null;

    final fnName = '_registerMethods_${sanitizePackageIdentifier(packageName)}';
    final buffer = StringBuffer();
    writeNestedPartHeader(buffer, 'AOT Methods Sub-Registry for [$packageName]');
    buffer.writeln('void $fnName() {');
    
    for (final line in lines) {
      buffer.writeln(line);
    }
    
    buffer.writeln('}');

    if (!packageDir.existsSync()) {
      packageDir.createSync(recursive: true);
    }
    final file = File('${packageDir.path}/${Constant.AOT_REGISTRY_METHODS_FILE_NAME}');
    await file.writeAsString(buffer.toString());
    return fnName;
  }
}
