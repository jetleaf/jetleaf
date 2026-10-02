// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_lang/jetleaf_lang.dart' show getNonNecessaryPackages;
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import 'proxy_generator.dart';
import 'src/utils.dart';

/// {@template proxy_builder}
/// # ProxyBuilder
///
/// A [Builder] implementation responsible for generating proxy subclasses
/// of annotated classes (e.g., those annotated with `@Service`, `@Component`,
/// `@Controller`, etc.) during Jetleaf’s build phase.
///
/// The `ProxyBuilder` integrates with the `build_runner` toolchain to
/// transform `.dart` source files into corresponding `.proxy.dart` files
/// that contain interception-ready subclasses. These generated proxies
/// serve as runtime wrappers that enable Jetleaf’s method interception,
/// dependency injection, and lifecycle management mechanisms.
///
/// The generated Dart source is intentionally kept below `lib`. This is a
/// Dart package boundary requirement, not only a Jetleaf runtime preference:
/// `dart run`, the analyzer, build_runner, and `package:` imports resolve
/// application source through the package's `lib` tree. A proxy written only
/// under `.jetleaf` is therefore outside the normal compilation graph and
/// cannot reliably be discovered or imported.
///
/// ---
///
/// ## ⚙️ How It Works
/// 1. **File Filtering** — Skips generation for any files inside the
///    [Constant.GENERATED_DIR_NAME] directory to prevent recursive
///    proxy generation.
/// 2. **Library Resolution** — Uses the `BuildStep.resolver` to resolve
///    the Dart library represented by the input asset.
/// 3. **Annotation Discovery** — Passes the library to the
///    [ProxyGenerator], which identifies stereotype annotations such as
///    `@Service` or `@Component`.
/// 4. **Proxy Generation** — For each discovered class, a proxy subclass
///    is emitted that wraps method calls in interception logic using
///    [Interceptable] and [MethodInterceptorDispatcher].
/// 5. **Output Storage** — The generated code is written to:
///    - The standard `.proxy.dart` file in the same directory, and
///    - A project-wide generated directory (`_jetleaf/`) for bootstrap inclusion.
///
/// ---
///
/// ## 🧩 Example
///
/// Suppose you have a service class:
///
/// ```dart
/// @Service()
/// class UserService {
///   String greet(String name) => 'Hello, $name';
/// }
/// ```
///
/// After running `dart run build_runner build`, `ProxyBuilder` will
/// generate a file named:
///
/// ```text
/// lib/user_service.proxy.dart
/// ```
///
/// containing:
///
/// ```dart
/// final class $$UserService with Interceptable implements UserService, ClassGettable<UserService> {
///   final UserService delegate;
///   $$UserService(this.delegate);
///
///   @override
///   String greet(String name) async =>
///       this.when<String>(() async => delegate.greet(name), delegate, 'greet',
///         MethodArguments(positionalArgs: [name]));
/// }
/// ```
///
/// ---
///
/// ## 📂 Output Organization
/// - Local proxy output: `lib/*.proxy.dart`
/// - Global generated proxy store under the package library directory:
///   `lib/_jetleaf/<package>/<path>_proxy.dart`
///
/// This dual output structure allows Jetleaf’s CLI (`jl build`) to include
/// proxies directly in the build bootstrap phase.
///
/// ---
///
/// ## 🧠 Notes
/// - Files inside `_jetleaf/` are ignored to avoid recursive proxy generation.
/// - SDK libraries (`dart:` imports) are skipped during analysis.
/// - The [ProxyGenerator] is stateless and can safely be reused across builds.
///
/// ---
///
/// ## See also
/// - [ProxyGenerator] — the core generator that emits proxy class source
/// - [Interceptable] — the mixin injected into generated proxy classes
/// - [MethodInterceptorDispatcher] — handles runtime interception flow
/// - [Constant] — defines the active generated-source and workspace names
///
/// {@endtemplate}
class ProxyBuilder extends Builder {
  /// {@macro proxy_builder}
  ProxyBuilder();

  /// Prefix used to identify Jetleaf framework libraries.
  ///
  /// Framework-owned libraries are already compiled with their required
  /// metadata and must not be recursively proxied by an application build.
  static const String KEYWORD = "package:jetleaf";

  /// URI scheme used by Dart SDK libraries.
  ///
  /// SDK declarations are outside the application proxy boundary and are
  /// excluded before annotation analysis begins.
  static const String DART = "dart:";

  /// Maps each Dart input library to its sibling proxy output.
  ///
  /// The global `lib/_jetleaf` copy is written separately by [build] for
  /// bootstrap and runtime consumers. Keeping this copy under `lib` is
  /// intentional: Dart execution and Jetleaf discovery must be able to find
  /// generated proxies through the normal source graph during `dart run`,
  /// `jetleaf run`, and low-level `jl` execution.
  @override
  final buildExtensions = const { '.dart': ['.proxy.dart'], };

  /// Generates proxy implementations for one build-runner input library.
  ///
  /// The method follows a deliberately staged pipeline:
  ///
  /// 1. Reject generated, framework, SDK, dependency, and non-library input.
  /// 2. Resolve the analyzer library and verify that it imports Jetleaf APIs.
  /// 3. Delegate annotation interpretation to [ProxyGenerator].
  /// 4. Persist both the local sibling output and the canonical workspace copy.
  ///
  /// Keeping filtering before library resolution avoids analyzer work for
  /// files that can never produce a Jetleaf proxy. Keeping the two output
  /// writes together ensures local source consumers and runtime bootstrap
  /// consumers observe the same generated proxy content.
  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;

    // Generated state can be written while build_runner is scanning. It must
    // be excluded before resolution or the builder can repeatedly process its
    // own output.
    final path = inputId.path;

    if (path.startsWith(Constant.GENERATED_DIR_NAME) ||
        path.startsWith('${Constant.WORKSPACE_DIR_NAME}/')) {
      return;
    }

    if (inputId.package.startsWith("jetleaf") || inputId.uri.toString().startsWith(KEYWORD)) {
      return;
    }

    if (inputId.uri.toString().startsWith(DART)) {
      return;
    }

    final skip = [
      ...getNonNecessaryPackages(),
      "fixnum",
      "graphs",
      "http_multi_server",
      "io",
      "jetson",
      "jtl",
      "matcher",
      "collection",
      "string_scanner",
      "mime",
      "pool",
      "pubspec_parse",
      "checked_yaml",
      "json_annotation",
      "shelf_web_socket",
      "shelf",
      "http_parser",
      "args",
      "logging",
      "source_span",
      "watcher",
      "boolean_selector",
      "stack_trace",
      "stream_transform",
      "convert",
      "file",
      "glob",
      "package_config",
      "path",
      "term_glyph",
      "yaml",
      "meta",
      "async",
      "typed_data",
      "crypto",
      "stream_channel",
      "web",
      "web_socket",
      "web_socket_channel",
    ];

    if (skip.any((s) => s.equals(inputId.package))) {
      return;
    }

    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
      return;
    }

    // A build input can be a part file or another non-library Dart unit. The
    // resolver check keeps proxy generation limited to complete libraries.
    if (!await buildStep.resolver.isLibrary(inputId)) {
      return; // Skip part files and non-library units
    }

    final resolver = buildStep.resolver;
    final lib = await resolver.libraryFor(inputId);

    // Analyzer can resolve SDK and framework libraries even when they appear
    // in an application's dependency graph. They are not application proxy
    // boundaries and are excluded here.
    if (lib.isInSdk || lib.uri.toString().startsWith(DART) || lib.identifier.contains(DART)) return;
    if (lib.uri.toString().startsWith(KEYWORD)) return;

    if ((await buildStep.inputLibrary).firstFragment.importedLibraries.map((i) => i.uri.toString()).toList().none((im) => im.contains(KEYWORD))) {
      return;
    }

    final reader = LibraryReader(lib);
    final generator = ProxyGenerator();
    final output = await generator.generate(reader, buildStep);
    if (output.trim().isEmpty) return;

    // Store the result in the active generated-source directory under `lib`.
    // The relative input path is retained in the output name so two source
    // files cannot overwrite one another when they share a basename. This is
    // deliberately separate from `.jetleaf`, which stores tooling metadata
    // and must not hide proxy Dart sources from runtime discovery.
    final inputPath = buildStep.inputId.path;
    final relPath = p.withoutExtension(inputPath);
    final outputPath =
        '${Constant.GENERATED_DIR_NAME}/${relPath.replaceFirst("lib", '${buildStep.inputId.package}_proxies')}_proxy.dart';
    await writeGeneratedOutput(output, File(outputPath));

    final outputId = inputId.changeExtension('.proxy.dart');
    await buildStep.writeAsString(outputId, output);
  }
}

/// {@template proxy_builder_factory}
/// Factory entrypoint for Jetleaf’s proxy code generator.
///
/// This function is invoked automatically by `build_runner` when
/// Jetleaf’s build extensions are registered in `build.yaml`.
///
/// Example `build.yaml` snippet:
/// ```yaml
/// targets:
///   $default:
///     builders:
///       jetleaf|proxy_builder:
///         generate_for:
///           - lib/**.dart
/// ```
///
/// Returns a new instance of [ProxyBuilder].
///
/// {@endtemplate}
Builder proxyBuilder(BuilderOptions options) => ProxyBuilder();
