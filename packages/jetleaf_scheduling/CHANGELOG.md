## [2.0.0]

### Breaking Changes
- **Unified Core Dependency**: Migrated from individual satellite dependencies (`jetleaf_lang`, `jetleaf_logging`, `jetleaf_pod`) to unified `jetleaf_core: ^2.0.0`.
- **Pure Dart Ahead-Of-Time (AOT) Compatibility**: 100% compliant with Ahead-Of-Time compilation (zero reflection, zero `dart:mirrors`).

### Enhancements
- High-precision task scheduling infrastructure: `CronTrigger`, `PeriodicTrigger`, and `FixedDelayTrigger`.
- Automated task execution pipeline: `ThreadPoolTaskScheduler`, `ScheduledTaskRegistrar`, and task cancellation lifecycle.
- Declarative `@Scheduled` annotation interception within Jetleaf application contexts.
- Timezone-aware scheduling leveraging `ZoneId` and `ZonedDateTime`.

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
- Initial stable release of Jetleaf Scheduling module (cron and timed task execution).
