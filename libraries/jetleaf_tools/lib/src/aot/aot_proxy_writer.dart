// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
//
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart' show parseString;
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:path/path.dart' as p;

import 'package:jetleaf_core/lang.dart';

import 'aot_sub_registrar_writer.dart';

/// Stereotype annotation names (simple identifiers) that qualify a class for
/// proxy generation. Matching is by the simple identifier of the annotation —
/// class-level Jetleaf stereotypes and common alternatives.
const Set<String> proxyStereotypeNames = {
  'Service',
  'Repository',
  'Component',
  'Configuration',
  'AutoConfiguration',
  'Controller',
  'RestController',
  'Pod',
  'Workflow',
  'Middleware',
  'CommunityModerator',
};

/// Names of members that never block proxy emission even when inherited from
/// external supertypes — they come for free on every Dart object.
const Set<String> _boringMembers = {
  'noSuchMethod',
  'toString',
  'hashCode',
  'runtimeType',
  '==',
};

/// Emits `$$JLInterfaced$$…` proxies for stereotype-annotated component
/// classes in the **root package** of the project.
///
/// The emitted files land in `<projectRoot>/lib/_jetleaf/proxies/` matching
/// the lib-relative layout of their origin (e.g. `lib/service/user_service.dart`
/// → `lib/_jetleaf/proxies/service/user_service.proxy.dart`). Every call starts by
/// purging the proxy directory, so generated proxies always reflect the
/// current sources exactly.
///
/// ## Correctness rules
///
/// * Proxies must implement every instance member they publicly inherit —
///   any class whose supertype declares public members the class does not
///   re-declare is skipped with a warning, because the generated proxy cannot
///   re-implement those members safely (their signatures may live outside
///   the scanned sources).
/// * Final/sealed/mixin classes cannot be implemented outside their library,
///   so they are skipped.
/// * Supertypes that cannot be resolved from the scanned sources (e.g. from
///   an unscanned dependency) are skipped with a warning — never emitted as a
///   broken class.
///
/// The generated classes follow the same shape as the interceptor proxies: a delegate
/// wrapped in an [Interceptable], forwarding everything straight through.
final class AotProxyWriter extends AotSubRegistrarWriter {
  const AotProxyWriter();

  /// Generates proxy sources. Returns the count of proxies written.
  Future<int> emitProjectProxies({
    required Directory projectRoot,
    required String packageName,
    required void Function(String) log,
    required List<ClassDeclaration> components,
  }) async {
    final proxyDir = Directory(p.join(projectRoot.path, Constant.PROXIES_GENERATED_DIR_NAME));

    // Purge stale proxies — regenerate deterministically from sources.
    if (await proxyDir.exists()) {
      await proxyDir.delete(recursive: true);
    }
    await proxyDir.create(recursive: true);

    final libDir = Directory(p.join(projectRoot.path, 'lib'));
    if (!await libDir.exists()) {
      return 0;
    }

    final byQn = <String, ClassDeclaration>{};
    final byName = <String, ClassDeclaration>{};
    for (final component in components) {
      final qn = component.getQualifiedName();
      if (qn.isNotEmpty) byQn[qn] = component;
      byName[component.getName()] = component;
    }

    var written = 0;
    final scanRoots = resolveComponentScanRoots(components);
    await for (final entity in libDir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      final relPath = p.relative(entity.path, from: libDir.path);
      if (relPath.startsWith('_jetleaf${p.separator}proxies${p.separator}') ||
          relPath.startsWith('_jetleaf${p.separator}main${p.separator}') ||
          relPath.startsWith('_jetleaf${p.separator}test${p.separator}')) {
        continue;
      }
      if (relPath.endsWith('.g.dart') || relPath.endsWith('.freezed.dart')) {
        continue;
      }

      final source = await entity.readAsString();
      final unit = _tryParse(entity.path, source);
      if (unit == null) {
        log('  proxy-gen: skipped unparsable file $relPath');
        continue;
      }

      for (final decl in unit.declarations) {
        if (decl is! ast.ClassDeclaration) continue;

        if (!_hasProxyStereotype(decl)) continue;

        // Component scan roots: only proxy classes in the declared packages.
        if (scanRoots != null) {
          final qualifiedName = 'package:$packageName/$relPath.${decl.namePart.typeName.lexeme}';
          final component = byQn[qualifiedName];
          if (component != null && !isComponentScanned(component, scanRoots)) continue;
        }

        final skip = _proxyDecision(
          decl: decl,
          byQn: byQn,
          byName: byName,
        );
        if (skip != null) {
          log('  proxy-gen: skipped ${decl.namePart.typeName.lexeme} — $skip');
          continue;
        }

        // A single file may declare several stereotype classes — suffix the
        // proxy with the class name or they clobber each other silently.
        final className = decl.namePart.typeName.lexeme;
        final classSnake = _toSnakeCase(className);
        final base = relPath.replaceAll('.dart', '');
        final proxyPath = p.join(proxyDir.path, '${base}_$classSnake.proxy.dart');
        final proxySource = _buildProxySource(
          className: decl.namePart.typeName.lexeme,
          packageName: packageName,
          libRelativePath: relPath,
          declaration: decl,
        );
        if (proxySource == null) {
          log('  proxy-gen: could not generate proxy for ${decl.namePart.typeName.lexeme}');
          continue;
        }
        final validationErrors = _tryParseErrors(proxyPath, proxySource);
        if (validationErrors.isNotEmpty) {
          try {
            await File('/tmp/proxy_debug_${decl.namePart.typeName.lexeme}.dart').writeAsString(proxySource);
          } catch (_) {}
          log('  proxy-gen: generated proxy for ${decl.namePart.typeName.lexeme} failed validation: ${validationErrors.take(3).join(" | ")} (dumped /tmp/proxy_debug_${decl.namePart.typeName.lexeme}.dart)');
          continue;
        }

        await Directory(p.dirname(proxyPath)).create(recursive: true);
        await File(proxyPath).writeAsString(proxySource);
        written++;
      }
    }

    return written;
  }

  /// `InMemoryUserRepository` → `in_memory_user_repository`
  String _toSnakeCase(String input) {
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch.toUpperCase() == ch && ch.toLowerCase() != ch) {
        if (i > 0) buffer.write('_');
        buffer.write(ch.toLowerCase());
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  ast.CompilationUnit? _tryParse(String path, String source) {
    try {
      final result = parseString(
        content: source,
        path: path,
      );
      return result.unit;
    } catch (_) {
      return null;
    }
  }

  List<String> _tryParseErrors(String path, String source) {
    try {
      final result = parseString(content: source, path: path, throwIfDiagnostics: false);
      return [for (final e in result.errors.take(5)) e.message];
    } catch (e) {
      return [e.toString()];
    }
  }

  bool _hasProxyStereotype(ast.ClassDeclaration declaration) {
    for (final annotation in declaration.metadata) {
      final name = annotation.name;
      final simple = name is ast.PrefixedIdentifier ? name.identifier.name : name.toSource();
      if (proxyStereotypeNames.contains(simple)) {
        return true;
      }
    }
    return false;
  }

  /// Returns a skip-reason when [declaration] cannot be proxied, or `null`
  /// when it is safe to generate a proxy for it.
  String? _proxyDecision({
    required ast.ClassDeclaration decl,
    required Map<String, ClassDeclaration> byQn,
    required Map<String, ClassDeclaration> byName,
  }) {
    final name = decl.namePart.typeName.lexeme;
    if (name.startsWith('_')) return 'private class';
    if (decl.finalKeyword?.lexeme != null) return 'final class cannot be implemented';
    if (decl.sealedKeyword?.lexeme != null) return 'sealed class cannot be implemented';
    if (decl.mixinKeyword?.lexeme != null) return 'mixin class — proxies target concrete classes';
    if (_alreadyInterceptable(decl)) return 'already Interceptable — proxy would be a no-op wrapper';

    final body = decl.body;
    if (body.members.isEmpty) return 'no members';

    final ownNames = <String>{};
    var instanceMemberCount = 0;
    for (final member in body.members) {
      if (member is ast.MethodDeclaration) {
        if (member.isStatic) continue;
        instanceMemberCount++;
        if (member.isOperator && member.name.lexeme == '==') {
          ownNames.add('==');
          continue;
        }
        ownNames.add(member.name.lexeme);
      } else if (member is ast.FieldDeclaration) {
        if (member.isStatic) continue;
        instanceMemberCount++;
        for (final variable in member.fields.variables) {
          ownNames.add(variable.name.lexeme);
        }
      }
    }
    if (instanceMemberCount == 0) return 'no instance members';

    // Gather instance members provided by supertypes — the proxy must re-
    // implement every one of them, and anything it cannot see is a hard fail.
    final inherited = <String>{};
    final unknownSupertypes = <String>{};
    final visited = <String>{};

    void collectFrom(String hint, String? qn) {
      final key = (qn != null && qn.isNotEmpty) ? qn : hint;
      if (!visited.add(key)) return;
      final decl2 = (qn != null && qn.isNotEmpty ? byQn[qn] : null) ?? byName[hint];
      if (decl2 == null) {
        unknownSupertypes.add(hint);
        return;
      }
      for (final m in decl2.getMethods()) {
        if (m.getIsStatic()) continue;
        final name = m.getName();
        if (_boringMembers.contains(name)) continue;
        if (ownNames.contains(name)) continue;
        inherited.add(name);
      }
      final parent = decl2.getSuperClass();
      if (parent != null) collectFrom(parent.getName(), parent.getPointerQualifiedName());
      for (final iface in decl2.getInterfaces()) {
        collectFrom(iface.getName(), iface.getPointerQualifiedName());
      }
      for (final mixin in decl2.getMixins()) {
        collectFrom(mixin.getName(), mixin.getPointerQualifiedName());
      }
    }

    void collectFromTypeExpression(ast.TypeAnnotation type) {
      final name = type.toSource().split('<').first.trim();
      collectFrom(name, null);
    }

    if (decl.extendsClause != null) {
      collectFromTypeExpression(decl.extendsClause!.superclass);
    }
    final implementsClause = decl.implementsClause;
    if (implementsClause != null) {
      for (final iface in implementsClause.interfaces) {
        collectFromTypeExpression(iface);
      }
    }
    final withClause = decl.withClause;
    if (withClause != null) {
      for (final mixin in withClause.mixinTypes) {
        collectFromTypeExpression(mixin);
      }
    }

    if (unknownSupertypes.isNotEmpty) {
      return 'unresolvable supertype(s): ${unknownSupertypes.join(', ')}';
    }
    if (inherited.isNotEmpty) {
      return 'inherited members (unimplemented): ${inherited.join(', ')}';
    }
    return null;
  }

  /// Equivalent of the legacy generator's `_hasInterceptableMixinOrSuper` —
  /// classes that already mix in or implement [Interceptable] do not need a
  /// `$$JLInterfaced$$` wrapper. Checked on the raw clause sources, so it
  /// works even when the mixin lives in an external package.
  bool _alreadyInterceptable(ast.ClassDeclaration decl) {
    final sources = <String>[];
    if (decl.extendsClause != null) sources.add(decl.extendsClause!.superclass.toSource());
    if (decl.withClause != null) sources.addAll(decl.withClause!.mixinTypes.map((t) => t.toSource()));
    if (decl.implementsClause != null) sources.addAll(decl.implementsClause!.interfaces.map((t) => t.toSource()));
    for (final source in sources) {
      if (RegExp(r'\bInterceptable\b').hasMatch(source)) return true;
    }
    return false;
  }

  /// Rewrites a single import directive's URI, re-anchoring lib-relative
  /// references against the origin file's lib-relative directory so the copied
  /// import resolves from lib/_jetleaf/proxies/....
  String _rebuildImport(ast.ImportDirective directive, String packageName, String originDir) {
    final source = directive.toSource();
    final uriString = directive.uri;
    final value = uriString.stringValue ?? '';
    if (value.startsWith('package:') || value.startsWith('dart:')) {
      return source;
    }
    final relative = p.posix.normalize(p.join(originDir, value));
    return source.replaceFirst("'$value'", "'package:$packageName/$relative'");
  }

  String? _buildProxySource({
    required String className,
    required String packageName,
    required String libRelativePath,
    required ast.ClassDeclaration declaration,
  }) {
    final classUri = 'package:$packageName/$libRelativePath';
    final proxyName = '${Constant.PROXY_IDENTIFIER}$className';

    final tpDecl = declaration.namePart.typeParameters?.toSource() ?? '';
    final tpUse = declaration.namePart.typeParameters?.typeParameters.map((p) => p.name.lexeme).join(', ') ?? '';
    final aliasedClass = tpUse.isEmpty ? className : '$className<$tpUse>';

    // Copy the imports of the origin file so raw type text round-trips perfectly.
    // Lib-relative .dart imports are re-anchored to package:<packageName>/... URIs
    // so they resolve from the proxy file's actual location.
    final originalImports = <String>[];
    final compilationUnit = declaration.parent as ast.CompilationUnit;
    final originDir = p.dirname(libRelativePath);
    for (final directive in compilationUnit.directives) {
      if (directive is ast.ImportDirective) {
        final src = _rebuildImport(directive, packageName, originDir);
        if (!originalImports.contains(src)) {
          originalImports.add(src);
        }
      }
    }

    final buffer = StringBuffer();
    writeGeneratedHeader(buffer, 'Interceptor Proxy for [$className]');
    buffer
      ..writeln('/// {@template ${proxyName.toLowerCase()}}')
      ..writeln('/// Interceptor proxy for [$classUri.$className].')
      ..writeln('///')
      ..writeln('/// This class is automatically generated by the Jetleaf proxy generator.')
      ..writeln('/// It wraps an instance of `$className` (the `delegate`) and routes')
      ..writeln('/// interceptable invocations (those returning a `Future` or `void`)')
      ..writeln('/// through Jetleaf’s `Interceptable.when` mechanism, enabling')
      ..writeln('/// runtime interceptors such as:')
      ..writeln('///')
      ..writeln('/// - `@Retryable` — transient-failure recovery with backoff')
      ..writeln('/// - `@Cacheable` — method-level result caching')
      ..writeln('/// - `@RateLimit` — sliding-window request throttling')
      ..writeln('/// - Custom `MethodInterceptor` beans discovered from the context\n')
      ..writeln('/// Member accesses that are not interceptable are forwarded directly')
      ..writeln('/// to the delegate. Final fields are read-only through the proxy.')
      ..writeln('///')
      ..writeln('/// ## See also')
      ..writeln('/// - [Interceptable] — the mixin providing `Interceptable.when`')
      ..writeln('/// - [ClassGettable] — Jetleaf runtime type-metadata access')
      ..writeln('/// - Constant.PROXY_IDENTIFIER — the declaration tag the AOT runtime matches')
      ..writeln('///')
      ..writeln('/// {@endtemplate}')
      ..writeln()
      ..writeln('import \'dart:async\';')
      ..writeln()
      ..writeln('import \'package:jetleaf_core/intercept.dart\';')
      ..writeln('import \'package:jetleaf_core/lang.dart\';')
      ..writeln();
    for (final import in originalImports) {
      buffer.writeln(import);
    }
    buffer.writeln('import \'$classUri\';');
    buffer.writeln();
    buffer.writeln('/// {@template ${proxyName.toLowerCase()}_delegate}');
    buffer.writeln('/// Underlying instance of the original class being proxied.');
    buffer.writeln('///');
    buffer.writeln('/// All property and method invocations are forwarded to this delegate,');
    buffer.writeln('/// which is the actual [`$className`] registered as a pod. The delegate');
    buffer.writeln('/// remains the single source of truth for all state and logic, so the');
    buffer.writeln('/// proxy layer adds interception and lifecycle hooks without changing');
    buffer.writeln('/// the original class\'s behaviour.');
    buffer.writeln('/// {@endtemplate}');
    buffer.writeln('final class $proxyName$tpDecl with Interceptable implements $aliasedClass, ClassGettable<$aliasedClass> {');
    buffer.writeln('  /// {@macro ${proxyName.toLowerCase()}_delegate}');
    buffer.writeln('  final $aliasedClass delegate;');
    buffer.writeln();
    buffer.writeln('  /// Runtime [Class] handle for the proxied type.');
    buffer.writeln('  ///');
    buffer.writeln('  /// Stored eagerly because [toClass] and [getRealClass] are both');
    buffer.writeln('  /// expected to be called by the interception pipeline at dispatch time.');
    buffer.writeln('  late final Class<$aliasedClass> _class = Class.fromQualifiedName(\'$classUri.$className\');');
    buffer.writeln();
    buffer.writeln('  /// Creates a new proxy wrapping the provided [delegate].');
    buffer.writeln('  $proxyName(this.delegate);');
    buffer.writeln();
    buffer.writeln('  /// Returns the Jetleaf runtime [Class] for the underlying type.');
    buffer.writeln('  ///');
    buffer.writeln('  /// Useful for diagnostics and for frameworks that inspect the proxied');
    buffer.writeln('  /// bean, e.g. to print the fully-qualified type in error messages.');
    buffer.writeln('  static Class<$aliasedClass> ${CONST_GetRealClass()}() => Class.fromQualifiedName(\'$classUri.$className\');');
    buffer.writeln();

    final body = declaration.body;
    for (final member in body.members) {
      _emitMember(buffer, member, proxyName, tpUse, aliasedClass, tpDecl, classUri, className);
    }

    buffer.writeln('  @override');
    buffer.writeln('  Class<$aliasedClass> toClass() => _class;');
    buffer.writeln('}');
    return buffer.toString();
  }

  /// Name of the static accessor the legacy generator emits for the proxied type.
  /// Matches `Constant.STATIC_REAL_CLASS_METHOD_NAME == 'getRealClass'` without
  /// forcing a dependency on the constant's compilation semantics in this file.
  String CONST_GetRealClass() => 'getRealClass';

  void _emitMember(
    StringBuffer buffer,
    ast.ClassMember member,
    String className,
    String typeParametersUse,
    String aliasedClass,
    String tpDecl,
    String classUri,
    String originalClassName,
  ) {
    if (member is ast.FieldDeclaration) {
      if (member.isStatic) return;
      for (final variable in member.fields.variables) {
        final name = variable.name.lexeme;
        if (name.startsWith('_')) continue;
        final type = member.fields.type?.toSource() ?? 'dynamic';
        final isFinal = member.fields.isFinal;
        buffer.writeln('  /// {@macro ${className.toLowerCase()}_$name}');
        buffer.writeln('  @override');
        buffer.writeln('  $type get $name => delegate.$name;');
        if (!isFinal) {
          buffer.writeln();
          buffer.writeln('  /// {@macro ${className.toLowerCase()}_$name}');
          buffer.writeln('  @override');
          buffer.writeln('  set $name($type value) => delegate.$name = value;');
        }
        buffer.writeln();
      }
      return;
    }

    if (member is! ast.MethodDeclaration) return;
    if (member.isStatic) return;

    final name = member.name.lexeme;
    final returnType = member.returnType?.toSource() ?? 'void';
    // Build the parameter signature deliberately — `parameters.toSource()` would
    // copy annotations (unresolvable in the proxy library) and any private
    // identifiers referenced by them.
    final typeParamsDecl = _methodTypeParametersDecl(member);
    final typeParamsUse = _methodTypeParametersUse(member);
    final paramsSigClean = _buildParameterSignature(member);

    if (name == '==') {
      buffer.writeln('  /// {@macro ${className.toLowerCase()}_equals}');
      buffer.writeln('  @override');
      buffer.writeln('  bool operator ==(Object other) {');
      buffer.writeln('    if (identical(other, this)) return true;');
      buffer.writeln('    return delegate == other;');
      buffer.writeln('  }');
      buffer.writeln();
      return;
    }
    if (name == 'hashCode') {
      buffer.writeln('  /// {@macro ${className.toLowerCase()}_hashCode}');
      buffer.writeln('  @override');
      buffer.writeln('  int get hashCode => delegate.hashCode;');
      buffer.writeln();
      return;
    }
    if (name == 'toString') {
      buffer.writeln('  /// {@macro ${className.toLowerCase()}_toString}');
      buffer.writeln('  @override');
      buffer.writeln('  String toString() => \'\$\$$originalClassName(\${delegate})\';');
      buffer.writeln();
      return;
    }
    if (name.startsWith('_')) return;

    final isInterceptor = _isInterceptableReturnType(member.returnType);
    buffer.writeln('  /// {@macro ${className.toLowerCase()}_$name}');
    buffer.writeln('  @override');
    if (member.isGetter) {
      buffer.writeln('  $returnType get $name => delegate.$name;');
      buffer.writeln();
      return;
    }
    if (member.isSetter) {
      final param = member.parameters?.parameters.first;
      final paramType = param?.type?.toSource() ?? 'dynamic';
      final paramName = param?.name?.lexeme ?? 'value';
      buffer.writeln('  set $name($paramType $paramName) => delegate.$name = $paramName;');
      buffer.writeln();
      return;
    }
    if (member.isOperator) {
      buffer.writeln('  $returnType operator $name$typeParamsDecl($paramsSigClean) {');
      buffer.writeln('    return delegate.$name$paramsSigClean;');
      buffer.writeln('  }');
      buffer.writeln();
      return;
    }
    if (isInterceptor) {
      final tieType = _extractTieType(member.returnType);
      final args = _executorArguments(member);
      buffer.writeln('  $returnType $name$typeParamsDecl($paramsSigClean) async {');
      buffer.writeln('    return when<$tieType>(');
      buffer.writeln('      () async => delegate.$name$typeParamsUse${_callArgs(member)},');
      buffer.writeln('      delegate,');
      buffer.writeln('      \'$name\',');
      buffer.writeln('      ExecutableArgument.optional($args),');
      buffer.writeln('      _class,');
      buffer.writeln('    );');
      buffer.writeln('  }');
      buffer.writeln();
      return;
    }
    buffer.writeln('  $returnType $name$typeParamsDecl($paramsSigClean) {');
    buffer.writeln('    return delegate.$name$typeParamsUse${_callArgs(member)};');
    buffer.writeln('  }');
    buffer.writeln();
  }

  bool _isInterceptableReturnType(ast.TypeAnnotation? type) {
    if (type == null) return false;
    final lower = type.toSource().toLowerCase();
    return lower == 'void' ||
        lower.startsWith('future<') ||
        lower.startsWith('futureor<') ||
        lower == 'future' ||
        lower == 'futureor';
  }

  String _extractTieType(ast.TypeAnnotation? type) {
    final source = type?.toSource() ?? 'dynamic';
    final lower = source.toLowerCase();
    if (lower.startsWith('future<')) {
      return source.substring(source.indexOf('<') + 1, source.lastIndexOf('>'));
    }
    if (lower.startsWith('futureor<')) {
      return source.substring(source.indexOf('<') + 1, source.lastIndexOf('>'));
    }
    if (lower == 'future' || lower == 'futureor' || lower == 'void') return lower;
    return source;
  }

  String _executorArguments(ast.MethodDeclaration member) {
    final params = member.parameters?.parameters ?? const <ast.FormalParameter>[];
    final positional = <String>[];
    final named = <String>[];
    for (final param in params) {
      final name = param.name?.lexeme;
      if (name == null) continue;
      if (param.isNamed) {
        named.add("'$name': $name");
      } else {
        positional.add(name);
      }
    }
    final parts = <String>[];
    if (positional.isNotEmpty) parts.add('positional: [${positional.join(', ')}]');
    if (named.isNotEmpty) parts.add('named: {${named.join(', ')}}');
    return parts.join(', ');
  }

  String _callArgs(ast.MethodDeclaration member) {
    final params = member.parameters?.parameters ?? const <ast.FormalParameter>[];
    final positional = <String>[];
    final named = <String>[];
    for (final param in params) {
      final name = param.name?.lexeme;
      if (name == null) continue;
      if (param.isNamed) {
        named.add('$name: $name');
      } else {
        positional.add(name);
      }
    }
    final args = [...positional, ...named];
    return '(${args.join(', ')})';
  }

  /// Method-level type parameters, e.g. `<T>` / `<T, U extends Foo>`.
  String _methodTypeParametersDecl(ast.MethodDeclaration member) {
    final list = member.typeParameters;
    if (list == null) return '';
    return '<${list.typeParameters.map((tp) => _typeParameterDecl(tp)).join(', ')}>';
  }

  String _methodTypeParametersUse(ast.MethodDeclaration member) {
    final list = member.typeParameters;
    if (list == null) return '';
    return '<${list.typeParameters.map((tp) => tp.name.lexeme).join(', ')}>';
  }

  String _typeParameterDecl(ast.TypeParameter tp) {
    final bound = tp.bound;
    if (bound == null) return tp.name.lexeme;
    return '${tp.name.lexeme} extends ${bound.toSource()}';
  }

  /// Builds a clean parameter signature — no annotations, no private
  /// references, default-aligned.
  String _buildParameterSignature(ast.MethodDeclaration member) {
    final params = member.parameters?.parameters ?? const <ast.FormalParameter>[];
    final parts = <String>[];
    final requiredPositional = <String>[];
    final optionalPositional = <String>[];
    final namedParams = <String>[];

    for (final param in params) {
      final paramName = param.name?.lexeme;
      if (paramName == null) continue;
      final paramType = param.type?.toSource() ?? 'dynamic';
      final defaultClause = param.defaultClause;
      // Preserve exactly what the source declared — Dart allows nullable
      // named parameters without a default (implicit null), so inferring
      // `required` here would break the override.
      final prefix = param.isRequired ? 'required ' : '';
      final defaultValue = defaultClause?.value.toSource();

      if (param.isNamed) {
        if (defaultValue != null) {
          namedParams.add('$prefix$paramType $paramName = $defaultValue');
        } else {
          namedParams.add('$prefix$paramType $paramName');
        }
      } else if (param.isOptionalPositional) {
        if (defaultValue != null) {
          optionalPositional.add('$paramType $paramName = $defaultValue');
        } else {
          optionalPositional.add('$paramType $paramName');
        }
      } else {
        // required positional
        requiredPositional.add('$paramType $paramName');
      }
    }

    parts.addAll(requiredPositional);
    if (optionalPositional.isNotEmpty) parts.add('[${optionalPositional.join(', ')}]');
    if (namedParams.isNotEmpty) parts.add('{${namedParams.join(', ')}}');
    return parts.join(', ');
  }
}
