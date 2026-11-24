# 020 — HttpSecurity and configurers

## Design reference
An `HttpSecurity` builder hosting ordered `SecurityConfigurer<O, B>` implementations, with `SharedObjects` and an `AbstractConfiguredSecurityBuilder`/`AbstractHttpConfigurer` two-phase lifecycle.

## Problem
The current `HttpSecurity` is a single 272-line builder that emits string expressions, has `void` terminal DSL methods, and silently ignores session policy. The roadmap's own chained configuration example does not compile. There is no ordered, composable configurer model and no way for a third party to add a configurer.

## Invariant
1. `HttpSecurity` MUST host ordered `SecurityConfigurer<SecurityFilterChain, HttpSecurity>` implementations with a two-phase `init(builder)` / `configure(chain)` lifecycle.
2. All terminal DSL methods MUST return a chainable value; the roadmap's §5 example MUST compile verbatim.
3. `SharedObjects` MUST make `AuthenticationManager`, `SecurityContextRepository`, and other shared Pods visible to every configurer through the Jetleaf `ApplicationContext`.
4. Every built object MUST pass through `ObjectPostProcessor` (record 021).
5. Configurers MUST be overridable by order and by pod replacement; no configurer may be hard-coded into `build()`.
6. `SessionCreationPolicy` MUST select the repository and session strategy (record 031); it must never be dead configuration.

## Extension seam
Users write a `SecurityConfigurer`, declare it as a pod with `@Order`, and it is applied. Users override any built-in configurer via `@ConditionalOnMissingPod`.

## Edge cases
Two configurers writing the same shared object; `init` phase depending on an object created in another configurer's `configure` phase; building twice; a configurer that throws mid-build; multiple `SecurityFilterChain` Pods with different matchers.

## Jetleaf mapping
Bridge the builder lifecycle to Jetleaf's container lifecycle (`InitializingPod`, `SmartInitializingSingleton`, `@PostConstruct`). `@Configuration` classes with `@Pod` factory methods register chains. Keep the public names `HttpSecurity`, `AuthorizeHttpRequestsConfigurer`, `CsrfConfigurer`, `SessionManagementConfigurer`, `ExceptionHandlingConfigurer`.

## Gating tests
- `roadmap_configuration_example_compiles`
- `configurers_run_in_order`
- `shared_objects_visible_to_all_configurers`
- `object_post_processor_applied_to_every_built_object`
- `custom_configurer_pod_is_applied`
- `session_policy_changes_repository`
