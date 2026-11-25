# 031 — Session management

## Design reference
A session model built around `SessionCreationPolicy`, `SessionManagementConfigurer`, `SessionAuthenticationStrategy`, fixation protection, and a session registry for concurrency-control hooks.

## Problem
`SessionCreationPolicy` is currently stored and never read — declaring `stateless` has no behavioural effect. The owner has explicitly required full session-state support in Pass A, not just the stateless path.

## Invariant
1. Each policy MUST select a repository and a session strategy:

   | Policy | Repository | Session creation |
   |---|---|---|
   | `stateless` | `NullSecurityContextRepository` | never; inbound sessions ignored |
   | `never` | `HttpSessionSecurityContextRepository(allowSessionCreation: false)` | never creates; reads existing |
   | `ifRequired` | `HttpSessionSecurityContextRepository` | creates only when context changes |
   | `always` | `HttpSessionSecurityContextRepository` | always creates |

2. On successful authentication in a stateful policy, a `SessionAuthenticationStrategy` MUST run; the default MUST change the session id to prevent session fixation.
3. `SessionRegistry` MUST record `SessionInformation` so concurrency control can be added later without renaming.
4. Invalidating a session MUST remove the stored context.
5. `stateless` MUST NOT read or write an `HttpSession` even when a session cookie is present.

## Extension seam
`SessionAuthenticationStrategy`, `SecurityContextRepository`, and `SessionRegistry` are overridable pods with `@ConditionalOnMissingPod`.

## Edge cases
A session created before authentication; a session invalidated mid-request; concurrent requests using one session; session expiry during a long request; `stateless` with an inbound session cookie; application servers that cannot change a session id (fall back to creating a new session and migrating attributes).

## Jetleaf mapping (verified)
`HttpSession` (`packages/jetleaf_web/lib/src/http/http_session.dart`) has `getId()`, `create()`, `fromIoHttpSession()`, `getAttribute`/`setAttribute`/`getAttributeNames`, `touch()`, `isNew()`, `invalidate()`, `isValid()`, `isExpired()`, and `JSESSIONID = 'JSESSIONID'`.

**The session id cannot be changed in place** — `_id` is `final`, there is no `changeSessionId()` or `setId()`, and `invalidate()` is one-way. Therefore `ChangeSessionIdAuthenticationStrategy` MUST be implemented as: create a new session via `HttpSession.create()`, copy all attributes from the old session, invalidate the old session, and emit a fresh `JSESSIONID` `ResponseCookie`. Document this as a deliberate design choice, since session ids are immutable.

Caveat: `IoRequest.getSession([bool create = true])` wraps the native `dart:io` session and **ignores the `create` flag**. Do not depend on `create: false` to avoid creating a session; control creation through the configured repository instead (`NullSecurityContextRepository` never calls `getSession` at all). Keep all public names listed above.

## Gating tests
- `session_policy_matrix` (all four states)
- `session_id_changes_on_authentication`
- `stateless_ignores_inbound_session_cookie`
- `session_invalidation_removes_context`
- `session_registry_records_session_information`