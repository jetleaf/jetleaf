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

export 'src/argument/executable_argument.dart';

export 'src/builder/runtime_builder.dart';
export 'src/builder/runtime_manifest.dart';
export 'src/serialization/jetleaf_json.dart';
export 'src/cache/jetleaf_paths.dart';
export 'src/cli/jl_cli.dart';
export 'src/builder/reachability.dart';
export 'src/builder/build_arg.dart';

export 'src/helpers/base.dart' hide equals, toString, toStringWith;
export 'src/helpers/equals_and_hash_code.dart';
export 'src/helpers/to_string.dart';
export 'src/helpers/qualified_name.dart';

export 'src/file_utility/abstract_file_utility.dart';
export 'src/file_utility/file_utility.dart';
export 'src/file_utility/located_files.dart';

export 'src/runner/run_scan.dart';
export 'src/runner/test_scan.dart';

export 'src/generator/library_generator.dart';
export 'src/generator/mock_library_generator.dart';
export 'src/generator/default_library_generator.dart';

export 'src/runtime/declaration/declaration.dart'
    hide
        StandardAnnotationDeclaration,
        StandardAnnotationFieldDeclaration,
        StandardClassDeclaration,
        StandardConstructorDeclaration,
        StandardDeclaration,
        StandardEntityDeclaration,
        StandardEnumDeclaration,
        StandardEnumFieldDeclaration,
        StandardFieldDeclaration,
        StandardFunctionDeclaration,
        StandardLibraryDeclaration,
        StandardLinkDeclaration,
        StandardMethodDeclaration,
        StandardMixinDeclaration,
        StandardParameterDeclaration,
        StandardRecordDeclaration,
        StandardRecordFieldDeclaration,
        StandardSourceDeclaration,
        StandardClosureDeclaration,
        MaterialAsset,
        DEFAULT_ENCODING,
        MaterialPackage;

export 'src/runtime/provider/runtime_provider.dart'
    hide
        addRuntimeAsset,
        addRuntimeAssets,
        addRuntimePackage,
        addRuntimePackages,
        addRuntimeSourceLibrary,
        setRuntimeLibraryTag,
        setRuntimeResolver,
        freezeRuntimeLibrary,
        createBuiltInPackage,
        createDefaultPackage,
        registerCachedDeclarations,
        getCachedDeclarations,
        StringExte;

export 'src/runtime/hint/default_runtime_hint_descriptor.dart';
export 'src/runtime/hint/abstract_runtime_hint.dart';
export 'src/runtime/hint/runtime_hint.dart';
export 'src/runtime/hint/runtime_hint_provider.dart';
export 'src/runtime/hint/runtime_hint_descriptor.dart';

export 'src/runtime/executor/aot/aot_runtime_executor.dart';
export 'src/runtime/executor/jit/jit_runtime_executor.dart';
export 'src/runtime/executor/default_runtime_executor.dart';
export 'src/runtime/executor/runtime_executor.dart';
export 'src/runtime/executor/resolving/runtime_executor_resolving.dart';

export 'src/runtime/scanner/application_runtime_scanner.dart';
export 'src/runtime/scanner/default_runtime_scanner_summary.dart';
export 'src/runtime/scanner/mock_runtime_scanner.dart';
export 'src/runtime/scanner/runtime_scanner.dart';
export 'src/runtime/scanner/runtime_scanner_configuration.dart';
export 'src/runtime/scanner/runtime_scanner_summary.dart';

export 'src/utils/dart_type_resolver.dart';
export 'src/utils/generic_type_parser.dart';
export 'src/utils/reflection_utils.dart';
export 'src/utils/utils.dart' hide StringX;
export 'src/utils/must_avoid.dart';
export 'src/utils/constant.dart' hide IterableExtension;

export 'src/system/system.dart';
export 'src/system/system_detector.dart' hide StandardSystemDetector;
export 'src/system/properties.dart';

export 'src/annotations.dart';
export 'src/exceptions.dart';
export 'src/classes.dart';