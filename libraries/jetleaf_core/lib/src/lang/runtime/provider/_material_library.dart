// ignore_for_file: unused_element
part of 'runtime_provider.dart';

/// {@template _unresolved_class}
/// Represents a class that could not be fully resolved or identified
/// during runtime analysis or reflection.
/// {@endtemplate}
final class _UnresolvedClass implements UnresolvedClass {
  final String _qualifiedName;
  final String _name;

  _UnresolvedClass(this._name, this._qualifiedName);

  @override
  String getName() => _name;

  @override
  String getQualifiedName() => _qualifiedName;

  @override
  String toString() => "UnresolvedClass($_name **** $_qualifiedName)";

  @override
  List<Object?> equalizedProperties() => [_name, _qualifiedName];
}

// ====================================================== MATERIAL LIBRARY ==============================================================

/// {@template material_library_impl}
/// Pure Dart in-memory implementation of the [MaterialLibrary] interface.
///
/// Manages class declarations, method discovery, and source library metadata
/// entirely without reflection or `dart:mirrors`.
/// {@endtemplate}
abstract final class _MaterialLibrary with EqualsAndHashCode implements MaterialLibrary {
  String _taggedLocation = "$MaterialLibrary";

  List<_SourceLibrary> _sourceLibraries = [];
  bool _cacheWarmed = false;

  final HashMap<Type, ClassDeclaration> _typeCache = HashMap();
  final HashMap<String, ClassDeclaration> _nameCache = HashMap();
  final HashSet<String> _missingNameCache = HashSet();
  final LinkedHashMap<String, ClassDeclaration> _qualifiedNameCache = LinkedHashMap();
  final LinkedHashMap<String, List<ClassDeclaration>> _classDeclarationSubClassCache = LinkedHashMap();
  final LinkedHashMap<String, List<_ClassReference>> _qualifiedNameSubClassCache = LinkedHashMap();
  final LinkedHashMap<Type, List<_ClassReference>> _typedSubClassCache = LinkedHashMap();
  final LinkedHashMap<Type, List<MethodDeclaration>> _annotatedMethodCache = LinkedHashMap();

  void setTaggedLocation(String location) {
    _taggedLocation = location;
  }

  String getTaggedLocation() => _taggedLocation;

  void addLibrary(Package package, String sourceCode, bool isSdkLibrary, dynamic library) {
    if (_sourceLibraries is UnmodifiableListView) return;
    final uri = library is Uri ? library : (library is String ? Uri.parse(library) : Uri.parse('unknown'));
    final source = _SourceLibrary(package, sourceCode, isSdkLibrary, uri);
    _sourceLibraries.add(source);
  }

  void freezeLibrary() {
    if (_sourceLibraries is UnmodifiableListView) return;
    _sourceLibraries = List<_SourceLibrary>.unmodifiable(_sourceLibraries);
  }

  @override
  List<SourceLibrary> getSourceLibraries() => _sourceLibraries;

  @override
  SourceLibrary? getSourceLibrary(String identifier) {
    for (final lib in _sourceLibraries) {
      if (lib.getPackage().getName() == identifier || lib.getSourceLocation().toString() == identifier) {
        return lib;
      }
    }
    return null;
  }

  @override
  bool get isPopulated => _cacheWarmed || _sourceLibraries.isNotEmpty;

  @override
  bool get isBackgroundWarmupComplete => true;

  @override
  Future<void> awaitBackgroundWarmup() async {}

  @override
  void cleanup() {
    _cacheWarmed = false;
    _nameCache.clear();
    _missingNameCache.clear();
    _qualifiedNameCache.clear();
    _typeCache.clear();
    _classDeclarationSubClassCache.clear();
    _qualifiedNameSubClassCache.clear();
    _typedSubClassCache.clear();
    _annotatedMethodCache.clear();
  }

  @override
  void enablePeriodicCleanup({Duration interval = const Duration(minutes: 5)}) {}

  @override
  void provideMaxCacheSize(int cacheSize) {}

  void registerCachedDeclarations(List<ClassDeclaration> declarations) {
    if (declarations.isNotEmpty) {
      _cacheWarmed = true;
    }
    for (final decl in declarations) {
      _nameCache[decl.getName()] = decl;
      _qualifiedNameCache[decl.getQualifiedName()] = decl;
      try {
        final type = decl.getType();
        if (type != Object && type != dynamic) {
          _typeCache[type] = decl;
        }
      } catch (_) {}
    }
  }

  List<ClassDeclaration> getCachedDeclarations() => _nameCache.values.toList();

  void _autoWarmFromCache() {
    if (isPopulated) return;
    try {
      final startDirs = <Directory>[Directory.current];
      try {
        if (Platform.script.isScheme('file')) {
          startDirs.add(File(Platform.script.toFilePath()).parent);
        }
      } catch (_) {}

      for (var dir in startDirs) {
        for (int i = 0; i < 6; i++) {
          for (final targetName in [Constant.TEST_DIR_NAME, Constant.MAIN_DIR_NAME]) {
            final cacheDir = Directory(p.join(dir.path, Constant.WORKSPACE_DIR_NAME, Constant.CACHE_DIR_NAME, targetName));
            if (cacheDir.existsSync()) {
              final fpFile = File(p.join(cacheDir.path, 'fingerprint.txt'));
              File? targetBin;
              if (fpFile.existsSync()) {
                final fp = fpFile.readAsStringSync().trim();
                final namedBin = File(p.join(cacheDir.path, 'cache_$fp.bin'));
                if (namedBin.existsSync()) targetBin = namedBin;
              }
              if (targetBin == null) {
                final binFiles = cacheDir.listSync().whereType<File>().where((f) => f.path.endsWith('.bin')).toList();
                if (binFiles.isNotEmpty) {
                  binFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
                  targetBin = binFiles.first;
                }
              }
              if (targetBin != null) {
                final bytes = targetBin.readAsBytesSync();
                final result = CacheSerializer.deserialize(bytes);
                registerCachedDeclarations(result.components);
                if (this is _MaterialRuntimeProvider) {
                  final provider = this as _MaterialRuntimeProvider;
                  if (result.packages.isNotEmpty) {
                    provider.addPackages(result.packages);
                  }
                  if (result.assets.isNotEmpty) {
                    provider.addAssets(result.assets);
                  }
                }
                if (this is CachedRuntimeProvider) {
                  (this as CachedRuntimeProvider).loadPrecomputedIndexesSync(dir, forTests: targetName == 'test');
                }
                if (isPopulated) return;
              }
            }
          }
          final parent = dir.parent;
          if (parent.path == dir.path) break;
          dir = parent;
        }
      }
    } catch (_) {}
  }

  /// Real `dart:core` library files, kept in sync with the Dart SDK.
  /// Synthetic declarations for these intrinsic types should report their
  /// actual SDK source locations instead of the generic `package:synthetic`
  /// URI.
  static const Map<String, String> _dartCoreLibraries = {
    'Object': 'dart:core/object.dart',
    'String': 'dart:core/string.dart',
    'int': 'dart:core/int.dart',
    'num': 'dart:core/num.dart',
    'double': 'dart:core/double.dart',
    'bool': 'dart:core/bool.dart',
    'Symbol': 'dart:core/symbol.dart',
    'Null': 'dart:core/null.dart',
    'Enum': 'dart:core/enum.dart',
    'Function': 'dart:core/function.dart',
    'Type': 'dart:core/type.dart',
    'Iterable': 'dart:core/iterable.dart',
    'List': 'dart:core/list.dart',
    'Map': 'dart:core/map.dart',
    'Set': 'dart:core/set.dart',
    'DateTime': 'dart:core/date_time.dart',
    'Duration': 'dart:core/duration.dart',
    'Pattern': 'dart:core/pattern.dart',
    'RegExp': 'dart:core/regexp.dart',
    'StackTrace': 'dart:core/stacktrace.dart',
    'Stopwatch': 'dart:core/stopwatch.dart',
    'StringSink': 'dart:core/string_sink.dart',
    'BigInt': 'dart:core/bigint.dart',
    'Comparable': 'dart:core/comparable.dart',
  };

  ClassDeclaration _synthesizeClassDeclaration(Type type, String typeString) {
    final simpleName = typeString.contains('.') ? typeString.split('.').last : typeString;
    final coreLibrary = _dartCoreLibraries[simpleName];
    final libUri = coreLibrary ?? 'package:synthetic/$simpleName.dart';
    final pkg = MaterialPackage(
      name: coreLibrary == null ? 'synthetic' : 'dart:core',
      version: '0.0.0',
      isRootPackage: false,
      filePath: '',
      rootUri: coreLibrary == null ? 'package:synthetic/' : 'dart:core',
      jetleafDependencies: [],
      dependencies: [],
      devDependencies: [],
    );
    final syntheticLib = StandardLibraryDeclaration(
      uri: libUri,
      parentPackage: pkg,
      name: coreLibrary == null ? 'synthetic' : 'dart:core',
      isPublic: true,
      isSynthetic: true,
    );
    final decl = StandardClassDeclaration(
      name: simpleName,
      type: type,
      library: syntheticLib,
      isPublic: true,
      isSynthetic: true,
      qualifiedName: typeString.contains(':')
        ? typeString
        : (simpleName == 'Object' ||
            simpleName == 'String' ||
            simpleName == 'int' ||
            simpleName == 'double' ||
            simpleName == 'bool' ||
            simpleName == 'num' ||
            simpleName == 'Symbol' ||
            simpleName == 'Null' ||
            simpleName == 'Enum' ||
            simpleName == 'dynamic'
            ? 'dart:core.$simpleName'
            : 'package:synthetic/$simpleName.dart.$simpleName'),
    );
    final resolvedType = decl.getType();
    if (resolvedType != Object || simpleName == 'Object') {
      _typeCache[resolvedType] = decl;
    }
    _nameCache[simpleName] = decl;
    _nameCache[typeString] = decl;
    _qualifiedNameCache[decl.getQualifiedName()] = decl;
    _qualifiedNameCache['synthetic.$simpleName'] = decl;
    _qualifiedNameCache['dart:core.$simpleName'] = decl;
    _qualifiedNameCache[simpleName] = decl;
    _qualifiedNameCache[typeString] = decl;
    return decl;
  }

  @override
  ClassDeclaration findClass<T>([String? package]) => findClassByType(T, package);

  /// Normalizes the runtime [Type] of a Dart VM implementation class
  /// (e.g. `_Map<String, dynamic>`) to its public interface counterpart
  /// (`Map`) so reflection lookups resolve to registered declarations.
  Type _normalizeType(Type type) {
    switch (type.toString().split('<').first) {
      case '_Map':
      case '_HashMap':
      case 'UnmodifiableMapView':
        return Map;
      case '_Set':
      case '_HashSet':
      case 'UnmodifiableSetView':
        return Set;
      case 'EmptyIterable':
        return Iterable;
      case 'ListQueue':
        return Queue;
      case 'CastList':
        return List;
      case 'CastMap':
        return Map;
      case 'CastSet':
        return Set;
      case 'UnmodifiableListView':
        return List;
      case '_ControllerStream':
        return Stream;
      case '_ByteDataView':
        return ByteData;
      case '_Int8ArrayView':
        return Int8List;
      case '_Uint8ArrayView':
        return Uint8List;
      default:
        return type;
    }
  }

  @override
  ClassDeclaration findClassByType(Type type, [String? package]) {
    final normalizedType = _normalizeType(type);
    if (!identical(normalizedType, type)) {
      return findClassByType(normalizedType, package);
    }

    if (type == Object) {
      return _typeCache[Object] ?? _synthesizeClassDeclaration(Object, 'Object');
    }

    if (_typeCache[type] case final classDeclaration?) {
      return classDeclaration;
    }

    if (!isPopulated) {
      _autoWarmFromCache();
      if (_typeCache[type] case final classDeclaration?) {
        return classDeclaration;
      }
    }

    final typeString = type.toString();

    // 1. Scan qualified name cache for exact type match first
    for (final decl in _qualifiedNameCache.values) {
      if (package != null && decl.getLibrary().getPackage().getName() != package) {
        continue;
      }
      try {
        final declType = decl.getType();
        if (declType != Object && declType == type) {
          _typeCache[type] = decl;
          return decl;
        }
      } catch (_) {}
    }

    // 2. Fall back to name match if no exact type matched (exact name first)
    for (final decl in _qualifiedNameCache.values) {
      if (package != null && decl.getLibrary().getPackage().getName() != package) {
        continue;
      }
      if (decl.getName() == typeString) {
        _typeCache[type] = decl;
        return decl;
      }
    }

    // Check name cache as fallback
    if (_nameCache[typeString] case final decl?) {
      if (package == null || decl.getLibrary().getPackage().getName() == package) {
        _typeCache[type] = decl;
        return decl;
      }
    }

    // If package filter was specified and we didn't find it, retry without package filter
    if (package != null) {
      for (final decl in _qualifiedNameCache.values) {
        if (decl.getName() == typeString) {
          _typeCache[type] = decl;
          return decl;
        }
      }
      if (_nameCache[typeString] case final decl?) {
        _typeCache[type] = decl;
        return decl;
      }
    }

    return _synthesizeClassDeclaration(type, typeString);
  }

  @override
  ClassDeclaration findClassByName(String name, [String? package]) {
    final cacheKey = package != null ? '$package:$name' : name;
    if (_missingNameCache.contains(cacheKey)) {
      throw ImmaterialClassException(name);
    }

    if (_nameCache[name] case final classDeclaration?) {
      if (package == null || classDeclaration.getLibrary().getPackage().getName() == package) {
        return classDeclaration;
      }
    }

    if (!isPopulated) {
      _autoWarmFromCache();
      if (_nameCache[name] case final classDeclaration?) {
        if (package == null || classDeclaration.getLibrary().getPackage().getName() == package) {
          return classDeclaration;
        }
      }
    }

    for (final decl in _qualifiedNameCache.values) {
      if (decl.getName() == name) {
        if (package == null || decl.getLibrary().getPackage().getName() == package) {
          _nameCache[name] = decl;
          return decl;
        }
      }
    }

    // If package filter was specified and not found, retry without package filter
    if (package != null) {
      if (_nameCache[name] case final classDeclaration?) {
        return classDeclaration;
      }
      for (final decl in _qualifiedNameCache.values) {
        if (decl.getName() == name) {
          _nameCache[name] = decl;
          return decl;
        }
      }
    }

    _missingNameCache.add(cacheKey);

    // Synthesize a best-effort declaration instead of hard-failing —
    // mirrors `findClassByType` for core types such as `String`/`Function`.
    try {
      final resolved = StandardDeclaration.resolveType(name);
      final synth = _synthesizeClassDeclaration(resolved, name);
      _missingNameCache.remove(cacheKey);
      return synth;
    } catch (_) {
      throw ImmaterialClassException(name);
    }
  }

  @override
  ClassDeclaration findClassByQualifiedName(String qualifiedName) {
    if (_qualifiedNameCache[qualifiedName] case final classDeclaration?) {
      return classDeclaration;
    }

    if (!isPopulated) {
      _autoWarmFromCache();
      if (_qualifiedNameCache[qualifiedName] case final classDeclaration?) {
        return classDeclaration;
      }
    }

    if (_nameCache[qualifiedName] case final classDeclaration?) {
      return classDeclaration;
    }

    // Try boundary suffix match (.name or #name) if package URI format differs slightly
    for (final entry in _qualifiedNameCache.entries) {
      if (entry.key == qualifiedName ||
          entry.key.endsWith('.$qualifiedName') ||
          entry.key.endsWith('#$qualifiedName')) {
        return entry.value;
      }
    }

    // Standard Dart SDK core types
    switch (qualifiedName) {
      case 'String' || 'dart:core.String':
        return _synthesizeClassDeclaration(String, 'String');
      case 'int' || 'dart:core.int':
        return _synthesizeClassDeclaration(int, 'int');
      case 'double' || 'dart:core.double':
        return _synthesizeClassDeclaration(double, 'double');
      case 'bool' || 'dart:core.bool':
        return _synthesizeClassDeclaration(bool, 'bool');
      case 'num' || 'dart:core.num':
        return _synthesizeClassDeclaration(num, 'num');
      case 'Symbol' || 'dart:core.Symbol':
        return _synthesizeClassDeclaration(Symbol, 'Symbol');
      case 'Null' || 'dart:core.Null':
        return _synthesizeClassDeclaration(Null, 'Null');
      case 'Enum' || 'dart:core.Enum':
        return _synthesizeClassDeclaration(Enum, 'Enum');
      case 'Object' || 'dart:core.Object':
        return _synthesizeClassDeclaration(Object, 'Object');
      case 'dynamic' || 'dart:core.dynamic':
        return _synthesizeClassDeclaration(dynamic, 'dynamic');
    }

    return _synthesizeClassDeclaration(Object, qualifiedName);
  }

  @override
  ClassDeclaration obtainClassDeclaration(Object object, [String? package]) {
    return findClassByType(object.runtimeType, package);
  }

  @override
  Iterable<ClassDeclaration> getSubClasses(ClassDeclaration classDeclaration) {
    if (!isPopulated) _autoWarmFromCache();
    final key = classDeclaration.getQualifiedName();
    if (_classDeclarationSubClassCache[key] case final cached?) {
      return cached;
    }

    final subclasses = <ClassDeclaration>[];
    for (final candidate in _qualifiedNameCache.values.toList()) {
      if (candidate == classDeclaration) continue;
      if (isSubclassOf(candidate, classDeclaration)) {
        subclasses.add(candidate);
      }
    }

    _classDeclarationSubClassCache[key] = subclasses;
    return subclasses;
  }

  @override
  Iterable<ClassReference> getSubClassReferences(String qualifiedName) {
    if (!isPopulated) _autoWarmFromCache();
    if (_qualifiedNameSubClassCache[qualifiedName] case final cached?) {
      return cached;
    }

    final parentDecl = _qualifiedNameCache[qualifiedName] ?? _nameCache[qualifiedName];
    if (parentDecl == null) return const [];

    final subclasses = getSubClasses(parentDecl);
    final refs = subclasses.map((c) => _ClassReference.fromDeclaration(c)).toList();
    _qualifiedNameSubClassCache[qualifiedName] = refs;
    return refs;
  }

  Iterable<ClassReference> getTypedSubClassesOf(Type type) {
    if (!isPopulated) _autoWarmFromCache();
    if (_typedSubClassCache[type] case final cached?) {
      return cached;
    }

    final parentDecl = _typeCache[type] ?? _nameCache[type.toString()];
    if (parentDecl == null) return const [];

    final subclasses = getSubClasses(parentDecl);
    final refs = subclasses.map((c) => _ClassReference.fromDeclaration(c)).toList();
    _typedSubClassCache[type] = refs;
    return refs;
  }

  bool isSubclassOf(ClassDeclaration candidate, ClassDeclaration parentClass, [Set<String>? visited]) {
    if (candidate == parentClass) return true;
    final v = visited ?? <String>{};
    final candidateKey = candidate.getQualifiedName();
    if (!v.add(candidateKey)) return false;

    final parentName = parentClass.getName();
    final parentQn = parentClass.getQualifiedName();

    final superClass = candidate.getSuperClass();
    if (superClass != null) {
      final scName = superClass.getName();
      final scQn = superClass.getPointerQualifiedName();
      if (scName == parentName || scQn == parentQn) {
        return true;
      }
      final superDecl = _qualifiedNameCache[scQn] ?? _nameCache[scName];
      if (superDecl != null && superDecl != candidate && isSubclassOf(superDecl, parentClass, v)) {
        return true;
      }
    }

    for (final iface in candidate.getInterfaces()) {
      final ifaceName = iface.getName();
      final ifaceQn = iface.getPointerQualifiedName();
      if (ifaceName == parentName || ifaceQn == parentQn) {
        return true;
      }
      final ifaceDecl = _qualifiedNameCache[ifaceQn] ?? _nameCache[ifaceName];
      if (ifaceDecl != null && ifaceDecl != candidate && isSubclassOf(ifaceDecl, parentClass, v)) {
        return true;
      }
    }

    return false;
  }

  @override
  Iterable<ClassDeclaration> getAllClasses() {
    if (!isPopulated) _autoWarmFromCache();
    return _qualifiedNameCache.values.toList();
  }

  @override
  Iterable<ClassDeclaration> getAllClassesInAPackage(String packageName) {
    if (!isPopulated) _autoWarmFromCache();
    return _qualifiedNameCache.values.where((c) => c.getLibrary().getPackage().getName() == packageName).toList();
  }

  @override
  Iterable<ClassDeclaration> getAllClassesInAPackageUri(String packageUri) {
    if (!isPopulated) _autoWarmFromCache();
    return _qualifiedNameCache.values.where((c) =>
        c.getPackageUri() == packageUri ||
        c.getLibrary().getUri().toString() == packageUri ||
        c.getQualifiedName().startsWith(packageUri)).toList();
  }

  @override
  Iterable<MethodDeclaration> collectAnnotatedMethods<T>([bool onlyJetleafPackages = true]) {
    if (!isPopulated) _autoWarmFromCache();
    final typeName = T.toString();
    final results = <MethodDeclaration>[];

    for (final classDecl in _qualifiedNameCache.values.toList()) {
      if (onlyJetleafPackages) {
        final pkg = classDecl.getLibrary().getPackage();
        if (pkg.getJetleafDependencies().isEmpty && !pkg.getName().startsWith('jetleaf')) {
          continue;
        }
      }

      for (final method in classDecl.getMethods()) {
        for (final annotation in method.getAnnotations()) {
          final annName = annotation.getName();
          final annType = annotation.getType();
          if (annType == T || annName == typeName || annName.endsWith(typeName)) {
            results.add(method);
            break;
          }
        }
      }
    }

    return results;
  }

  @override
  Iterable<MethodDeclaration> getAllMethods() {
    if (!isPopulated) _autoWarmFromCache();
    final methods = <MethodDeclaration>[];
    for (final classDecl in _qualifiedNameCache.values) {
      methods.addAll(classDecl.getMethods());
    }
    return methods;
  }

  @override
  Iterable<MethodDeclaration> getAllJetleafDependentMethods() {
    if (!isPopulated) _autoWarmFromCache();
    final methods = <MethodDeclaration>[];
    for (final classDecl in _qualifiedNameCache.values) {
      final pkg = classDecl.getLibrary().getPackage();
      if (pkg.getJetleafDependencies().isNotEmpty || pkg.getName().startsWith('jetleaf')) {
        methods.addAll(classDecl.getMethods());
      }
    }
    return methods;
  }

  @override
  Iterable<UnresolvedClass> getUnresolvedClasses() => const [];

  @override
  Iterable<UnresolvedClass> getPackageUnresolvedClasses(String packageName) => const [];

  @override
  List<Object?> equalizedProperties() => [_taggedLocation, _sourceLibraries, _qualifiedNameCache];
}