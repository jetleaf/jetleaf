## Unreleased

### Added

- **`WRITE_NULL_MAP_VALUES`**: `JetsonObjectMapper()` now enables `SerializationFeature.WRITE_NULL_MAP_VALUES` by default — null DTO fields are serialized (`"key": null`) instead of silently omitted. Call `mapper.disableFeature(WRITE_NULL_MAP_VALUES.name)` to restore the previous behaviour.
- **`SerializationFeature.WRITE_NULL_MAP_VALUES`**, **raw `null` preservation**: JSON adapters (Set/Map/List) now keep `null` elements exactly as written in both directions.

### Changed

- **`StringJsonGenerator`**: No longer strips empty maps, empty lists, or null fields from output — the generator emits exactly what is written, so the JSON-writer round-trip and the map-serializer stays trivially in sync.
- **`JsonGenerator` flushContext handling of remaining trailing-comma**: pretty-printed output no longer emits a trailing comma before closing structures.
- **Null field serialization and deserialization symmetry**: previously asymmetric handling produced `"items": [null, 1]` from `"items": [...]` with `null` values dropped; now `List`/`Map`/`Set` adapters round-trip explicit nulls.
- **`jetson_test.dart`** rewritten as a proper smoke test (no longer relies on the `@JetleafTest` harness); covers flat payload round-trip and null-field preservation.

---

## [2.1.0]

### Enhancements

- **Erased `Object` Targets**: `DartJsonSerializationAdapter` now treats genuine `Object`/`dynamic`/`Null` targets as erased (Jackson semantics — objects become maps, arrays become lists, scalars pass through) using a **qualified-name** discriminator, so cache-synthetic declarations that merely report `Object` as their `Type` are no longer misclassed — they continue through the reflective dataclass path.
- **Parameterized Collections**: JSON, YAML and XML `List`/`Map`/`Set` adapters and their (de)serialization contexts now accept parameterized type declarations for element/key/value resolution.
- **YAML Parsing**: `StringYamlParser` handles multi-document markers and document boundaries correctly in mixed YAML files.
- **Dependency Bump**: `jetleaf_core: ^2.1.0`.

---

## [2.0.1]

### Enhancements
- Updated runtime dependency to `jetleaf_core: ^2.0.1`.
- Cleaned dependency tree to ensure complete separation from development tooling.

---

## [2.0.0]

### Breaking Changes
- **Unified Core Dependency**: Replaced legacy dependencies (`jetleaf_lang`, `jetleaf_convert`, `jetleaf_pod`, `jetleaf_utils`, `jetleaf_env`) with unified `package:jetleaf_core/core.dart`, `package:jetleaf_core/convert.dart`, etc.
- **Pure Dart Ahead-Of-Time (AOT) Compatibility**: 100% compliant with Ahead-Of-Time compilation (zero reflection, zero `runtime reflection`). Uses compiled constructors and field extractors.

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