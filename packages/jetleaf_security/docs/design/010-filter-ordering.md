# 010 — Filter ordering

## Design reference
A `FilterComparator` and canonical order table that give security filters deterministic, relative placement.

## Problem
Security filters are order-sensitive. The current package sorts by magic integers and offers only `addFilter`, so a custom filter cannot be placed reliably relative to authentication or authorization. A concrete consequence is that `CsrfFilter` runs outside `ExceptionTranslationFilter`.

## Invariant
1. There MUST be one canonical order table, expressed as named constants, not scattered literals.
2. `ExceptionTranslationFilter` MUST be inside (later than) every filter that can throw a security exception, OR that filter MUST handle its own denial. `CsrfFilter` uses the latter (record 013).
3. `AuthorizationFilter` MUST be terminal.
4. `addFilterBefore(filter, Class)` and `addFilterAfter(filter, Class)` MUST produce order-independent placement relative to the named filter.
5. Multiple filters with the same order MUST have a deterministic tie-break.
6. Filter order MUST be visible in an assertion test so regressions are caught.

## Extension seam
`@Order`/`Ordered` plus `AnnotationAwareOrderComparator`, as used by `FilterManager`. Users register custom filters as pods or via the DSL. A lower numeric value runs earlier.

**Two distinct order domains MUST NOT be confused:**
1. **External** — the `FilterChainProxy` entry point and web's own filters are separate beans discovered by `FilterManager`. `jetleaf_web`'s `CorsFilter` has `getOrder() => Ordered.HIGHEST_PRECEDENCE` and its `CsrfFilter` has `HIGHEST_PRECEDENCE + 1`. The proxy must carry an explicit `@Order` that places it correctly relative to them.
2. **Internal** — the table below orders `SecurityFilter`s *inside* the proxy. Those are not beans and are not seen by `FilterManager`.

If CORS/CSRF are delegated to `jetleaf_web` (record 013), they run in domain 1 and the internal table must not duplicate them.

## Edge cases
Two custom filters claiming the same position; a custom filter placed before the context holder (must fail fast or be documented as unsupported); duplicate filter classes; a filter registered both as a pod and via DSL.

## Jetleaf mapping
Reuse `AnnotationAwareOrderComparator`. Publish the order table in a single `filter_orders.dart` or as constants on `SecurityFilters`. Do not reimplement sorting.

## Gating tests
- `canonical_order_table_is_asserted`
- `addFilterBefore_places_relative_to_named_filter`
- `addFilterAfter_places_relative_to_named_filter`
- `duplicate_order_is_deterministic`
- `csrf_denial_is_translated` (fails today)
