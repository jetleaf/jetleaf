part of 'runtime_provider.dart';
/// {@template cached_runtime_provider}
/// A [RuntimeProvider] subclass optimized for cache-mode operation.
///
/// When the runtime is loaded from a pre-built `.jetleaf/` cache instead of
/// a full mirror scan, expensive operations like `getSubClasses()` and
/// `collectAnnotatedMethods()` can use pre-computed JSON indexes instead of
/// walking `_ClassReference` trees.
///
/// Falls back to the parent implementation when indexes aren't loaded.
/// {@endtemplate}
final class CachedRuntimeProvider extends _MaterialRuntimeProvider {
  /// Pre-computed subclass index: `{qualifiedName: [childQualifiedNames]}`.
  ///
  /// Built by the VSCode builder extension and stored in
  /// `.jetleaf/subclasses.json`. Maps each class to its direct subclasses
  /// (via superclass, interfaces, and mixins).
  Map<String, List<String>>? _subclassIndex;
  /// Pre-computed annotated methods index: `{annotationName: [{class, method, uri}]}`.
  ///
  /// Built by the VSCode builder extension and stored in
  /// `.jetleaf/annotated_methods.json`.
  Map<String, dynamic>? _annotatedIndex;
  /// {@macro cached_runtime_provider}
  CachedRuntimeProvider._() : super._();
  /// Loads pre-computed indexes from the given [directory]'s `.jetleaf/` folder.
  ///
  /// If the index files don't exist or can't be parsed, the indexes stay
  /// `null` and the parent class methods are used instead.
  ///
  /// When [forTests] is true, checks `.jetleaf/test/` first (since test
  /// caches include test-defined classes that production caches don't have).
  Future<void> loadPrecomputedIndexes(Directory directory, {bool forTests = false}) async {
    await _loadSubclassIndex(directory, forTests: forTests);
    await _loadAnnotatedIndex(directory, forTests: forTests);
  }

  void loadPrecomputedIndexesSync(Directory directory, {bool forTests = false}) {
    _loadSubclassIndexSync(directory, forTests: forTests);
    _loadAnnotatedIndexSync(directory, forTests: forTests);
  }
  /// Whether pre-computed indexes are loaded and ready to use.
  bool get hasPrecomputedIndexes =>
      _subclassIndex != null || _annotatedIndex != null;
  // ── Subclass index loading ──────────────────────────────────────────
  Future<void> _loadSubclassIndex(Directory directory, {bool forTests = false}) async {
    // Production: only check production cache.
    // Test: check test cache first (includes test-defined classes),
    //       then fall back to production (for shared library classes).
    final candidates = forTests
        ? [
            JetleafPaths.subclassesJson(directory, forTests: true),
            JetleafPaths.subclassesJson(directory),
          ]
        : [
            JetleafPaths.subclassesJson(directory),
          ];
    for (final file in candidates) {
      try {
        if (!file.existsSync()) continue;
        final content = await file.readAsString();
        final Map<String, dynamic> raw = jsonDecode(content);
        _subclassIndex = raw.map((key, value) =>
            MapEntry(key, (value as List<dynamic>).cast<String>()));
        return;
      } catch (_) {}
    }
  }

  void _loadSubclassIndexSync(Directory directory, {bool forTests = false}) {
    final candidates = forTests
        ? [
            JetleafPaths.subclassesJson(directory, forTests: true),
            JetleafPaths.subclassesJson(directory),
          ]
        : [
            JetleafPaths.subclassesJson(directory),
          ];
    for (final file in candidates) {
      try {
        if (!file.existsSync()) continue;
        final content = file.readAsStringSync();
        final Map<String, dynamic> raw = jsonDecode(content);
        _subclassIndex = raw.map((key, value) =>
            MapEntry(key, (value as List<dynamic>).cast<String>()));
        return;
      } catch (_) {}
    }
  }

  // ── Annotated methods index loading ─────────────────────────────────
  Future<void> _loadAnnotatedIndex(Directory directory, {bool forTests = false}) async {
    final candidates = forTests
        ? [
            JetleafPaths.annotatedMethodsJson(directory, forTests: true),
            JetleafPaths.annotatedMethodsJson(directory),
          ]
        : [
            JetleafPaths.annotatedMethodsJson(directory),
          ];
    for (final candidate in candidates) {
      try {
        if (!candidate.existsSync()) continue;
        final content = await candidate.readAsString();
        _annotatedIndex = (jsonDecode(content) as Map).cast<String, dynamic>();
        return;
      } catch (_) {}
    }
  }

  void _loadAnnotatedIndexSync(Directory directory, {bool forTests = false}) {
    final candidates = forTests
        ? [
            JetleafPaths.annotatedMethodsJson(directory, forTests: true),
            JetleafPaths.annotatedMethodsJson(directory),
          ]
        : [
            JetleafPaths.annotatedMethodsJson(directory),
          ];
    for (final candidate in candidates) {
      try {
        if (!candidate.existsSync()) continue;
        final content = candidate.readAsStringSync();
        _annotatedIndex = (jsonDecode(content) as Map).cast<String, dynamic>();
        return;
      } catch (_) {}
    }
  }
  // ── Overridden methods ──────────────────────────────────────────────
  @override
  Iterable<ClassDeclaration> getSubClasses(ClassDeclaration classDeclaration) sync* {
    if (_subclassIndex case final index?) {
      final qualifiedName = classDeclaration.getQualifiedName();
      final bareName = classDeclaration.getName();
      final childNames = index[qualifiedName] ?? index[bareName];
      if (childNames != null && childNames.isNotEmpty) {
        final result = <ClassDeclaration>[];
        final visited = <String>{};
        _resolveTransitiveChildren(childNames, index, result, visited);
        // Final dedup by qualified name — catches any duplicates from
        // the same class being reachable via multiple index key formats
        final deduped = <ClassDeclaration>[];
        final seen = <String>{};
        for (final decl in result) {
          if (seen.add(decl.getQualifiedName())) {
            deduped.add(decl);
          }
        }
        _classDeclarationSubClassCache[qualifiedName] = deduped;
        yield* deduped;
        return;
      }
      // Key not in index — fall through to mirror-based search
    }
    yield* super.getSubClasses(classDeclaration);
  }
  /// Recursively resolves all transitive children from the flat index.
  ///
  /// Deduplicates by the resolved declaration's qualified name, which is
  /// stable regardless of whether the index uses bare or qualified keys.
  void _resolveTransitiveChildren(
    List<String> childNames,
    Map<String, List<String>> index,
    List<ClassDeclaration> result,
    Set<String> visited,
  ) {
    for (final childName in childNames) {
      if (visited.contains(childName)) continue;
      final resolved = _resolveChildClass(childName);
      if (resolved == null) continue;
      // Deduplicate by the resolved declaration's own qualified name
      final qn = resolved.getQualifiedName();
      if (!visited.add(qn)) continue;
      result.add(resolved);
      // Recurse: try qualified name first, then bare name
      final bareName = childName.contains('#') ? childName.split('#').last : childName;
      final grandchildren = index[childName] ?? index[bareName];
      if (grandchildren != null && grandchildren.isNotEmpty) {
        _resolveTransitiveChildren(grandchildren, index, result, visited);
      }
    }
  }
  /// Resolves a child class by qualified or bare name.
  ///
  /// Tries multiple strategies:
  /// 1. Qualified name cache / _sourceLibraries lookup
  /// 2. Bare name cache / mirror lookup
  /// 3. Direct mirror search across all libraries
  ClassDeclaration? _resolveChildClass(String childName) {
    // Strategy 1: standard qualified name lookup
    try {
      return findClassByQualifiedName(childName);
    } catch (_) {}
    // Strategy 2: extract bare name and try findClassByName
    final bareName = childName.contains('#')
        ? childName.split('#').last
        : childName;
    try {
      return findClassByName(bareName);
    } catch (_) {}
    return null;
  }
  @override
  Iterable<MethodDeclaration> collectAnnotatedMethods<T>([bool onlyJetleafPackages = true]) sync* {
    if (_annotatedIndex == null) {
      _autoWarmFromCache();
    }
    // Fast path: use pre-computed annotated methods index
    if (_annotatedIndex case final index?) {
      final typeName = '$T';
      // Extract the simple name from the generic type string
      // e.g., "MyAnnotation" from "MyAnnotation" or "Instance of 'MyAnnotation'"
      final simpleName = typeName.contains('.')
          ? typeName.split('.').last
          : typeName;
      final entries = index[simpleName] as List<dynamic>?;
      if (entries == null || entries.isEmpty) return;
      if (_annotatedMethodCache[T] case final cached?) {
        yield* cached;
        return;
      }
      final seen = <String>{};
      final results = <MethodDeclaration>[];
      for (final entry in entries) {
        if (entry is! Map) continue;
        final className = entry['class']?.toString() ?? '';
        final methodName = entry['method']?.toString() ?? '';
        final uri = entry['uri']?.toString() ?? '';
        final id = '$uri#$className.$methodName';
        if (!seen.add(id)) continue;
        try {
          ClassDeclaration classDecl;
          try {
            classDecl = findClassByQualifiedName('$uri.$className');
          } catch (_) {
            try {
              classDecl = findClassByQualifiedName('$uri#$className');
            } catch (_) {
              classDecl = findClassByQualifiedName(className);
            }
          }
          final method = classDecl.getMethods().where((m) => m.getName() == methodName).firstOrNull;
          if (method != null) {
            results.add(method);
          }
        } catch (_) {}
      }
      _annotatedMethodCache[T] = results;
      yield* results;
      return;
    }
    // Slow path: delegate to parent (mirror-based scan)
    yield* super.collectAnnotatedMethods<T>(onlyJetleafPackages);
  }
}