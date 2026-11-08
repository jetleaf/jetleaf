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
  * `lib/src/lang/` — Metaprogramming mirror interfaces (`Class`, `Field`, `Method`, `Constructor`), high-performance collections (`ArrayList`, `LinkedList`, `Stack`, `Queue`, `HashMap`), primitive wrappers, I/O streams, and time utilities.
  * `lib/src/logging/` — Structured logging pipeline with ANSI console formatting, customizable log levels, and configurable printers.
  * `lib/src/convert/` — Type conversion engine (`ConversionService`), standard converters, and extensible registry.
  * `lib/src/utils/` — Placeholder resolution, configuration parsers (YAML, JSON, XML, Properties), assertion helpers, and stack trace sanitization.
* **Fine-Grained & Umbrella Exports**:
  * `package:jetleaf_core/jetleaf_core.dart` — Umbrella export re-exporting the entire framework runtime.
  * Individual entry points for focused imports: `package:jetleaf_core/core.dart`, `package:jetleaf_core/pod.dart`, `package:jetleaf_core/env.dart`, `package:jetleaf_core/logging.dart`, `package:jetleaf_core/convert.dart`, `package:jetleaf_core/utils.dart`, `package:jetleaf_core/lang.dart`.
  * Preserved full backwards compatibility with sub-library exports: `annotation.dart`, `context.dart`, `format.dart`, `intercept.dart`, `message.dart`, `collections.dart`, `design.dart`, `extensions.dart`, `io.dart`, `printers.dart`, and `property.dart`.
* **Pure AOT Compliance**: Completely eliminated runtime mirrors (`dart:mirrors`) and dynamic evaluation bottlenecks. Full compatibility with Dart AOT native compilation (`dart compile exe`).
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