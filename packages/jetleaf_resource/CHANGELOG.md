## [2.0.0]

### Breaking Changes
- **Unified Core Dependency**: Migrated from individual satellite dependencies (`jetleaf_lang`, `jetleaf_env`, `jetleaf_logging`, `jetleaf_pod`) to unified `jetleaf_core: ^2.0.0`.
- **Pure Dart Ahead-Of-Time (AOT) Compatibility**: 100% compliant with Ahead-Of-Time compilation (zero reflection, zero `dart:mirrors`).

### Enhancements
- High-throughput caching infrastructure: in-memory LRU/LFU cache implementations, eviction policies, TTL expiration, and cache managers.
- Declarative caching annotations: `@Cacheable`, `@CacheEvict`, `@CachePut`, and key generators.
- Adaptive rate-limiting subsystem with sliding window, token bucket, and fixed window algorithms.
- Seamless interceptor integration with Jetleaf IoC containers.

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
- Updated dependencies: `jetleaf_lang`, `jetleaf_env`, `jetleaf_core`, `jetleaf_logging`, `jetleaf_pod`.

---

## [1.1.1]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_env`, `jetleaf_core`, `jetleaf_logging`, `jetleaf_pod`.

---

## [1.1.0]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_env`, `jetleaf_core`, `jetleaf_logging`, `jetleaf_pod`.

---

## [1.0.0]

### Added
- Initial stable release of Jetleaf Resource management module (caching and rate limiting).
