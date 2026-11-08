import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:path/path.dart' as p;

import '../../runtime/declaration/declaration.dart';
import 'discovered_files.dart';

class _ParsedUnit {
  final File file;
  final String packageName;
  final String uri;
  final List<String> lines;
  final ast.CompilationUnit unit;
  final Set<String> imports;

  const _ParsedUnit({
    required this.file,
    required this.packageName,
    required this.uri,
    required this.lines,
    required this.unit,
    required this.imports,
  });
}

class _PendingAnnotation {
  final StandardAnnotationDeclaration declaration;
  final String name;
  final String constructorName;
  final List<dynamic> positionalArgs;
  final Map<String, dynamic> namedArgs;

  const _PendingAnnotation({
    required this.declaration,
    required this.name,
    required this.constructorName,
    required this.positionalArgs,
    required this.namedArgs,
  });
}

class _PendingSuperParam {
  final StandardParameterDeclaration parameter;
  final String className;
  final String paramName;

  const _PendingSuperParam({
    required this.parameter,
    required this.className,
    required this.paramName,
  });
}

/// Builds declarations from discovered files using the analyzer.
///
/// Returns [ClassDeclaration] objects directly — no intermediate
/// representation needed.
final class DeclarationBuilder {
  final Map<String, ast.Expression> _topLevelConsts = {};
  final Map<String, ast.Expression> _classStaticConsts = {};
  final List<_PendingAnnotation> _pendingAnnotations = [];
  final List<_PendingSuperParam> _pendingSuperParams = [];
  final List<StandardLinkDeclaration> _allLinks = [];
  final Set<String> _evaluatingConsts = {};
  String? _currentClassName;
  String? _currentUri;
  final Map<StandardLinkDeclaration, String> _linkOriginUri = Map.identity();
  final Map<String, Set<String>> _importsByUri = {};

  /// Builds class declarations from discovered files.
  Future<List<ClassDeclaration>> build({required DiscoveredFiles files, required String packageName}) async {
    _topLevelConsts.clear();
    _classStaticConsts.clear();
    _pendingAnnotations.clear();
    _pendingSuperParams.clear();
    _allLinks.clear();
    _evaluatingConsts.clear();
    _linkOriginUri.clear();
    _importsByUri.clear();
    _currentUri = null;

    final parsedUnits = <_ParsedUnit>[];

    // Pass 1: Parse AST units and index static/top-level constant declarations
    for (final file in files.getAnalyzableDartFiles()) {
      try {
        final owner = files.packageNames[file.path] ??
            files.packageNames[file.absolute.path] ??
            packageName;
        final content = await file.readAsString();
        final result = parseString(content: content, throwIfDiagnostics: false);
        final unit = result.unit;
        final lines = content.split('\n');
        var uri = _resolveToPackageUri(file.path, owner);

        final imports = <String>{};
        for (final directive in unit.directives) {
          if (directive is ast.PartOfDirective) {
            final partUri = directive.uri?.stringValue;
            if (partUri != null) {
              final parentFilePath = p.normalize(p.join(p.dirname(file.path), partUri));
              uri = _resolveToPackageUri(parentFilePath, owner);
            }
            break;
          } else if (directive is ast.ImportDirective) {
            final importStr = directive.uri.stringValue;
            if (importStr != null && importStr.isNotEmpty) {
              if (importStr.startsWith('package:') || importStr.startsWith('dart:')) {
                imports.add(importStr);
              } else {
                final resolved = p.normalize(p.join(p.dirname(uri), importStr));
                imports.add(resolved);
              }
            }
          }
        }

        _importsByUri[uri] = imports;
        _indexConstants(unit);
        parsedUnits.add(_ParsedUnit(
          file: file,
          packageName: owner,
          uri: uri,
          lines: lines,
          unit: unit,
          imports: imports,
        ));
      } catch (_) {
        // Skip files that can't be parsed
      }
    }

    // Pass 2: Build declarations for all classes, mixins, and enums
    final components = <ClassDeclaration>[];
    final classesByUri = <String, Map<String, ClassDeclaration>>{};
    for (final parsed in parsedUnits) {
      try {
        _currentUri = parsed.uri;
        final classes = _buildLibraryFromUnit(parsed);
        components.addAll(classes);
        final map = classesByUri.putIfAbsent(parsed.uri, () => <String, ClassDeclaration>{});
        for (final c in classes) {
          map[c.getName()] = c;
        }
      } catch (_) {}
    }
    _currentUri = null;

    // Build lookup map by simple name (prefer root package or public declarations)
    final classByName = <String, ClassDeclaration>{};
    for (final comp in components) {
      final name = comp.getName();
      if (!classByName.containsKey(name) || comp.getPackageUri().startsWith('package:$packageName/')) {
        classByName[name] = comp;
      }
    }

    // Pass 3: Resolve super formal parameters, links, and annotation metadata
    _resolveSuperParameters(classByName);
    _resolveLinks(classByName, classesByUri);
    _resolveAnnotations(classByName);

    return components;
  }

  /// Indexes top-level and class-level `static const` expressions for constant evaluation.
  void _indexConstants(ast.CompilationUnit unit) {
    for (final decl in unit.declarations) {
      if (decl is ast.TopLevelVariableDeclaration) {
        if (decl.variables.isConst || decl.variables.isFinal) {
          for (final v in decl.variables.variables) {
            if (v.initializer != null) {
              _topLevelConsts[v.name.lexeme] = v.initializer!;
            }
          }
        }
      } else if (decl is ast.ClassDeclaration) {
        final className = decl.namePart.typeName.lexeme;
        if (decl.body is ast.BlockClassBody) {
          for (final member in (decl.body as ast.BlockClassBody).members) {
            if (member is ast.FieldDeclaration && member.isStatic && (member.fields.isConst || member.fields.isFinal)) {
              for (final v in member.fields.variables) {
                if (v.initializer != null) {
                  _classStaticConsts['$className.${v.name.lexeme}'] = v.initializer!;
                  _topLevelConsts.putIfAbsent(v.name.lexeme, () => v.initializer!);
                }
              }
            }
          }
        }
      }
    }
  }

  /// Builds class declarations from a pre-parsed [_ParsedUnit].
  List<ClassDeclaration> _buildLibraryFromUnit(_ParsedUnit parsed) {
    final unit = parsed.unit;
    final uri = parsed.uri;
    final lines = parsed.lines;
    final declarations = <ClassDeclaration>[];

    final library = StandardLibraryDeclaration(
      uri: uri,
      name: uri,
      isPublic: true,
      isSynthetic: false,
      parentPackage: MaterialPackage(
        name: parsed.packageName,
        version: 'unknown',
        isRootPackage: false,
        filePath: null,
        rootUri: null,
        dependencies: const [],
        devDependencies: const [],
        jetleafDependencies: const [],
      ),
    );

    for (final declaration in unit.declarations) {
      if (declaration is ast.ClassDeclaration) {
        declarations.add(_buildClass(declaration, uri, lines, library));
      } else if (declaration is ast.MixinDeclaration) {
        declarations.add(_buildMixin(declaration, uri, lines, library));
      } else if (declaration is ast.EnumDeclaration) {
        declarations.add(_buildEnum(declaration, uri, lines, library));
      }
    }

    return declarations;
  }

  /// Builds a class declaration from an AST node.
  ClassDeclaration _buildClass(ast.ClassDeclaration node, String uri, List<String> lines, LibraryDeclaration library) {
    final name = node.namePart.typeName.lexeme;
    final prevClassName = _currentClassName;
    _currentClassName = name;
    try {
      final isPublic = !_isPrivateName(name);
      final qualifiedClassName = '$uri.$name';

      final constructors = <ConstructorDeclaration>[];
      final fields = <FieldDeclaration>[];
      final methods = <MethodDeclaration>[];
      final annotations = _buildAnnotations(node.metadata, library);

      if (node.body is ast.BlockClassBody) {
        final members = (node.body as ast.BlockClassBody).members;
        final fieldTypes = <String, String>{};
        final fieldLinks = <String, StandardLinkDeclaration>{};
        final fieldNullability = <String, bool>{};

        for (final member in members) {
          if (member is ast.FieldDeclaration) {
            final typeName = _resolveType(member.fields.type);
            final link = _buildTypeAnnotationLink(member.fields.type);
            final nullable = _isNullableType(member.fields.type);
            for (final v in member.fields.variables) {
              final vName = v.name.lexeme;
              fieldTypes[vName] = typeName;
              fieldLinks[vName] = link;
              fieldNullability[vName] = nullable;
            }
            fields.addAll(_buildFields(member, name, qualifiedClassName, library));
          }
        }

        for (final member in members) {
          if (member is ast.ConstructorDeclaration) {
            constructors.add(_buildConstructor(member, name, qualifiedClassName, library, fieldTypes, fieldLinks, fieldNullability));
          } else if (member is ast.MethodDeclaration) {
            methods.add(_buildMethod(member, name, qualifiedClassName, library));
          }
        }
      }

      if (constructors.isEmpty && node.abstractKeyword == null) {
        constructors.add(StandardConstructorDeclaration(
          name: '',
          type: Object,
          isPublic: true,
          isSynthetic: true,
          parentClass: _registerLink(StandardLinkDeclaration(
            name: name,
            type: Object,
            isPublic: isPublic,
            isSynthetic: false,
            pointerType: Object,
            qualifiedName: qualifiedClassName,
          )),
          parameters: const [],
          annotations: const [],
          sourceLocation: null,
          isConst: false,
          isFactory: false,
        ));
      }

      StandardLinkDeclaration? superClass;
      if (node.extendsClause != null) {
        superClass = _buildNamedTypeLink(node.extendsClause!.superclass);
      }

      final interfaces = <StandardLinkDeclaration>[];
      if (node.implementsClause != null) {
        for (final iface in node.implementsClause!.interfaces) {
          interfaces.add(_buildNamedTypeLink(iface));
        }
      }

      final mixins = <StandardLinkDeclaration>[];
      if (node.withClause != null) {
        for (final mixin in node.withClause!.mixinTypes) {
          mixins.add(_buildNamedTypeLink(mixin));
        }
      }

      final typeArguments = <LinkDeclaration>[];
      if (node.namePart.typeParameters case final typeParams?) {
        for (final tp in typeParams.typeParameters) {
          final tpName = tp.name.lexeme;
          typeArguments.add(_registerLink(StandardLinkDeclaration(
            name: tpName,
            type: Object,
            pointerType: Object,
            qualifiedName: tpName,
            isPublic: true,
            isSynthetic: false,
          )));
        }
      }

      return StandardClassDeclaration(
        name: name,
        type: Object,
        isPublic: isPublic,
        isSynthetic: false,
        library: library,
        constructors: constructors,
        fields: fields,
        methods: methods,
        superClass: superClass,
        interfaces: interfaces,
        mixins: mixins,
        typeArguments: typeArguments,
        annotations: annotations,
        sourceLocation: Uri.parse('$uri:${_getStartLine(node, lines)}'),
        isAbstract: node.abstractKeyword != null,
        isMixin: node.mixinKeyword != null,
        isSealed: node.sealedKeyword != null,
        isBase: node.baseKeyword != null,
        isInterface: node.interfaceKeyword != null,
        qualifiedName: qualifiedClassName,
        isFinal: node.finalKeyword != null,
        isRecord: false,
        packageUri: uri,
        simpleName: name,
        kind: TypeKind.classType,
      );
    } finally {
      _currentClassName = prevClassName;
    }
  }

  /// Builds a mixin declaration from an AST node.
  ClassDeclaration _buildMixin(ast.MixinDeclaration node, String uri, List<String> lines, LibraryDeclaration library) {
    final name = node.name.lexeme;
    final isPublic = !_isPrivateName(name);
    final qualifiedClassName = '$uri.$name';

    final fields = <FieldDeclaration>[];
    final methods = <MethodDeclaration>[];
    for (final member in node.body.members) {
      if (member is ast.FieldDeclaration) {
        fields.addAll(_buildFields(member, name, qualifiedClassName, library));
      } else if (member is ast.MethodDeclaration) {
        methods.add(_buildMethod(member, name, qualifiedClassName, library));
      }
    }

    final interfaces = <StandardLinkDeclaration>[];
    if (node.implementsClause != null) {
      for (final iface in node.implementsClause!.interfaces) {
        interfaces.add(_buildNamedTypeLink(iface));
      }
    }

    final constraints = <StandardLinkDeclaration>[];
    if (node.onClause != null) {
      for (final constraint in node.onClause!.superclassConstraints) {
        constraints.add(_buildNamedTypeLink(constraint));
      }
    }

    final annotations = _buildAnnotations(node.metadata, library);

    return StandardMixinDeclaration(
      name: name,
      type: Object,
      isPublic: isPublic,
      isSynthetic: false,
      library: library,
      constructors: const [],
      fields: fields,
      methods: methods,
      superClass: null,
      interfaces: interfaces,
      mixins: const [],
      annotations: annotations,
      sourceLocation: Uri.parse('$uri:${_getStartLine(node, lines)}'),
      isAbstract: false,
      isMixin: true,
      isSealed: false,
      isBase: node.baseKeyword != null,
      isInterface: false,
      qualifiedName: qualifiedClassName,
      isFinal: false,
      isRecord: false,
      packageUri: uri,
      simpleName: name,
      constraints: constraints,
    );
  }

  /// Builds an enum declaration from an AST node.
  ClassDeclaration _buildEnum(ast.EnumDeclaration node, String uri, List<String> lines, LibraryDeclaration library) {
    final name = node.namePart.typeName.lexeme;
    final isPublic = !_isPrivateName(name);
    final qualifiedClassName = '$uri.$name';

    final constructors = <ConstructorDeclaration>[];
    final fields = <FieldDeclaration>[];
    final methods = <MethodDeclaration>[];
    final annotations = _buildAnnotations(node.metadata, library);

    final fieldTypes = <String, String>{};
    final fieldLinks = <String, StandardLinkDeclaration>{};
    final fieldNullability = <String, bool>{};

    for (final member in node.body.members) {
      if (member is ast.FieldDeclaration) {
        final typeName = _resolveType(member.fields.type);
        final link = _buildTypeAnnotationLink(member.fields.type);
        final nullable = _isNullableType(member.fields.type);
        for (final v in member.fields.variables) {
          final vName = v.name.lexeme;
          fieldTypes[vName] = typeName;
          fieldLinks[vName] = link;
          fieldNullability[vName] = nullable;
        }
        fields.addAll(_buildFields(member, name, qualifiedClassName, library));
      }
    }

    for (final member in node.body.members) {
      if (member is ast.ConstructorDeclaration) {
        constructors.add(_buildConstructor(member, name, qualifiedClassName, library, fieldTypes, fieldLinks, fieldNullability));
      } else if (member is ast.MethodDeclaration) {
        methods.add(_buildMethod(member, name, qualifiedClassName, library));
      }
    }

    final interfaces = <StandardLinkDeclaration>[];
    if (node.implementsClause != null) {
      for (final iface in node.implementsClause!.interfaces) {
        interfaces.add(_buildNamedTypeLink(iface));
      }
    }

    final mixins = <StandardLinkDeclaration>[];
    if (node.withClause != null) {
      for (final mixin in node.withClause!.mixinTypes) {
        mixins.add(_buildNamedTypeLink(mixin));
      }
    }

    final enumValues = <EnumFieldDeclaration>[];
    for (var i = 0; i < node.constants.length; i++) {
      final constant = node.constants[i];
      enumValues.add(StandardEnumFieldDeclaration(
        name: constant.name.lexeme,
        type: Object,
        isPublic: !_isPrivateName(constant.name.lexeme),
        isSynthetic: false,
        value: null,
        position: i,
        isNullable: false,
        linkDeclaration: _registerLink(StandardLinkDeclaration(
          name: constant.name.lexeme,
          type: Object,
          isPublic: true,
          isSynthetic: false,
          pointerType: Object,
          qualifiedName: '$qualifiedClassName.${constant.name.lexeme}',
        )),
      ));
    }

    return StandardEnumDeclaration(
      name: name,
      type: Object,
      isPublic: isPublic,
      isSynthetic: false,
      library: library,
      constructors: constructors,
      fields: fields,
      methods: methods,
      superClass: null,
      interfaces: interfaces,
      mixins: mixins,
      annotations: annotations,
      sourceLocation: Uri.parse('$uri:${_getStartLine(node, lines)}'),
      isAbstract: false,
      qualifiedName: qualifiedClassName,
      values: enumValues,
    );
  }

  /// Builds a constructor declaration from an AST node.
  ConstructorDeclaration _buildConstructor(
    ast.ConstructorDeclaration node,
    String className,
    String qualifiedClassName,
    LibraryDeclaration library, [
    Map<String, String>? fieldTypes,
    Map<String, StandardLinkDeclaration>? fieldLinks,
    Map<String, bool>? fieldNullability,
  ]) {
    final ctorName = node.name?.lexeme ?? '';
    final params = _buildParameters(
      node.parameters,
      library,
      className: className,
      fieldTypes: fieldTypes,
      fieldLinks: fieldLinks,
      fieldNullability: fieldNullability,
    );
    final annotations = _buildAnnotations(node.metadata, library);

    return StandardConstructorDeclaration(
      name: ctorName,
      type: Object,
      isPublic: node.name == null || !_isPrivateName(ctorName),
      isSynthetic: false,
      parentClass: _registerLink(StandardLinkDeclaration(
        name: className,
        type: Object,
        isPublic: !_isPrivateName(className),
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: qualifiedClassName,
      )),
      parameters: params,
      annotations: annotations,
      sourceLocation: null,
      isConst: node.constKeyword != null,
      isFactory: node.factoryKeyword != null,
    );
  }

  /// Builds field declarations from a field declaration node.
  List<FieldDeclaration> _buildFields(
    ast.FieldDeclaration node,
    String className,
    String qualifiedClassName,
    LibraryDeclaration library,
  ) {
    final fields = <FieldDeclaration>[];
    final link = _buildTypeAnnotationLink(node.fields.type);
    final nullable = _isNullableType(node.fields.type);
    final annotations = _buildAnnotations(node.metadata, library);

    for (final field in node.fields.variables) {
      final fieldAnns = [
        ...annotations,
        ..._buildAnnotations(field.metadata, library),
      ];
      fields.add(StandardFieldDeclaration(
        name: field.name.lexeme,
        type: Object,
        parentClass: _registerLink(StandardLinkDeclaration(
          name: className,
          type: Object,
          isPublic: !_isPrivateName(className),
          isSynthetic: false,
          pointerType: Object,
          qualifiedName: qualifiedClassName,
        )),
        linkDeclaration: link,
        annotations: fieldAnns,
        isPublic: !_isPrivateName(field.name.lexeme),
        isSynthetic: false,
        sourceLocation: null,
        isStatic: node.isStatic,
        isLate: node.fields.isLate,
        isConst: node.fields.isConst,
        isFinal: node.fields.isFinal || node.fields.isConst,
        isNullable: nullable,
      ));
    }

    return fields;
  }

  /// Registers a link declaration for post-pass qualified name resolution.
  StandardLinkDeclaration _registerLink(StandardLinkDeclaration link) {
    _allLinks.add(link);
    if (_currentUri != null) {
      _linkOriginUri[link] = _currentUri!;
    }
    return link;
  }

  /// Builds a [StandardLinkDeclaration] from an arbitrary [ast.TypeAnnotation].
  StandardLinkDeclaration _buildTypeAnnotationLink(ast.TypeAnnotation? typeNode) {
    if (typeNode is ast.NamedType) {
      return _buildNamedTypeLink(typeNode);
    }
    final raw = _resolveType(typeNode);
    final clean = raw.endsWith('?') ? raw.substring(0, raw.length - 1) : raw;
    return _registerLink(StandardLinkDeclaration(
      name: clean,
      type: Object,
      pointerType: Object,
      qualifiedName: clean,
      isPublic: true,
      isSynthetic: false,
    ));
  }

  /// Builds a [StandardLinkDeclaration] from an AST [ast.NamedType], recursively capturing type arguments.
  StandardLinkDeclaration _buildNamedTypeLink(ast.NamedType namedType) {
    final name = namedType.name.lexeme;
    final typeArgs = <LinkDeclaration>[];
    if (namedType.typeArguments case final argsNode?) {
      for (final arg in argsNode.arguments) {
        typeArgs.add(_buildTypeAnnotationLink(arg));
      }
    }
    return _registerLink(StandardLinkDeclaration(
      name: name,
      type: Object,
      pointerType: Object,
      typeArguments: typeArgs,
      qualifiedName: name,
      isPublic: !_isPrivateName(name),
      isSynthetic: false,
    ));
  }

  /// Builds a method declaration from an AST node.
  MethodDeclaration _buildMethod(
    ast.MethodDeclaration node,
    String className,
    String qualifiedClassName,
    LibraryDeclaration library,
  ) {
    final returnLink = _buildTypeAnnotationLink(node.returnType);
    final nullableReturn = _isNullableType(node.returnType);
    final params = _buildParameters(node.parameters, library, className: className);
    final annotations = _buildAnnotations(node.metadata, library);

    return StandardMethodDeclaration(
      name: node.name.lexeme,
      type: Object,
      returnType: returnLink,
      parameters: params,
      annotations: annotations,
      isPublic: !_isPrivateName(node.name.lexeme),
      isSynthetic: false,
      sourceLocation: null,
      isStatic: node.isStatic,
      isAbstract: node.body is ast.EmptyFunctionBody && node.externalKeyword == null,
      isExternal: node.externalKeyword != null,
      isGetter: node.isGetter,
      isSetter: node.isSetter,
      isAsync: node.body.isAsynchronous,
      parentClass: _registerLink(StandardLinkDeclaration(
        name: className,
        type: Object,
        isPublic: !_isPrivateName(className),
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: qualifiedClassName,
      )),
      hasNullableReturn: nullableReturn,
    );
  }

  /// Builds parameter declarations from a parameter list.
  List<ParameterDeclaration> _buildParameters(
    ast.FormalParameterList? params,
    LibraryDeclaration library, {
    String? className,
    Map<String, String>? fieldTypes,
    Map<String, StandardLinkDeclaration>? fieldLinks,
    Map<String, bool>? fieldNullability,
  }) {
    if (params == null) return [];

    final parameters = <ParameterDeclaration>[];
    var index = 0;

    for (final param in params.parameters) {
      String? name;
      StandardLinkDeclaration? link;
      bool isNullable = false;
      final bool isRequired = param.isRequired;
      final bool isOptional = param.isOptional;
      final bool isNamed = param.isNamed;
      bool hasDefaultValue = false;
      dynamic defaultValue;
      bool isUnresolvedSuperParam = false;

      ast.FormalParameter inner = param;
      if (param is ast.DefaultFormalParameter) {
        hasDefaultValue = param.defaultValue != null;
        defaultValue = _evalAstExpression(param.defaultValue);
        inner = param.parameter;
      }

      if (inner is ast.SimpleFormalParameter) {
        name = inner.name?.lexeme;
        link = _buildTypeAnnotationLink(inner.type);
        isNullable = _isNullableType(inner.type);
      } else if (inner is ast.FieldFormalParameter) {
        name = inner.name.lexeme;
        if (inner.type != null) {
          link = _buildTypeAnnotationLink(inner.type);
          isNullable = _isNullableType(inner.type);
        } else if (fieldLinks != null && fieldLinks.containsKey(name)) {
          link = fieldLinks[name]!;
          isNullable = fieldNullability != null ? (fieldNullability[name] ?? false) : false;
        } else {
          final fallbackType = (fieldTypes != null ? fieldTypes[name] : null) ?? 'dynamic';
          final clean = fallbackType.endsWith('?') ? fallbackType.substring(0, fallbackType.length - 1) : fallbackType;
          link = _registerLink(StandardLinkDeclaration(
            name: clean,
            type: Object,
            isPublic: true,
            isSynthetic: false,
            pointerType: Object,
            qualifiedName: clean,
          ));
          isNullable = fallbackType.endsWith('?');
        }
      } else if (inner is ast.SuperFormalParameter) {
        name = inner.name.lexeme;
        if (inner.type != null) {
          link = _buildTypeAnnotationLink(inner.type);
          isNullable = _isNullableType(inner.type);
        } else {
          isUnresolvedSuperParam = true;
          link = _registerLink(StandardLinkDeclaration(
            name: 'dynamic',
            type: Object,
            isPublic: true,
            isSynthetic: false,
            pointerType: Object,
            qualifiedName: 'dynamic',
          ));
          isNullable = !isRequired;
        }
      } else if (inner is ast.FunctionTypedFormalParameter) {
        name = inner.name.lexeme;
        link = _registerLink(StandardLinkDeclaration(
          name: 'Function',
          type: Function,
          isPublic: true,
          isSynthetic: false,
          pointerType: Function,
          qualifiedName: 'Function',
        ));
        isNullable = inner.question != null;
      }

      final paramAnnotations = <AnnotationDeclaration>[
        ..._buildAnnotations(param.metadata, library),
        if (!identical(inner, param)) ..._buildAnnotations(inner.metadata, library),
      ];

      if (name != null && link != null) {
        final paramDecl = StandardParameterDeclaration(
          name: name,
          type: Object,
          typeDeclaration: link,
          isNullable: isNullable,
          isRequired: isRequired,
          isOptional: isOptional,
          isNamed: isNamed,
          hasDefaultValue: hasDefaultValue,
          defaultValue: defaultValue,
          index: index,
          isPublic: !_isPrivateName(name),
          isSynthetic: false,
          sourceLocation: null,
          annotations: paramAnnotations,
        );
        if (isUnresolvedSuperParam && className != null) {
          _pendingSuperParams.add(_PendingSuperParam(
            parameter: paramDecl,
            className: className,
            paramName: name,
          ));
        }
        parameters.add(paramDecl);
        index++;
      }
    }

    return parameters;
  }

  /// Builds a list of [AnnotationDeclaration]s from an AST metadata node list.
  List<AnnotationDeclaration> _buildAnnotations(ast.NodeList<ast.Annotation> metadata, LibraryDeclaration library) {
    if (metadata.isEmpty) return const [];
    return [
      for (final meta in metadata)
        _buildAnnotation(meta, library),
    ];
  }

  /// Builds an annotation declaration and queues it for post-pass field/argument resolution.
  AnnotationDeclaration _buildAnnotation(ast.Annotation meta, LibraryDeclaration library) {
    String annName;
    String ctorName = meta.constructorName?.name ?? '';
    final id = meta.name;
    if (id is ast.PrefixedIdentifier) {
      annName = id.prefix.name;
      if (ctorName.isEmpty) {
        ctorName = id.identifier.name;
      }
    } else {
      annName = id.name;
    }

    final positionalArgs = <dynamic>[];
    final namedArgs = <String, dynamic>{};

    if (meta.arguments case final argList?) {
      for (final arg in argList.arguments) {
        if (arg is ast.NamedExpression) {
          namedArgs[arg.name.label.name] = _evalAstExpression(arg.expression);
        } else {
          positionalArgs.add(_evalAstExpression(arg));
        }
      }
    }

    final initialUserValues = <String, dynamic>{...namedArgs};
    for (var i = 0; i < positionalArgs.length; i++) {
      initialUserValues['\$$i'] = positionalArgs[i];
    }
    if (positionalArgs.length == 1 && !initialUserValues.containsKey('value')) {
      initialUserValues['value'] = positionalArgs[0];
    }
    if (meta.typeArguments case final typeArgs?) {
      final args = typeArgs.arguments.map((a) => a.toSource()).toList();
      if (args.isNotEmpty) {
        initialUserValues['__typeArgument'] = args.first;
        initialUserValues['__typeArguments'] = args;
      }
    }

    final initialFields = <String, AnnotationFieldDeclaration>{};
    var pos = 0;
    for (final entry in initialUserValues.entries) {
      if (entry.key.startsWith(r'$')) continue;
      initialFields[entry.key] = StandardAnnotationFieldDeclaration(
        name: entry.key,
        isPublic: true,
        isSynthetic: false,
        defaultValue: null,
        hasDefaultValue: false,
        userValue: entry.value,
        hasUserValue: true,
        position: pos++,
        type: Object,
        linkDeclaration: _registerLink(StandardLinkDeclaration(
          name: entry.key,
          type: Object,
          pointerType: Object,
          qualifiedName: entry.key,
          isPublic: true,
          isSynthetic: false,
        )),
      );
    }

    final link = _registerLink(StandardLinkDeclaration(
      name: annName,
      type: Object,
      isPublic: true,
      isSynthetic: false,
      pointerType: Object,
      qualifiedName: annName,
    ));

    final decl = StandardAnnotationDeclaration(
      linkDeclaration: link,
      instance: null,
      isPublic: true,
      isSynthetic: false,
      name: annName,
      type: Object,
      fields: initialFields,
      userProvidedValues: initialUserValues,
    );

    _pendingAnnotations.add(_PendingAnnotation(
      declaration: decl,
      name: annName,
      constructorName: ctorName,
      positionalArgs: positionalArgs,
      namedArgs: namedArgs,
    ));

    return decl;
  }

  /// Resolves `super.param` types and default values by walking the superclass hierarchy.
  void _resolveSuperParameters(Map<String, ClassDeclaration> classByName) {
    for (final pending in _pendingSuperParams) {
      var current = classByName[pending.className];
      final visited = <String>{};
      while (current != null && visited.add(current.getName())) {
        final superLink = current.getSuperClass();
        if (superLink == null) break;
        final superClass = classByName[superLink.getName()];
        if (superClass == null) break;

        // Check superclass constructor parameters first (for default values and types)
        ParameterDeclaration? matchedParam;
        for (final ctor in superClass.getConstructors()) {
          for (final p in ctor.getParameters()) {
            if (p.getName() == pending.paramName) {
              matchedParam = p;
              break;
            }
          }
          if (matchedParam != null) break;
        }

        // Also check superclass fields for concrete type declaration
        FieldDeclaration? matchedField;
        for (final f in superClass.getFields()) {
          if (f.getName() == pending.paramName) {
            matchedField = f;
            break;
          }
        }

        if (matchedField != null && matchedField.getLinkDeclaration().getName() != 'dynamic') {
          pending.parameter.resolveSuperParameter(
            typeDeclaration: matchedField.getLinkDeclaration(),
            isNullable: matchedField.isNullable(),
            hasDefaultValue: matchedParam?.getHasDefaultValue(),
            defaultValue: matchedParam?.getDefaultValue(),
          );
          break;
        } else if (matchedParam != null && matchedParam.getLinkDeclaration().getName() != 'dynamic') {
          pending.parameter.resolveSuperParameter(
            typeDeclaration: matchedParam.getLinkDeclaration(),
            isNullable: matchedParam.getIsNullable(),
            hasDefaultValue: matchedParam.getHasDefaultValue(),
            defaultValue: matchedParam.getDefaultValue(),
          );
          break;
        }

        current = superClass;
      }
    }
  }

  /// Enriches all [StandardLinkDeclaration]s with resolved qualified names and canonical URIs.
  void _resolveLinks(Map<String, ClassDeclaration> classByName, Map<String, Map<String, ClassDeclaration>> classesByUri) {
    for (final link in _allLinks) {
      final name = link.getName();
      final qName = link.getPointerQualifiedName();
      if (qName == name) {
        ClassDeclaration? targetClass;
        final originUri = _linkOriginUri[link];
        if (originUri != null) {
          // 1. Check if defined in the same file/library
          targetClass = classesByUri[originUri]?[name];

          // 2. Check if defined in imported libraries
          if (targetClass == null) {
            final imports = _importsByUri[originUri];
            if (imports != null) {
              for (final imp in imports) {
                if (classesByUri[imp]?[name] case final found?) {
                  targetClass = found;
                  break;
                }
              }
            }
          }
        }

        // 3. Fall back to classByName
        targetClass ??= classByName[name];

        if (targetClass != null) {
          final pkgUri = targetClass.getPackageUri();
          final uri = pkgUri.isNotEmpty ? Uri.tryParse(pkgUri) : null;
          link.resolveLink(targetClass.getQualifiedName(), uri);
        }
      }
    }
  }

  /// Enriches all [_PendingAnnotation]s with constructor parameter names, field metadata, and defaults.
  void _resolveAnnotations(Map<String, ClassDeclaration> classByName) {
    for (final pending in _pendingAnnotations) {
      final annClass = classByName[pending.name];
      if (annClass == null) continue;

      final userValues = <String, dynamic>{
        ...pending.declaration.getUserProvidedValues(),
        ...pending.namedArgs,
      };

      // Locate target constructor on the annotation class
      final ctors = annClass.getConstructors();
      ConstructorDeclaration? targetCtor;
      if (ctors.isNotEmpty) {
        targetCtor = ctors.firstWhere(
          (c) => c.getName() == pending.constructorName,
          orElse: () => ctors.firstWhere(
            (c) => c.getName().isEmpty,
            orElse: () => ctors.first,
          ),
        );
      }

      if (targetCtor != null && pending.positionalArgs.isNotEmpty) {
        final posParams = targetCtor.getParameters().where((p) => !p.getIsNamed()).toList();
        for (var i = 0; i < pending.positionalArgs.length; i++) {
          if (i < posParams.length) {
            final paramName = posParams[i].getName();
            userValues[paramName] = pending.positionalArgs[i];
          } else {
            userValues['\$$i'] = pending.positionalArgs[i];
          }
        }
      } else if (pending.positionalArgs.isNotEmpty) {
        for (var i = 0; i < pending.positionalArgs.length; i++) {
          userValues['\$$i'] = pending.positionalArgs[i];
        }
        if (pending.positionalArgs.length == 1 && !userValues.containsKey('value')) {
          userValues['value'] = pending.positionalArgs[0];
        }
      }

      // Collect all fields and constructor parameter defaults across annClass and its superclasses
      final allFields = <String, FieldDeclaration>{};
      final paramDefaults = <String, dynamic>{};
      final paramHasDefault = <String, bool>{};
      final paramLinks = <String, LinkDeclaration>{};

      var current = annClass;
      final visited = <String>{};
      while (visited.add(current.getName())) {
        for (final f in current.getFields()) {
          if (!f.getIsStatic()) {
            allFields.putIfAbsent(f.getName(), () => f);
          }
        }
        for (final c in current.getConstructors()) {
          for (final p in c.getParameters()) {
            paramLinks.putIfAbsent(p.getName(), () => p.getLinkDeclaration());
            if (p.getHasDefaultValue() && !paramHasDefault.containsKey(p.getName())) {
              paramHasDefault[p.getName()] = true;
              paramDefaults[p.getName()] = p.getDefaultValue();
            }
          }
        }
        final superLink = current.getSuperClass();
        if (superLink == null) break;
        final next = classByName[superLink.getName()];
        if (next == null) break;
        current = next;
      }

      final resolvedFields = <String, AnnotationFieldDeclaration>{};
      var pos = 0;

      final fieldNames = <String>{
        ...allFields.keys,
        ...paramLinks.keys,
        ...userValues.keys.where((k) => !k.startsWith(r'$')),
      };

      for (final fieldName in fieldNames) {
        final fieldDecl = allFields[fieldName];
        final link = fieldDecl?.getLinkDeclaration() ??
            paramLinks[fieldName] ??
            _registerLink(StandardLinkDeclaration(
              name: 'Object',
              type: Object,
              pointerType: Object,
              qualifiedName: 'Object',
              isPublic: true,
              isSynthetic: false,
            ));
        final hasDefault = paramHasDefault[fieldName] ?? false;
        final defaultVal = paramDefaults[fieldName];
        final hasUser = userValues.containsKey(fieldName);
        final userVal = userValues[fieldName];

        resolvedFields[fieldName] = StandardAnnotationFieldDeclaration(
          name: fieldName,
          isPublic: !_isPrivateName(fieldName),
          isSynthetic: false,
          defaultValue: defaultVal,
          hasDefaultValue: hasDefault,
          userValue: userVal,
          hasUserValue: hasUser,
          position: pos++,
          type: link.getType(),
          linkDeclaration: link,
          isFinal: fieldDecl?.getIsFinal() ?? true,
          isConst: fieldDecl?.getIsConst() ?? false,
          isNullable: fieldDecl?.isNullable() ?? (defaultVal == null && userVal == null),
        );
      }

      final pkgUri = annClass.getPackageUri();
      final uri = pkgUri.isNotEmpty ? Uri.tryParse(pkgUri) : null;
      final resolvedLink = StandardLinkDeclaration(
        name: annClass.getName(),
        type: annClass.getType(),
        pointerType: annClass.getType(),
        qualifiedName: annClass.getQualifiedName(),
        canonicalUri: uri,
        referenceUri: uri,
        isPublic: annClass.getIsPublic(),
        isSynthetic: annClass.getIsSynthetic(),
      );

      for (final entry in pending.declaration.getUserProvidedValues().entries) {
        if (entry.key.startsWith('__')) {
          userValues[entry.key] = entry.value;
          resolvedFields[entry.key] = StandardAnnotationFieldDeclaration(
            name: entry.key,
            isPublic: true,
            isSynthetic: true,
            defaultValue: null,
            hasDefaultValue: false,
            userValue: entry.value,
            hasUserValue: true,
            position: pos++,
            type: Object,
            linkDeclaration: _registerLink(StandardLinkDeclaration(
              name: entry.key,
              type: Object,
              pointerType: Object,
              qualifiedName: entry.key,
              isPublic: true,
              isSynthetic: true,
            )),
          );
        }
      }

      pending.declaration.resolveMetadata(
        linkDeclaration: resolvedLink,
        fields: resolvedFields,
        userProvidedValues: userValues,
      );
    }
  }

  /// Evaluates a constant AST expression into a Dart runtime value.
  dynamic _evalAstExpression(ast.Expression? expr) {
    if (expr == null) return null;
    if (expr is ast.NullLiteral) return null;
    if (expr is ast.BooleanLiteral) return expr.value;
    if (expr is ast.IntegerLiteral) return expr.value;
    if (expr is ast.DoubleLiteral) return expr.value;
    if (expr is ast.SimpleStringLiteral) return expr.value;
    if (expr is ast.AdjacentStrings) {
      return expr.strings.map((s) => _evalAstExpression(s)?.toString() ?? '').join();
    }
    if (expr is ast.StringInterpolation) {
      final buffer = StringBuffer();
      for (final el in expr.elements) {
        if (el is ast.InterpolationString) {
          buffer.write(el.value);
        } else if (el is ast.InterpolationExpression) {
          final val = _evalAstExpression(el.expression);
          buffer.write(val?.toString() ?? '');
        }
      }
      return buffer.toString();
    }
    if (expr is ast.SymbolLiteral) {
      return expr.components.map((t) => t.lexeme).join('.');
    }
    if (expr is ast.ParenthesizedExpression) {
      return _evalAstExpression(expr.expression);
    }
    if (expr is ast.PrefixExpression) {
      final operand = _evalAstExpression(expr.operand);
      final op = expr.operator.lexeme;
      if (op == '-') {
        if (operand is int) return -operand;
        if (operand is double) return -operand;
      } else if (op == '!') {
        if (operand is bool) return !operand;
      }
      return operand;
    }
    if (expr is ast.BinaryExpression) {
      final left = _evalAstExpression(expr.leftOperand);
      final right = _evalAstExpression(expr.rightOperand);
      final op = expr.operator.lexeme;
      if (op == '+' && left is String && right is String) return left + right;
      if (op == '+' && left is int && right is int) return left + right;
      if (op == '-' && left is int && right is int) return left - right;
      if (op == '*' && left is int && right is int) return left * right;
    }
    if (expr is ast.ListLiteral) {
      final items = <dynamic>[];
      for (final el in expr.elements) {
        if (el is ast.Expression) {
          items.add(_evalAstExpression(el));
        }
      }
      if (items.isNotEmpty) {
        if (items.every((e) => e is String)) return items.cast<String>().toList();
        if (items.every((e) => e is int)) return items.cast<int>().toList();
        if (items.every((e) => e is double)) return items.cast<double>().toList();
        if (items.every((e) => e is bool)) return items.cast<bool>().toList();
      }
      final typeArg = expr.typeArguments?.arguments.firstOrNull?.toSource();
      if (items.isEmpty) {
        if (typeArg == 'String') return <String>[];
        if (typeArg == 'int') return <int>[];
        if (typeArg == 'bool') return <bool>[];
      }
      return items;
    }
    if (expr is ast.SetOrMapLiteral) {
      final isMap = expr.elements.any((e) => e is ast.MapLiteralEntry) ||
          (expr.typeArguments?.arguments.length == 2);
      if (isMap) {
        final map = <String, dynamic>{};
        for (final el in expr.elements) {
          if (el is ast.MapLiteralEntry) {
            final k = _evalAstExpression(el.key)?.toString() ?? '';
            map[k] = _evalAstExpression(el.value);
          }
        }
        return map;
      } else {
        final items = <dynamic>{};
        for (final el in expr.elements) {
          if (el is ast.Expression) {
            items.add(_evalAstExpression(el));
          }
        }
        if (items.isNotEmpty) {
          if (items.every((e) => e is String)) return items.cast<String>().toSet();
          if (items.every((e) => e is int)) return items.cast<int>().toSet();
          if (items.every((e) => e is bool)) return items.cast<bool>().toSet();
        }
        final typeArg = expr.typeArguments?.arguments.firstOrNull?.toSource();
        if (items.isEmpty) {
          if (typeArg == 'String') return <String>{};
          if (typeArg == 'int') return <int>{};
        }
        return items;
      }
    }
    if (expr is ast.TypeLiteral) {
      return expr.type.toSource();
    }
    if (expr is ast.PrefixedIdentifier) {
      final key = '${expr.prefix.name}.${expr.identifier.name}';
      if (_classStaticConsts.containsKey(key) && _evaluatingConsts.add(key)) {
        try {
          return _evalAstExpression(_classStaticConsts[key]);
        } finally {
          _evaluatingConsts.remove(key);
        }
      }
      return key;
    }
    if (expr is ast.SimpleIdentifier) {
      final key = expr.name;
      if (_currentClassName != null) {
        final classKey = '$_currentClassName.$key';
        if (_classStaticConsts.containsKey(classKey) && _evaluatingConsts.add(classKey)) {
          try {
            return _evalAstExpression(_classStaticConsts[classKey]);
          } finally {
            _evaluatingConsts.remove(classKey);
          }
        }
      }
      if (_topLevelConsts.containsKey(key) && _evaluatingConsts.add(key)) {
        try {
          return _evalAstExpression(_topLevelConsts[key]);
        } finally {
          _evaluatingConsts.remove(key);
        }
      }
      return key;
    }
    if (expr is ast.MethodInvocation) {
      if (expr.target == null && expr.methodName.name == 'Duration') {
        return _evalDurationArgs(expr.argumentList);
      }
    }
    if (expr is ast.InstanceCreationExpression) {
      final typeName = expr.constructorName.type.name.lexeme;
      if (typeName == 'Duration') {
        return _evalDurationArgs(expr.argumentList);
      }
    }
    return expr.toSource();
  }

  /// Evaluates a `Duration(...)` AST argument list into a [Duration] instance.
  Duration _evalDurationArgs(ast.ArgumentList argumentList) {
    int days = 0;
    int hours = 0;
    int minutes = 0;
    int seconds = 0;
    int milliseconds = 0;
    int microseconds = 0;

    for (final arg in argumentList.arguments) {
      if (arg is ast.NamedExpression) {
        final name = arg.name.label.name;
        final val = _evalAstExpression(arg.expression);
        final intVal = val is int ? val : (int.tryParse(val?.toString() ?? '') ?? 0);
        switch (name) {
          case 'days':
            days = intVal;
            break;
          case 'hours':
            hours = intVal;
            break;
          case 'minutes':
            minutes = intVal;
            break;
          case 'seconds':
            seconds = intVal;
            break;
          case 'milliseconds':
            milliseconds = intVal;
            break;
          case 'microseconds':
            microseconds = intVal;
            break;
        }
      }
    }

    return Duration(
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
      microseconds: microseconds,
    );
  }

  /// Checks whether a type annotation is nullable (ends with `?` or is `dynamic`).
  bool _isNullableType(ast.TypeAnnotation? type) {
    if (type == null) return true;
    if (type.question != null) return true;
    final src = type.toSource();
    return src.endsWith('?') || src == 'dynamic' || src == 'Object?';
  }

  /// Resolves a type annotation to a string.
  String _resolveType(ast.TypeAnnotation? type) {
    if (type == null) return 'dynamic';
    return type.toString();
  }

  /// Whether a name is private (starts with underscore).
  bool _isPrivateName(String name) => name.startsWith('_');

  /// Gets the start line number for an AST node.
  int _getStartLine(ast.AstNode node, List<String> lines) {
    if (lines.isEmpty) return 0;
    int charCount = 0;
    for (var i = 0; i < lines.length; i++) {
      charCount += lines[i].length + 1;
      if (charCount > node.offset) return i + 1;
    }
    return lines.length;
  }

  /// Resolves a file path to a package URI.
  String _resolveToPackageUri(String filePath, String packageName) {
    if (filePath.isEmpty) return '';

    final normalizedPath = p.normalize(filePath);

    final libSep = '${p.separator}lib${p.separator}';
    final libIndex = normalizedPath.lastIndexOf(libSep);
    if (libIndex != -1) {
      final relativePath = normalizedPath.substring(libIndex + libSep.length);
      return 'package:$packageName/$relativePath';
    }

    final currentProjectLibPath =
        p.normalize(p.join(Directory.current.path, 'lib'));
    if (p.isWithin(currentProjectLibPath, normalizedPath)) {
      final relativePath =
          p.relative(normalizedPath, from: currentProjectLibPath);
      final cleanedRelativePath =
          relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
      return 'package:$packageName/$cleanedRelativePath';
    }

    return 'file://$normalizedPath';
  }
}
