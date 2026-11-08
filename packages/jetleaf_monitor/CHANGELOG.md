## [1.0.0]

### Added
- Comprehensive AOT runtime monitoring, actuators, health indicators, and metric collectors.
- Support for structured system diagnostics, JVM/Dart VM memory and thread metric reporters.
- Ready-to-use runnable example under `example/`.

### Changed
- **BREAKING:** Migrated to the unified `jetleaf_core` 2.0.0 architecture. Replaced legacy separate packages (`jetleaf_lang`, `jetleaf_env`, `jetleaf_logging`, `jetleaf_pod`) with direct imports from `package:jetleaf_core/...`.
- Integrated `jetson` 2.0.0 for high-performance JSON/actuator metric serialization.
- Dart SDK constraint bumped to `^3.9.0`.