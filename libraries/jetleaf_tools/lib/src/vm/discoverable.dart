part of 'jetleaf_vm.dart';

/// {@template discoverable}
/// # Discoverable
///
/// Finds `@JetleafEntry` / `@JetleafTest` usages on top-level `void main()`.
///
/// Middle of the `EntryWriter → Discoverable → JetleafVM` chain: inherits
/// stub generation, adds analyzer discovery. Like [EntryWriter] it is
/// `abstract final` in a part file — extendable only inside the
/// `jetleaf_vm` library — with a `@protected` API surface. All helpers
/// are private static members: nothing in this unit lives outside a class.
///
/// {@endtemplate}
@internal
abstract final class Discoverable extends EntryWriter {
  /// {@macro discoverable}
  Discoverable();

  /// Discovers annotated entry points under [projectRoot].
  ///
  /// Only `void main()` functions are considered — annotations anywhere
  /// else (classes, non-main functions) are ignored and reported via
  /// [onWarning].
  ///
  /// Scans `lib/`, `bin/` and `test/` directly (no dependency packages);
  /// generated output (`_jetleaf/`, `.dart_tool/`, `build/`, `.jetleaf/`)
  /// is never scanned. With [only], just those files are scanned
  /// (`jl dev --path`) and nothing else is detected or booted.
  ///
  /// **Parameters:**
  /// - [projectRoot]: project root to scan.
  /// - [onWarning]: misuse sink (annotations outside `void main()`).
  /// - [only]: optional file allowlist (absolute or project-relative
  ///   `.dart` paths). Missing entries warn and are skipped.
  ///
  /// **Returns:** the [EntryRegistry] sorted by file path.
  @protected
  Future<EntryRegistry> discoverEntries(
    Directory projectRoot, {
    void Function(String message)? onWarning,
    List<String>? only,
  }) async {
    final found = <EntryRecord>[];

    if (only != null) {
      for (final raw in only) {
        final abs = p.isAbsolute(raw)
            ? p.normalize(raw)
            : p.normalize(p.join(projectRoot.path, raw));
        final file = File(abs);
        if (!abs.endsWith('.dart') || !await file.exists()) {
          onWarning?.call('scoped path skipped (not a Dart file): $raw');
          continue;
        }
        try {
          final record = await _scanEntryFile(projectRoot, file, onWarning);
          if (record != null) found.add(record);
        } catch (_) {
          // Skip files that can't be read or parsed.
        }
      }
      found.sort((a, b) => a.file.compareTo(b.file));
      return EntryRegistry(found);
    }

    for (final sub in ['lib', 'bin', 'test']) {
      final dir = Directory(p.join(projectRoot.path, sub));
      if (!await dir.exists()) continue;
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        try {
          final record = await _scanEntryFile(projectRoot, entity, onWarning);
          if (record != null) found.add(record);
        } catch (_) {
          // Skip files that can't be read or parsed.
        }
      }
    }

    found.sort((a, b) => a.file.compareTo(b.file));
    return EntryRegistry(found);
  }

  /// Parses a single file for an annotated top-level `main()`.
  ///
  /// **Parameters:**
  /// - [projectRoot]: root used for the project-relative file key.
  /// - [file]: candidate Dart file.
  /// - [onWarning]: misuse sink.
  ///
  /// **Returns:** the [EntryRecord], or null for bare mains and
  /// non-entry files (misuse still warns).
  static Future<EntryRecord?> _scanEntryFile(
    Directory projectRoot,
    File file,
    void Function(String message)? onWarning,
  ) async {
    final content = await file.readAsString();
    final result = parseString(content: content, throwIfDiagnostics: false);
    final relative = p.relative(file.path, from: projectRoot.path);

    for (final declaration in result.unit.declarations) {
      if (declaration is! ast.FunctionDeclaration) continue;
      if (declaration.name.lexeme != 'main') continue;

      for (final meta in declaration.metadata) {
        final name = _annotationName(meta);
        if (name == 'JetleafEntry' || name == 'JetleafTest') {
          final args = _stringListArg(meta, 0);
          return EntryRecord(
            file: relative,
            kind: name == 'JetleafTest' ? EntryKind.test : EntryKind.entry,
            args: args,
            timeoutSeconds: _namedIntArg(meta, 'timeoutSeconds', 60),
          );
        }
      }
      // A bare main() without our annotations is not an entry — keep
      // scanning in case a second main exists (invalid Dart, but harmless).
    }

    // User-facing Jetleaf applications use the framework starter annotation
    // on the application class rather than putting @JetleafEntry on main.
    // Treat that established application contract as the production entry,
    // while keeping ordinary bare Dart mains out of the registry.
    if (relative.startsWith('lib${p.separator}') &&
        content.contains('JetleafApplication.run(') &&
        content.contains('JetleafApplicationStarter')) {
      return EntryRecord(file: relative, kind: EntryKind.entry);
    }

    // Annotations on non-main declarations are misuse — warn loudly since
    // the user likely expected discovery.
    if (_mentionsJetleafEntry(content)) {
      onWarning?.call('$relative mentions @JetleafEntry/@JetleafTest '
          'outside void main(); ignored (targets: void main() only).');
    }
    return null;
  }

  /// Unqualified annotation name.
  ///
  /// **Parameters:**
  /// - [meta]: the annotation node.
  ///
  /// **Returns:** `JetleafEntry` for `@JetleafEntry()` and
  /// `@prefix.JetleafEntry()` alike.
  static String _annotationName(ast.Annotation meta) {
    final name = meta.name;
    if (name is ast.PrefixedIdentifier) return name.identifier.name;
    return name.toString();
  }

  /// Reads a positional string-list argument.
  ///
  /// **Parameters:**
  /// - [meta]: the annotation node.
  /// - [index]: positional argument index.
  ///
  /// **Returns:** the strings when argument [index] is a list literal,
  /// empty otherwise.
  static List<String> _stringListArg(ast.Annotation meta, int index) {
    try {
      final args = meta.arguments?.arguments;
      if (args == null || index >= args.length) return const [];
      final expr = args[index];
      if (expr is ast.ListLiteral) {
        return expr.elements
            .whereType<ast.SimpleStringLiteral>()
            .map((e) => e.value)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Reads a named integer argument.
  ///
  /// **Parameters:**
  /// - [meta]: the annotation node.
  /// - [name]: argument name (e.g. `timeoutSeconds`).
  /// - [fallback]: value when absent or malformed.
  ///
  /// **Returns:** the integer value or [fallback].
  static int _namedIntArg(ast.Annotation meta, String name, int fallback) {
    try {
      final args = meta.arguments?.arguments;
      if (args == null) return fallback;
      for (final arg in args.whereType<ast.NamedExpression>()) {
        if (arg.name.label.name == name &&
            arg.expression is ast.IntegerLiteral) {
          return (arg.expression as ast.IntegerLiteral).value ?? fallback;
        }
      }
    } catch (_) {}
    return fallback;
  }

  /// Checks annotation mentions for misuse warnings.
  ///
  /// **Parameters:**
  /// - [content]: raw file content.
  ///
  /// **Returns:** true when either entry annotation name appears anywhere.
  static bool _mentionsJetleafEntry(String content) =>
      content.contains('JetleafEntry') || content.contains('JetleafTest');
}

/// {@template entry_kind}
/// Kind of a discovered JetLeaf entry.
///
/// Internal to the `jetleaf_vm` library: produced by [Discoverable],
/// consumed by [JetleafVM].
///
/// {@endtemplate}
@internal
enum EntryKind {
  /// A `main()` annotated with `@JetleafEntry()` (production runtime).
  entry,

  /// A `main()` annotated with `@JetleafTest()` (test runtime).
  test,
}

/// {@template entry_record}
/// A single discovered entry: one annotated top-level `main()`.
///
/// Internal to the `jetleaf_vm` library: produced by [Discoverable],
/// tracked by [JetleafVM] via `EntryStatus`.
///
/// {@endtemplate}
@internal
final class EntryRecord {
  /// {@macro entry_record}
  const EntryRecord({
    required this.file,
    required this.kind,
    this.args = const [],
    this.timeoutSeconds = 60,
  });

  /// Project-relative file path using `/` separators.
  final String file;

  /// Whether this is an app entry or a test entry.
  final EntryKind kind;

  /// Args declared on the annotation, forwarded to `main` on invoke.
  final List<String> args;

  /// Only meaningful for [EntryKind.test].
  final int timeoutSeconds;

  /// `true` when [file] lives under `test/`.
  ///
  /// **Returns:** whether the test runtime applies.
  bool get forTests => kind == EntryKind.test;

  /// Serializes to a VM-state-compatible object.
  ///
  /// **Returns:** `{file, kind, args, timeoutSeconds}`.
  Map<String, Object?> toJson() => {
        'file': file,
        'kind': kind.name,
        'args': args,
        'timeoutSeconds': timeoutSeconds,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryRecord && file == other.file && kind == other.kind;

  @override
  int get hashCode => Object.hash(file, kind);

  @override
  String toString() => 'EntryRecord($file, ${kind.name})';
}

/// {@template entry_registry}
/// The full set of entries discovered in a project.
///
/// Internal to the `jetleaf_vm` library.
///
/// {@endtemplate}
@internal
final class EntryRegistry {
  /// {@macro entry_registry}
  const EntryRegistry([this.entries = const []]);

  /// Entries sorted by file path.
  final List<EntryRecord> entries;

  /// Number of `@JetleafEntry` mains.
  ///
  /// **Returns:** the app entry count.
  int get appCount =>
      entries.where((e) => e.kind == EntryKind.entry).length;

  /// Number of `@JetleafTest` mains.
  ///
  /// **Returns:** the test entry count.
  int get testCount =>
      entries.where((e) => e.kind == EntryKind.test).length;

  /// True when nothing was discovered.
  ///
  /// **Returns:** whether [entries] is empty.
  bool get isEmpty => entries.isEmpty;

  /// Serializes to a JSON-compatible list.
  ///
  /// **Returns:** one object per entry.
  List<Map<String, Object?>> toJson() =>
      entries.map((e) => e.toJson()).toList();
}
