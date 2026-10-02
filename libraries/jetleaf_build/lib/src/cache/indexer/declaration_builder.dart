import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:path/path.dart' as p;

import '../../runtime/declaration/declaration.dart';
import 'discovered_files.dart';

/// Builds declarations from discovered files using the analyzer.
///
/// Returns [ClassDeclaration] objects directly — no intermediate
/// representation needed.
final class DeclarationBuilder {
  /// Builds class declarations from discovered files.
  Future<List<ClassDeclaration>> build({required DiscoveredFiles files, required String packageName}) async {
    final components = <ClassDeclaration>[];

    for (final file in files.getAnalyzableDartFiles()) {
      try {
        final owner = files.packageNames[file.path] ??
            files.packageNames[file.absolute.path] ??
            packageName;
        final classes = await _buildLibrary(file, owner);
        components.addAll(classes);
      } catch (_) {
        // Skip files that can't be parsed
      }
    }

    return components;
  }

  /// Builds class declarations from a single Dart file.
  Future<List<ClassDeclaration>> _buildLibrary(File file, String packageName) async {
    final content = await file.readAsString();
    final result = parseString(content: content);

    final unit = result.unit;
    final declarations = <ClassDeclaration>[];
    final lines = content.split('\n');
    final uri = _resolveToPackageUri(file.path, packageName);

    // Create a library declaration for this file
    final library = StandardLibraryDeclaration(
      uri: uri,
      name: uri,
      isPublic: true,
      isSynthetic: false,
      parentPackage: MaterialPackage(
        name: packageName,
        version: 'unknown',
        isRootPackage: false,
        filePath: null,
        rootUri: null,
        dependencies: const [],
        devDependencies: const [],
        jetleafDependencies: const [],
      ),
    );

    // Extract declarations
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
    final isPublic = !_isPrivateName(name);

    // Build constructors
    final constructors = <ConstructorDeclaration>[];
    final fields = <FieldDeclaration>[];
    final methods = <MethodDeclaration>[];
    final annotations = <AnnotationDeclaration>[];

    if (node.body is ast.BlockClassBody) {
      final members = (node.body as ast.BlockClassBody).members;
      for (final member in members) {
        if (member is ast.ConstructorDeclaration) {
          constructors.add(_buildConstructor(member, name, library));
        } else if (member is ast.FieldDeclaration) {
          fields.addAll(_buildFields(member, name, library));
        } else if (member is ast.MethodDeclaration) {
          methods.add(_buildMethod(member, name, library));
        }
      }
    }

    // Build annotations
    for (final meta in node.metadata) {
      annotations.add(_buildAnnotation(meta.name.name, library));
    }

    // Extract superclass
    StandardLinkDeclaration? superClass;
    if (node.extendsClause != null) {
      final superName = node.extendsClause!.superclass.name.lexeme;
      superClass = StandardLinkDeclaration(
        name: superName,
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: superName,
      );
    }

    // Extract interfaces
    final interfaces = <StandardLinkDeclaration>[];
    if (node.implementsClause != null) {
      for (final iface in node.implementsClause!.interfaces) {
        interfaces.add(StandardLinkDeclaration(
          name: iface.name.lexeme,
          type: Object,
          isPublic: true,
          isSynthetic: false,
          pointerType: Object,
          qualifiedName: iface.name.lexeme,
        ));
      }
    }

    // Extract mixins
    final mixins = <StandardLinkDeclaration>[];
    if (node.withClause != null) {
      for (final mixin in node.withClause!.mixinTypes) {
        mixins.add(StandardLinkDeclaration(
          name: mixin.name.lexeme,
          type: Object,
          isPublic: true,
          isSynthetic: false,
          pointerType: Object,
          qualifiedName: mixin.name.lexeme,
        ));
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
      annotations: annotations,
      sourceLocation: Uri.parse('$uri:${_getStartLine(node, lines)}'),
      isAbstract: node.abstractKeyword != null,
      isMixin: false,
      isSealed: node.sealedKeyword != null,
      isBase: node.baseKeyword != null,
      isInterface: node.interfaceKeyword != null,
      qualifiedName: '$uri.$name',
      isFinal: node.finalKeyword != null,
      isRecord: false,
      packageUri: uri,
      simpleName: name,
      kind: TypeKind.classType,
    );
  }

  /// Builds a mixin declaration from an AST node.
  ClassDeclaration _buildMixin(ast.MixinDeclaration node, String uri, List<String> lines, LibraryDeclaration library) {
    final name = node.name.lexeme;
    final isPublic = !_isPrivateName(name);

    final methods = <MethodDeclaration>[];
    for (final member in node.body.members) {
      if (member is ast.MethodDeclaration) {
        methods.add(_buildMethod(member, name, library));
      }
    }

    final annotations = <AnnotationDeclaration>[];
    for (final meta in node.metadata) {
      annotations.add(_buildAnnotation(meta.name.name, library));
    }

    return StandardClassDeclaration(
      name: name,
      type: Object,
      isPublic: isPublic,
      isSynthetic: false,
      library: library,
      constructors: const [],
      fields: const [],
      methods: methods,
      superClass: null,
      interfaces: const [],
      mixins: const [],
      annotations: annotations,
      sourceLocation: Uri.parse('$uri:${_getStartLine(node, lines)}'),
      isAbstract: false,
      isMixin: true,
      isSealed: false,
      isBase: node.baseKeyword != null,
      isInterface: false,
      qualifiedName: '$uri.$name',
      isFinal: false,
      isRecord: false,
      packageUri: uri,
      simpleName: name,
      kind: TypeKind.mixinType,
    );
  }

  /// Builds an enum declaration from an AST node.
  ClassDeclaration _buildEnum(ast.EnumDeclaration node, String uri, List<String> lines, LibraryDeclaration library) {
    final name = node.namePart.typeName.lexeme;
    final isPublic = !_isPrivateName(name);

    final constructors = <ConstructorDeclaration>[];
    final methods = <MethodDeclaration>[];
    final annotations = <AnnotationDeclaration>[];

    for (final member in node.body.members) {
      if (member is ast.ConstructorDeclaration) {
        constructors.add(_buildConstructor(member, name, library));
      } else if (member is ast.MethodDeclaration) {
        methods.add(_buildMethod(member, name, library));
      }
    }

    for (final meta in node.metadata) {
      annotations.add(_buildAnnotation(meta.name.name, library));
    }

    // Extract enum values
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
        linkDeclaration: StandardLinkDeclaration(
          name: constant.name.lexeme,
          type: Object,
          isPublic: true,
          isSynthetic: false,
          pointerType: Object,
          qualifiedName: '$uri.$name.${constant.name.lexeme}',
        ),
      ));
    }

    return StandardEnumDeclaration(
      name: name,
      type: Object,
      isPublic: isPublic,
      isSynthetic: false,
      library: library,
      constructors: constructors,
      fields: const [],
      methods: methods,
      superClass: null,
      interfaces: const [],
      mixins: const [],
      annotations: annotations,
      sourceLocation: Uri.parse('$uri:${_getStartLine(node, lines)}'),
      isAbstract: false,
      qualifiedName: '$uri.$name',
      values: enumValues,
    );
  }

  /// Builds a constructor declaration from an AST node.
  ConstructorDeclaration _buildConstructor(ast.ConstructorDeclaration node, String className, LibraryDeclaration library) {
    final ctorName = node.name?.lexeme ?? '';
    final params = _buildParameters(node.parameters, library);

    return StandardConstructorDeclaration(
      name: ctorName,
      type: Object,
      isPublic: node.name == null || !_isPrivateName(ctorName),
      isSynthetic: false,
      parentClass: StandardLinkDeclaration(
        name: className,
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: className,
      ),
      parameters: params,
      annotations: const [],
      sourceLocation: null,
      isConst: node.constKeyword != null,
      isFactory: node.factoryKeyword != null,
    );
  }

  /// Builds field declarations from a field declaration node.
  List<FieldDeclaration> _buildFields(ast.FieldDeclaration node, String className, LibraryDeclaration library) {
    final fields = <FieldDeclaration>[];
    final typeName = _resolveType(node.fields.type);

    for (final field in node.fields.variables) {
      fields.add(StandardFieldDeclaration(
        name: field.name.lexeme,
        type: Object,
        parentClass: StandardLinkDeclaration(
          name: className,
          type: Object,
          isPublic: true,
          isSynthetic: false,
          pointerType: Object,
          qualifiedName: className,
        ),
        linkDeclaration: StandardLinkDeclaration(
          name: typeName,
          type: Object,
          isPublic: true,
          isSynthetic: false,
          pointerType: Object,
          qualifiedName: typeName,
        ),
        annotations: const [],
        isPublic: !_isPrivateName(field.name.lexeme),
        isSynthetic: false,
        sourceLocation: null,
        isStatic: node.isStatic,
        isLate: node.fields.isLate,
        isConst: node.fields.isConst,
        isFinal: node.fields.isFinal || node.fields.isConst,
        isNullable: typeName.endsWith('?'),
      ));
    }

    return fields;
  }

  /// Builds a method declaration from an AST node.
  MethodDeclaration _buildMethod(ast.MethodDeclaration node, String className, LibraryDeclaration library) {
    final returnType = _resolveType(node.returnType);
    final params = _buildParameters(node.parameters, library);
    final annotations = [
      for (final metadata in node.metadata)
        _buildAnnotation(metadata.name.name, library),
    ];

    return StandardMethodDeclaration(
      name: node.name.lexeme,
      type: Object,
      returnType: StandardLinkDeclaration(
        name: returnType,
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: returnType,
      ),
      parameters: params,
      annotations: annotations,
      isPublic: !_isPrivateName(node.name.lexeme),
      isSynthetic: false,
      sourceLocation: null,
      isStatic: node.isStatic,
      isAbstract: node.body is ast.EmptyFunctionBody,
      isExternal: false,
      isGetter: node.isGetter,
      isSetter: node.isSetter,
      parentClass: StandardLinkDeclaration(
        name: className,
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: className,
      ),
      hasNullableReturn: returnType.endsWith('?'),
    );
  }

  /// Builds parameter declarations from a parameter list.
  List<ParameterDeclaration> _buildParameters(ast.FormalParameterList? params, LibraryDeclaration library) {
    if (params == null) return [];

    final parameters = <ParameterDeclaration>[];
    var index = 0;

    for (final param in params.parameters) {
      String? name;
      String typeName = 'dynamic';
      bool isRequired = false;
      bool isOptional = false;
      bool isNamed = false;
      dynamic defaultValue;

      if (param is ast.SimpleFormalParameter) {
        name = param.name?.lexeme;
        typeName = _resolveType(param.type);
        isRequired = param.isRequired;
        isOptional = param.isOptional;
      } else if (param is ast.DefaultFormalParameter) {
        isNamed = param.isNamed;
        defaultValue = param.defaultValue;
        if (param.parameter is ast.SimpleFormalParameter) {
          final simple = param.parameter as ast.SimpleFormalParameter;
          name = simple.name?.lexeme;
          typeName = _resolveType(simple.type);
          isRequired = simple.isRequired;
          isOptional = simple.isOptional;
        } else if (param.parameter is ast.FieldFormalParameter) {
          final field = param.parameter as ast.FieldFormalParameter;
          name = field.name.lexeme;
          typeName = _resolveType(field.type);
          isRequired = field.isRequired;
          isOptional = field.isOptional;
        } else if (param.parameter is ast.SuperFormalParameter) {
          final superParam = param.parameter as ast.SuperFormalParameter;
          name = superParam.name.lexeme;
          typeName = _resolveType(superParam.type);
          isRequired = superParam.isRequired;
          isOptional = superParam.isOptional;
        }
      } else if (param is ast.FieldFormalParameter) {
        name = param.name.lexeme;
        typeName = _resolveType(param.type);
        isRequired = param.isRequired;
        isOptional = param.isOptional;
      } else if (param is ast.SuperFormalParameter) {
        name = param.name.lexeme;
        typeName = _resolveType(param.type);
        isRequired = param.isRequired;
        isOptional = param.isOptional;
      }

      if (name != null) {
        parameters.add(StandardParameterDeclaration(
          name: name,
          type: Object,
          typeDeclaration: StandardLinkDeclaration(
            name: typeName,
            type: Object,
            isPublic: true,
            isSynthetic: false,
            pointerType: Object,
            qualifiedName: typeName,
          ),
          isNullable: typeName.endsWith('?'),
          isRequired: isRequired,
          isOptional: isOptional,
          isNamed: isNamed,
          hasDefaultValue: defaultValue != null,
          defaultValue: defaultValue,
          index: index,
          isPublic: true,
          isSynthetic: false,
          sourceLocation: null,
          annotations: const [],
        ));
        index++;
      }
    }

    return parameters;
  }

  /// Builds an annotation declaration.
  AnnotationDeclaration _buildAnnotation(String name, LibraryDeclaration library) {
    return StandardAnnotationDeclaration(
      linkDeclaration: StandardLinkDeclaration(
        name: name,
        type: Object,
        isPublic: true,
        isSynthetic: false,
        pointerType: Object,
        qualifiedName: name,
      ),
      instance: null,
      isPublic: true,
      isSynthetic: false,
      name: name,
      type: Object,
      fields: const {},
      userProvidedValues: const {},
    );
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
