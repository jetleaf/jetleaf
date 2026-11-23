# 015 — AuthorizationFilter

## Design reference
An `AuthorizationFilter` that evaluates typed `AuthorizationManager<RequestAuthorizationContext>` rules for request security.

## Problem
The current authorization filter evaluates hand-built expression strings at request time. That is stringly typed, injection-prone, and cannot express composable authorization rules.

## Invariant
1. The filter MUST evaluate typed `AuthorizationManager<RequestAuthorizationContext>` objects, never strings.
2. A `null`/anonymous authentication with a deny decision MUST produce 401 via the entry point path; a fully authenticated deny MUST produce 403.
3. The first matching rule MUST win, and `anyRequest()` MUST be terminal and required.
4. Missing matchers MUST deny by default (fail closed).
5. The filter MUST be terminal in the chain (record 010).

## Extension seam
`AuthorizationManager` implementations are pods; users add custom managers via `access(...)` or by contributing a manager pod with `@Order`.

## Edge cases
No rule matches; overlapping matchers; method-specific matchers; async dispatch; `permitAll()` on a path that also matches a `hasRole` rule (first-match wins must be tested).

## Jetleaf mapping
Use `jetleaf_web`'s path matching machinery (see record 010 for the current regex compiler defect). `RequestMatcher` stays as the public name. Rules become typed objects, not `AuthorizationRule(expression: String)`.

## Gating tests
- `permit_all_allows_request`
- `has_role_denies_without_role`
- `first_matching_rule_wins`
- `no_matching_rule_denies`
- `expression_injection_via_role_name_is_impossible` (typed rules make this structurally impossible)
