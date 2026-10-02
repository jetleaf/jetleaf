/// ⏱️ **Jetleaf Rate Limiting Library**
///
/// This library provides a comprehensive rate-limiting system for Jetleaf
/// applications, enabling fine-grained control over method calls, API
/// access, and other resources.
///
/// It supports annotations, method interceptors, storage backends,
/// event tracking, metrics, and pluggable resolvers.
///
///
/// ## 🔑 Key Concepts
///
/// - **Rate-Limit Operations**: control access frequency per resource or method.
/// - **Storage Backends**: persist rate-limit state with optional rollback support.
/// - **Metrics**: track allowed, denied, and reset events for monitoring.
/// - **Events**: observe rate-limiting lifecycle events in real-time.
/// - **Resolvers & Managers**: dynamically determine applicable limits.
/// - **Annotations**: declarative, method-level rate limiting.
///
///
/// ## 📦 Exports Overview
///
/// ### ⚙ Core
/// - `RateLimitAnnotationMethodInterceptor` — intercepts annotated methods  
/// - `RateLimitComponentRegistrar` — registers rate-limit components  
/// - `RateLimitOperationContext` / `DefaultRateLimitOperationContext` — runtime operation metadata
///
///
/// ### 📊 Metrics
/// - `RateLimitMetrics` — interface for tracking metrics  
/// - `SimpleRateLimitMetrics` — default implementation for monitoring events
///
///
/// ### 🏗 Managers
/// - `RateLimitManager` — primary orchestrator of rate-limiting rules  
/// - `RateLimitManagerRegistry` — manages multiple managers  
/// - `SimpleRateLimitManager` — default implementation
///
///
/// ### 🔍 Resolvers
/// - `RateLimitResolver` — determines applicable limits dynamically  
/// - `RateLimitResolverRegistry` — registry for multiple resolvers  
/// - `SimpleRateLimitResolver` — default implementation
///
///
/// ### 🗄 Storage
/// - `RateLimitStorage` — storage interface for rate-limit entries  
/// - `RateLimitStorageRegistry` — manage multiple storage backends  
/// - `ConfigurableRateLimitStorage` — custom-configurable storage  
/// - `DefaultRateLimitStorage` — standard in-memory implementation  
/// - `RollBackCapableRateLimitStorage` — supports rollback operations  
/// - `RateLimitResource` — resource representation  
/// - `RateLimitEntry` / `SimpleRateLimitEntry` — stored rate-limit state
///
///
/// ### 📝 Events
/// - `RateLimitEvent` — base event type  
/// - `RateLimitAllowedEvent` — emitted when a call passes  
/// - `RateLimitDeniedEvent` — emitted when a call is blocked  
/// - `RateLimitResetEvent` — emitted when counters reset  
/// - `RateLimitClearEvent` — emitted when cache or storage is cleared
///
///
/// ### 🏷 Annotations & Config
/// - `annotations.dart` — declarative, method-level rate limiting  
/// - `RateLimitConfigurer` — programmatic configuration  
/// - `RateLimitResult` — encapsulates the result of a rate-limited operation
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to enable full rate-limiting capabilities:
/// ```dart
/// import 'package:jetleaf_resource/rate_limit.dart';
///
/// @RateLimited(maxCalls: 5, duration: Duration(minutes: 1))
/// void fetchData() {
///   // method code
/// }
/// ```
///
/// Supports pluggable storage, metrics, events, and error handling.
///
///
/// © 2025 Hapnium & Jetleaf Contributors
library;

export 'src/rate_limit/core/default_rate_limit_operation_context.dart';
export 'src/rate_limit/core/rate_limit_annotation_method_interceptor.dart';
export 'src/rate_limit/core/rate_limit_component_registrar.dart';
export 'src/rate_limit/core/rate_limit_operation_context.dart';

export 'src/rate_limit/events/rate_limit_allowed_event.dart';
export 'src/rate_limit/events/rate_limit_clear_event.dart';
export 'src/rate_limit/events/rate_limit_denied_event.dart';
export 'src/rate_limit/events/rate_limit_event.dart';
export 'src/rate_limit/events/rate_limit_reset_event.dart';

export 'src/rate_limit/manager/rate_limit_manager.dart';
export 'src/rate_limit/manager/rate_limit_manager_registry.dart';
export 'src/rate_limit/manager/simple_rate_limit_manager.dart';

export 'src/rate_limit/metrics/rate_limit_metrics.dart';
export 'src/rate_limit/metrics/simple_rate_limit_metrics.dart';

export 'src/rate_limit/resolver/rate_limit_resolver.dart';
export 'src/rate_limit/resolver/rate_limit_resolver_registry.dart';
export 'src/rate_limit/resolver/simple_rate_limit_resolver.dart';

export 'src/rate_limit/storage/configurable_rate_limit_storage.dart';
export 'src/rate_limit/storage/default_rate_limit_storage.dart';
export 'src/rate_limit/storage/rate_limit_resource.dart';
export 'src/rate_limit/storage/rate_limit_storage.dart';
export 'src/rate_limit/storage/rate_limit_storage_registry.dart';
export 'src/rate_limit/storage/roll_back_capable_rate_limit_storage.dart';
export 'src/rate_limit/storage/rate_limit_entry.dart';
export 'src/rate_limit/storage/simple_rate_limit_entry.dart';

export 'src/rate_limit/annotations.dart';
export 'src/rate_limit/rate_limit_configurer.dart';
export 'src/rate_limit/rate_limit_result.dart';