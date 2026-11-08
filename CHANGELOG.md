## [2.0.0]

### Breaking Changes

- **Unified Core Architecture**: Replaced separate split runtime packages (`jetleaf_pod`, `jetleaf_lang`, `jetleaf_env`, `jetleaf_logging`, `jetleaf_convert`, `jetleaf_utils`) with the unified `jetleaf_core` package (`version: ^2.0.0`).
- **Modern Export Submodules**: Modular library imports are now exposed directly through `package:jetleaf/jetleaf.dart` or submodules (`package:jetleaf/core.dart`, `package:jetleaf/pod.dart`, `package:jetleaf/env.dart`, `package:jetleaf/logging.dart`, `package:jetleaf/convert.dart`, `package:jetleaf/utils.dart`, `package:jetleaf/lang.dart`).
- **AOT Tooling Unification**: Integrated `jetleaf_tools` (`jl build`, `jl dev`) replacing legacy build runners with native, mirror-free Ahead-Of-Time (AOT) compile-time registries.
- **Dart SDK Constraint**: Bumped minimum Dart SDK constraint to `^3.9.0`.

### Added

- **Unified `JetleafApplication` Bootstrap**: Streamlined application bootstrap with `JetleafApplication.run` supporting automatic AOT registrar integration and zero-config scanner fallback.
- **Application Types**: Native support for `ApplicationType.WEB` (HTTP web servers) and `ApplicationType.NONE` (CLI utilities and batch applications).
- **Compile-Time AOT Synthesis**: Ahead-Of-Time code synthesis generates zero-reflection constructor and member dispatch tables in `_jetleaf/` that survive `dart compile exe` tree-shaking.
- **Full Workspace Integration**: Multi-project workspace support across all official Jetleaf packages (`jetleaf_core`, `jetleaf_tools`, `jetleaf_web`, `jetleaf_resource`, `jetleaf_scheduling`, `jetleaf_retry`, `jetleaf_validation`, `jetleaf_monitor`, `jetson`, `jtl`).
- **Comprehensive Lifecycle Support**: Fully unified lifecycle processors for `@PostConstruct`, `@PreDestroy`, `@OnApplicationReady`, and `@OnApplicationStarting`.
- **Hierarchical Configuration & Profiles**: Unified property loading for `.properties`, `.yaml`, `.json`, environment variables, and CLI arguments with profile activation (`--jetleaf.profiles.active=...`).
- **Extensive Sample Projects**:
  - `sample_projects/cli_app` — CLI applications with `CommandLineRunner`, `ApplicationRunner`, and custom exit code generators.
  - `sample_projects/resource_app` — Multi-profile resource resolution, `@Value` expression injection, and `@ConfigurationProperties`.
  - `sample_projects/scanner_app` — Pure runtime scanning and execution without pre-compiled AOT registrars.
  - `sample_projects/ultimate` — Complete enterprise integration suite testing complex circular dependencies, deep 4-level annotations, fault tolerance, caching, and streaming web pipelines.

### Changed

- Re-engineered framework internals to use unified `jetleaf_core` abstractions.
- All internal classes now cleanly separate framework concerns with zero circular runtime dependencies.

---

## [1.2.1]

### Changed

- Updated dependencies: `jetleaf_core`, `jetleaf_pod` and `jetleaf_convert`.

---

## [1.2.0]

### Changed

- Updated dependencies: all.

**NOTE** This is the current stable version of jetleaf recommended for all environments.

---

## [1.1.2]

### Changed

- Updated dependencies: `jetleaf_core`, `jetleaf_pod`.

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

---

## [1.0.7]

### Changed

- Updated dependencies: `jetleaf_env`, `jetleaf_core`.

### Added

- `JetleafPropertySourceOrderRule` to match the new API from `jetleaf_env`.

---

## [1.0.6]

### Changed

- Updated dependencies.

### Fixed

- Fixed environment listener issues with property source sorting.
- Moved exception reporting logic to `ExceptionReporterManager`.
- Separated internal packages into specified libraries.

---

## [1.0.5]

### Changed

- Updated dependencies.

---

## [1.0.4]

### Added

- Added support for custom property sources.

---

## [1.0.3]

### Changed

- Updated dependencies.

---

## [1.0.2]

### Changed

- Performance improvements and bug fixes.

---

## [1.0.1]

### Changed

- Documentation updates and formatting improvements.

---

## [1.0.0]

### Added

- Initial release of the Jetleaf backend framework.
- Core IoC container with dependency injection.
- Application bootstrap and lifecycle management.
- Configuration and environment management.
- Logging, type conversion, and utility modules.
