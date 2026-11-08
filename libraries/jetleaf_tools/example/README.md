# jetleaf_tools example

A runnable showcase demonstrating the developer tooling, AST indexing, runtime manifest generation, and AOT runtime execution capabilities of `jetleaf_tools` 1.0.0.

## Running the Example

```sh
cd example
dart pub get
dart run lib/main.dart
```

## Features Demonstrated

1. **AST Codebase Analysis (`DeclarationBuilder`, `FileDiscovery`)**
   - Automatically crawls and parses Dart source files via the Dart Analyzer.
   - Extracts complete structural metadata (`ClassDeclaration`, `ConstructorDeclaration`, `MethodDeclaration`, `FieldDeclaration`, parameter types, and nullability) without loading code into mirrors or running the VM.
2. **Runtime Manifest Generation (`RuntimeManifest`)**
   - Serializes discovered component qualified names and metadata into structured JSON manifests for production build verification.
3. **AOT Runtime Executor (`AotRuntimeExecutor`)**
   - Direct function-pointer registration and invocation for constructors and methods.
   - Demonstrates how Jetleaf achieves pure Dart AOT compatibility with zero reliance on `dart:mirrors`.