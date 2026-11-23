## 1.1.0

### Added & Improvements

- **Hot Reload & AOT Re-binding**: `AotRegistrarWriter` now emits `force` parameter support on `registerGeneratedArtifacts` / `_initRuntime` plus `reloadGeneratedArtifacts(...)` / `reloadTestGeneratedArtifacts(...)`, and `JetleafVM` invokes `HotReloadCoordinator.notifyReload(...)` after `vmService.reloadSources(...)`.

- **Development runtime registrar (`src/runner/registrar.dart`)**: Extracted and exported `isDevelopmentRuntime`, `AotRegistrar`, `bindAotRegistrar`, `getBoundAotRegistrar`, `resolveProjectRoot`, and `ensureDevelopmentRuntime` for both `runScan` and `runTestScan` (`forTests: true`). Automatic building and binding only run in development mode (disabled in production/AOT builds), with a bootstrapped child-process fallback (`SIGINT`/`SIGTERM` forwarding) when `_jetleaf/main.dart` is not imported directly.
- **Test AOT partitioning**: `AotRegistrarWriter` and `TestCommand` partition main and test AOT artifacts cleanly across `aot_pod_registry_writer.dart`, `aot_proxy_writer.dart`, `aot_sub_registrar_writer.dart`, `aot_type_registry_writer.dart`, `build_command.dart`, and `entry_commands.dart`.
- **Pub Workspace support**: `jl dev`, `jl run`, `jl test`, `jl build`, `jl status` and `jl stop` now fan out to pub-workspace members when invoked at a workspace root (`pubspec.yaml` with a top-level `workspace:` list). Running inside a member directory is unchanged. Workspace member detection walks the root's `pubspec.yaml` and each member's `resolution: workspace` flag.
- **`jl proxy`**: New subcommand emits interceptable AOT proxies for stereotype-annotated components to `lib/_jetleaf/proxies/` without rebuilding caches or the AOT registry (useful for inspecting generated proxies between builds).
- **Test Runner AOT Registration**: `jl test` stubs now import and invoke `lib/_jetleaf/test.dart` (as `aot.registerTestGeneratedArtifacts()`) before any `@JetleafTest` entry runs — framework method dispatches through the generated dispatch tables now resolve correctly in warm test VMs instead of failing with `MethodNotFoundException`.
- **Test-scan Parity**: `jl build` / `jl dev` test scans request `skipTests: false`; production scans request `skipTests: true`.
- **Pod Definition `@Pod` Factory-method AOT Emission**: `jl build` emits configuration `@Pod` factory methods statically into generated registries (matching `AnnotatedPodMethodBuilder` naming exactly — `@Named` > `@Pod('value')` > bare method name), unwraps `Future<X>` return types to their completeness type `X`, honours `@Primary` on factory methods, and registers `<configClass>`-qualified pod names alongside the bare name when both are free to avoid duplicate names.
- **`.jetleaf` Project Detection**: `isJetLeafBuildProject` now recognises projects with a `.jetleaf/` state directory (how in-repo framework packages are detected).
- **Annotation Constructor Calls**: The generated annotation-registry writer resolves `Clazz.namedCtor(...)` / `const Clazz.namedCtor(...)` constructor references, normalises list-like annotation arguments to `List<dynamic>`, and drops spurious empty-constructor `constructByName` lookups that previously produced invalid annotation instances.

### Changed

- **Workspace & constant consolidation**: Refactored `workspace.dart` into `final class Workspace` with static methods (`Workspace.membersFromPubspec`, `Workspace.isRoot`, `Workspace.members`, `Workspace.memberOwning`), removed the duplicate `lib/src/utils/constant.dart` in favor of `Constant` from `jetleaf_core`, and updated `AotRegistrarWriter` and `registrar.dart` to use `Constant` function name fields.
- **AOT registry layout**: `lib/_jetleaf/main/registry.g.dart`, `lib/_jetleaf/test/registry.g.dart` and `lib/_jetleaf/proxies/` consolidate the previously scattered `lib/_jetleaf_test/`, `lib/_proxies/` and root-level `lib/_jetleaf/` directories. Master file renamed `aot_registry.g.dart` → `main/registry.g.dart`; registrar renamed `registerGeneratedAotPods` → `registerGeneratedArtifacts` (main) and `registerGeneratedTestAotPods` → `registerTestGeneratedArtifacts` (test).
- **Workspace CLI**: `jl` family reworked for workspace fan-out; each command understands both a single-project root and a workspace root.
- **Mirror removal**: `dart:mirrors` mentions eliminated throughout documentation and doc comments (`hasMirrorImport`/`_mirrorImportRegex` helpers removed); `runtime reflection` vocabulary throughout.
- **Package discovery**: `packageUris` propagation now preserves workspace package orderings across dependency buttons consistently.

---

## 1.0.2

### Architecture & Tooling Refinement
* **Inverted Tooling Dependency**: `jetleaf_tools` now cleanly depends on `jetleaf_core: ^2.0.1` as a build and code-generation toolchain.
* **Separation of Concerns**: Moved runtime data models, reflective declarations, binary buffer serialization, and core exceptions into `jetleaf_core`.
* **No Core Re-Exports**: Removed all runtime re-exports from `jetleaf_tools` so it functions strictly as a compiler, scanner, and CLI development toolchain.

## 1.0.1

### Fixes & Improvements
* **Resolved Circular Dependency**: Removed unintended runtime dependency on `jetleaf_core` to establish `jetleaf_tools` as a strictly independent, standalone tooling package.
* **Pub.dev Packaging Compliance**:
  * Moved `package:meta` from `dev_dependencies` to runtime `dependencies` to satisfy pub.dev validation requirements for annotations used across `lib/src/`.
  * Added root `LICENSE` file for pub.dev distribution.

## 1.0.0

### Initial Release
* **Unified Tooling Architecture**: Initial standalone release of `jetleaf_tools`, consolidating compiler infrastructure, static analysis, code generation, and the `jl` CLI toolchain for the Jetleaf ecosystem.
* **AOT Code Generation & Reflection Registry**:
  * Automated synthesis of static metadata registries (`registry.g.dart`) without runtime reflection.
  * Direct method invocation and constructor dispatch mapping to preserve tree-shaking while enabling full metaprogramming capabilities.
  * Annotation reflection generation for runtime introspection.
* **Incremental Build & Cache System**:
  * High-speed AST analyzer caching via `CacheableManager` and binary disk serialization.
  * Dependency graph reachability analysis to strip unreferenced runtime declarations during production builds.
* **Developer CLI (`jl`)**:
  * `jl dev` — Zero-configuration hot-reloading development server powered by Dart VM Service and the frontend compiler.
  * `jl build` — Production compilation pipeline generating optimized `.dill` kernel artifacts or standalone native binaries (`dart compile exe`).
  * `jl run` — Production kernel execution runner.
  * `jl proxy` — Proxy-only emission: writes `$$JLInterfaced$$` interceptable proxies for stereotype-annotated components to `lib/_jetleaf/proxies/` without rebuilding caches or the AOT registry (useful for inspecting generated proxies between builds).
* **Runtime Scanning**:
  * Parallel codebase scanning (`runScan`) for annotations, pods, configurations, and component discovery.
  * Test scanner (`runTestScan`) for rapid integration testing without code generation overhead.