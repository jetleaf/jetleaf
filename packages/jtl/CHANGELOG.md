# Changelog

All notable changes to this project will be documented in this file.  
This project follows a simple, human-readable changelog format inspired by
[Keep a Changelog](https://keepachangelog.com/) and adheres to semantic versioning.

---

## [2.0.0]

### Breaking Changes
- **Unified Core Dependency**: Migrated from individual satellite dependencies (`jetleaf_lang`, `jetleaf_logging`) to the unified `jetleaf_core: ^2.0.0` architecture.
- **Pure Dart Ahead-Of-Time (AOT) Compatibility**: 100% compliant with ahead-of-time compilation — zero reflection, zero `dart:mirrors`.

### Enhancements
- High-performance streaming and string template interpolation engine.
- Built-in filter registry featuring HTML sanitization, uppercase/lowercase casing, trimming, date/number formatting, and defaults.
- Zero-allocation template caching architecture for high-concurrency server environments.
- Defensive expression evaluation resolving nested dot-notation properties and map keys.

---

## [1.1.2]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`

---

## [1.1.1]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`

---

## [1.1.0]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`

---

## [1.0.9]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`

---

## [1.0.8]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`

---

## [1.0.7]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`

---

## [1.0.6]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`

---

## [1.0.5]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_logging`

---

## [1.0.0]

### Added
- Initial stable release of Jetleaf Template Language (JTL).