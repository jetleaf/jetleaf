# 014 — ExceptionTranslationFilter

## Design reference
An `ExceptionTranslationFilter` that translates security exceptions raised inside the chain into correct HTTP responses at a single boundary, without swallowing programming errors.

## Problem
Translate security exceptions raised inside the chain into correct HTTP responses at a single boundary, without swallowing programming errors.

## Invariant
1. The filter MUST sit outside `AuthorizationFilter`.
2. It MUST translate `AuthenticationException` via `AuthenticationEntryPoint` and `AccessDeniedException` via `AccessDeniedHandler`.
3. For an anonymous or remember-me principal, an `AccessDeniedException` MUST be treated as unauthenticated (401), decided through `AuthenticationTrustResolver` (record 004).
4. It MUST NOT write a response if the response is already committed.
5. Any filter that throws a security exception from OUTSIDE this filter MUST handle its own denial. `CsrfFilter` is the canonical case: the design injects an `AccessDeniedHandler` into `CsrfFilter` itself rather than reordering it.

## Extension seam
`AuthenticationEntryPoint`, `AccessDeniedHandler`, `AuthenticationTrustResolver` are all overridable pods (`@ConditionalOnMissingPod`).

## Edge cases
CSRF denial thrown upstream; anonymous denial; committed response; async/error dispatch; exception thrown by the controller (must NOT be translated).

## Jetleaf mapping
`ExceptionTranslationFilter implements SecurityFilter`, order −10. Delegates to `jetleaf_web` `ServerHttpResponse.setStatus`. Uses `HttpHeaders` for `WWW-Authenticate`. `RequestCache` is Pass B.

## Gating tests
- `exception_translation_authentication_exception_yields_401`
- `exception_translation_access_denied_yields_403`
- `exception_translation_anonymous_denial_yields_401`
- `csrf_failure_yields_json_403` (regression for the current bug)
- `controller_runtime_exception_is_not_translated`
- `committed_response_is_not_rewritten`