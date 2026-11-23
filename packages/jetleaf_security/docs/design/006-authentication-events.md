# 006 — AuthenticationEventPublisher

## Design reference
An `AuthenticationEventPublisher` with a default implementation, plus success, failure, and interactive-success event types that make authentication observable for audit logging, metrics, and lockout policies.

## Problem
Authentication successes and failures must be observable for audit logging, metrics, and lockout policies. The current package has no event mechanism at all.

## Invariant
1. Every successful `ProviderManager.authenticate` MUST publish a success event.
2. Every failed authentication MUST publish a failure event carrying the exception type.
3. Event publication MUST NOT change the authentication outcome; a failing publisher MUST NOT turn success into failure.
4. A no-op default MUST exist so the framework works without an event bus.

## Extension seam
`AuthenticationEventPublisher` is a public pod guarded by `@ConditionalOnMissingPod`.

## Edge cases
Event publisher throws; event published for an anonymous authentication (should not be); event published twice when parent manager also succeeds; async listeners outliving the request.

## Jetleaf mapping
First check whether Jetleaf exposes an application event publisher. If it does, bridge the security events to it. If not, define the interface and a `NoOpAuthenticationEventPublisher` default pod. Do not invent a new event bus inside the security package.

## Gating tests
- `success_event_published_once`
- `failure_event_carries_exception_type`
- `publisher_failure_does_not_change_outcome`
- `no_op_publisher_is_default`
