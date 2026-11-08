/// 🛠️ **Jetleaf Tools: Build, Scanning & AOT Runtime Engine**
///
/// The `jetleaf_tools` library is the core tooling and compilation framework powering
/// the Jetleaf ecosystem. It provides static AST scanning, reflection metadata extraction,
/// Ahead-Of-Time (AOT) static dispatcher generation, binary cache serialization,
/// and the high-performance CLI runner (`jl dev`, `jl build`).
///
/// ---
///
/// ## 🏛️ Tooling & Compilation Topology
///
/// ```text
/// ┌────────────────────────────────────────────────────────────────────────┐
/// │                          jetleaf_tools (1.0.0)                         │
/// ├─────────────────────┬──────────────────────┬───────────────────────────┤
/// │      CLI & VM       │   AST & Indexing     │      AOT & Dispatch       │
/// ├─────────────────────┼──────────────────────┼───────────────────────────┤
/// │ • jl dev (Watch/VM) │ • DeclarationBuilder │ • AotRuntimeExecutor      │
/// │ • jl build (Kernel) │ • FileDiscovery      │ • RuntimeManifest         │
/// │ • Resident Compiler │ • BinaryBuilder/Cache│ • Zero-Mirrors Execution  │
/// └─────────────────────┴──────────────────────┴───────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🖥️ CLI & Runners
/// - [JlCli] — command-line interface entry point powering `jl dev` and `jl build`.
/// - `runScan` — programmatically triggers complete application source code analysis.
/// - `testScan` — triggers lightweight test-scoped metadata scanning.
///
/// ### 📜 Declarations & Metadata
/// - `Declaration` — root reflective metadata model for Dart language elements.
/// - `ClassDeclaration`, `MethodDeclaration`, `FieldDeclaration`, `ConstructorDeclaration`.
///
/// ### ⚡ AOT Runtime Execution
/// - [AotRuntimeExecutor] — mirrorless invocation engine dispatching calls via registered function pointers.
/// - [RuntimeManifest] — build verification manifest tracking compiled components and fingerprints.
///
/// ### 💾 Binary Cache & Paths
/// - [JetleafPaths] — path resolver for `.jetleaf/` directory layout.
/// - `BinaryBuilder`, `BinaryReader` — packed binary serializer for scan-time caching.
///
/// ---
///
/// ## 🎯 Usage Example: AOT Function-Pointer Dispatch
///
/// ```dart
/// import 'package:jetleaf_tools/jetleaf_tools.dart';
///
/// class GreeterService {
///   String greet(String name) => 'Hello, $name!';
/// }
///
/// void main() {
///   // 1. Register AOT constructor
///   AotRuntimeExecutor.registerNamedConstructor('GreeterService', ([args]) {
///     return GreeterService();
///   });
///
///   // 2. Register AOT method invoker
///   AotRuntimeExecutor.registerMethod('GreeterService.greet', (inst, args) {
///     final greeter = inst as GreeterService;
///     final name = args.getPositionalArguments()[0] as String;
///     return greeter.greet(name);
///   });
///
///   // 3. Dispatch instantiation and method execution with zero reflection
///   final instance = AotRuntimeExecutor.constructByName('GreeterService');
///   final executor = AotRuntimeExecutor(DefaultRuntimeHintDescriptor());
///   final message = executor.invokeMethod(
///     instance,
///     'greet',
///     ExecutableArgument.unmodified(const {}, ['World']),
///   );
///
///   print(message); // Output: Hello, World!
/// }
/// ```
///
/// {@category Build & Tooling}
library;

export 'src/builder/runtime_builder.dart';
export 'src/builder/runtime_manifest.dart';
export 'src/serialization/jetleaf_json.dart';
export 'src/cache/jetleaf_paths.dart';
export 'src/cli/jl_cli.dart';
export 'src/builder/reachability.dart';
export 'src/builder/build_arg.dart';

export 'src/file_utility/abstract_file_utility.dart';
export 'src/file_utility/file_utility.dart';
export 'src/file_utility/located_files.dart';

export 'src/runner/run_scan.dart';
export 'src/runner/test_scan.dart';

export 'src/generator/library_generator.dart';
export 'src/generator/mock_library_generator.dart';
export 'src/generator/default_library_generator.dart';

export 'src/runtime/scanner/application_runtime_scanner.dart';
export 'src/runtime/scanner/default_runtime_scanner_summary.dart';
export 'src/runtime/scanner/mock_runtime_scanner.dart';
export 'src/runtime/scanner/runtime_scanner.dart';
export 'src/runtime/scanner/runtime_scanner_configuration.dart';
export 'src/runtime/scanner/runtime_scanner_summary.dart';

export 'src/utils/dart_type_resolver.dart';
export 'src/utils/utils.dart' hide StringX;
export 'src/utils/must_avoid.dart';