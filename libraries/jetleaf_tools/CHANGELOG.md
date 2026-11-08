## 1.0.0

### Initial Release
* **Unified Tooling Architecture**: Initial standalone release of `jetleaf_tools`, consolidating compiler infrastructure, static analysis, code generation, and the `jl` CLI toolchain for the Jetleaf ecosystem.
* **AOT Code Generation & Reflection Registry**:
  * Automated synthesis of static metadata registries (`aot_registry.g.dart`) without runtime mirrors.
  * Direct method invocation and constructor dispatch mapping to preserve tree-shaking while enabling full metaprogramming capabilities.
  * Annotation reflection generation for runtime introspection.
* **Incremental Build & Cache System**:
  * High-speed AST analyzer caching via `CacheableManager` and binary disk serialization.
  * Dependency graph reachability analysis to strip unreferenced runtime declarations during production builds.
* **Developer CLI (`jl`)**:
  * `jl dev` — Zero-configuration hot-reloading development server powered by Dart VM Service and the frontend compiler.
  * `jl build` — Production compilation pipeline generating optimized `.dill` kernel artifacts or standalone native binaries (`dart compile exe`).
  * `jl run` — Production kernel execution runner.
* **Runtime Scanning**:
  * Parallel codebase scanning (`runScan`) for annotations, pods, configurations, and component discovery.
  * Test scanner (`runTestScan`) for rapid integration testing without code generation overhead.
