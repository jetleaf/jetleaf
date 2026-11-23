# 017 — SecurityExpressionHandler

## Design reference
A `SecurityExpressionHandler` with a method-security variant, an expression root, an evaluation context, and a `PermissionEvaluator` seam for annotation-based authorization.

## Problem
The current parser tokenises and evaluates on every call, cannot parse list syntax, and resolves property paths only against `Map`. The roadmap's `principal.organizationId` and `returnObject.ownerId` examples therefore evaluate to `null`.

## Invariant
1. An expression MUST be lexed **once** and cached by expression string; evaluation MUST NOT re-tokenise. (Phase 4 implementation note: the token list is cached; the recursive-descent parser still rebuilds its per-call state. Full AST materialisation is a tracked refinement, not a correctness gate.)
2. Property paths MUST resolve against Dart objects, not only `Map` keys. The default uses Jetleaf reflection (`Class.getField(...).getValue(...)`), which requires AOT metadata from `jl build`. `SecurityExpressionPropertyResolvers` allows applications (and tests) to register resolvers for plain objects that are not in the AOT registry. Both paths must be covered by tests.
3. The grammar MUST support `hasAnyRole(['A','B'])`, `hasAnyAuthority([...])`, `isAuthenticated`, `isAnonymous`, `isFullyAuthenticated`, `#param`, `principal.*`, `authentication.*`, `returnObject.*`, boolean operators, `==`/`!=`, and relational operators.
4. User-supplied values MUST be bound as values, never concatenated into the expression source.
5. A parse error MUST fail closed with a clear exception naming the expression.
6. `#param` MUST resolve through `Method.getParameters().getName()` combined with `MethodInvocation.getArgument().getPositionalArguments()` — never by guessing. Follow the web resolvers' convention `annotation.value ?? parameter.getName()` where an explicit name is available.

## Extension seam
`SecurityExpressionHandler` is a public pod; users add custom functions by extending the evaluation root or supplying a handler.

## Edge cases
`null` property in a path; a property that is itself an object; a `Map` key colliding with a getter name; expression used on a class-level annotation; expression cached across isolates; async method result as `returnObject`.

## Jetleaf mapping (verified)
Keep `SecurityExpressionParser` (roadmap name) as the parser inside the `SecurityExpressionHandler`. Use `jetleaf_core/lang.dart` reflection for property access.

Parameter names **are** retained: `Parameter.getName()` returns the source lexeme (`libraries/jetleaf_core/lib/src/lang/meta/parameter/_parameter.dart:10-20`), populated by the AOT generator (`declaration_builder.dart:731`). `ExecutableArgument` carries values only — generated proxies pass positional values (`ExecutableArgument.optional(positional: [...])`) — so bind `#orgId` by pairing `invocation.getMethod().getParameters()` with `invocation.getArgument().getPositionalArguments()`. Web resolvers use the same pattern (`packages/jetleaf_web/lib/src/annotation/resolvers.dart:199`). No `@P` annotation is needed; ignore the stale `Source.getName()` doc claiming positional names are empty.

## Gating tests
- `has_any_role_list_syntax` (fails today)
- `has_any_authority_list_syntax` (fails today)
- `object_property_path_resolution` (fails today)
- `expression_parsed_once` (cache assertion)
- `expression_injection_via_role_name_is_impossible`
- `parse_error_fails_closed`
