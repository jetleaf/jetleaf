# 029 — HeaderWriter / security headers

## Design reference
A composable `HeaderWriter` model with a `HeaderWriterFilter` and independent writers for HSTS, `X-Frame-Options`, Content-Security-Policy, and Referrer-Policy.

## Problem
`SecurityHeadersFilter` is a monolith: users cannot override one header without replacing the whole filter, and there is no per-header configuration seam.

## Invariant
1. Each security header MUST be produced by an independent `HeaderWriter`.
2. `HeaderWriterFilter` MUST run all writers in a deterministic order.
3. Writers MUST NOT overwrite a header explicitly set by the application unless configured to do so.
4. HSTS, `nosniff`, `X-Frame-Options`, and Referrer-Policy MUST be configurable independently.
5. Default header values MUST follow current OWASP guidance.

## Extension seam
`HeaderWriter` is a public interface; writers are ordered pods, overridable via `@ConditionalOnMissingPod`.

## Edge cases
Response already committed; duplicate header names; CSP nonce generation; disabling all headers; preflight responses.

## Jetleaf mapping
Keep `SecurityHeadersFilter` as the public name (owner decision) but compose `HeaderWriter`s internally. Use `HttpHeaders` from `jetleaf_web`.

## Gating tests
- `default_headers_emitted`
- `writer_can_be_replaced_by_pod`
- `application_header_not_overwritten_by_default`
- `headers_disabled`