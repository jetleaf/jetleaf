// Shared AOT bootstrap for the web test suite.
import 'package:jetleaf_web/_jetleaf/test/registry.g.dart' show registerTestGeneratedArtifacts;

/// Registers the test-only AOT registry for web artifacts (jetson registry,
/// jetson dependencies, jetleaf_core, jetson tools and `jetleaf_web`).
///
/// `dart test` compiles each suite separately; library-level laziness means
/// merely importing the registry does not materialise the metadata. Call this
/// at the start of tests that rely on annotation/registry materialisation.
Future<void> ensureTestAotRegistered() => registerTestGeneratedArtifacts();

/// Initialises the generated test registry synchronously.
///
/// `registerTestGeneratedArtifacts()` runs `_initRuntime()` before its first
/// suspension point, so calling it without `await` initialises the registry
/// immediately. Test files call this from a synchronous `main()` so all
/// registry libraries are loaded before any test file declares its groups.
void ensureTestAotRegisteredSync() {
  registerTestGeneratedArtifacts();
}