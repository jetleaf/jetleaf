## [2.0.0]

### Breaking Changes
- **Unified Core Dependency**: Migrated from individual satellite dependencies (`jetleaf_lang`, `jetleaf_env`, `jetleaf_logging`) to unified `jetleaf_core: ^2.0.0`.
- **Pure Dart Ahead-Of-Time (AOT) Compatibility**: 100% compliant with Ahead-Of-Time compilation (zero reflection, zero `dart:mirrors`).

### Enhancements
- Comprehensive validator constraints: `@NotNull`, `@NotBlank`, `@NotEmpty`, `@Min`, `@Max`, `@Size`, `@Pattern`, `@Email`, `@Future`, `@Past`, and custom constraints.
- Composable validation engine with `Validator`, `BindingResult`, `FieldError`, and `ValidationException`.
- Automated request payload and model validation integration with web handlers.
- Internationalized validation error messages via `MessageSource`.

---

## [1.1.5]

### Changed
- Updated dependencies: `jetleaf_core`.

---

## [1.1.4]

### Changed
- Updated dependencies: `jetleaf_core`.

---

## [1.1.3]

### Changed
- Updated dependencies: `jetleaf_core`.

---

## [1.1.2]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_env`, `jetleaf_core`, `jetleaf_logging`.

---

## [1.1.1]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_env`, `jetleaf_core`, `jetleaf_logging`.

---

## [1.1.0]

### Changed
- Updated dependencies: `jetleaf_lang`, `jetleaf_env`, `jetleaf_core`, `jetleaf_logging`.

---

## [1.0.0]

### Added
- Initial stable release of Jetleaf Validation module.