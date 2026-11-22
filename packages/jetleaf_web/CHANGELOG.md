## [2.1.0]

### Added

- **Component-scan scope**: `AbstractAnnotatedHandlerMapping` now honours `@ComponentScan` — controllers whose package is not in the declared `basePackages` / `basePackageClasses` are not mapped, mirroring the scan semantics of the annotation processor.
- **`jetleaf.jetson.naming-strategy`**: New environment property selecting the global Jetson mapper naming strategy. Supported: `snake-case` (default), `kebab-case`, `camel-case` / `none` / `identity` (no transformation). Unknown values throw `IllegalArgumentException` with the supported list.
- **`test_helpers.dart`**: Shared test bootstrapper calling `ensureTestAotRegistered()` for warm-test-VM registrar loading.
- **Test bootstrap**: `@JetleafTest` entries import `../test_helpers.dart` and `await ensureTestAotRegistered()` — previously the AOT registrar was not loaded in tests that reach beyond annotation reads, producing `MethodNotFoundException` for framework reflection calls.

### Changed

- **Test AOT registry**: Warm test VMs now import `lib/_jetleaf/test/registry.g.dart` as a package root (`package:jetleaf_web/_jetleaf/test/registry.g.dart`) — previously `package:jetleaf_web/_jetleaf/aot_registry.g.dart`.
- **Component-scan scope filters**: Registrar-based scan now honours `@ComponentScan(includeFilters: [FilterType.ANNOTATION])` scopes for handler mapping resolution.
- **`handler_test.dart`**: Jetson-constructed request DTO tests updated to reflect null-field round-trip preservation.
- **Dependency Bumps**: `jetleaf_core: ^2.1.0`, `jetson: ^2.1.0`, `jtl: ^2.1.0`.

### Fixed

- **Server dispatch & handler resolution**: Fixed request dispatch, parameter/return adaptation, and handler mapping edge cases in `AbstractServerDispatcher`, `AnnotatedHandlerAdapter`, and `AbstractAnnotatedHandlerMapping`.
- **MediaType in Annotations**: `@RequestMapping`/`produces`/`consumes` now filter raw entries through `whereType<MediaType>()` when routing — parameterized/annotation fragments can no longer leak non-MediaType values into handler lookup.
- **Accept Header Negotiation**: `StringReturnValueHandler` now ignores wildcard `*/*` Accept entries and falls back to `text/plain`, matching RFC 7231 semantics.
- **Test `_ControllerDefinition` Test Helper**: Default definition now points at the registered `HttpStatus` type instead of the unregistered `Object` type (AOT/JIT compatible).
- Minor handler mapping/interceptor/adapter manager fixes and `int`/`String` content negotiation adjustments.

---

## [2.0.0]

### Added
- Unified AOT web stack with complete compile-time reflectionless routing, filter chains, and JSON body binding.
- Full integration with `jetleaf_core` 2.0.0 context, pod lifecycle, and dependency injection.
- Direct JSON serialization and parsing via `jetson` 2.0.0.
- Server-side template rendering support using `jtl` 2.0.0.
- Fully working runnable example under `example/`.

### Changed
- **BREAKING:** Migrated to unified `jetleaf_core` 2.0.0 architecture. Replaced legacy separate packages (`jetleaf_lang`, `jetleaf_env`, `jetleaf_logging`, `jetleaf_pod`) with cohesive imports from `package:jetleaf_core/...`.
- Updated dependencies: `jetleaf_core: ^2.0.0`, `jetson: ^2.0.0`, `jtl: ^2.0.0`.
- Bumped minimum Dart SDK constraint to `^3.9.0`.

---

## [1.11.3]

### Changed

- Updated dependencies - `jetson`, `jetleaf_core` and `jetleaf_pod`

---

## [1.11.2]

### Changed

- Updated dependency - `jetson`

---

## [1.11.1]

### Changed

- The `jetleaf_web` package is now organized into sub-libraries:
  - `package:jetleaf_web/web.dart`
  - `package:jetleaf_web/http.dart`
  - And others
  - `package:jetleaf_web/jetleaf_web.dart` (imports all sub-libraries)

This reorganization allows users to import only the classes they need,
reducing unnecessary dependencies and improving clarity.

---

## [1.11.0]

### Changed

- Updated dependencies: `jetleaf_core`, `jetleaf_pod`, `jetson`.

---

## [1.1.3]

### Fixed

- Cors issue.

---

## [1.1.2]

### Changed

- Updated dependencies: `jetleaf_core`, `jetleaf_pod`, `jetson`.

---

## [1.1.1]

### Changed

- Updated dependencies: all.

---

## [1.1.0]

### Changed

- Updated dependencies: all.

---

## [1.0.9]

### Changed

- Updated dependencies: all.

---

## [1.0.8]

### Changed

- Updated dependencies: all.

### Added

- `IoWebServerrSecurityContextFactory` for pseudo security context integration with `HttpServer`.  
  _Note: This API may be removed in future versions; use with caution._

### Fixed

- Fixed issues with `getUri` method in server.

---

## [1.0.7]

### Changed

- Updated dependencies: all.

---

## [1.0.6]

### Changed

- Updated dependencies: `jetleaf_env`, `jetson`, `jetleaf_core`.

---

## [1.0.5]

### Changed

- Updated dependencies.

### Added

- `ServerDispatcherErrorListenerr` for error listening in the server.

---

## [1.0.4]

### Changed

- Updated dependencies.

---

## [1.0.3]

### Changed

- Updated dependencies.

---

## [1.0.2]

### Changed

- Updated dependencies.

---

## [1.0.1]

### Changed

- Updated dependencies.

---

## [1.0.0+1]

Patch release: dependency alignment and small improvements.

### Changed

- Updated package dependencies and aligned with other JetLeaf modules.

---

## [1.0.0]

Initial release.

### Added

- Web server and routing primitives for building HTTP APIs and web applications.
- Template rendering integration with `jtl`, multipart handling, and content negotiation.

---

## Links

- Homepage: <https://jetleaf.hapnium.com>  
- Documentation: <https://jetleaf.hapnium.com/docs/web>  
- Repository: <https://github.com/jetleaf/jetleaf>  
- Issues: <https://github.com/jetleaf/jetleaf/issues>  

---

**Contributors:** Hapnium & JetLeaf contributors