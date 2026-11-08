## [2.0.0]

### Breaking Changes
- **Unified Core Dependency**: Migrated from individual satellite dependencies (`jetleaf_lang`, `jetleaf_logging`, `jetleaf_pod`) to unified `jetleaf_core: ^2.0.0`.
- **Pure Dart Ahead-Of-Time (AOT) Compatibility**: 100% compliant with Ahead-Of-Time compilation (zero reflection, zero `dart:mirrors`).

### Enhancements
- Robust retry policies: `SimpleRetryPolicy`, `TimeoutRetryPolicy`, `CircuitBreakerRetryPolicy`, and composite policies.
- Pluggable backoff policies: `FixedBackOffPolicy`, `ExponentialBackOffPolicy`, `ExponentialRandomBackOffPolicy`, and `UniformRandomBackOffPolicy`.
- Circuit breaker state machine with `CLOSED`, `OPEN`, and `HALF_OPEN` states.
- Declarative `@Retryable` and `@Recover` method interception in Jetleaf IoC containers.

---

## [1.1.5]

### Changed
- Updated dependencies: `jetleaf_core`, `jetleaf_pod`.

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
- Updated dependencies: `jetleaf_lang`, `jetleaf_core`, `jetleaf_logging`, `jetleaf_pod`.

---

## [1.1.1]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_core`, `jetleaf_logging`, `jetleaf_pod`.

---

## [1.1.0]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_core`, `jetleaf_logging`, `jetleaf_pod`.

---

## [1.0.0]

### Added
- Initial stable release of Jetleaf Retry resilience module.