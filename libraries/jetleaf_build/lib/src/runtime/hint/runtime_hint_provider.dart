import 'runtime_hint.dart';

/// {@template runtime_hint_provider}
/// A factory interface responsible for producing concrete [RuntimeHint]
/// instances.
///
/// `RuntimeHintProvider` represents the *declarative entry point* through which
/// Jetleaf discovers and instantiates runtime hints during both:
///
/// - **AOT analysis** (via build-time scanning)  
/// - **JIT / mirror-based reflection** (during runtime hint resolution)  
///
/// Implementations of this interface are typically lightweight and are used
/// to *register* a hint type with the Jetleaf resolution system without
/// requiring the hint itself to expose a public constructor.
///
/// ## Purpose
/// Jetleaf’s runtime behavior is extensible through `RuntimeHint`
/// implementations, which can override:
///
/// - Instance creation  
/// - Method invocation  
/// - Field reads  
/// - Field writes  
///
/// However, hints may require initialization logic, configuration, or
/// dependency injection. `RuntimeHintProvider` abstracts how the hint instance
/// is constructed, allowing:
///
/// - Controlled instantiation  
/// - Centralized configuration  
/// - Injection of external services  
/// - Reuse of hint objects where appropriate  
///
/// This isolates hint creation from the rest of the reflection system.
///
/// ## Typical Usage
/// ```dart
/// class UserHintProvider implements RuntimeHintProvider {
///   @override
///   RuntimeHint createHint() => UserHint();
/// }
/// ```
///
/// Providers are registered and discovered by the AOT resolver through Jetleaf's
/// annotation scanning and code generation pipeline.
///
/// ## Integration Notes
/// - The returned hint **must** implement [RuntimeHint].  
/// - Providers should avoid expensive initialization during construction.
///   Defer work to the hint instance when possible.  
/// - The resolver may construct providers multiple times depending on the
///   chosen execution path (AOT or JIT).  
///
/// {@endtemplate}
abstract interface class RuntimeHintProvider {
  /// {@macro runtime_hint_provider}
  const RuntimeHintProvider();

  /// Creates and returns a new [RuntimeHint] instance.
  ///
  /// Implementations must return a fully initialized hint that is ready to
  /// participate in Jetleaf’s runtime override pipeline.
  ///
  /// The resolver may call this method:
  /// - During initial AOT configuration  
  /// - During JIT fallback resolution  
  /// - When processing generated metadata  
  ///
  /// Returning `null` is not allowed; implementations must always return a
  /// valid hint instance.
  RuntimeHint createHint();
}