# 021 — ObjectPostProcessor

## Design reference
An `ObjectPostProcessor<T>` universal interception point for objects created during configuration, with a container-aware bridge for pod-created objects.

## Problem
Without a universal interception point for objects created during configuration, users cannot customise framework-internal objects (filters, managers, converters) without forking the builder.

## Invariant
1. `ObjectPostProcessor<T>` MUST expose `T postProcess(T object)`.
2. Every object created by a configurer or by `HttpSecurity.build()` MUST pass through it exactly once.
3. Post-processing MUST be able to replace an object with a subclass/wrapper and have the replacement used downstream.
4. There MUST be a no-op default pod.
5. It MUST bridge to Jetleaf's `PodPostProcessor` for container-created pods, but MUST NOT rely on the bridge for objects built during the DSL phase.

## Extension seam
Public pod with `@ConditionalOnMissingPod`; a fluent generic interface.

## Edge cases
Post-processor returns `null`; post-processor throws; object post-processed twice through two paths; an object that is also a pod; ordering when multiple post-processors exist.

## Jetleaf mapping
Define the public interface in `config/object_post_processor.dart`. Jetleaf's `PodPostProcessor` exists in `libraries/jetleaf_core` and operates at container initialisation time, which is *later* than DSL construction — therefore the explicit interface is required rather than relying solely on the container hook.

## Gating tests
- `every_built_object_is_post_processed_once`
- `post_processor_can_replace_object`
- `no_op_default_when_unconfigured`
- `pod_post_processor_bridge_applies_to_container_pods`