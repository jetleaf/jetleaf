import 'dart:io';

import 'package:jetleaf_core/lang.dart';
import 'aot_sub_registrar_writer.dart';

/// {@template aot_type_registry_writer}
/// 🏷️ **Ahead-Of-Time (AOT) Type Token Registry Code Generator**
///
/// Generates package-scoped `registry_types.g.dart` sub-registry part files containing
/// statically registered [Type] tokens registered via `MaterializedLibrary.registerType`.
///
/// When running compiled, resolving a [Type] token from a runtime
/// string identifier (e.g. `'UserService'`) or fully qualified URI is impossible because
/// Dart tree-shakers strip runtime symbol metadata.
///
/// [AotTypeRegistryWriter] establishes bidirectional type mappings ahead-of-time:
/// - Maps the simple class name (e.g. `'UserService'`) to `p0.UserService`
/// - Maps the qualified class URI (e.g. `'package:my_app/user.dart/UserService'`) to `p0.UserService`
///
/// These registrations allow the IoC container and conversion subsystems to lookup concrete
/// types using [Class.forName] or [ClassType.toClass] even in native binary builds.
///
/// ## 🎯 Sample Generated Output
///
/// ```dart
/// // Generated in lib/_jetleaf/my_app/registry_types.g.dart
/// part of '../registry.g.dart';
///
/// void _registerTypes_my_app() {
///   MaterializedLibrary.registerType(
///     'UserService',
///     p0.UserService,
///     'package:my_app/user_service.dart/UserService',
///   );
///   MaterializedLibrary.registerType(
///     'DatabaseConfig',
///     p0.DatabaseConfig,
///     'package:my_app/config.dart/DatabaseConfig',
///   );
/// }
/// ```
/// {@endtemplate}
final class AotTypeRegistryWriter extends AotSubRegistrarWriter {
  /// {@macro aot_type_registry_writer}
  const AotTypeRegistryWriter();

  /// Writes `registry_types.g.dart` for [packageName] into [packageDir] if any non-generic types exist.
  ///
  /// Iterates through [components], skipping private types and types with unresolved generic arguments.
  /// Registers both the simple name and qualified URI with `AotRuntimeExecutor`.
  ///
  /// Returns the generated top-level registration function name (e.g. `_registerTypes_my_package`),
  /// or `null` if no types were registered.
  Future<String?> write({
    required Directory packageDir,
    required String packageName,
    required List<ClassDeclaration> components,
    required Map<String, String> libraryAliases,
    required Set<String> registeredTypes,
  }) async {
    final lines = <String>[];
    final scanRoots = resolveComponentScanRoots(components);

    for (final component in components) {
      if (scanRoots != null && !isComponentScanned(component, scanRoots)) continue;
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

      final prefix = libraryAliases[libraryUri] != null ? '${libraryAliases[libraryUri]}.' : '';
      final qName = component.getQualifiedName();

      // Emit the raw class Type for every public, non-synthetic class —
      // generic classes included. The raw class literal (e.g. `p0.HashMap`)
      // is a valid Type expression and the runtime needs those tokens for
      // converter pair matching and declaration lookup. For non-generic types,
      // also pass `<$prefix$cleanClassName>` so `MaterializedLibrary` captures
      // a `StandardTypeReifier<T>` for reified List<T>, Set<T>, and Map<K, T>.
      if (component.getIsPublic() && isValidDartIdentifier(cleanClassName) && registeredTypes.add(qName)) {
        final hasTypeParams = component.getTypeArguments().isNotEmpty;
        final typeArgClause = hasTypeParams ? '' : '<$prefix$cleanClassName>';
        lines.add('''
  MaterializedLibrary.registerType$typeArgClause(
    '${escapeDartStringLiteral(cleanClassName)}',
    $prefix$cleanClassName,
    '${escapeDartStringLiteral(qName)}',
  );''');
      }
    }

    if (lines.isEmpty) return null;

    final fnName = '_registerTypes_${sanitizePackageIdentifier(packageName)}';
    final buffer = StringBuffer();
    writeNestedPartHeader(buffer, 'AOT Types Sub-Registry for [$packageName]');
    buffer.writeln('void $fnName() {');
    for (final line in lines) {
      buffer.writeln(line);
    }
    buffer.writeln('}');

    if (!packageDir.existsSync()) {
      packageDir.createSync(recursive: true);
    }
    final file = File('${packageDir.path}/${Constant.REGISTRY_TYPES_FILE_NAME}');
    await file.writeAsString(buffer.toString());
    return fnName;
  }
}