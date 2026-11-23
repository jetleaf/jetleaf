# 018 — MethodSecurityMetadataSource

## Design reference
A `MethodSecurityMetadataSource` with pre/post, `@Secured`, and `@RolesAllowed` variants that discover security annotations on methods and their declaring classes.

## Problem
The current annotations are plain classes, so neither Jetleaf's reflection registry nor any interceptor can discover them. They are inert data holders.

## Invariant
1. `@PreAuthorize`, `@PostAuthorize`, `@Secured`, `@RolesAllowed`, `@EnableWebSecurity`, `@EnableMethodSecurity` MUST extend `ReflectableAnnotation`, declare `@Target`, and override `annotationType` and `equalizedProperties`.
2. Metadata lookup MUST check both the method and its declaring class, in that order.
3. Multiple annotations on one method MUST all be enforced.
4. Annotation values MUST be read reflectively via `getDirectAnnotation<T>()` / `getAnnotations<T>()`; no manual `List<Object>` parameter may be required in production code.
5. `@EnableMethodSecurity` MUST be the switch that activates method-security interception.

## Extension seam
Users add custom metadata sources as ordered pods; the built-in source is `@ConditionalOnMissingPod`.

## Edge cases
Inherited annotations; overridden methods; interface annotations; class-level `@Secured` with method-level `@PreAuthorize`; a method with no annotations; annotations on async methods returning `Future`.

## Jetleaf mapping
Follow the annotation conventions in `packages/jetleaf_web/lib/src/annotation/core.dart` and `.../request_mapping.dart`, and the consumption pattern in `abstract_annotated_handler_mapping.dart` (`type.getDirectAnnotation<RestController>()`). Reflection API comes from `jetleaf_core/lang.dart`.

## Gating tests
- `annotations_are_discoverable_via_reflection` (fails today)
- `class_level_annotation_is_enforced`
- `multiple_annotations_all_enforced`
- `enable_method_security_activates_interception`
- `overridden_method_annotations`
