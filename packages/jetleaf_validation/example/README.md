# Jetleaf Validation Example

This example demonstrates how to use `jetleaf_validation` 2.0.0 for declarative constraint validation.

## Features Covered
- Inspecting constraint metadata (`@Email`, `@Size`, `@Min`)
- Initializing `SimpleValidationContext` with `StandardEnvironment`
- Executing constraint validation (`EmailConstraintValidator.isValid`)
- Validating string boundaries and non-blank rules (`NotBlankConstraintValidator`)

## Running the Example

From this directory:

```bash
dart run lib/main.dart
```