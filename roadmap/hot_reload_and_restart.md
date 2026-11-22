# Architectural Design for Hot Reload & Hot Restart in JetLeaf

> **Status:** Roadmap / Architectural Specification  
> **Scope:** `jetleaf_core`, `jetleaf_tools`, `jetleaf_web`, `jetleaf_data`, `jetleaf_scheduling`, `jetleaf_resource`, `jtl`, `jetson`, `jetleaf_validation`, `jetleaf_retry`

To give JetLeaf a first-class **Hot Reload** (sub-second delta update preserving state) and **Hot Restart** (full context teardown and re-bootstrap inside the same resident VM isolate) that every library (`jetleaf_web`, `jetleaf_data`, `jetleaf_scheduling`, `jetleaf_resource`, etc.) and user pod can hook into, the design is layered into four tiers.

---

## Tier A — Core Contracts in `jetleaf_core`

### 1. `HotReloadDelta` & `HotReloadEvent` (`ApplicationContextEvent`)

Computed by comparing the previous `RuntimeManifest` fingerprint table against the new scan:

- `Set<Class> getModifiedClasses()` — classes whose AST body or annotations changed.
- `Set<String> getAddedPodNames()` / `Set<String> getModifiedPodNames()` / `Set<String> getRemovedPodNames()`.
- `Set<String> getModifiedAssetPaths()` — changed `.yaml`, `.properties`, `.html`, `.jtl`, or `.sql` assets.
- `bool isStructuralChange()` — `true` if constructor signatures of singleton pods or class hierarchies changed in a way that requires re-instantiating affected pods.

### 2. `HotRestartEvent` (`ApplicationContextEvent`)

Published right before `ConfigurableApplicationContext` tears down for a Hot Restart, allowing pods holding OS resources (HTTP sockets, database pools, file locks) to release or hand them off cleanly.

### 3. `RefreshablePod` Interface (for Stateful Pods & Libraries)

```dart
abstract interface class RefreshablePod {
  /// Invoked after Dart VM `reloadSources` completes during a Hot Reload.
  Future<void> onHotReload(HotReloadDelta delta, ApplicationContext context);
}
```

### 4. `@RefreshScope` Annotation (Spring Cloud `@RefreshScope` Equivalent)

Pods annotated with `@RefreshScope()` (or `ScopeDesign.type('refresh')`) are lazily re-instantiated on the next access whenever a `HotReloadEvent` modifies their declaring class or any `@ConfigurationProperties` / `@Value` key they depend on.

### 5. `ReloadAwarePodProcessor` (`PodProcessor` Extension)

```dart
abstract interface class ReloadAwarePodProcessor implements PodProcessor {
  /// Re-processes a pod whose class or methods were modified during Hot Reload.
  Future<void> processOnHotReload(
    Object pod,
    Class podClass,
    String name,
    HotReloadDelta delta,
  );
}
```

---

## Tier B — How `DefaultListablePodFactory` & `MaterializedLibrary` Process a Hot Reload

### 1. Re-binding `MaterializedLibrary` Dispatch Tables

- In `AotRegistrarWriter`, update `_initRuntime()` to accept `bool force = false` (or expose `reloadGeneratedArtifacts(DefaultListablePodFactory factory, HotReloadDelta delta)`).
- After `vmService.reloadSources(isolateId)` completes, calling `reloadGeneratedArtifacts(...)` overwrites `_registeredTypes`, `_constructorFactories`, `_methodInvokers`, `_fieldGetters`, `_fieldSetters`, and `_annotationInstanceResolver` with the newly reloaded closures.

### 2. Selective Singleton Refresh in `DefaultListablePodFactory`

- **Body-only edit on an existing pod method:** Dart VM's `reloadSources` updates the method code in-place on existing heap instances automatically; no pod re-instantiation is needed.
- **Added pod:** Registered via `registerDefinition` and instantiated if non-lazy.
- **Removed pod:** Destroyed via `destroySingleton(podName)` and removed from `_definitions`.
- **Modified constructor / injected field on a singleton pod:** The container calls `destroySingleton(podName)`, re-registers the updated `RootPodDefinition`, re-instantiates the singleton, and re-injects it into dependent pods (or marks `@RefreshScope` proxies dirty).

---

## Tier C — How Each JetLeaf Package Hooks Into Hot Reload & Hot Restart

| Package | On Hot Reload (`HotReloadEvent` / `RefreshablePod`) | On Hot Restart (`HotRestartEvent`) |
| :--- | :--- | :--- |
| **`jetleaf_web`** | `AbstractAnnotatedHandlerMapping` implements `RefreshablePod`: when any `@RestController` / `@Controller` / `@ControllerAdvice` class is in `delta.getModifiedClasses()`, it unregisters routes owned by that controller and re-runs `registerHandler` for the updated controller methods. The `HttpServer` socket on port `8080` stays bound — **0ms socket downtime**. | `IoWebServer` closes active keep-alive connections and calls `HttpServer.close(force: true)` before the new context binds the port (or reuses a shared `ServerSocket` in `JetleafVM`). |
| **`jetleaf_data`** | `DefaultEntityMetadataRegistry` evicts and rebuilds `EntityMetadata` for any `@Entity` class in `delta.getModifiedClasses()`. `RepositoryFactorySupport` invalidates cached `QueryMethod` part-trees for modified repository interfaces. `DefaultConnectionPool` stays open — active DB connections are preserved. | `DefaultConnectionPool.close()` rolls back any in-flight transactions and closes physical connections before re-initializing. |
| **`jetleaf_scheduling`** | `SchedulingAnnotationPodProcessor` implements `ReloadAwarePodProcessor`: for any modified pod in `delta.getModifiedClasses()`, it calls `_cancelScheduledTasks(pod)` to cancel old timers and re-scans the pod's `@Scheduled` / `@Cron` / `@Periodic` annotations to start updated triggers immediately. | Cancels all active timers and shuts down `ConcurrentTaskScheduler`. |
| **`jetleaf_resource`** | If a `@Cacheable` / `@RateLimit` method's signature or key expression changed, `CacheAnnotationMethodInterceptor` refreshes its operation metadata while preserving in-memory `CacheStorage` entries (unless `@CacheEvict` or a model schema change is detected). Reloads `.yaml`/`.properties` into `Environment` if in `delta.getModifiedAssetPaths()`. | Clears ephemeral in-memory caches and rate-limit windows. |
| **`jtl` & `jetson`** | `InMemoryTemplateCache` evicts any template path present in `delta.getModifiedAssetPaths()` so the next HTTP request renders the edited `.html`/`.jtl` file immediately. `Jetson` evicts cached `ObjectMapper` serializer/deserializer adapters for modified DTO classes. | Full cache reset on context recreation. |
| **`jetleaf_validation` & `jetleaf_retry`** | Evicts cached constraint metadata / retry policy descriptors for classes in `delta.getModifiedClasses()`. | Full reset on context recreation. |

---

## Tier D — Tooling & VM Service Orchestration (`jetleaf_tools` / `jl dev`)

1. **Incremental Scan & Delta Computation:** File watcher detects changes in `lib/**` or asset directories, runs an incremental scan, and computes `HotReloadDelta` against the prior `RuntimeManifest`.
2. **Hot Reload Flow:**
   - Regenerates affected `_jetleaf/` registry entries if annotations, pods, or signatures changed.
   - Invokes `vmService.reloadSources(isolateId)` over the Dart VM Service protocol.
   - Calls `reloadGeneratedArtifacts(factory, delta)` inside the isolate, triggers `DefaultListablePodFactory` selective refresh, invokes `ReloadAwarePodProcessor` / `RefreshablePod` hooks, and publishes `HotReloadEvent`.
3. **Hot Restart Flow:**
   - Triggered when `delta.isStructuralChange()` requires a clean container rebuild or when explicitly requested by the developer.
   - Publishes `HotRestartEvent`, tears down the active `ConfigurableApplicationContext`, re-initializes `MaterializedLibrary` with `force: true`, and re-bootstraps `JetApplication` in the same resident isolate.