// test/support/ensure_registry.dart
//
// The jetleaf_data test suite relies on reflection over entities. Run
// `jl build --test` in the package (or the repo root) first — it emits the
// AOT registry imported here. The `_jetleaf/` directories are content-addressed
// and gitignored, so importing them does not change the source tree.

import 'package:jetleaf_data/_jetleaf/test/registry.g.dart' as aot;

bool _registered = false;

/// Registers the generated AOT artifacts. Idempotent.
Future<void> ensureAotRegistered() async {
  if (_registered) {
    return;
  }

  await aot.registerTestGeneratedArtifacts();
  _registered = true;
}