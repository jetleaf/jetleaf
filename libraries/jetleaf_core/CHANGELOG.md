## 2.1.0

### Added

- **Hot Reload & Hot Restart Infrastructure**: Added `HotReloadDelta`, `HotReloadEvent`, `HotRestartEvent`, `RefreshablePod`, `ReloadAwarePodProcessor`, `@RefreshScope`, `RefreshPodScope`, `HotReloadCoordinator`, `DefaultListablePodFactory.refreshOnHotReload(...)`, and `AbstractApplicationContext.triggerHotReload(...)` / `triggerHotRestart(...)`.

- **Reified generic type support (`TypeReifier` / `StandardTypeReifier<T>`)**: Runtime reflection (`_MaterialLibrary`) now resolves reified generic `List`, `Set`, and `Map` types even for user-defined or previously unknown types.
- **`hasClass` probe**: The runtime package now exposes `RuntimeProvider.hasClass(String name, [String? package])` — a strict, non-synthesizing existence check for a class known to the registry (used in place of defensive type-lookup gymnastics that synthesized fallback declarations).
- **`MaterializedLibrary.hasRegisteredType`**: Strict type-registry lookup without synthesizing fallback entries.
- **`Class.forType` Type-token support**: `Class.forType(int)`, `Class.forType(List<String>)` and similar type-token calls resolve deterministically through `Runtime.findClassByType` instead of synthesizing placeholder declarations.
- **Parameterized generic hierarchy**: `ClassUtils.getClassHierarchy(...)` now walks the raw base classes of parameterized generics (`List<T>`, `Set<T>`, `Map<K, V>`, `Iterable<T>`) so ancestor matching works for parameterized component types.
- **`_typeSignature()`**: `Class` instances created from erased runtime `Type`s (e.g. through `Class.declared(...)`) now recover reified type arguments from the declaration when `T` has no generic arguments — `Class<List<int>>().componentType()` resolves.
- **`_MaterialLibrary.hasClass`**: Strict provider probe reused everywhere that needs truthful class-existence before synthesis.
- **Parameterized `findClassByName(…)` fallback**: Unknown simple names synthesize a best-effort declaration rooted at `package:synthetic/SimpleName.dart` instead of throwing (kept for call sites that probe existence first).

### Changed

- **Terminology**: "mirrors" / "dart:mirrors" has been replaced with "runtime reflection" throughout documentation, examples and source comments. `Class` is described as a reflective bridge (reflection-agnostic).
- **`isClass` semantics**: `ClassUtils.isClass(name)` now probes `Runtime.hasClass(name)` strictly instead of relying on permissive synth fallbacks — truly missing class names correctly report `false`.
- **`Class.forType`**: Passing a `Type` token returns `Class<Type>`; value instances still return `Class<C>`.
- **`_Class` parameterized preference**: When constructing parameterized classes, scanned base declarations are preferred over synthesized ones only when they are real (scanned) declarations — synthetic `List` bases no longer shadow the synthesized `List<int>` declaration carrying reified arguments.
- **Helper consolidation**: `conversion_adapter_utils.dart` rewritten — generic `x == Class<Y>() || x.getType() is Y` chains replaced by `x.getType() == Y` throughout.

### Fixed

- **Pod destruction double-wrapping guard**: `AbstractPodFactory.destroyPod` now checks for `DisposableLifecycleManager` before delegating to `_destroy`, preventing duplicate lifecycle wrapping.
- **Event listener deduplication**: `SimpleApplicationEventBus.addApplicationListener` avoids duplicate listener registration.
- **Processor & interception hardening**: Fixes across `AutowiredAnnotationPodProcessor`, `CommonAnnotationPodProcessor`, `ConfigurationPropertyPodProcessor`, `AbstractMethodDispatcher`, and `Interceptable`.
- **`DefaultConversionService.remove()`** restores the built-in converter snapshot instead of clearing the bucket (custom converters removed first; builtins survive `remove()`).
- **`Iterable` to `String` conversion** emits comma-separated values (Spring semantics) instead of leaking through an arbitrary `toString()`.
- **`ConfigurationPropertyPodProcessor`** no longer crashes with a null-check exception when the annotation is present via `hasDirectAnnotation` but cannot be constructed at this stage (AOT/JIT visibility gap) — the bean is silently skipped instead of failing.
- **`fromUri`** on `StandardLibraryDeclaration` rejects empty package names (e.g. `''`) and resolves nearest pubspec `name:` for `file://` URIs.
- **Private VM implementation types** (e.g. `_Map<String, dynamic>`, `_BigIntImpl`, `_RegExp`, `_SimpleUri`) are normalized to their public interface declarations for reflection sites.
- **Parameterized Collections**: `Class<T>.isArray()` and `Class<T>.isKeyValuePaired()` now recognise parameterized generic targets (`List<T>`, `Set<T>`, `Map<K, V>`, `MapEntry<K, V>`) via both the reified `Type` and the declaration name, in addition to `TypeKind` and type-argument inspection.
- **Class Resolution**: `findClassByType` / `_MaterialLibrary.findClassByType` no longer fall back to matching bare base names for parameterized types — prevents `Class<User>()` resolving to an unrelated `User` declaration from another package or scope.
- **Factory Method Dedup**: `AnnotatedPodMethodBuilder` only qualifies an auto-named pod (`configClass.methodName`) when the pre-existing bare-name definition comes from a different factory method; same-method re-definition keeps the bare method name.
- **Reflective Utils**: Removed the broken reified-generic reflection helpers that mislabelled collected list/map/set/iterable element types; element types are now resolved purely through `Runtime.obtainClassDeclaration`.
- **AOT Execution**: Minor cleanups to the `AotRuntimeExecutor` runtime executor.

### Removed

- **Legacy executor stubs**: Removed `default_runtime_executor.dart`, `jit_runtime_executor.dart`, and `runtime_executor_resolving.dart` — dead code from the pre-unified executor design. Runtime execution unifies behind `AotRuntimeExecutor`.
- **`_mirrorImportRegex` / `hasMirrorImport`** (in `jetleaf_tools`): mirror-related helpers removed.

---

## 2.0.1

### Architectural Enhancements
* **Independent Core Architecture**: Completely removed runtime dependency on `jetleaf_tools`. `jetleaf_core` is now 100% self-contained with zero dependencies on build or developer tooling.
* **Native Runtime Foundation**:
  * Moved binary buffer I/O (`BinaryBuilder`, `BinaryReader`) into `package:jetleaf_core/cache.dart`.
  * Moved reflective declaration models (`Declaration`, `ClassDeclaration`, `FieldDeclaration`, `MethodDeclaration`, `ConstructorDeclaration`, `Asset`, `Package`) into `package:jetleaf_core/declaration.dart`.
  * Integrated core runtime exceptions (`Throwable`, `RuntimeException`, `ClassNotFoundException`, etc.) directly into `package:jetleaf_core/lang.dart`.
  * Integrated object helpers (`EqualsAndHashCode`, `ToString`, `QualifiedName`), argument containers (`ExecutableArgument`), runtime hints (`RuntimeHint`), and system utilities (`System`, `SystemDetector`).
* **Clean Downward Dependency**: Allows applications and extension packages (`jtl`, `jetson`, `jetleaf_web`, etc.) to run purely on `jetleaf_core` without requiring `jetleaf_tools` at runtime.

## 2.0.0

### Landmark Architectural Consolidation
* **Unified Core Architecture**: Consolidated 7 previously independent runtime packages (`jetleaf_lang`, `jetleaf_convert`, `jetleaf_pod`, `jetleaf_env`, `jetleaf_logging`, `jetleaf_utils`, and `jetleaf_core`) into a single cohesive, high-performance runtime package.
* **Streamlined Dependency Graph**: Removed external package fragmentation. Users now only need `jetleaf_core: ^2.0.0` for full runtime capabilities and `jetleaf_tools: ^1.0.1` for compilation and developer tooling.
* **Modular Internal Organization**:
  * `lib/src/core/` — Application context, event bus, condition evaluators, lifecycle processors, availability indicators, and diagnostic reporters.
  * `lib/src/env/` — Unified environment abstractions, profile management (`dev`, `prod`, `test`), and hierarchical property source resolution.
  * `lib/src/pod/` — Dependency injection container, pod factories (`DefaultListablePodFactory`), scoping engines, lifecycle callbacks, and alias registries.
  * `lib/src/lang/` — Metaprogramming metadata interfaces (`Class`, `Field`, `Method`, `Constructor`), high-performance collections (`ArrayList`, `LinkedList`, `Stack`, `Queue`, `HashMap`), primitive wrappers, I/O streams, and time utilities.
  * `lib/src/logging/` — Structured logging pipeline with ANSI console formatting, customizable log levels, and configurable printers.
  * `lib/src/convert/` — Type conversion engine (`ConversionService`), standard converters, and extensible registry.
  * `lib/src/utils/` — Placeholder resolution, configuration parsers (YAML, JSON, XML, Properties), assertion helpers, and stack trace sanitization.
* **Fine-Grained & Umbrella Exports**:
  * `package:jetleaf_core/jetleaf_core.dart` — Umbrella export re-exporting the entire framework runtime.
  * Individual entry points for focused imports: `package:jetleaf_core/core.dart`, `package:jetleaf_core/pod.dart`, `package:jetleaf_core/env.dart`, `package:jetleaf_core/logging.dart`, `package:jetleaf_core/convert.dart`, `package:jetleaf_core/utils.dart`, `package:jetleaf_core/lang.dart`.
  * Preserved full backwards compatibility with sub-library exports: `annotation.dart`, `context.dart`, `format.dart`, `intercept.dart`, `message.dart`, `collections.dart`, `design.dart`, `extensions.dart`, `io.dart`, `printers.dart`, and `property.dart`.
* **Pure AOT Compliance**: Completely eliminated runtime reflection and dynamic evaluation bottlenecks. Full compatibility with Dart AOT native compilation (`dart compile exe`).
* **Tooling Integration**: Updated compiler interface to depend on `jetleaf_tools: ^1.0.1`.

---

## 1.1.6

* Optimized pod definition lookup performance in `DefaultListablePodFactory`.
* Improved nested property resolution for composite property sources.
* Updated dependency constraints for sub-packages (`jetleaf_pod: ^1.1.5`, `jetleaf_convert: ^1.1.4`, `jetleaf_env: ^1.1.4`).

---

## 1.1.5

* Added support for custom shutdown hooks and graceful termination listeners.
* Enhanced error reporting in application context initialization failures.
* Bumped dependencies across the ecosystem.

---

## 1.1.4

* Improved lifecycle post-processor ordering with priority comparator.
* Fixed edge cases in circular dependency detection during singleton instantiation.
* Updated `jetleaf_pod` to `^1.1.3`.

---

## 1.1.3

* Enhanced condition evaluation with composite `@Conditional` annotations.
* Added support for profile-based condition filtering.
* Updated sub-package dependencies.

---

## 1.1.2

* Refined method interception hooks for `@Interceptable` components.
* Performance optimizations in event bus subscriber dispatching.
* Updated `jetleaf_env` to `^1.1.2`.

---

## 1.1.1

* Added `ApplicationAvailability` indicators for readiness and liveness probes.
* Improved diagnostic exception reporting with categorized error summaries.
* Updated sub-package dependencies.

---

## 1.1.0

* Introduced `@ConfigurationProperties` type-safe binding.
* Added support for embedded value resolvers across pod definitions.
* Enhanced exit code generation and application shutdown lifecycle.

---

## 1.0.2

* Improved prototype-scoped pod recreation performance.
* Enhanced string placeholder parsing in environment property sources.

---

## 1.0.1+1

* Fixed minor type resolution issue in `AnnotatedPodDefinitionReader`.
* Updated `jetleaf_pod` dependency.

---

## 1.0.1

* Added support for `@Primary` and `@Qualifier` disambiguation.
* Improved hierarchical message source lookups with internationalization fallback.

---

## 1.0.0+1

* Updated documentation links and package topics.
* Incremented `jetleaf_lang` dependency.

---

## 1.0.0

* Initial stable release of `jetleaf_core`.
* Core application context (`GenericApplicationContext`, `AnnotationConfigApplicationContext`).
* Dependency injection engine powered by `DefaultListablePodFactory`.
* Event bus and application listener infrastructure.
* Lifecycle management with initialization and destruction phases.