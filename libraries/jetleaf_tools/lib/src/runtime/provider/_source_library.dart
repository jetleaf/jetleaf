// ignore_for_file: unused_field, unused_element
part of 'runtime_provider.dart';

/// {@template source_library}
/// Represents a Dart source library analyzed at runtime.
///
/// This class encapsulates a library's core metadata and source code,
/// providing access to its package, URI, source content, and whether
/// it belongs to the Dart SDK.
/// {@endtemplate}
final class _SourceLibrary implements SourceLibrary {
  /// The package to which this library belongs.
  final Package _package;

  /// The URI of this library.
  final Uri _uri;

  /// The raw source code of the library.
  final String _sourceCode;

  /// Whether this library is part of the Dart SDK.
  final bool _isSdkLibrary;

  /// The hierarchy level of the library, used internally for sorting or analysis.
  int _hierarchy = -1;

  /// Holds all **class references** discovered within a library.
  final List<_ClassReference> _classReferences = [];

  /// {@macro source_library}
  _SourceLibrary(this._package, this._sourceCode, this._isSdkLibrary, this._uri);

  /// Adds a class reference to this library.
  void addClassReference(_ClassReference ref) => _classReferences.add(ref);

  void _setHierarchy(int value) => _hierarchy = value;

  @override
  Uri getSourceLocation() => _uri;

  @override
  String getDebugIdentifier() => _isSdkLibrary ? "[dart_sdk]:::$_uri" : "[lib]:::$_uri";

  @override
  Package getPackage() => _package;

  String getSourceCode() => _sourceCode;

  @override
  String sourceCode() => _sourceCode;

  @override
  bool isSdkLibrary() => _isSdkLibrary;

  @override
  List<ClassReference> getClassReferences() => List.unmodifiable(_classReferences);

  @override
  String getUri() => _uri.toString();

  @override
  String getName() => _uri.toString();

  @override
  List<Object?> equalizedProperties() => [_uri, _package];

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write(_isSdkLibrary ? "SdkLibrary" : "SourceLibrary");
    buffer.write("($_uri, package: ${_package.getName()}");
    final count = _classReferences.length;
    buffer.write(", $count ${count == 1 ? 'class' : 'classes'}");
    if (_classReferences.isNotEmpty) {
      if (count == 1) {
        buffer.write(" (${_classReferences.first._qualifiedName})");
      } else {
        buffer.write(" (${_classReferences.map((c) => c._qualifiedName).join(', ')})");
      }
    }
    buffer.write(")");
    return buffer.toString();
  }
}

/// Concrete implementation of [ClassReference] using static AST declarations.
final class _ClassReference extends ClassReference {
  final String _qualifiedName;
  final Type _type;
  final ClassDeclaration? _declaration;
  _ClassReference? _superClass;
  List<_ClassReference>? _interfaces;
  final List<_AnnotatedMethodReference> _annotatedMethods = [];

  _ClassReference({
    required String qualifiedName,
    required Type type,
    ClassDeclaration? declaration,
    _ClassReference? superClass,
    List<_ClassReference>? interfaces,
  })  : _qualifiedName = qualifiedName,
        _type = type,
        _declaration = declaration,
        _superClass = superClass,
        _interfaces = interfaces;

  factory _ClassReference.fromDeclaration(ClassDeclaration decl) {
    return _ClassReference(
      qualifiedName: decl.getQualifiedName(),
      type: decl.getType(),
      declaration: decl,
    );
  }

  @override
  String getQualifiedName() => _qualifiedName;

  @override
  Type getType() => _type;

  ClassDeclaration? getDeclaration() => _declaration;

  @override
  ClassReference? getSuperClass() => _superClass;

  @override
  List<ClassReference> getInterfaces() => _interfaces ?? const [];

  @override
  List<Object?> equalizedProperties() => [_qualifiedName, _type];

  @override
  String toString() => "ClassReference($_qualifiedName)";
}

/// Reference to a method that has an annotation.
final class _AnnotatedMethodReference {
  final String methodName;
  final Object annotation;
  final String qualifiedName;

  const _AnnotatedMethodReference({
    required this.methodName,
    required this.annotation,
    required this.qualifiedName,
  });
}
