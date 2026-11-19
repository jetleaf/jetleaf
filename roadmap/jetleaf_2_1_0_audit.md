# JetLeaf 2.1.0 — Full Framework Stability Audit & Remediation Plan

> **Objective:** Elevate every library and package in JetLeaf (`jetleaf_core`, `jetleaf_tools`, `jetleaf_resource`, `jetleaf_web`, `jetleaf_scheduling`, `jetleaf_validation`, `jetleaf_retry`, `jetleaf_actuator`, `jetson`, `jtl`, and `jetleaf_data`) to enterprise Spring Boot parity with zero edge-case regressions before deploying **2.1.0**.

---

## Status Summary

| # | Module | Issue | Severity | Status |
|---|--------|-------|----------|--------|
| 1 | `jetleaf_core` | Swapped `AdaptableMap.CLASS` and `AdaptableSet.CLASS` type tokens | High | **Fixed** |
| 2 | `jetleaf_core` | `BinaryReader.readDynamicValue()` tag `6` (Set) returned `List` instead of `Set` | High | **Fixed** |
| 3 | `jetleaf_core` / `jetleaf_tools` | Reified generic collections (`List<T>`, `Set<T>`, `Map<K, V>`) for unknown/user types & `Function.apply` | Critical | **Fixed** |
| 4 | `jetleaf_core` | `Interceptable.when()` passes proxy (`this`) instead of unwrapped `target` (`delegate`) | Critical | Proposed |
| 5 | `jetleaf_core` | `AbstractMethodDispatcher.when()` & `_invokeAroundChain()` re-invoke target method when result is `null` or `void` | Critical | Proposed |
| 6 | `jetleaf_core` | `CommonAnnotationPodProcessor` does not `await` async `@PreConstruct`, `@PostConstruct`, `@PreDestroy`, `@Cleanup` | High | Proposed |
| 7 | `jetleaf_core` | `AutowiredAnnotationPodProcessor` skips `@Value`/`@Env` on fields with default values & partial `@Qualifier` constructor args | High | Proposed |
| 8 | `jetleaf_core` | `ConfigurationPropertyPodProcessor` attempts to bind `static` fields, treats `List`/`Set`/`Map` as nested pods, and lacks relaxed kebab-case binding | High | Proposed |
| 9 | `jetleaf_tools` | `AotPodRegistryWriter` treats `@OnApplicationReady` as zero-arg `@PostConstruct`, ignores multiple lifecycle methods, and lacks `@Value`/collection constructor support | High | Proposed |
| 10 | `jetleaf_tools` | `AotProxyWriter` emits invalid Dart syntax for non-intercepted operator methods | Medium | Proposed |
| 11 | `jetleaf_tools` | `BuildCommand`, `RunCommand`, and `TestCommand` do not normalize relative `--root` paths to `.absolute` | Medium | Proposed |
| 12 | `jetleaf_resource` | `@Cacheable` never writes computed result to cache on miss & reuses a single mutable `_DefaultCacheOperationContext` across concurrent calls | Critical | Proposed |
| 13 | `jetleaf_web` | `AbstractAnnotatedHandlerMapping` uses `\|\|` instead of `&&` when excluding `@ControllerAdvice` / `@RestControllerAdvice` | High | Proposed |
| 14 | `jetleaf_web` | `AnnotatedHandlerAdapter` mutates incoming request `Content-Type` and `Accept` headers via `addAll` | High | Proposed |
| 15 | `jetleaf_web` | `AbstractServerDispatcher._requestFingerprintCache` is unbounded across unique concrete request paths | Medium | Proposed |
| 16 | `jetleaf_scheduling` | `SchedulingAnnotationPodProcessor._scheduledTasks` is keyed by `Object pod`, overwriting tasks when a pod has multiple scheduled methods | High | Proposed |
| 17 | `jetleaf_validation` | `ValidationFactory.validateProperty` ignores resolved `activeGroups`, and `validate()` does not skip `static` fields (`CLASS`) | Medium | Proposed |
| 18 | `jetleaf_retry` | `DefaultRetryExecutor.execute()` calls `listener.onClose()` twice when retry attempts are exhausted | Medium | Proposed |
| 19 | `jetleaf_actuator` | `AbstractMonitoringService.start()` never sets `_isRunning = true`, and `DefaultMonitoringService.create()` overwrites accumulated performance metrics | Medium | Proposed |
| 20 | `jetson` | `DartJsonSerializationAdapter.serialize()` reflects over and serializes `static` fields (such as `static final Class CLASS`) | High | Proposed |
| 21 | `jtl` | `DefaultTemplateRenderer._processIncludes()` is a placeholder comment stub, and `DefaultVariableResolver` only resolves `Map` keys rather than reflective object fields/methods | Medium | Proposed |

---

## Detailed Analysis & Proposed Fixes

---

### Issue 4: `Interceptable.when()` Passes Proxy (`this`) Instead of `target` (`delegate`)

- **File:** `libraries/jetleaf_core/lib/src/core/intercept/interceptable.dart` (lines 122–129)
- **Root Cause:**
  Generated proxy classes (`$$MyService with Interceptable`) call:
  ```dart
  when<ReturnType>(() async => delegate.myMethod(), delegate, 'myMethod', ExecutableArgument.optional(...), _class);
  ```
  However, `Interceptable.when` ignores the `target` parameter (`delegate`) and passes `this` (the proxy instance `$$MyService`) to `support!.when(...)`.
- **Impact:**
  1. `MethodInvocation.getTarget()` returns the proxy instead of the real pod instance.
  2. When `targetClass` is omitted, `target.getClass()` looks up `$$MyService` in the AOT type registry (where generated proxy classes are not registered), causing reflective lookups or field reads on `invocation.getTarget()` to fail.

#### Current Code (`Before`)
```dart
  @override
  Future<T> when<T>(AsyncMethodInvocator<T> function, Object target, String methodName, [ExecutableArgument? arguments, Class? targetClass]) async {
    if (support != null) {
      return support!.when(function, this, methodName, arguments, targetClass);
    }

    return function();
  }
```

#### Proposed Fix (`After`)
```dart
  @override
  Future<T> when<T>(AsyncMethodInvocator<T> function, Object target, String methodName, [ExecutableArgument? arguments, Class? targetClass]) async {
    if (support != null) {
      return support!.when(function, target, methodName, arguments, targetClass);
    }

    return function();
  }
```

---

### Issue 5: `AbstractMethodDispatcher` Re-Invokes Target Method When Return Value Is `null` or `void`

- **File:** `libraries/jetleaf_core/lib/src/core/intercept/abstract_method_dispatcher.dart` (lines 93–102 and 400–422)
- **Root Cause:**
  Both `AbstractMethodDispatcher.when()` and `_ChainedMethodInterceptor._invokeAroundChain()` use `result != null` as the signal for whether an `AroundMethodInterceptor` handled the invocation:
  ```dart
  final T? result = await chain[index].aroundInvocation(wrapper);
  if (result != null) {
    return result;
  }
  return next();
  ```
  And in `AbstractMethodDispatcher.when`:
  ```dart
  final result = await intercept<T>(invocation);
  if (result != null) {
    return result;
  }
  return invocation.proceed();
  ```
- **Impact:**
  1. **Double execution of `void` / `Future<void>` and nullable methods:** When a `@Transactional` or `@Repository` method returns `Future<void>` or `Future<User?>` (where the user is not found and returns `null`), `aroundInvocation` calls `await invocation.proceed()`, gets `null`, and returns `null`. Then `_invokeAroundChain` sees `result == null` and calls `return next()` (invoking `invocation.proceed()` a **second time**!), and then `AbstractMethodDispatcher.when` ALSO sees `result == null` and calls `return invocation.proceed()` a **third time**!
  2. **Short-circuiting with `null` fails:** If an `AroundMethodInterceptor` intentionally short-circuits and returns `null`, the underlying target method still runs.

#### Current Code (`Before`)
```dart
// In AbstractMethodDispatcher.when (lines 94-101):
MethodInvocation<T> invocation = SimpleMethodInvocation(target, targetClass, method, arguments, function);
final result = await intercept<T>(invocation);

if (result != null) {
  return result;
}

return invocation.proceed();
```
```dart
// In _ChainedMethodInterceptor._invokeAroundChain (lines 400-422):
Future<T> _invokeAroundChain<T>(List<AroundMethodInterceptor> chain, MethodInvocation<T> invocation, [int index = 0]) async {
  if (index >= chain.length) {
    return invocation.proceed();
  }

  Future<T> next() async => await _invokeAroundChain(chain, invocation, index + 1);
  final wrapper = _DelegatingInvocation(invocation, next);
  final T? result = await chain[index].aroundInvocation(wrapper);

  if (result != null) {
    return result;
  }

  return next();
}
```

#### Proposed Fix (`After`)
Track whether `wrapper.proceed()` was invoked on `_DelegatingInvocation` (and in `AbstractMethodDispatcher.when`, note that `intercept<T>(invocation)` already invokes `_invokeAroundChain(aroundInterceptors, invocation)` which terminates at `invocation.proceed()` when `chain` is empty or when each interceptor calls `invocation.proceed()`!):

```dart
// In AbstractMethodDispatcher.when (lines 94-96):
MethodInvocation<T> invocation = SimpleMethodInvocation(target, targetClass, method, arguments, function);
final result = await intercept<T>(invocation);
return result as T;
```
```dart
// In _DelegatingInvocation:
final class _DelegatingInvocation<T> implements MethodInvocation<T> {
  final MethodInvocation<T> _delegate;
  final AsyncMethodInvocator<T> _next;
  bool _proceeded = false;
  T? _lastResult;

  _DelegatingInvocation(this._delegate, this._next);

  bool hasProceeded() => _proceeded;
  T? getLastResult() => _lastResult;

  @override
  Future<T> proceed() async {
    _proceeded = true;
    final res = await _next();
    _lastResult = res;
    return res;
  }
  // ... existing forwarding methods ...
}

// In _ChainedMethodInterceptor._invokeAroundChain:
Future<T> _invokeAroundChain<T>(List<AroundMethodInterceptor> chain, MethodInvocation<T> invocation, [int index = 0]) async {
  if (index >= chain.length) {
    return invocation.proceed();
  }

  Future<T> next() async => await _invokeAroundChain(chain, invocation, index + 1);
  final wrapper = _DelegatingInvocation(invocation, next);
  final T? result = await chain[index].aroundInvocation(wrapper);

  if (result != null) {
    return result;
  }

  // If the around interceptor already called wrapper.proceed() and the legitimate
  // return value was null (e.g. Future<void> or Future<User?>), do NOT call next() again!
  if (wrapper.hasProceeded()) {
    return result as T;
  }

  // Compatibility for around interceptors that return null to mean "continue chain"
  // without calling invocation.proceed() themselves (such as CacheAnnotationMethodInterceptor on cache miss):
  return next();
}
```
> **Why this design is safe:** It preserves compatibility with interceptors like `CacheAnnotationMethodInterceptor` (which returns `null` without calling `invocation.proceed()` when there is a cache miss) while preventing double/triple execution when an interceptor like `TransactionalMethodInterceptor` or `RepositoryMethodInterceptor` calls `await invocation.proceed()` and the method returns `null` or `void`!

---

### Issue 6: `CommonAnnotationPodProcessor` Does Not `await` Async Lifecycle Methods

- **File:** `libraries/jetleaf_core/lib/src/core/context/processors/common_annotation_pod_processor.dart` (lines 91–136)
- **Root Cause:**
  `method.invoke(pod)` is called synchronously without checking if the return value is a `Future` and awaiting it.
- **Impact:**
  Any `@PreConstruct`, `@PostConstruct`, `@PreDestroy`, or `@Cleanup` method returning `Future<void>` runs detached in the background; dependent pods receive an uninitialized pod, and shutdown hooks exit before async cleanup finishes.

#### Current Code (`Before`)
```dart
  @override
  Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async {
    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<PreConstruct>()) {
        method.invoke(pod);
      }
    }

    return pod;
  }
```

#### Proposed Fix (`After`)
```dart
  Future<void> _invokeLifecycleMethod(Method method, Object pod) async {
    final result = method.invoke(pod);
    if (result is Future) {
      await result;
    }
  }

  @override
  Future<Object?> processBeforeInitialization(Object pod, Class podClass, String name) async {
    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<PreConstruct>()) {
        await _invokeLifecycleMethod(method, pod);
      }
    }

    return pod;
  }

  @override
  Future<Object?> processAfterInitialization(Object pod, Class podClass, String name) async {
    if (_hasAotInvoker(name, destroy: false)) {
      return pod;
    }

    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<PostConstruct>()) {
        await _invokeLifecycleMethod(method, pod);
      }
    }

    return pod;
  }

  @override
  Future<void> processAfterDestruction(Object pod, Class podClass, String name) async {
    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<Cleanup>()) {
        await _invokeLifecycleMethod(method, pod);
      }
    }
  }

  @override
  Future<void> processBeforeDestruction(Object pod, Class podClass, String name) async {
    if (_hasAotInvoker(name, destroy: true)) {
      return;
    }

    for (final method in podClass.getMethods()) {
      if (method.hasDirectAnnotation<PreDestroy>()) {
        await _invokeLifecycleMethod(method, pod);
      }
    }
  }
```

---

### Issue 7: `AutowiredAnnotationPodProcessor` Skips `@Value`/`@Env` on Default-Initialized Fields & Partial `@Qualifier` Constructor Args

- **File:** `libraries/jetleaf_core/lib/src/core/context/processors/autowired_annotation_pod_processor.dart` (lines 90–133 and 150–159)
- **Root Cause:**
  1. In `populateValues` (lines 150–158):
     ```dart
     final currentValue = field.getValue(pod);
     if (currentValue != null) {
       continue;
     }
     ```
     In Dart, fields annotated with `@Value('#{server.port}')` or `@Env('PORT')` frequently declare a fallback initializer (`int port = 8080;`). Because `currentValue != null`, `populateValues` skips `@Value` and `@Env` injection completely!
  2. In `determineCandidateArguments` (lines 90–133):
     When a constructor has 2 parameters and only 1 is annotated with `@Qualifier`, `determineCandidateArguments` only adds the `@Qualifier` parameter to `args` and returns a 1-element list for a 2-parameter constructor.

#### Proposed Fix (`After`)
1. In `populateValues`, only skip `currentValue != null` for `@Autowired` fields (which may have been supplied via constructor), while always applying `@Value` and `@Env` when present:
```dart
        // Skip already initialized @Autowired fields (set by constructor or factory),
        // unless @Value or @Env is explicitly overriding a default field initializer.
        if (hasAutowired && !hasValue && !hasEnv) {
          try {
            final currentValue = field.getValue(pod);
            if (currentValue != null) {
              continue;
            }
          } catch (_) {}
        }
```
2. In `determineCandidateArguments`, if any parameter has `@Qualifier`, resolve all parameters in `parameters` (using `qualifier?.value` when `@Qualifier` is present and `null` lookup otherwise) so the returned `List<ArgumentValue>` is complete for the executable:
```dart
  @override
  Future<List<ArgumentValue>?> determineCandidateArguments(String podName, Executable executable, Iterable<Parameter> parameters) async {
    if (!parameters.any((p) => p.hasDirectAnnotation<Qualifier>())) {
      return null;
    }

    final args = <ArgumentValue>[];
    for (final param in parameters) {
      final paramClass = param.getReturnClass();
      final classContent = _getClassContent(paramClass);
      final qualifier = param.getDirectAnnotation<Qualifier>();

      final dep = await _podFactory.resolveDependency(
        DependencyDescriptor(
          source: paramClass,
          podName: podName,
          propertyName: param.getName(),
          type: paramClass,
          args: null,
          component: classContent.component ?? paramClass.componentType(),
          key: classContent.key ?? paramClass.keyType(),
          isEager: true,
          isRequired: param.isRequired(),
          lookup: qualifier?.value,
        ),
      );

      args.add(
        ArgumentValue(
          dep,
          qualifiedName: paramClass.getQualifiedName(),
          packageName: paramClass.getPackage().getName(),
          name: param.getName(),
        ),
      );
    }

    return args.isEmpty ? null : args;
  }
```

---

### Issue 8: `ConfigurationPropertyPodProcessor` Static Fields, Collection Properties & Relaxed Binding

- **File:** `libraries/jetleaf_core/lib/src/core/context/processors/configuration_property_pod_processor.dart` (lines 175–222 and 327–329)
- **Root Cause:**
  1. `_resolvePropertyValues` iterates `targetClass.getFields()` without skipping `field.isStatic()` (such as `static final Class CLASS = ...`). When `rawValue` is null, it attempts `_createNestedInstance(Class, 'prefix.CLASS')`!
  2. `_isPrimitiveOrEnum` returns `false` for `List`, `Set`, and `Map`, causing `_resolvePropertyValues` to call `_createNestedInstance` on `List`/`Map` instead of converting or reading indexed/map environment properties.
  3. Property lookup only checks exact `prefix.fieldName` (camelCase) without falling back to kebab-case (`prefix.field-name`) or snake_case (`prefix.field_name`), which are standard in YAML/ENV configuration.

#### Proposed Fix (`After`)
```dart
  Object? _lookupRelaxedProperty(String prefix, String fieldName) {
    final exactKey = prefix.isEmpty ? fieldName : '$prefix.$fieldName';
    final direct = _environment.getProperty(exactKey);
    if (direct != null) return direct;

    final snake = fieldName.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (m) => '${m.group(1)}_${m.group(2)!.toLowerCase()}',
    ).toLowerCase();
    final kebab = snake.replaceAll('_', '-');

    final kebabKey = prefix.isEmpty ? kebab : '$prefix.$kebab';
    final fromKebab = _environment.getProperty(kebabKey);
    if (fromKebab != null) return fromKebab;

    final snakeKey = prefix.isEmpty ? snake : '$prefix.$snake';
    return _environment.getProperty(snakeKey);
  }
```
And in `_resolvePropertyValues`:
- Skip `if (field.isStatic() || field.isConst()) continue;`
- Treat collection types (`fieldType.isCollection()` or `fieldType.isMap()`) as convertible values via `_podFactory.getConversionService().convert(...)` rather than calling `_createNestedInstance`.

---

### Issue 9: `AotPodRegistryWriter` Lifecycle & Constructor Resolution Gaps

- **File:** `libraries/jetleaf_tools/lib/src/aot/aot_pod_registry_writer.dart` (lines 139–142 and 774–843)
- **Root Cause:**
  1. `_postConstructNames` includes `_onApplicationReadyName` (`'OnApplicationReady'`). `_buildInitInvoker` emits `(instance as dynamic).methodName()` with 0 arguments, which fails if an `@OnApplicationReady` method accepts `ApplicationContext` or `ApplicationReadyEvent`, and also runs it during pod initialization instead of application ready.
  2. `_buildInitInvoker` and `_buildDestroyInvoker` return inside the loop on the **first** matching method, ignoring any additional `@PostConstruct` or `@PreDestroy` methods on the class.

#### Proposed Fix (`After`)
1. Remove `_onApplicationReadyName` from `_postConstructNames`:
```dart
  Set<String> get _postConstructNames => {
    _postConstructName,
  };
```
2. Collect all `@PostConstruct` methods in `_buildInitInvoker` (and all `@PreDestroy` methods in `_buildDestroyInvoker`) so multiple lifecycle hooks on a class are all invoked in sequence (awaiting any returned `Future`):
```dart
  String? _buildInitInvoker(
    ClassDeclaration component,
    String prefix,
    String className,
    Map<String, ClassDeclaration> classByName,
  ) {
    final matchingMethods = <MethodDeclaration>[];
    for (final method in component.getMethods()) {
      if (method.getParameters().isNotEmpty) continue;
      for (final annotation in method.getAnnotations()) {
        if (matchesOrExtendsAnnotation(annotation.getName(), _postConstructNames, classByName)) {
          matchingMethods.add(method);
          break;
        }
      }
    }
    if (matchingMethods.isEmpty) return null;

    final buffer = StringBuffer('(instance) async {\n');
    for (final method in matchingMethods) {
      buffer.writeln('  final res_${method.getName()} = (instance as dynamic).${method.getName()}();');
      buffer.writeln('  if (res_${method.getName()} is Future) await res_${method.getName()};');
    }
    buffer.write('}');
    return buffer.toString();
  }
```

---

### Issue 10: `AotProxyWriter` Invalid Syntax for Operator Methods

- **File:** `libraries/jetleaf_tools/lib/src/aot/aot_proxy_writer.dart` (lines 554–560)
- **Root Cause:**
  For an operator method (e.g., `operator [](String key)` or `operator +(Money other)`), `AotProxyWriter` emits:
  ```dart
  return delegate.$name$paramsSigClean; // e.g. return delegate.[]String key;
  ```
  which is invalid Dart syntax.

#### Proposed Fix (`After`)
Extract the parameter names and emit valid Dart operator forwarding:
```dart
    if (member.isOperator) {
      final params = member.parameters?.parameters ?? const <FormalParameter>[];
      final argNames = params.map((p) => p.name?.lexeme ?? '').where((n) => n.isNotEmpty).toList();
      final String delegateCall;
      if (name == '[]' && argNames.length == 1) {
        delegateCall = 'delegate[${argNames[0]}]';
      } else if (name == '[]=' && argNames.length == 2) {
        delegateCall = 'delegate[${argNames[0]}] = ${argNames[1]}';
      } else if (name == 'unary-' && argNames.isEmpty) {
        delegateCall = '-delegate';
      } else if (name == '~' && argNames.isEmpty) {
        delegateCall = '~delegate';
      } else if (argNames.length == 1) {
        delegateCall = 'delegate $name ${argNames[0]}';
      } else {
        delegateCall = 'delegate';
      }
      buffer.writeln('  $returnType operator $name$typeParamsDecl($paramsSigClean) {');
      buffer.writeln('    return $delegateCall;');
      buffer.writeln('  }');
      buffer.writeln();
      return;
    }
```

---

### Issue 11: CLI Relative `--root` Path Not Normalized to `.absolute`

- **Files:**
  - `libraries/jetleaf_tools/lib/src/cli/build_command.dart` (line 41)
  - `libraries/jetleaf_tools/lib/src/cli/entry_commands.dart` (lines 61, 179)
- **Root Cause:**
  When a user passes a relative path like `--root packages/jetleaf_data`, `Directory(root).path` is `'packages/jetleaf_data'`. Downstream code constructing `file://${root.path}/...` produces `file://packages/jetleaf_data/...` (where `packages` is parsed as a URI authority/hostname instead of a path), crashing the Dart kernel compiler with `Cannot extract a non-Windows file path from a file URI with an authority`.

#### Proposed Fix (`After`)
Normalize `Directory(root).absolute`:
```dart
final directory = Directory(root).absolute;
```

---

### Issue 12: `@Cacheable` Never Writes to Cache on Miss & Shares Mutable Operation Context

- **Files:**
  - `packages/jetleaf_resource/lib/src/cache/operation/cacheable_operation.dart` (lines 77–112)
  - `packages/jetleaf_resource/lib/src/cache/core/cache_annotation_method_interceptor.dart` (lines 205–249)
  - `packages/jetleaf_resource/lib/src/cache/core/default_cache_operation_context.dart`
- **Root Cause:**
  1. In `CacheAnnotationMethodInterceptor.aroundInvocation`:
     - `CacheableOperation.execute(context)` runs before the method. On a cache miss, it calls `context.setCacheMiss()`.
     - After the method finishes, `afterReturning` runs:
       ```dart
       if (context.isCacheMiss()) {
         await operation.execute(context);
       }
       ```
       Wait — `afterReturning` calls `CacheableOperation.execute(context)` again! And what does `CacheableOperation.execute(context)` do? It only calls `cache.get(key)` and `context.setCacheMiss()` — it **never calls `cache.put(key, result)`**!
  2. Furthermore, `_getOrCreate()` in `CacheAnnotationMethodInterceptor` returns a **single cached instance** (`_operationContext ??= _DefaultCacheOperationContext(...)`) and `.withInvocation(invocation)` mutates `_invocation` in-place without resetting `_cachedResult` or `_cacheMiss`! Once one call hits the cache (`_cachedResult = value`), every subsequent call on that interceptor sees `context.hasCachedResult() == true`!

#### Proposed Fix (`After`)
1. Have `_getOrCreate()` create a fresh `_DefaultCacheOperationContext` per invocation (or have `withInvocation` return a fresh context instance with clean `_cachedResult = null`, `_result = null`, `_cacheMiss = false`), and bind it to the invocation so `aroundInvocation` and `afterReturning` share the per-invocation context cleanly.
2. In `CacheableOperation.execute(context)`:
   When `context.isCacheMiss()` is already `true` (the post-invocation phase in `afterReturning`), store `context.getResult()` into the resolved caches via `cache.put(key, context.getResult())` (respecting `unless` conditions):
```dart
    if (context.isCacheMiss()) {
      final canPut = await annotation.unless.shouldCache(context);
      if (!canPut) {
        return;
      }

      final result = context.getResult();
      for (final cache in caches) {
        try {
          await cache.put(key, result);
        } catch (e, st) {
          await context.onPut(e, st, cache, key, result);
        }
      }
      return;
    }
```

---

### Issue 13: `AbstractAnnotatedHandlerMapping` Uses `||` Instead of `&&` When Excluding `@ControllerAdvice`

- **File:** `packages/jetleaf_web/lib/src/server/handler_mapping/abstract_annotated_handler_mapping.dart` (line 106)
- **Root Cause:**
  ```dart
  if (controller != null && (controller is! ControllerAdvice || controller is! RestControllerAdvice))
  ```
  Because `RestControllerAdvice` extends `ControllerAdvice`, if `controller` is a `ControllerAdvice` (not `RestControllerAdvice`), `controller is! RestControllerAdvice` is `true`, so `false || true` evaluates to `true`!
- **Impact:**
  `@ControllerAdvice` pods are mistakenly registered as route controllers in `AbstractAnnotatedHandlerMapping`.

#### Proposed Fix (`After`)
```dart
  // Exclude @ControllerAdvice and @RestControllerAdvice pods.
  if (controller != null && controller is! ControllerAdvice && controller is! RestControllerAdvice) {
    final target = await applicationContext.getPod(name);
    definitions.add(_ControllerDefinition(controller, type, target, name));
  }
```

---

### Issue 14: `AnnotatedHandlerAdapter` Overwrites Request `Content-Type` and `Accept` Headers

- **File:** `packages/jetleaf_web/lib/src/server/handler_adapter/annotated_handler_adapter.dart` (lines 64–75)
- **Root Cause:**
  `AnnotatedHandlerAdapter.handle` unconditionally appends the handler's `consumes` and `produces` media types onto the incoming `request.getHeaders()` via `addAll`:
  ```dart
  if (handler.consumes.isNotEmpty) {
    request.getHeaders().addAll(HttpHeaders.CONTENT_TYPE, handler.consumes.map((i) => i.toString()).toList());
  }
  if (handler.produces.isNotEmpty) {
    request.getHeaders().addAll(HttpHeaders.ACCEPT, handler.produces.map((i) => i.toString()).toList());
  }
  ```
- **Impact:**
  Corrupts the client's actual `Content-Type` (e.g., `multipart/form-data; boundary=...` or `application/json; charset=utf-8`) and `Accept` headers by appending duplicate values before argument resolvers and return value handlers inspect them.

#### Proposed Fix (`After`)
Only set default `Content-Type` / `Accept` headers if the incoming request did not already supply them:
```dart
  @override
  Future<void> handle(ServerHttpRequest request, ServerHttpResponse response, HandlerMethod handler) async {
    if (handler is AnnotatedHandlerMethod) {
      if (handler.consumes.isNotEmpty && request.getHeaders().getContentType() == null) {
        request.getHeaders().set(HttpHeaders.CONTENT_TYPE, handler.consumes.first.toString());
      }

      if (handler.produces.isNotEmpty && request.getHeaders().getAccept().isEmpty) {
        request.getHeaders().addAll(HttpHeaders.ACCEPT, handler.produces.map((i) => i.toString()).toList());
      }

      return await doHandle(handler, handler.definition.target, request, response, handler.method);
    }
  }
```

---

### Issue 15: Unbounded `_requestFingerprintCache` in `AbstractServerDispatcher`

- **File:** `packages/jetleaf_web/lib/src/server/dispatcher/abstract_server_dispatcher.dart` (lines 203 and 448–453)
- **Root Cause:**
  `_requestFingerprintCache` caches every unique `"$method:$concretePath"` (e.g., `"GET:/users/1"`, `"GET:/users/2"`, ..., `"GET:/users/1000000"`) with no maximum capacity.
- **Impact:**
  In a long-running production server with parameterized URLs (`/users/{id}`), `_requestFingerprintCache` grows without bound, causing a gradual memory leak.

#### Proposed Fix (`After`)
Enforce a bounded LRU/FIFO cap (e.g. `static const int _MAX_FINGERPRINT_CACHE_SIZE = 4096;`) when inserting into `_requestFingerprintCache`:
```dart
      if (!_requestFingerprintCache.containsKey(requestKey)) {
        if (_requestFingerprintCache.length >= _MAX_FINGERPRINT_CACHE_SIZE) {
          _requestFingerprintCache.remove(_requestFingerprintCache.keys.first);
        }
        _requestFingerprintCache[requestKey] = patternKey;
        if (log.getIsTraceEnabled()) {
          log.trace('💾 Fingerprinted: $requestKey → $patternKey');
        }
      }
```

---

### Issue 16: `SchedulingAnnotationPodProcessor` Overwrites Tasks When a Pod Has Multiple Scheduled Methods

- **File:** `packages/jetleaf_scheduling/lib/src/scheduling_annotation_pod_procesor.dart` (lines 320, 843, 945, 963, 976)
- **Root Cause:**
  `_scheduledTasks` is declared as:
  ```dart
  final Map<Object, ScheduledTask> _scheduledTasks = {};
  ```
  and populated via `_scheduledTasks.add(task.pod, scheduledTask);` (which sets `_scheduledTasks[pod] = scheduledTask`).
- **Impact:**
  When a single service pod defines two or more `@Scheduled`, `@Cron`, or `@Periodic` methods, only the last scheduled task is retained in `_scheduledTasks`; earlier tasks lose their lifecycle reference and are not cancelled on pod destruction or context shutdown.

#### Proposed Fix (`After`)
Change `_scheduledTasks` to `final Map<Object, List<ScheduledTask>> _scheduledTasks = {};`:
```dart
final Map<Object, List<ScheduledTask>> _scheduledTasks = {};
```
Append each task via `_scheduledTasks.putIfAbsent(task.pod, () => []).add(scheduledTask);`, and in `processBeforeDestruction` / `onApplicationEvent`, iterate and cancel all tasks in the list for each pod.

---

### Issue 17: `ValidationFactory` Static Field Reflection & `validateProperty` Group Resolution

- **File:** `packages/jetleaf_validation/lib/src/validation_factory.dart` (lines 144–146 and 188–207)
- **Root Cause:**
  1. In `validate()` (line 144): `for (final field in classInfo.getFields())` does not skip `field.isStatic()`, reading `field.getValue(target)` on static fields like `CLASS`.
  2. In `validateProperty()` (line 188 & 207):
     `final activeGroups = resolveActiveGroups(field, field.getReturnClass(), groups);` is computed on line 188, but line 207 checks:
     ```dart
     if (!shouldValidate(annotation, getActiveGroups(groups))) continue;
     ```
     passing raw `groups` instead of `activeGroups`!

#### Proposed Fix (`After`)
1. In `validate()`:
```dart
    for (final field in classInfo.getFields()) {
      if (field.isStatic() || field.isConst()) continue;
      final value = field.getValue(target);
```
2. In `validateProperty()` (line 207):
```dart
      if (!shouldValidate(annotation, getActiveGroups(activeGroups))) continue;
```

---

### Issue 18: `DefaultRetryExecutor` Calls `listener.onClose` Twice on Retry Exhaustion

- **File:** `packages/jetleaf_retry/lib/src/impl/default_retry_executor.dart` (lines 194–207)
- **Root Cause:**
  Inside the `try` block, when retries are exhausted and `recovery == null` (lines 195–199):
  ```dart
  for (final listener in _listeners) {
    listener.onClose(context, lastException);
  }
  throw RetryExhaustedException(...);
  ```
  That thrown `RetryExhaustedException` is immediately caught by the outer `catch (e)` on line 200:
  ```dart
  } catch (e) {
    for (final listener in _listeners) {
      listener.onClose(context, e is Exception ? e : null);
    }
    rethrow;
  }
  ```
  invoking `listener.onClose` a **second time**!

#### Proposed Fix (`After`)
In the outer `catch (e)` block, do not re-trigger `listener.onClose` if `e is RetryExhaustedException` (since `onClose` was already notified with `lastException` right before throwing `RetryExhaustedException`):
```dart
    } catch (e) {
      if (e is! RetryExhaustedException) {
        for (final listener in _listeners) {
          listener.onClose(context, e is Exception ? e : null);
        }
      }

      rethrow;
    }
```

---

### Issue 19: `AbstractMonitoringService.start()` Never Sets `_isRunning = true` & `DefaultMonitoringService.create()` Overwrites Metrics

- **Files:**
  - `packages/jetleaf_actuator/lib/src/core/abstract_monitoring_service.dart` (lines 204–234)
  - `packages/jetleaf_actuator/lib/src/core/default_monitoring_service.dart` (lines 127–135)
- **Root Cause:**
  1. `AbstractMonitoringService.start()` checks `if (_isRunning) return;` and starts `_memoryTimer`, but never sets `_isRunning = true;`. Consequently, `isRunning()` always returns `false`, `start()` can spawn duplicate timers if called again, and `stop()` (if it checks `_isRunning`) is a no-op.
  2. `DefaultMonitoringService.create()` creates a brand-new `ConfigurablePerformance` and overwrites `_performanceResource[key]` on every monitored method invocation instead of returning the existing `ConfigurablePerformance` tracker for `key`!

#### Proposed Fix (`After`)
1. In `AbstractMonitoringService.start()`:
```dart
  @override
  FutureOr<void> start() async {
    if (_isRunning) {
      return;
    }
    _isRunning = true;
    _memoryTimer = Timer.periodic(getInterval(), (timer) {
      // ...
```
2. In `DefaultMonitoringService.create()`:
```dart
  @override
  ConfigurablePerformance create(Monitor monitor, Source source, [String? name]) {
    return synchronized(_performanceResource, () {
      final key = createKey(monitor, source, name);
      final existing = _performanceResource[key];
      if (existing != null) {
        return existing;
      }

      final performance = ConfigurablePerformance(name: key, location: getLocation(source));
      _performanceResource.add(key, performance);
      return performance;
    });
  }
```

---

### Issue 20: `DartJsonSerializationAdapter` Serializes Static Fields (`CLASS`)

- **File:** `packages/jetson/lib/src/json/adapter/dart_json_serialization_adapter.dart` (lines 250–265)
- **Root Cause:**
  `DartJsonSerializationAdapter.serialize` loops over `type.getFields()` without skipping static or const fields (`field.isStatic() || field.isConst()`).
- **Impact:**
  Every JetLeaf class that follows the convention `static final Class<Foo> CLASS = Class<Foo>(...);` has its static `CLASS` field serialized into JSON output (or triggers infinite recursion when serializing `Class<Foo>`).

#### Proposed Fix (`After`)
```dart
    // 3. Reflect over fields
    for (final field in fields) {
      // Skip static, const, and ignored fields
      if (field.isStatic() || field.isConst()) continue;
      if (field.hasDirectAnnotation<JsonIgnore>()) continue;
```

---

### Issue 21: `jtl` Template Includes (`{{> partial}}`) & Reflective Object Property Resolution

- **File:** `packages/jtl/lib/src/_template.dart` (lines 491–497)
- **Root Cause:**
  `_processIncludes` replaces `{{> templateName}}` with `'<!-- Include: $templateName -->'` instead of resolving the partial template through the template cache/asset builder and rendering it with `context`.

#### Proposed Fix (`After`)
Resolve the included template from the renderer's `AssetBuilder` / `TemplateCache` and recursively render its content with `_renderTemplate`:
```dart
  String _processIncludes(String rawContent, Template template, TemplateContext context) {
    final includePattern = RegExp(r'\{\{>\s*([^}]+)\s*\}\}');
    return rawContent.replaceAllMapped(includePattern, (match) {
      final templateName = match.group(1)!.trim();
      try {
        final asset = _assetBuilder.build(templateName);
        if (asset.exists()) {
          final includedContent = asset.getContentAsString();
          return _renderTemplate(includedContent, template, context);
        }
      } catch (_) {}
      return '';
    });
  }
```
