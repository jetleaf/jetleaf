<div align="center">

# jetleaf_tools

**Build compiler pipeline, static AST reflection generator, incremental caching engine, and CLI toolchain for the Jetleaf framework.**

[![pub package](https://img.shields.io/pub/v/jetleaf_tools.svg?logo=dart&logoColor=white&color=0b2ab5)](https://pub.dev/packages/jetleaf_tools)
[![tests](https://img.shields.io/badge/tests-passing-brightgreen.svg?logo=github)](https://github.com/jetleaf/jetleaf)
[![AOT code generator](https://img.shields.io/badge/AOT%20Codegen-zero%20mirrors-success.svg)](https://pub.dev/packages/jetleaf_tools)
[![license](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![platform](https://img.shields.io/badge/platform-macos%20%7C%20linux%20%7C%20windows-lightgrey)](https://pub.dev/packages/jetleaf_tools)

</div>

<p align="left">
  <a href="#-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-developer-cli-jl">Developer CLI</a> •
  <a href="#-build-pipeline--architecture">Build Architecture</a> •
  <a href="#-aot-registry-synthesis">AOT Registry Synthesis</a> •
  <a href="#-incremental-caching">Incremental Caching</a> •
  <a href="#-runtime-scanning-api">Runtime Scanning API</a> •
  <a href="#-testing">Testing</a>
</p>

---

`jetleaf_tools` provides the build-time compiler infrastructure, static analysis scanners, ahead-of-time (AOT) reflection registries, and command-line developer tooling (`jl`) for the Jetleaf application ecosystem.

It replaces runtime reflection (`dart:mirrors`) with build-time code synthesis — allowing your server, CLI, and web applications to benefit from rich dependency injection, configuration binding, and metadata introspection while compiling to lightning-fast, tree-shaken native binaries (`dart compile exe`).

```dart
import 'package:jetleaf_tools/jetleaf_tools.dart';
```

---

## ✨ Features

* **Mirror-Free AOT Code Synthesis** — Automatically synthesizes static reflection registries (`aot_registry.g.dart`) containing constructor dispatch tables, method invocation adapters, and metadata tables without any reliance on `dart:mirrors`.
* **The `jl` Developer CLI** — Unified command-line interface featuring:
  * `jl dev` — Rapid hot-reloading development server with resident compiler state.
  * `jl build` — Production AOT build pipeline with reachability tree-shaking and kernel bundling.
* **High-Speed Incremental Caching** — Analyzes AST deltas using `CacheableManager` and binary disk serialization, ensuring millisecond-level incremental builds during development.
* **Reachability Tree-Shaking Protection** — Traces dependency graphs from entry points to ensure reflection-driven classes are explicitly linked and preserved during `dart compile exe` tree shaking.
* **Dual Execution Modes (JIT & AOT)** — Seamlessly supports both JIT scanning during local iterations and pre-compiled AOT dispatch registries in production builds.

---

## 📦 Installation

Add `jetleaf_tools` to your `dev_dependencies` in `pubspec.yaml`:

```yaml
dependencies:
  jetleaf_core: ^2.0.0

dev_dependencies:
  jetleaf_tools: ^1.0.1
```

To use the `jl` command-line executable globally:

```sh
dart pub global activate jetleaf_tools
```

Or run directly via `dart run`:

```sh
dart run jetleaf_tools:jl --help
```

---

## 💻 Developer CLI (`jl`)

`jetleaf_tools` provides the primary developer workflow tool `jl`:

### 1. `jl dev` — Development Mode with Hot Reload

Runs your application with hot reloading enabled. Watches project source directories, re-indexes modified ASTs incrementally, and refreshes the running Dart isolate:

```sh
# Start development server on default entrypoint (bin/main.dart)
jl dev

# Specify custom entrypoint and target port
jl dev --entry=bin/server.dart --port=8080
```

### 2. `jl build` — Production Compilation

Scans the application codebase, synthesizes the complete AOT dispatch registry, and produces an optimized production build:

```sh
# Compile to a production kernel bundle (.dill)
jl build

# Compile to a standalone native executable (.exe)
jl build --exe -o build/app.exe
```

### 3. `jl test` — Automated Test Suite Runner

Scans test files and runs unit and integration tests with synthetic reflection contexts:

```sh
jl test
```

---

## 🏗 Build Pipeline & Architecture

The `jetleaf_tools` compiler engine operates through four structured pipeline phases:

```text
  ┌────────────────┐       ┌────────────────────┐       ┌──────────────────┐
  │  Source Code   │  ──>  │ Analyzer & Scanner │  ──>  │ Reachability     │
  │  AST Parsing   │       │ Metadata Discovery │       │ Graph Tracing    │
  └────────────────┘       └────────────────────┘       └──────────────────┘
                                                                  │
                                                                  ▼
  ┌────────────────┐       ┌────────────────────┐       ┌──────────────────┐
  │ Native Binary  │  <──  │ Dart AOT Compiler  │  <──  │ AOT Registry     │
  │ (Tree-Shaken)  │       │ (dart compile exe) │       │ Code Synthesis   │
  └────────────────┘       └────────────────────┘       └──────────────────┘
```

1. **AST Scanning**: Discovers `@Component`, `@Service`, `@Repository`, `@Configuration`, `@Pod`, `@Autowired`, and `@Value` annotations using the Dart Analyzer.
2. **Metadata Discovery**: Resolves type hierarchies, constructor signatures, method parameter matrices, and runtime hints.
3. **Reachability Analysis**: Discovers all reachable types from entry points, eliminating unused code declarations.
4. **Registry Synthesis**: Generates `_jetleaf/aot_registry.g.dart` mapping class tokens to dynamic constructors and methods.

---

## ⚡ AOT Registry Synthesis

In standard Dart AOT native compilation, unreferenced symbols are stripped by the compiler tree-shaker. `jetleaf_tools` generates direct, strongly-typed programmatic invocation adapters:

```dart
// Generated by jetleaf_tools - Do not edit manually
void registerJetleafAot(AotRuntimeExecutor executor) {
  // Registers constructor factory
  executor.registerConstructor('UserService', (args) {
    return UserService(args.getPositional(0));
  });

  // Registers method invocation dispatcher
  executor.registerMethod('UserService.createUser', (instance, args) {
    return (instance as UserService).createUser(args.getPositional(0));
  });
}
```

This guarantees that:
- Dart's compiler retains necessary constructors and methods without requiring `dart:mirrors`.
- Execution is fully native with zero runtime dynamic reflection overhead.

---

## 🗄 Incremental Caching

The caching subsystem maintains serialized metadata under `.jetleaf/cache/`:
- **File Hashes**: Tracks MD5 file signatures to skip unchanged source files.
- **Binary Declaration Cache**: Serializes AST models into compact binary formats.
- **Fast Startup**: Re-uses cached metadata between builds to reduce cold-start compilation times by over 80%.

---

## 🔍 Runtime Scanning API

For programmatic framework and plugin extensions, `jetleaf_tools` exposes runtime scanning interfaces:

```dart
import 'package:jetleaf_tools/jetleaf_tools.dart';

void main() async {
  // Execute a runtime scan across the current project
  final summary = await runScan(
    args: ['--profile=prod'],
    config: RuntimeScannerConfiguration(
      targetPackages: ['my_app'],
      scanDevDependencies: false,
    ),
  );

  print('Discovered ${summary.discoveredClasses.length} managed classes.');
}
```

---

## 🧪 Testing

Run package tests:

```sh
dart test
```

---

## 📄 License

Licensed under the Apache License, Version 2.0. See the [LICENSE](LICENSE) file for details.