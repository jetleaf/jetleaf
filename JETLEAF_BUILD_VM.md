# Jetleaf Build VM Runtime

This document describes the resident VM design implemented by
`libraries/jetleaf_build`. It covers discovery, cache warming, entry VMs,
test execution, logging, CLI usage, lifecycle, and the benchmark comparing
the new annotated workflow with direct `dart test` execution.

## Purpose

`jetleaf_build` is a framework build/runtime layer. It is not an SDK.

The development command starts a resident manager process. The manager
discovers annotated entries, warms the production and test caches, and boots a
resident Dart VM for each selected entry. Later `jl run` and `jl test` commands
connect to that manager instead of starting a fresh runtime scan.

The design has two separate warm layers:

1. **Build cache warm-up**: filesystem discovery and declaration/cache writing
   performed by the manager.
2. **Runtime warm-up**: `runScan` or `runTestScan` executed inside the entry VM
   after the generated parked stub starts.

Both are completed before the manager reports the entry as active.

## Lifecycle

### `jl dev`

For each discovered `@JetleafEntry()` or `@JetleafTest()` entry:

1. Validate the project and bind the manager control socket.
2. Discover annotated `void main()` functions.
3. Warm the production and test build caches.
4. Generate a parked entry stub.
5. Import the target entry into that stub so its libraries are visible to the
   runtime scanner.
6. Compile and launch a resident Dart VM with assertions enabled.
7. Execute the entry VM's one-time `runScan` or `runTestScan`.
8. Start the loopback command server inside the child VM.
9. Publish the entry as `parked` and ready.

The manager remains alive until `jl stop`, Ctrl-C, or another termination
signal is received.

### `jl test`

For an already active test VM:

1. Connect to the manager control socket.
2. Wait for manager readiness if startup is still in progress.
3. Incrementally recompile the generated test driver.
4. Reload the resident isolate.
5. Send a test command through the child VM's loopback command socket.
6. Run the test engine and stream child output back to the client.
7. Return exit code `0` only when the test engine reports success.

The generated `_ensureJetleafRuntime()` guard is already true in this path.
The manager also emits `ensure-runtime:skipped`, making the reuse explicit.

### When scanning happens again

`runScan` or `runTestScan` runs when an entry VM is initially booted. It runs
again only when that VM has exited, failed, or must be cleanly rebooted.

An ordinary `jl test` request against a healthy resident VM does not perform a
second runtime scan. `--lazy` changes the timing: it delays the first VM boot,
so the first `jl test` request performs that entry's initial warm-up.

## Generated Entry Stubs

`entry_writer.dart` generates two kinds of stubs.

### Parked stub

The parked stub:

- imports the selected user entry;
- runs the production or test runtime scan once;
- reports `[jl] runtime ready`;
- opens a loopback command socket;
- keeps the isolate alive with a timer and server socket.

### Runner stub

The runner stub is written during a test or application request. It contains:

- the user entry import;
- the runtime guard;
- the test driver or application invocation;
- the command handler used by the resident VM.

The test driver resets `_jlTestsDone`, `_jlTestsPassed`, and the error state on
every invocation. It runs registration, pumps the event queue, builds a suite,
runs the test engine, and returns a boolean result.

## Logging

Manager and child-VM output is represented as structured `log` events using
`JetleafLogRecord`.

Each event preserves machine-readable fields:

```json
{
  "type": "log",
  "timestamp": "2026-09-29T19:57:12.000Z",
  "level": "info",
  "source": "vm",
  "entry": "test/example_test.dart",
  "stream": "stdout",
  "message": "[jl] runtime ready",
  "formatted": "[19:57:12] [INFO] [vm] [test/example_test.dart] [jl] runtime ready"
}
```

The CLI prints `formatted`. `jetleaf_cli` can consume `message`, `level`,
`source`, `entry`, `stream`, and `phase` while ignoring the human prefix.

Human manager output uses this shape:

```text
[19:57:12] [INFO] [manager] warming test/example_test.dart ...
[19:57:12] [INFO] [vm] [test/example_test.dart] [jl] runtime ready
```

The startup banner is intentionally unformatted. Use `--plain` to suppress
timestamps and source prefixes for regular log lines:

```bash
dart run jetleaf_build:jl dev --plain
```

Use `--machine` when another process should consume JSON lines directly:

```bash
dart run jetleaf_build:jl dev --machine
```

## CLI Reference

All commands below are run from the project using `jetleaf_build`.

### Start development mode

```bash
dart run jetleaf_build:jl dev
```

Options:

- `--root <dir>`: project root, defaulting to the current directory.
- `--path <file>`: boot only the selected entry; repeatable.
- `--verbose`: print in-isolate scanner callbacks.
- `--plain`: omit human log prefixes.
- `--lazy`: discover and warm caches, but boot entry VMs on demand.
- `--machine`: emit JSON event lines.
- `--once`: warm caches and exit without resident VMs.

Examples:

```bash
dart run jetleaf_build:jl dev --path test/conversion_utils_test.dart
dart run jetleaf_build:jl dev --verbose
dart run jetleaf_build:jl dev --once
```

### Run an application entry

```bash
dart run jetleaf_build:jl run lib/main.dart
```

Application arguments must follow a clear separator:

```bash
dart run jetleaf_build:jl run lib/main.dart -- --port 8080
```

### Run one test entry

```bash
dart run jetleaf_build:jl test test/example_test.dart
```

Run all discovered test entries:

```bash
dart run jetleaf_build:jl test --all
```

### Inspect or stop the manager

```bash
dart run jetleaf_build:jl status
dart run jetleaf_build:jl stop
```

The manager writes:

- `Jetleaf.VM`: human-readable entry states;
- `.dart_tool/jetleaf_build/manager.json`: manager PID, control port, and
  readiness state;
- `.dart_tool/jetleaf_build/entries/`: incremental entry snapshots.

## State Model

An entry transitions through states such as:

```text
discovered -> warming -> parked -> running -> parked
                         \-> failed
```

If the child process exits unexpectedly, its entry is marked failed. The next
run disposes the stale backend and boots a clean VM.

## Benchmark

### Test subject

The benchmark used the existing `jetleaf_convert` conversion test, containing
seven test cases and runtime-dependent conversion metadata. The annotated
variant was run through the resident VM. A temporary unannotated copy was used
for the direct `dart test` experiments and removed afterward.

The measurements were taken on 2026-09-29 from the local Jetleaf workspace.
They are comparative measurements, not a hardware-independent performance
claim.

### Results

| Workflow | Result | Wall time | Interpretation |
| --- | ---: | ---: | --- |
| `jl test` with no manager | exit 1 | 2.28 s | Correctly fails fast because no resident VM exists. |
| Direct original `dart test` | exit 1 | 4.16 s | Fails before tests because Jetleaf runtime metadata is not initialized. |
| Unannotated copy with plain `runTestScan()` in `setUpAll` | exit 1 | 8.99 s | Scan completes, but generic converter metadata is incomplete. |
| Unannotated copy with forced loading in `setUpAll` | interrupted | 4:07.18 | Worker-isolate force loading did not complete during the benchmark. |
| Annotated `jl dev` startup to resident readiness | success | about 39 s | Includes discovery, cache warm-up, VM compilation, and runtime scan. |
| First `jl test` against resident VM | exit 0 | 24.60 s | Includes incremental runner compilation, reload, test engine, and streamed output. Runtime scan was skipped. |
| Repeated `jl test` against same VM | exit 0 | 4.36 s | Reuses the resident VM and warmed runtime. |

The resident workflow moves the expensive work into the explicit development
startup phase. Once startup is complete, repeated tests are materially faster
and, more importantly, operate against the already initialized Jetleaf runtime.

### Observed warm-path evidence

The test client reported:

```text
… recompile:done errors=0
… ensure-runtime:skipped
… run-tests:start
...
00:00 +7: All tests passed!
… run-tests:done
```

There was no second `[jl] runtime ready` event during the test request. The
only runtime-ready event occurred during `jl dev` VM boot.

### Benchmark interpretation

The two designs optimize different phases:

- Direct `dart test` has low process startup overhead, but it has no automatic
  Jetleaf runtime bootstrap and therefore cannot run these tests unchanged.
- The annotated resident design pays a deliberate startup cost once, then
  reuses the VM and runtime across test commands.
- The first warm test still pays incremental compilation and reload cost.
- Repeated warm tests are the meaningful steady-state comparison.

For a developer running many test files or rerunning one file repeatedly, the
resident design amortizes the scan and VM startup cost. For a single isolated
test invocation, `jl dev` startup is additional overhead unless the manager is
already running.

## Recommended Workflows

Interactive development:

```bash
dart run jetleaf_build:jl dev
dart run jetleaf_build:jl test test/example_test.dart
dart run jetleaf_build:jl test test/another_test.dart
dart run jetleaf_build:jl stop
```

Focused debugging:

```bash
dart run jetleaf_build:jl dev --path test/example_test.dart --verbose
dart run jetleaf_build:jl test test/example_test.dart
```

CI cache preparation:

```bash
dart run jetleaf_build:jl dev --once
```

Tool integration:

```bash
dart run jetleaf_build:jl dev --machine
```

Consume the JSON event stream and prefer the structured log fields over
parsing the formatted human line.

## Shared Workspace Paths

The VM does not own a private directory policy. Its state is part of the
workspace contract exported by `jetleaf_build`:

```text
.jetleaf/
    generated/entries/<entry>.dart
    vm/state.json
    vm/manager.json
    vm/entries/<entry>.dill
```

`Constant` in `src/utils/constant.dart` defines the names, and `JetleafPaths`
in `src/cache/jetleaf_paths.dart` joins them to the project root. The VM,
entry writer, cache scanners, CLI, and higher framework layers must use these
services so a project never receives competing workspace layouts. The
low-level `lib/_jetleaf` generated-source directory remains an active
runtime/build contract; `.dart_tool/jetleaf_build` and `Jetleaf.VM` are the
legacy VM-state locations handled only by migration.

When adding a generated artifact, add its stable name to `Constant`, add its
path constructor to `JetleafPaths`, document its lifecycle here, and then use
that constructor from the owning feature. This keeps cleanup, migration,
diagnostics, and future CLI consumers aligned.
