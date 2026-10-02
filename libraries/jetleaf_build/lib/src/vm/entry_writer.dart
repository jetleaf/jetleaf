part of 'jetleaf_vm.dart';

/// {@template entry_writer}
/// # Entry Writer
///
/// Generates the per-entry stub files that [JetleafVM] compiles and boots.
///
/// Sealed into the `jetleaf_vm` library (part file): only the
/// `EntryWriter → Discoverable → JetleafVM` chain inside this library
/// can extend it. Every method is additionally `@protected`, so even
/// inside the library only the subclass chain may call them.
///
/// Each discovered `@JetleafEntry` / `@JetleafTest` `void main()` gets its
/// own constant stub path (`.jetleaf/generated/entries/<slug>.dart`) so entries never
/// clobber each other and every frontend server can incrementally recompile
/// its own root.
///
/// ---
///
/// ## Overview
/// The [EntryWriter] emits two stub modes per entry:
/// 1. Parked (`writeParkedEntryStub`) — `main()` never completes; the VM
///    idles warm. Also exposes `_ensureJetleafRuntime()` so later runs can
///    populate the JetLeaf runtime inside the already-warm isolate.
/// 2. Runner (`writeRunnerEntryStub`) — `main()` forwards to the user's
///    entry file, so an incremental compile + isolate reload executes user
///    code in the already-warm isolate (mirrors loaded, `Runtime`
///    populated).
///
/// ---
///
/// ## Emission Workflow
///
/// 1. **Slug** — [stubSlugFor] derives a filesystem-safe name from the
///    project-relative entry path (`test/a_test.dart` → `test__a_test`).
/// 2. **Import** — [resolveEntryImport] maps the entry to a `package:` URI
///    under `lib/`, or to a percent-encoded absolute `file:` URI otherwise
///    (raw paths break compilation when directories contain spaces).
/// 3. **Shape** — [entryMainShapeFor] inspects the entry `main()` so the
///    generated call matches its signature: no positional params gets a
///    bare `entry.main()` (an args call would not compile), and a
///    synchronous `void` main gets a bare statement (its value can't be
///    inspected with `is Future`).
/// 4. **Write** — the stub is written with the shared `dart:async` import
///    (timers keep parked and finished runners alive for the next run).
///
/// ---
///
/// ## Design Notes
///
/// ### 1. Protected API
/// Every method is `@protected`: only [JetleafVM] (the single subclass
/// chain) may call them. The class itself is `abstract final` in a part
/// file, so no code outside the `jetleaf_vm` library can extend it.
/// Unit tests drive the API through `JetleafVM.instance` (pure file-I/O
/// methods need no running manager).
///
/// ### 2. Import prefixes
/// Generated stubs use `jl` (JetLeaf API) and `entry` (user code).
/// Leading-underscore prefixes are avoided on purpose: analyzer lints
/// (`unnecessary_underscores`, public-prefix rules) run against generated
/// files in editors, and the stubs must stay warning-clean.
///
/// {@endtemplate}
@internal
abstract final class EntryWriter {
  /// {@macro entry_writer}
  EntryWriter();

  /// Derives a filesystem-safe slug from a project-relative [entryKey].
  ///
  /// **Parameters:**
  /// - [entryKey]: project-relative entry path (`test/app_test.dart`).
  ///
  /// **Returns:** the slug (`test__app_test`).
  ///
  /// ```dart
  /// stubSlugFor('test/app_test.dart') // 'test__app_test'
  /// ```
  @protected
  String stubSlugFor(String entryKey) => entryKey
      .replaceAll('/', '__')
      .replaceAll('\\', '__')
      .replaceAll('.dart', '');

  /// Resolves the stub file for [entryKey] under [projectRoot].
  ///
  /// **Parameters:**
  /// - [projectRoot]: project root.
  /// - [entryKey]: project-relative entry path.
  ///
  /// **Returns:** `.jetleaf/generated/entries/<slug>.dart`.
  @protected
  File stubFileFor(Directory projectRoot, String entryKey) => File(
    p.join(
      JetleafPaths.generatedDir(projectRoot).path,
      Constant.ENTRIES_DIR_NAME,
      '${stubSlugFor(entryKey)}.dart',
    ),
  );

  /// File-system-root-relative URI of the stub, used with
  /// `FrontendServerClient` (same `org-dartlang-root` scheme as boot).
  ///
  /// **Parameters:**
  /// - [projectRoot]: project root.
  /// - [entryKey]: project-relative entry path.
  ///
  /// **Returns:** the `org-dartlang-root://` stub URI.
  @protected
  String stubRootUriFor(Directory projectRoot, String entryKey) =>
      'org-dartlang-root:///${stubFileFor(projectRoot, entryKey).absolute.path}';

  /// Snapshot path for [entryKey]'s incremental compiler output.
  ///
  /// **Parameters:**
  /// - [projectRoot]: project root.
  /// - [entryKey]: project-relative entry path.
  ///
  /// **Returns:** `.jetleaf/vm/entries/<slug>.dill`.
  @protected
  String snapshotPathFor(Directory projectRoot, String entryKey) => p.join(
    JetleafPaths.vmDir(projectRoot).path,
    Constant.ENTRIES_DIR_NAME,
    '${stubSlugFor(entryKey)}.dill',
  );

  /// Writes the parked stub for [entryKey].
  ///
  /// The parked `main()` never completes (hourly dummy timer + pending
  /// completer — an outstanding future alone does not hold the event
  /// loop).
  ///
  /// **Parameters:**
  /// - [projectRoot]: project root.
  /// - [entryKey]: project-relative entry path.
  /// - [forTests]: selects the `runTestScan` (`@JetleafTest`) or
  ///   `runScan` (`@JetleafEntry`) runtime in `_ensureJetleafRuntime()`.
  /// - [verbose]: stream scan logs to isolate stdout (`[scan] …` lines)
  ///   instead of silencing them.
  ///
  /// **Returns:** when the stub file is written.
  @protected
  Future<void> writeParkedEntryStub(Directory projectRoot, String entryKey, {
    required bool forTests,
    File? entryFile,
    bool verbose = false,
  }) {
    final entryImport = entryFile == null
        ? ''
        : "import '${resolveEntryImport(projectRoot, entryFile)}' as warm_entry;";
    return _writeStub(projectRoot, entryKey, '''
${_generatedHeader(entryKey, forTests, 'Parked mode: keeps the prewarmed VM alive with zero user code running.')}
${_ensureImport()}
${_commandImports()}
$entryImport
${_ensureFunction(forTests, verbose: verbose)}
${_commandServer()}
${_parkedMain()}
''');
  }

  /// Rewrites the stub for [entryKey] to import and invoke [entryFile].
  ///
  /// The generated call (and tail) matches the entry signature reported
  /// by [entryMainShapeFor] — see its contract for the exact rules.
  ///
  /// **Parameters:**
  /// - [projectRoot]: project root.
  /// - [entryKey]: project-relative entry path.
  /// - [entryFile]: user entry file whose `main` is invoked.
  /// - [forTests]: selects the test (`runTestScan`) or production
  ///   (`runScan`) runtime in `_ensureJetleafRuntime()`.
  /// - [verbose]: stream scan logs to isolate stdout (`[scan] …` lines)
  ///   instead of silencing them.
  ///
  /// **Returns:** when the stub file is written.
  @protected
  Future<void> writeRunnerEntryStub(Directory projectRoot, String entryKey, File entryFile, {
    required bool forTests,
    bool verbose = false,
  }) async {
    final import = resolveEntryImport(projectRoot, entryFile);
    if (forTests) {
      await _writeStub(
        projectRoot,
        entryKey,
        _testDriverStub(entryKey, import),
      );
      return;
    }

    final shape = await entryMainShapeFor(entryFile);
    final call = shape.takesArgs ? 'entry.main(args)' : 'entry.main()';
    // `await` accepts Future and plain values alike — but never `void`.
    final tail = shape.returnsVoid
        ? '$call;'
        : 'final result = $call;\n  if (result is Future) await result;';
    await _writeStub(projectRoot, entryKey, '''
${_generatedHeader(entryKey, forTests, 'Runner mode: executes ${entryFile.path} inside the prewarmed isolate.')}
${_ensureImport()}
import '$import' as entry;

${_ensureFunction(forTests, verbose: verbose)}

/// Invokes the user entry `main`.
///
/// Auto-generated by `jl dev`; do not edit.
Future<void> main(List<String> args) async {
  // Keep the isolate alive after user main completes so the VM
  // survives for the next run (see parked main above).
  Timer.periodic(const Duration(hours: 1), (_) {});
  await _jlHandleCommand({'type': 'app', 'args': args});
}

Future<bool> _jlHandleCommand(Map<String, dynamic> message) async {
  if (message['type'] != 'app') return false;
  final args = ((message['args'] as List?) ?? const [])
      .map((value) => value.toString())
      .toList();
  await _ensureJetleafRuntime();
  $tail
  return true;
}
''');
  }

  /// Runner stub for test entries: drives the entry tests in this isolate
  /// with the test engine and reports success as a boolean.
  ///
  /// Mirrors the direct-run path (`dart test/<file>.dart`): declares the
  /// entry `main` (resolved dynamically with [Function.apply] so every
  /// `main` signature works) into a fresh `Declarer`, pumps the queue,
  /// then runs a single-suite `Engine` with the expanded reporter. The
  /// reporter streams to stdout; the returned future completes with the
  /// test result — this is what makes warm-VM test runs observable
  /// (evaluating `main()` alone only registers tests, never runs them).
  ///
  /// Test-engine imports are `src/`-internal to `test_api`/`test_core`
  /// (same as first-party `scaffolding.dart`); the stub header already
  /// suppresses `implementation_imports`. The root `main()` below only
  /// idles warm — the manager evaluates [runJetleafTests] directly.
  ///
  /// **Parameters:**
  /// - [entryKey]: project-relative entry path (banner only).
  /// - [import]: entry import URI for the `entry` prefix.
  /// - [verbose]: stream scan logs to isolate stdout (`[scan] …` lines)
  ///   instead of silencing them.
  ///
  /// **Returns:** the runner stub source.
  String _testDriverStub(String entryKey, String import) =>
      '''
${_generatedHeader(entryKey, true, 'Test-driver mode: executes the entry tests with the test engine in this isolate.')}
import 'dart:async';
import 'package:test_api/backend.dart' show Runtime, SuitePlatform;
import 'package:test_api/scaffolding.dart' show pumpEventQueue;
import 'package:test_api/src/backend/declarer.dart' show Declarer;
import 'package:test_api/src/backend/invoker.dart' show Invoker;
import 'package:test_core/src/runner/suite.dart' show SuiteConfiguration;
import 'package:test_core/src/runner/engine.dart' show Engine;
import 'package:test_core/src/runner/plugin/environment.dart' show PluginEnvironment;
import 'package:test_core/src/runner/reporter/expanded.dart' show ExpandedReporter;
import 'package:test_core/src/runner/runner_suite.dart' show RunnerSuite;
import 'package:test_core/src/util/os.dart' show currentOSGuess;
import 'package:test_core/src/util/print_sink.dart' show PrintSink;
import '$import' as entry;

bool _jlTestsPassed = false;

Future<bool> runJetleafTests([List<String> args = const []]) async {
  _jlTestsPassed = false;
  try {
  final declarer = Declarer(isStandalone: true);
  final dynamic registration = declarer.declare(() {
    try {
      return Function.apply(entry.main, [args]);
    } on NoSuchMethodError {
      return Function.apply(entry.main, const []);
    }
  });
  if (registration is Future) await registration;
  print('[jl] tests declared, pumping queue ...');
  await pumpEventQueue();
  print('[jl] building suite ...');
  final group = declarer.build();
  final suite = RunnerSuite(
    const PluginEnvironment(),
    SuiteConfiguration.empty,
    group,
    SuitePlatform(Runtime.vm, compiler: null, os: currentOSGuess),
    path: 'jetleaf-test',
  );
  final engine = Engine();
  engine.suiteSink.add(suite);
  engine.suiteSink.close();
  ExpandedReporter.watch(
    engine,
    PrintSink(),
    color: false,
    printPath: false,
    printPlatform: false,
  );
  print('[jl] engine starting ...');
  final success = await Invoker.guard(engine.run);
  print('[jl] engine done: \$success');
  _jlTestsPassed = success == true;
  } catch (e) {
    print('[jl] engine error: \$e');
  } finally {
    print('[jl] tests done: \$_jlTestsPassed');
  }
  return _jlTestsPassed;
}

Future<bool> _jlHandleCommand(Map<String, dynamic> message) async {
  if (message['type'] != 'test') return false;
  final args = ((message['args'] as List?) ?? const [])
      .map((value) => value.toString())
      .toList();
  return runJetleafTests(args);
}

Future<void> main() async {
  // Idles warm: the manager sends test commands through the loopback socket.
  // Never completes so the VM survives between runs.
  Timer.periodic(const Duration(hours: 1), (_) {});
  await Completer<void>().future;
}
''';

  /// Inspects [entryFile]'s top-level `main()` and reports its call shape.
  ///
  /// - [takesArgs]: true when `main` accepts a positional argument
  ///   (required or optional). Unparseable files fall back to true —
  ///   the debugger fallback in `JetleafVM` retries bare on mismatch.
  /// - [returnsVoid]: true when `main` declares a `void` return — sync
  ///   or `async` alike (an `async void` invocation is still statically
  ///   `void`). Such mains must be invoked as a bare statement: neither
  ///   `is Future` nor `await` accepts a `void` expression.
  ///
  /// **Parameters:**
  /// - [entryFile]: user entry file to inspect.
  ///
  /// **Returns:** `(takesArgs, returnsVoid)`.
  @protected
  Future<({bool takesArgs, bool returnsVoid})> entryMainShapeFor(File entryFile) async {
    try {
      final content = await entryFile.readAsString();
      final result = parseString(content: content, throwIfDiagnostics: false);
      
      for (final declaration in result.unit.declarations) {
        if (declaration is! ast.FunctionDeclaration) continue;
        if (declaration.name.lexeme != 'main') continue;
        
        final params = declaration.functionExpression.parameters?.parameters ?? [];
        final takesArgs = params.any((param) => param.isRequiredPositional || param.isOptionalPositional);
        final returnsVoid = declaration.returnType?.toString().trim() == 'void';
        
        return (takesArgs: takesArgs, returnsVoid: returnsVoid);
      }
    } catch (_) {}

    return (takesArgs: true, returnsVoid: false);
  }

  /// Resolves [entryFile] to the import URI used inside the stub.
  ///
  /// Entries under `lib/` use `package:` URIs; anything else uses a
  /// percent-encoded absolute `file:` URI ([Uri.file]) — raw paths break
  /// compilation as soon as the project root contains spaces.
  ///
  /// **Parameters:**
  /// - [projectRoot]: project root (owns `lib/` and `pubspec.yaml`).
  /// - [entryFile]: user entry file to import.
  ///
  /// **Returns:** the import URI string.
  @protected
  String resolveEntryImport(Directory projectRoot, File entryFile) {
    final packageName = JetleafVM._resolvePackageName(projectRoot);
    final normalized = p.normalize(entryFile.absolute.path);
    final libDir = p.normalize(p.join(projectRoot.absolute.path, 'lib'));
    if (p.isWithin(libDir, normalized)) {
      final rel = p.relative(normalized, from: libDir);
      return 'package:$packageName/$rel';
    }

    return Uri.file(normalized).toString();
  }

  // ---------------------------------------------------------- emission

  /// Generated-file header shared by parked and runner stubs.
  ///
  /// Mirrors the proxy generator's `writeGeneratedHeader` shape
  /// (lint suppressions, [Constant.BANNER_ART], AUTO-GENERATED tag,
  /// copyright) plus the stub mode and entry it was generated for.
  ///
  /// **Parameters:**
  /// - [entryKey]: project-relative entry path.
  /// - [forTests]: annotation kind rendered in the banner.
  /// - [mode]: parked/runner description line.
  ///
  /// **Returns:** the header block.
  String _generatedHeader(String entryKey, bool forTests, String mode) {
    final year = DateTime.now().year;
    return '''
// ignore_for_file: unused_import, depend_on_referenced_packages, library_prefixes, unnecessary_underscores, duplicate_import, deprecated_member_use, unnecessary_import, prefer_final_fields, implementation_imports
//
${Constant.BANNER_ART.trim()}
//
// AUTO-GENERATED entry stub for [$entryKey]
// Do not edit manually. Regenerated by `jl dev` on every run.
//
// ---------------------------------------------------------------------------
// Jetleaf Framework
//
// Copyright (c) $year Hapnium & Jetleaf Contributors
//
// Licensed under the MIT License. See LICENSE file in the root of the jetleaf project
//
// This file is part of the Jetleaf Framework, a modern, modular backend
// framework for Dart.
//
// For documentation and usage, visit:
// https://jetleaf.hapnium.com/docs
// ---------------------------------------------------------------------------
// $mode
// Entry: $entryKey (${forTests ? '@JetleafTest' : '@JetleafEntry'})''';
  }

  /// JetLeaf API import for `_ensureJetleafRuntime()`.
  ///
  /// **Returns:** the `jl` import line.
  String _ensureImport() =>
      "import 'dart:async';\n"
      "import 'package:jetleaf_build/jetleaf_build.dart' as jl;\n"
      "import 'package:jetleaf_build/src/runtime/scanner/runtime_scanner_configuration.dart' "
      "show RuntimeBuildMode, RuntimeScannerConfiguration;";

  /// Imports used by the parked VM command server.
  String _commandImports() => "import 'dart:convert';\nimport 'dart:io';";

  /// Populates the JetLeaf runtime inside the warm isolate.
  ///
  /// First run may take a while (mirror scan); afterwards the
  /// `.jetleaf/` cache fast path (or the already-populated guard)
  /// makes it cheap. Silent callbacks — VM output stays clean.
  ///
  /// Completion is flag-observed, never awaited: debugger evaluation
  /// returns async futures uncompleted, so the manager triggers the
  /// scan here and polls `_jlRuntimeReady` (failure lands in
  /// `_jlRuntimeError`). The guard also makes repeat runs free.
  ///
  /// **Parameters:**
  /// - [forTests]: `runTestScan` when true, `runScan` otherwise.
  ///
  /// **Returns:** the `_ensureJetleafRuntime()` source.
  String _ensureFunction(bool forTests, {bool verbose = false}) {
    final String logCallbacks = verbose
        ? '''
      onInfo: (msg, __) => print('[scan] \$msg'),
      onWarning: (msg, __) => print('[scan] \$msg'),
      onError: (msg, __) => print('[scan] \$msg'),'''
        : '''
      onInfo: (_, __) {},
      onWarning: (_, __) {},
      onError: (_, __) {},''';
    final String scanCall = forTests
        ? 'await jl.runTestScan(\n'
              '      config: RuntimeScannerConfiguration(reload: false, forceLoadLibraries: true, buildMode: RuntimeBuildMode.compatibility),\n'
              '      $logCallbacks\n    );'
        : 'await jl.runScan(\n'
              '      config: RuntimeScannerConfiguration(reload: false, forceLoadLibraries: true, buildMode: RuntimeBuildMode.compatibility),\n'
              '      $logCallbacks\n    );';
    final String kind = forTests ? 'test runtime' : 'production runtime';
    return '''
bool _jlRuntimeReady = false;
String? _jlRuntimeError;

/// Populates the JetLeaf $kind inside the warm isolate.
///
/// Auto-generated by `jl dev`; do not edit.
Future<void> _ensureJetleafRuntime() async {
  if (_jlRuntimeReady) return;
  try {
    $scanCall
    _jlRuntimeReady = true;
    print('[jl] runtime ready');
  } catch (e, stackTrace) {
    // Recorded for the manager poll; rethrowing here would surface as
    // untracked isolate noise instead of a proper run failure.
    _jlRuntimeError = '\$e\\n\$stackTrace';
    print('[jl] runtime error: \$_jlRuntimeError');
  }
}''';
  }

  /// Parked root: idles forever on a dummy timer + pending completer.
  ///
  /// **Returns:** the parked `main()` source.
  String _parkedMain() => '''
/// Idles warm: never completes so the VM survives until a run.
///
/// Auto-generated by `jl dev`; do not edit.
Future<void> main() async {
  // An outstanding future alone does not hold the event loop (the VM
  // exits once the queue drains), so keep a dummy periodic timer alive.
  // Hot restart replaces this root entirely.
  Timer.periodic(const Duration(hours: 1), (_) {});
  await _ensureJetleafRuntime();
  await _jlCommandServer();
}''';

  /// Keeps the resident isolate available for reload-and-run commands.
  String _commandServer() => '''
Future<bool> _jlHandleCommand(Map<String, dynamic> message) async => false;

Future<void> _jlCommandServer() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  print('[jl] control port: \${server.port}');
  await for (final socket in server) {
    unawaited(() async {
      try {
        final line = await socket
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .first;
        final message = jsonDecode(line) as Map<String, dynamic>;
        final ok = await _jlHandleCommand(message);
        socket.writeln(jsonEncode({'ok': ok}));
        await socket.flush();
      } catch (e) {
        socket.writeln(jsonEncode({'ok': false, 'error': e.toString()}));
        await socket.flush();
      } finally {
        await socket.close();
      }
    }());
  }
}''';

  /// Writes stub [content] for [entryKey], prepending `dart:async`
  /// (timers/completers) when the template does not include it.
  ///
  /// **Parameters:**
  /// - [projectRoot]: project root owning `_jetleaf/`.
  /// - [entryKey]: project-relative entry path.
  /// - [content]: stub source to write.
  ///
  /// **Returns:** when the file is written.
  Future<void> _writeStub(Directory projectRoot, String entryKey, String content) async {
    final file = stubFileFor(projectRoot, entryKey);
    await file.parent.create(recursive: true);
    // Built-in templates place imports after the generated header. Keep this
    // fallback for future templates without moving imports above the header.
    final withImport = content.contains('dart:async')
        ? content
        : content.replaceFirst(
            RegExp(r'(?=import )'),
            "import 'dart:async';\n",
          );
    await file.writeAsString(withImport);
  }
}
