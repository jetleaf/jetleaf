# Testing with `jl`

How tests run in this repo: one warm manager per package, declarative
entries, no bootstrap boilerplate.

## The model

- `jl dev` (per package) discovers every `void main()` annotated with
  `@JetleafTest` / `@JetleafEntry`, warms the shared `.jetleaf/` cache
  once, and boots one VM per entry.
- Running a test = invoking its `main()` inside the already-warm isolate.
  The manager populates the JetLeaf runtime first (cache fast path after
  the first run), so test files contain **no** `runTestScan` /
  `setupRuntime` calls.
- Plain `dart test` does **not** bootstrap the runtime. A cold run fails
  with `Runtime is not yet initialized`. Always run through `jl`.

## Annotating a test

```dart
import 'package:jetleaf_lang/lang.dart'; // or package:jetleaf_build/jetleaf_build.dart
import 'package:test/test.dart';

@JetleafTest()
void main() {
  test('…', () {
    // Runtime already populated.
  });
}
```

Rules:

- Only top-level `void main()` is discovered (sync or `async` — both
  compile to the right call shape automatically).
- Options: `@JetleafTest(args: [...], timeoutSeconds: 30)`.
- Never call `runTestScan` / `setupRuntime` in test files — delete them
  instead of commenting out.
- Apps use the sibling `@JetleafEntry()` (production runtime,
  `.jetleaf/` cache) and run via `jl run`.

## Running

From the package directory (e.g. `libraries/jetleaf_convert/`):

```bash
dart run jetleaf_build:jl dev                          # once, keep running
dart run jetleaf_build:jl test test/app_test.dart      # one file
dart run jetleaf_build:jl test --all                   # every @JetleafTest entry
dart run jetleaf_build:jl run lib/main.dart            # app entries
dart run jetleaf_build:jl status                       # state incl. ws:// URLs
dart run jetleaf_build:jl stop                         # everything
```

`jl dev` flags: `--lazy` (boot VMs on first run), `--once` (warm cache
and exit, for CI — no VMs), `--root <dir>` (manage another package).

Entry states live in `./Jetleaf.VM` at the package root (4-space JSON
array, gitignored). Manager metadata (pid, control port) lives in
`.dart_tool/jetleaf_build/manager.json`.

## VS Code

- Tasks + attach config: `libraries/jetleaf_convert/.vscode/` (concrete,
  no prompts) and the shared, documented setup in `.vscode/` (repo root,
  package picker + reuse instructions in `.vscode/README.md`).
- The `Run | Debug` CodeLens above code always runs cold `dart` and
  bypasses `jl`. Warm runs: `Terminal > Run Task > jl: test current
  file`. Warm debugging: `jl: status` → copy the entry `ws://` URL →
  F5 `jl: attach warm VM` → paste.

## New test checklist

1. Create `test/<name>_test.dart` with a top-level `void main()`.
2. Put `@JetleafTest()` directly above `main`.
3. Write `group`/`test` normally. No `setUpAll` scan, no helpers.
4. Run `jl test test/<name>_test.dart` (dev running). It appears in
   `./Jetleaf.VM` and in `jl test --all` automatically.

## Troubleshooting

| Symptom | Meaning / fix |
|---|---|
| `Runtime is not yet initialized` | Ran cold (`dart test`) or outside `jl dev`. Run via `jl test` with dev up. |
| `jl dev is not running (no manager file)` | Start `jl dev` in the package first. |
| `recompiled … (errors=N)` + `compile: …` lines | Real compile errors in the entry/stub — read the `compile:` lines, they name the file and line. |
| `stale vm detected …, rebooting …` | The isolate predated its stub; the manager rebooted it and retried. Informational. |
| `VM busy` | That entry is mid-run; wait or `jl stop <file>`. |
| `Timed out waiting for … boot` | First frontend compile is slow (large graph); wait for the `active …` line, or use `--lazy`. |
| Edits not picked up | Save again (watcher debounces 750ms); check the `changed … / reloaded vm …` lines in the dev terminal. |

## Reference

- Annotations: `libraries/jetleaf_build/lib/src/annotations.dart`
  (`JetleafEntry`, `JetleafTest`, re-exported by `jetleaf_lang`'s
  `lang.dart`).
- Manager: `libraries/jetleaf_build/lib/src/vm/jetleaf_vm.dart`
  (`EntryWriter → Discoverable → JetleafVM`).
- Protocol: `runApp` / `runTest` / `status` / `stop` over the loopback
  control channel; `done` frame terminates each connection.
