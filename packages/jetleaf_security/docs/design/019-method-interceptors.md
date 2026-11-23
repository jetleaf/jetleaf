# 019 — Method security interceptors

## Design reference
Before/after method interceptors backed by `AuthorizationManager`s (`PreAuthorize`, `PostAuthorize`, `Secured`, and `@RolesAllowed`), plus a legacy `MethodSecurityInterceptor` facade for the existing convenience API.

## Problem
`MethodSecurityInterceptor` is a plain helper with no `canIntercept(Method)`, never registered with `DefaultMethodInterceptor`. The example calls it manually, so `@PreAuthorize` has never been enforced on a real invocation.

## Invariant
1. `AuthorizationManagerBeforeMethodInterceptor` and `...After...` MUST be real Jetleaf `MethodInterceptor` implementations with `canIntercept(Method)`.
2. They MUST be registered as pods and discovered by `DefaultMethodInterceptor` via `MethodInterceptorRegistry`.
3. A denial MUST prevent the target method body from executing (pre) or reject the result (post).
4. Class-level and method-level annotations MUST both be honoured.
5. `MethodSecurityInterceptor` MUST remain as a public facade with the existing `intercept<T>(...)` convenience API, delegating to the same managers — no duplicate policy logic.
6. `@PostAuthorize` MUST throw on denial; result rewriting via `MethodInvocation.hijack` is reserved for a future `@PostFilter`.

## Extension seam
Interceptors are ordered pods with `@Order`; users add custom `MethodInterceptor`s. Before/after ordering uses `@RunBefore`/`@RunAfter` where needed.

## Edge cases
Async `Future`-returning methods; a method that throws (after-interceptor must not run); a denial after side effects already occurred (document that `@PostAuthorize` cannot undo them); proxies not generated for the target class (must fail loudly or be documented).

## Jetleaf mapping (verified)
Use `Interceptable.when()` and `MethodInterceptor`/`AroundMethodInterceptor` from `libraries/jetleaf_core/lib/src/core/intercept/`. `DefaultMethodInterceptor.processAfterInitialization()` (`default_method_interceptor.dart:204-221`) injects the dispatcher only when a `$$JLInterfaced$$` proxy subclass is found; **otherwise it returns the plain pod and annotations silently never fire. There is no runtime fallback.**

Proxy generation facts:
- Driven by the **`jl` CLI of `jetleaf_tools`** (`jl build` or `jl proxy`) — there is no `build.yaml` and no `build_runner` generator. Users add `jetleaf_tools` as a dev dependency and run the CLI.
- Eligible stereotypes: `Service`, `Repository`, `Component`, `Configuration`, `AutoConfiguration`, `Controller`, `RestController`, `Pod`, `Workflow`, `Middleware`, `CommunityModerator`.
- Output: `lib/_jetleaf/proxies/**_ClassName.proxy.dart`, regenerated on every run.
- Skip rules: private classes; **`final`/`sealed`/`mixin class`**; classes already mixing in `Interceptable`; classes with no instance members; unresolvable supertypes; unimplemented inherited public members.

Consequences: the README MUST state that secured classes must be non-final and carry a stereotype, and that `jl build` must be run. A build-level integration test MUST assert a generated proxy exists and that `DefaultMethodInterceptor` wraps the pod.

## Gating tests
- `proxied_controller_denied_before_body_executes`
- `proxy_generation_integration`
- `class_level_preauthorize_enforced`
- `async_secured_method_enforced`
- `method_security_interceptor_facade_delegates`
