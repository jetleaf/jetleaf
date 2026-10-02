# Jetleaf CLI

Jetleaf applications are managed through the `jetleaf` and `jl` commands.
The CLI coordinates the user-facing `jetleaf` starter with the lower-level
runtime and build facilities supplied by `jetleaf_core` and `jetleaf_build`.

`jetleaf_build` remains useful when developing Jetleaf infrastructure packages
directly. A normal Jetleaf application should use this CLI instead of
importing `jetleaf_build` in application code.

## Commands

```bash
jetleaf create my_app
jetleaf init
jetleaf dev
jetleaf test test/application_test.dart
jetleaf run lib/main.dart
jetleaf build
jetleaf proxy
jetleaf status
jetleaf stop
jetleaf clean
jetleaf clean --all
jetleaf help
```

`jl` is the short executable alias:

```bash
jl dev
jl test test/application_test.dart
jl build
```

Arguments intended for the application or test framework follow `--`:

```bash
jl test test/application_test.dart -- --reporter expanded
jl run lib/main.dart -- --port 8080
```

## Application Entry Point

The supported application contract remains:

```dart
import 'package:jetleaf/jetleaf.dart';

Future<void> main(List<String> args) async {
  final context = await JetleafApplication.run(Application(), args);
  print(context?.getDisplayName());
}

@JetleafApplicationStarter()
class Application {}
```

`init` discovers the starter class and the application file. It does not
replace `JetleafApplication.run` with a second context API.

## Project State

The root `Jetleaf` file is machine-owned project metadata. It is extensionless
JSON and identifies a directory as a Jetleaf application. It records the
application entrypoint, discovered tests, runtime mode, toolchain details,
generated paths, and initialization status.

Generated state is kept in `.jetleaf`:

```text
.jetleaf/
├── project/       context and runtime metadata
├── main/          application runtime metadata
├── cache/         main and test scan caches
├── generated/     bootstrap and entry stubs
├── proxy/         proxy manifest and tooling metadata
├── build/         app.dill and build reports
├── vm/            manager state, entry state, and snapshots
└── reports/       initialization and diagnostic reports
```

Legacy `_jetleaf`, `.dart_tool/jetleaf_build`, and root `Jetleaf.VM` state is
not the canonical location. The new paths are centralized in the path policy
so command implementations do not invent their own directories.

## Initialization and Warm Runtime

`jetleaf init` performs project detection, metadata preparation, proxy/build
cache generation, and starts the resident VM manager unless `--no-warm` is
provided.

```bash
jetleaf init
jetleaf init --no-warm
jetleaf dev
```

The resident manager stores its state under `.jetleaf/vm`. `dev`, `run`, and
`test` communicate with it through the existing loopback control protocol.
When the runtime manifest and fingerprints are current, test execution can
reuse the warmed VM without repeating the complete test scan.

## Build Output

The production build is Dart VM/kernel oriented. It does not produce an AOT
executable.

```text
.jetleaf/build/app.dill
.jetleaf/build/build.json
```

```bash
jetleaf build
jetleaf build --skip-tree-shaking
jetleaf build --strict
```

Tree-shaking is conservative. Classes referenced by Jetleaf annotations,
configuration, enabled modules, runtime hints, proxies, resources, and
unresolved dynamic references are retained. `--skip-tree-shaking` produces a
complete metadata build when a project uses discovery that cannot be proven
statically.

## JSON Files

All persisted Jetleaf JSON uses one formatter:

- UTF-8.
- Four-space indentation.
- Stable schema property order.
- Stable array order.
- Multiline arrays and objects.
- A trailing newline.
- Atomic replacement through a temporary file.

Package metadata follows this shape:

```json
[
    {
        "name": "jetleaf_build",
        "version": "1.0.0",
        "isRootPackage": true,
        "filePath": "/workspace/jetleaf_build/pubspec.yaml",
        "rootUri": "package:jetleaf_build/",
        "dependencies": [],
        "devDependencies": [],
        "jetleafDependencies": []
    }
]
```

Protocol messages exchanged with a resident VM may remain compact JSON lines;
the persisted project files and reports use the readable formatter.

## Runtime Modes

`development` performs discovery and watches source changes. `compatibility`
loads valid manifests first and falls back to scanning when necessary.
`strict` requires valid generated metadata and is intended for CI or
reproducible builds.

## Cleanup

```bash
jetleaf clean
```

Stops resident VMs and removes generated bootstrap, proxy, build, and report
state while preserving reusable caches where possible.

```bash
jetleaf clean --all
```

Removes all Jetleaf-managed state, including the root `Jetleaf` file and
caches. Deletion is restricted to paths owned by the detected project.

## Lower-Level Projects

Packages such as `jetleaf_build` and `jetleaf_core` are implementation layers.
When working inside one of those packages directly, the lower-level command
remains available:

```bash
dart run jetleaf_build:jl dev
dart run jetleaf_build:jl test test/some_test.dart
```

That workflow is intentionally separate from the normal Jetleaf application
workflow.

## Canonical Path Contract

All Jetleaf layers use one generated-state contract. The names are declared in
`jetleaf_build`'s `Constant` class, and platform-aware absolute paths are
constructed by `JetleafPaths`. The CLI re-exports that path service; it does
not define an alternative layout. This is important for packages such as
`jetleaf_lang`, `jetleaf_core`, and `jetleaf_web`, which may consume build
metadata without depending on CLI implementation details.

The canonical project layout is:

```text
Jetleaf
.jetleaf/
    project/       context and runtime manifests
    main/          application registry and runtime metadata
    cache/         main and test discovery caches
    generated/     bootstrap and entry source
    proxy/         proxy source and manifest
    build/         kernel, launcher, and build reports
    vm/            manager state, entry state, and snapshots
    reports/       diagnostics and command reports
```

Use `Constant.WORKSPACE_DIR_NAME`, `Constant.PROJECT_DIR_NAME`, and the other
named constants when a component needs a path segment. Use
`JetleafPaths.projectDir(root)`, `JetleafPaths.vmDir(root)`, or the matching
path method when it needs a file-system location. Do not reconstruct paths
with string interpolation in a package-specific helper.

The `.jetleaf` workspace is distinct from the active low-level generated
source directory `lib/_jetleaf`. The latter is still part of the existing
`jetleaf_build` runtime contract and is used by low-level packages and
generated imports. The CLI may migrate its generated artifacts into the
project workspace, but it must not reinterpret `JETLEAF_GENERATED_DIR_NAME`
or `GENERATED_DIR_NAME` as deprecated aliases. `.dart_tool/jetleaf_build` and
`Jetleaf.VM` are migration inputs for VM state, with existing canonical files
taking precedence.

Proxy Dart files follow the same boundary. The sibling proxy output and the
global generated proxy copy both remain under `lib`, normally as
`lib/<source>.proxy.dart` and `lib/_jetleaf/..._proxy.dart`. `.jetleaf/proxy`
may hold manifests or CLI metadata, but it must not become the source location
for executable proxy Dart files.
