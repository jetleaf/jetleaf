import 'dart:io';

import 'package:jetleaf_core/lang.dart';
import 'aot_sub_registrar_writer.dart';

/// {@template aot_annotation_registry_writer}
/// 🏷️ **Ahead-Of-Time (AOT) Annotation Factory Registry Code Generator**
///
/// Generates the global `registry_annotations.g.dart` sub-registry part file under `lib/_jetleaf/`
/// containing runtime annotation deserialization and instantiation logic.
///
/// In pure Dart AOT execution (no `dart:mirrors`), classes cannot reflectively reconstruct
/// live annotation instances from compile-time AST descriptors.
/// [AotAnnotationRegistryWriter] generates an automated deserialization engine that binds to
/// `Annotation.registerInstanceFactory`:
///
/// 1. **Argument Normalization**: Intercepts AST argument representations and normalizes:
///    - `ClassType<T>(...)` and `ClassType.qualified(...)` tokens into concrete [ClassType] instances
///    - `AnnotatedTypeFilter<T>()` and `TypeFilter` directives
///    - `EventType<T>(...)` definitions
///    - Static members and enum values (`LogLevel.info`)
///    - Nested constructor invocations (`@ComponentScan(excludeFilters: [TypeFilter(...)])`)
///    - Primitive literals (`int`, `double`, `bool`, `String`, `null`)
///    - Strongly-typed list and map collections
/// 2. **Instance Construction**: Dispatches the deserialized arguments to [AotRuntimeExecutor.constructByName],
///    instantiating the concrete annotation class dynamically.
///
/// ## 🎯 Sample Generated Output
///
/// ```dart
/// // Generated in lib/_jetleaf/registry_annotations.g.dart
/// part of 'aot_registry.g.dart';
///
/// void _registerAnnotations() {
///   Annotation.registerInstanceFactory((name, ann) {
///     final userValues = ann.getUserProvidedValues();
///     final namedValues = <String, dynamic>{};
///     final posArgs = <Object?>[];
///     for (final entry in userValues.entries) {
///       if (entry.key.startsWith(r'$')) {
///         posArgs.add(_normalizeAnnotationValue(entry.value));
///       } else {
///         namedValues[entry.key] = _normalizeAnnotationValue(entry.value);
///       }
///     }
///     final args = ExecutableArgument.unmodified(namedValues, posArgs);
///     return AotRuntimeExecutor.constructByName(name, args);
///   });
/// }
/// ```
/// {@endtemplate}
final class AotAnnotationRegistryWriter extends AotSubRegistrarWriter {
  /// {@macro aot_annotation_registry_writer}
  const AotAnnotationRegistryWriter();

  /// Writes `registry_annotations.g.dart` directly into [generatedRootDir].
  ///
  /// Emits argument parsing primitives (`_splitTopLevelArgs`, `_normalizeNestedRawArg`,
  /// `_normalizeAnnotationValue`) and registers the global annotation instance factory.
  ///
  /// Returns the generated top-level registration function name (`_registerAnnotations`).
  Future<String> write({required Directory generatedRootDir}) async {
    const fnName = '_registerAnnotations';
    final buffer = StringBuffer();
    writeRootPartHeader(buffer, 'AOT Annotations Sub-Registry');

    buffer.writeln(r"final _classTypePattern = RegExp(r'^ClassType<([^>]+)>\((.*)\)$');");
    buffer.writeln(r"""final _qualifiedClassTypePattern = RegExp(r'''^ClassType\.qualified\(\s*['"]([^'"]+)['"]\s*\)$''');""");
    buffer.writeln(r"final _annotatedTypeFilterPattern = RegExp(r'^AnnotatedTypeFilter<([^>]+)>\(\)$');");
    buffer.writeln(r"final _eventTypePattern = RegExp(r'^(?:const\s+)?EventType<([^>]+)>\((.*)\)$');");
    buffer.writeln(r"final _enumOrStaticPattern = RegExp(r'^([A-Z][A-Za-z0-9_]*)\.([A-Za-z0-9_]+)$');");
    buffer.writeln(r"final _ctorCallPattern = RegExp(r'^(?:const\s+)?([A-Z][A-Za-z0-9_]*)(?:<[^>]+>)?\((.*)\)$', dotAll: true);");
    buffer.writeln();
    buffer.writeln('List<String> _splitTopLevelArgs(String input) {');
    buffer.writeln('  final result = <String>[];');
    buffer.writeln('  var depth = 0;');
    buffer.writeln('  String? quote;');
    buffer.writeln('  var start = 0;');
    buffer.writeln('  for (var i = 0; i < input.length; i++) {');
    buffer.writeln('    final ch = input[i];');
    buffer.writeln('    if (quote != null) {');
    buffer.writeln(r"      if (ch == quote && (i == 0 || input[i - 1] != r'\')) {");
    buffer.writeln('        quote = null;');
    buffer.writeln('      }');
    buffer.writeln('      continue;');
    buffer.writeln('    }');
    buffer.writeln("""    if (ch == "'" || ch == '"') {""");
    buffer.writeln('      quote = ch;');
    buffer.writeln('    } else if (ch == "(" || ch == "[" || ch == "{" || ch == "<") {');
    buffer.writeln('      depth++;');
    buffer.writeln('    } else if (ch == ")" || ch == "]" || ch == "}" || ch == ">") {');
    buffer.writeln('      if (depth > 0) depth--;');
    buffer.writeln('    } else if (ch == "," && depth == 0) {');
    buffer.writeln('      final part = input.substring(start, i).trim();');
    buffer.writeln('      if (part.isNotEmpty) result.add(part);');
    buffer.writeln('      start = i + 1;');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('  final tail = input.substring(start).trim();');
    buffer.writeln('  if (tail.isNotEmpty) result.add(tail);');
    buffer.writeln('  return result;');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('dynamic _normalizeNestedRawArg(String raw) {');
    buffer.writeln('  final trimmed = raw.trim();');
    buffer.writeln("""  if ((trimmed.startsWith("'") && trimmed.endsWith("'")) || (trimmed.startsWith('"') && trimmed.endsWith('"'))) {""");
    buffer.writeln('    return trimmed.substring(1, trimmed.length - 1);');
    buffer.writeln('  }');
    buffer.writeln('  if (trimmed == "true") return true;');
    buffer.writeln('  if (trimmed == "false") return false;');
    buffer.writeln('  if (trimmed == "null") return null;');
    buffer.writeln('  final asInt = int.tryParse(trimmed);');
    buffer.writeln('  if (asInt != null) return asInt;');
    buffer.writeln('  final asDouble = double.tryParse(trimmed);');
    buffer.writeln('  if (asDouble != null) return asDouble;');
    buffer.writeln('  return _normalizeAnnotationValue(trimmed);');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('dynamic _normalizeAnnotationValue(dynamic val) {');
    buffer.writeln('  if (val is String) {');
    buffer.writeln('    final trimmed = val.trim();');
    buffer.writeln('    final match = _classTypePattern.firstMatch(trimmed);');
    buffer.writeln('    if (match != null) {');
    buffer.writeln('      return ClassType<Object>(null, match.group(1)!);');
    buffer.writeln('    }');
    buffer.writeln('    final qMatch = _qualifiedClassTypePattern.firstMatch(trimmed);');
    buffer.writeln('    if (qMatch != null) {');
    buffer.writeln('      return ClassType<Object>.qualified(qMatch.group(1)!);');
    buffer.writeln('    }');
    buffer.writeln('    final filterMatch = _annotatedTypeFilterPattern.firstMatch(trimmed);');
    buffer.writeln('    if (filterMatch != null) {');
    buffer.writeln('      return AnnotationTypeFilter(ClassType<Object>(null, filterMatch.group(1)!).toClass());');
    buffer.writeln('    }');
    buffer.writeln('    final eventMatch = _eventTypePattern.firstMatch(trimmed);');
    buffer.writeln('    if (eventMatch != null) {');
    buffer.writeln('      final typeName = eventMatch.group(1)!.trim();');
    buffer.writeln('      final pkgArg = eventMatch.group(2)!.trim();');
    buffer.writeln('      final pkg = pkgArg.isNotEmpty ? _normalizeNestedRawArg(pkgArg) as String? : null;');
    buffer.writeln('      return EventType<ApplicationEvent>(pkg, typeName);');
    buffer.writeln('    }');
    buffer.writeln('    final enumMatch = _enumOrStaticPattern.firstMatch(trimmed);');
    buffer.writeln('    if (enumMatch != null) {');
    buffer.writeln('      final resolved = AotRuntimeExecutor.constructByName(trimmed);');
    buffer.writeln('      if (resolved != null) return resolved;');
    buffer.writeln('    }');
    buffer.writeln('    final ctorMatch = _ctorCallPattern.firstMatch(trimmed);');
    buffer.writeln('    if (ctorMatch != null) {');
    buffer.writeln('      final className = ctorMatch.group(1)!;');
    buffer.writeln('      final rawArgs = ctorMatch.group(2)!.trim();');
    buffer.writeln('      if (rawArgs.isEmpty) {');
    buffer.writeln('        final constructed = AotRuntimeExecutor.constructByName(className);');
    buffer.writeln('        if (constructed != null) return constructed;');
    buffer.writeln('      } else {');
    buffer.writeln('        final parts = _splitTopLevelArgs(rawArgs);');
    buffer.writeln('        final posArgs = <Object?>[];');
    buffer.writeln('        final namedArgs = <String, dynamic>{};');
    buffer.writeln('        for (final part in parts) {');
    buffer.writeln('          var colonIdx = -1;');
    buffer.writeln('          var depth = 0;');
    buffer.writeln('          String? quote;');
    buffer.writeln('          for (var i = 0; i < part.length; i++) {');
    buffer.writeln('            final ch = part[i];');
    buffer.writeln('            if (quote != null) {');
    buffer.writeln(r"              if (ch == quote && (i == 0 || part[i - 1] != r'\')) quote = null;");
    buffer.writeln('              continue;');
    buffer.writeln('            }');
    buffer.writeln("""            if (ch == "'" || ch == '"') { quote = ch; }""");
    buffer.writeln('            else if (ch == "(" || ch == "[" || ch == "{" || ch == "<") { depth++; }');
    buffer.writeln('            else if (ch == ")" || ch == "]" || ch == "}" || ch == ">") { if (depth > 0) depth--; }');
    buffer.writeln('            else if (ch == ":" && depth == 0) { colonIdx = i; break; }');
    buffer.writeln('          }');
    buffer.writeln('          if (colonIdx > 0) {');
    buffer.writeln('            final key = part.substring(0, colonIdx).trim();');
    buffer.writeln('            final rawVal = part.substring(colonIdx + 1).trim();');
    buffer.writeln('            namedArgs[key] = _normalizeNestedRawArg(rawVal);');
    buffer.writeln('          } else {');
    buffer.writeln('            posArgs.add(_normalizeNestedRawArg(part));');
    buffer.writeln('          }');
    buffer.writeln('        }');
    buffer.writeln('        final constructed = AotRuntimeExecutor.constructByName(className, ExecutableArgument.unmodified(namedArgs, posArgs));');
    buffer.writeln('        if (constructed != null) return constructed;');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('    return val;');
    buffer.writeln('  }');
    buffer.writeln('  if (val is List) {');
    buffer.writeln('    if (val.isEmpty) return val;');
    buffer.writeln('    final mapped = val.map(_normalizeAnnotationValue).toList();');
    buffer.writeln('    if (mapped.every((e) => e is String)) return mapped.cast<String>().toList();');
    buffer.writeln('    if (mapped.every((e) => e is int)) return mapped.cast<int>().toList();');
    buffer.writeln('    if (mapped.every((e) => e is double)) return mapped.cast<double>().toList();');
    buffer.writeln('    if (mapped.every((e) => e is bool)) return mapped.cast<bool>().toList();');
    buffer.writeln('    if (mapped.every((e) => e is ClassType)) return mapped.map((e) => e is ClassType<Object> ? e : ClassType<Object>(e.package, e.name, e.pd, e.declaration, e.qualifiedName)).cast<ClassType<Object>>().toList();');
    buffer.writeln('    if (mapped.every((e) => e is Condition)) return mapped.cast<Condition>().toList();');
    buffer.writeln('    if (mapped.every((e) => e is ComponentScanFilter)) return mapped.cast<ComponentScanFilter>().toList();');
    buffer.writeln('    if (mapped.every((e) => e is TypeFilter)) return mapped.cast<TypeFilter>().toList();');
    buffer.writeln('    if (mapped.every((e) => e is Type)) return mapped.cast<Type>().toList();');
    buffer.writeln('    if (mapped.every((e) => e != null)) return mapped.cast<Object>().toList();');
    buffer.writeln('    return mapped;');
    buffer.writeln('  }');
    buffer.writeln('  return val;');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('void $fnName() {');
    buffer.writeln('  Annotation.registerInstanceFactory((name, ann) {');
    buffer.writeln('    final userValues = ann.getUserProvidedValues();');
    buffer.writeln('    final namedValues = <String, dynamic>{};');
    buffer.writeln('    final posArgs = <Object?>[];');
    buffer.writeln('    for (final entry in userValues.entries) {');
    buffer.writeln("      if (entry.key.startsWith(r'\$')) {");
    buffer.writeln('        posArgs.add(_normalizeAnnotationValue(entry.value));');
    buffer.writeln('      } else {');
    buffer.writeln('        namedValues[entry.key] = _normalizeAnnotationValue(entry.value);');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('    final args = ExecutableArgument.unmodified(namedValues, posArgs);');
    buffer.writeln('    return AotRuntimeExecutor.constructByName(name, args);');
    buffer.writeln('  });');
    buffer.writeln('}');

    if (!generatedRootDir.existsSync()) {
      generatedRootDir.createSync(recursive: true);
    }
    
    final file = File('${generatedRootDir.path}/${Constant.AOT_REGISTRY_ANNOTATIONS_FILE_NAME}');
    await file.writeAsString(buffer.toString());
    return fnName;
  }
}