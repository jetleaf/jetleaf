## [2.0.0]

### Breaking Changes
- **Unified Core Dependency**: Replaced legacy dependencies (`jetleaf_lang`, `jetleaf_convert`, `jetleaf_pod`, `jetleaf_utils`, `jetleaf_env`) with unified `package:jetleaf_core/core.dart`, `package:jetleaf_core/convert.dart`, etc.
- **Pure Dart Ahead-Of-Time (AOT) Compatibility**: 100% compliant with Ahead-Of-Time compilation (zero reflection, zero `dart:mirrors`). Uses compiled constructors and field extractors.

### Enhancements
- High-throughput JSON deserialization and serialization (`ObjectMapper`).
- Support for `@JsonCreator`, `@JsonOutput`, `@JsonProperty`, and `@JsonIgnore` annotations.
- Deep model binding and type token conversion supporting nested generic collections (`List<T>`, `Map<K, V>`).
- Seamless integration with the Jetleaf conversion service and IoC container.

---

## [1.1.7]

### Changed
- Updated dependencies: `jetleaf_core`, `jetleaf_pod` and `jetleaf_convert`.

### Added
- `ToJsonFactory`.

---

## [1.1.6]

### Added
- Introduced the `JsonOutput` annotation as the counterpart to `JsonCreator`.
- Added new mechanisms for constructing objects from JSON values.

### Fixed
- Resolved exception swallowing issues; thrown exceptions are now properly propagated.

---

## [1.1.5]

### Changed
- Restructured the `jetson` library into focused sub-libraries (e.g. `json`, `mapper`, etc.), while keeping the main `jetson` entry point exporting all modules.
- Exceptions thrown during `newInstance` invocation are no longer silently ignored.

### Added
- `FailedDeserializationException` for clearer error reporting during deserialization.

---

## [1.1.4]

### Changed
- Updated dependencies: `jetleaf_core`, `jetleaf_pod`.

---

## [1.1.3]

### Changed
- Updated dependencies: `jetleaf_core`, `jetleaf_pod`.

---

## [1.1.2]

### Changed
- Updated dependencies: `jetleaf_core`, `jetleaf_pod`.

---

## [1.0.0]

### Added
- Initial stable release of Jetson JSON object mapping and serialization core for Jetleaf.
