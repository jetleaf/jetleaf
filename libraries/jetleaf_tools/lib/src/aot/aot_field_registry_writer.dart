import 'dart:io';

import '../runtime/declaration/declaration.dart';
import '../utils/constant.dart';
import 'aot_sub_registrar_writer.dart';

/// {@template aot_field_registry_writer}
/// 🔍 **Ahead-Of-Time (AOT) Field Accessor Registry Code Generator**
///
/// Generates package-scoped `registry_fields.g.dart` sub-registry part files containing
/// statically compiled field getter and setter closures registered with `AotRuntimeExecutor.registerFieldGetter`
/// and `AotRuntimeExecutor.registerFieldSetter`.
///
/// In pure Dart AOT execution (no `dart:mirrors`), classes cannot have their fields read or
/// written dynamically. [AotFieldRegistryWriter] generates high-performance accessor closures that
/// safely cast the target instance to its concrete static type:
/// - Direct getters: `(inst) => (inst as p0.User).email`
/// - Direct mutable setters: `(inst, val) => (inst as p0.User).email = val as dynamic`
///
/// `final` and `const` fields omit setter registration, ensuring runtime immutability guarantees.
/// Private fields and universal root `Object` members are excluded.
///
/// ## 🎯 Sample Generated Output
///
/// ```dart
/// // Generated in lib/_jetleaf/my_app/registry_fields.g.dart
/// part of '../aot_registry.g.dart';
///
/// void _registerFields_my_app() {
///   // Mutable field: getter + setter
///   AotRuntimeExecutor.registerFieldGetter(
///     'Account.status',
///     (inst) => (inst as p0.Account).status,
///   );
///   AotRuntimeExecutor.registerFieldSetter(
///     'Account.status',
///     (inst, val) => (inst as p0.Account).status = val as dynamic,
///   );
///
///   // Read-only final field: getter only
///   AotRuntimeExecutor.registerFieldGetter(
///     'Account.id',
///     (inst) => (inst as p0.Account).id,
///   );
/// }
/// ```
/// {@endtemplate}
final class AotFieldRegistryWriter extends AotSubRegistrarWriter {
  /// {@macro aot_field_registry_writer}
  const AotFieldRegistryWriter();

  /// Writes `registry_fields.g.dart` for [packageName] into [packageDir] if any public fields exist.
  ///
  /// Iterates through [components], skipping private fields, static members, and root `Object` members.
  /// Registers getters for all fields and setters for non-final fields.
  ///
  /// Returns the generated top-level registration function name (e.g. `_registerFields_my_package`),
  /// or `null` if no fields were registered.
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

      for (final field in component.getFields()) {
        if (!field.getIsPublic() || field.getIsStatic()) continue;
        final fieldName = field.getName();
        
        if (!isValidDartIdentifier(fieldName) || AotSubRegistrarWriter.skippedMemberNames.contains(fieldName)) {
          continue;
        }

        final memberKey = '$cleanClassName.$fieldName';
        if (!registeredMembers.add('field:$memberKey')) continue;

        lines.add('''
  AotRuntimeExecutor.registerFieldGetter(
    '$memberKey',
    (inst) => (inst as $prefix$cleanClassName).$fieldName,
  );''');
        if (!field.getIsFinal() && !field.getIsConst()) {
          lines.add('''
  AotRuntimeExecutor.registerFieldSetter(
    '$memberKey',
    (inst, val) => (inst as $prefix$cleanClassName).$fieldName = val as dynamic,
  );''');
        }
      }
    }

    if (lines.isEmpty) return null;

    final fnName = '_registerFields_${sanitizePackageIdentifier(packageName)}';
    final buffer = StringBuffer();
    writeNestedPartHeader(buffer, 'AOT Fields Sub-Registry for [$packageName]');
    buffer.writeln('void $fnName() {');
    
    for (final line in lines) {
      buffer.writeln(line);
    }
    
    buffer.writeln('}');

    if (!packageDir.existsSync()) {
      packageDir.createSync(recursive: true);
    }
    
    final file = File('${packageDir.path}/${Constant.AOT_REGISTRY_FIELDS_FILE_NAME}');
    await file.writeAsString(buffer.toString());
    return fnName;
  }
}