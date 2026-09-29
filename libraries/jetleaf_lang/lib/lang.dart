// ignore_for_file: deprecated_member_use

/// # Core Language Architecture: Metaprogramming Runtime, Reflection & System Topologies
///
/// A highly optimized reflection, metaprogramming, and asset resolution subsystem. This framework 
/// acts as an advanced runtime reflection engine designed to unlock deep structural introspection 
/// for enterprise applications with minimal performance degradation.
///
/// This library decouples domain codebeds from static execution paths, orchestrating three primary system segments:
///
/// 1. **Meta-Reflection Subsystem:** Structural mirror mappings providing complete type inspection 
///    via [Class], [Field], [Method], [Constructor], [Parameter], and [Annotation] trackers.
/// 2. **Asset & Resource Loading Layers:** Multi-environment localization and configuration asset engines 
///    managed using standard unified [AssetResource] and [ClassPathResource] topologies.
/// 3. **Dynamic Invocation Runtimes:** Reflection execution managers ([ExecutableSelector], [ExecutableInstantiator]) 
///    that perform fast dynamic type lookups, argument matrix checking, and constructor or method invocation handling.
///
/// ---
///
/// ## 1. Reflective Precedence & Execution Matrix
///
/// ```text
///                             [Class]
///                                |
///        +-----------------------+-----------------------+
///        |                       |                       |
///    [Field]                [Method]               [Constructor]
///  (Accessors)            (Invocation)             (Instantiation)
///        |                       |                       |
/// [FieldAccessExcept]   [MethodNotFoundExcept]   [ConstructorNotFoundExcept]
/// ```
///
/// ---
///
/// ## 2. Core Reflection Mechanics & Safety
///
/// ### Defensive Metaprogramming & Argument Matrix Resolution
/// Dynamic data binding, deserialization loops, and dependency injection engines communicate heavily with reflection systems. 
/// Components like [ExecutableArgumentResolver] validate incoming argument buffers against targeted [Parameter] signposts. 
/// If signature patterns break, specialized exceptions (e.g., [MissingRequiredNamedParameterException] or [TooManyPositionalArgumentException]) 
/// capture the failure state cleanly before native stack overflows can occur.
///
/// ### Optimized Asset Bundling
/// File reads from disk, inside archive packages, or across compilation build caches are normalized using [AssetLoader] and [Bundler]. 
/// This guarantees stable path parsing structures, regardless of whether resources are bundled during background tasks 
/// or loaded actively at runtime.
///
/// ### Pipeline Architecture Example
/// ```dart
/// // Dynamically instantiating a class component safely using the meta-reflection engine
/// final Class controllerType = Class.of<AuthenticationController>();
/// 
/// final Constructor targetedInitializer = controllerType.getConstructors()
///     .firstWhere((constructor) => constructor.hasAnnotation<Inject>());
/// 
/// // Perform arguments auto-resolution injection
/// final Object instance = targetedInitializer.newInstance(
///   positionalArguments: [databaseConnectionPool, loggerInstance],
///   namedArguments: {'timeoutOverride': 30.seconds},
/// );
/// ```
library;

export 'design.dart';

// ============================================================================
// ASSET LOADER LAYER & RESOURCE RESOLUTION ENGINES
// ============================================================================

export 'src/meta/resource/asset_loader/_bundler.dart';
export 'src/meta/resource/asset_loader/bundler.dart';
export 'src/meta/resource/asset_loader/interface.dart';
export 'src/meta/resource/class_path/class_path_resource.dart' hide DefaultClassPathResource;
export 'src/meta/resource/asset_path/asset_resource.dart' hide DefaultAssetBuilder, DefaultAssetPathResource, FileAssetPathResource;

// ============================================================================
// METAPROGRAMMING MIRRORS & TYPE INTROSPECTION SYSTEM
// ============================================================================

export 'src/meta/class/class.dart';
export 'src/meta/class/class_gettable.dart';
export 'src/meta/class/class_type.dart';
export 'src/meta/field/field.dart';
export 'src/meta/constructor/constructor.dart';
export 'src/meta/method/method.dart';
export 'src/meta/parameter/parameter.dart';
export 'src/meta/enum/enum_value.dart';
export 'src/meta/annotation/annotation.dart';
export 'src/meta/protection_domain/protection_domain.dart';
export 'src/meta/package_identifier.dart';
export 'src/meta/core.dart';
export 'src/meta/hint/materialized_runtime_hint.dart';
export 'src/meta/record/record_field.dart';

// ============================================================================
// DYNAMIC ARGUMENT RESOLUTION & EXECUTABLE RUNTIMES
// ============================================================================

export 'src/meta/executable/executable_argument_resolver.dart';
export 'src/meta/executable/executable_selector.dart';
export 'src/meta/executable/executable_instantiator.dart';

// ============================================================================
// EXTERNAL INTEGRATION INTERFACES & RUNTIME SYSTEM HOOKS
// ============================================================================

export 'package:jetleaf_build/jetleaf_build.dart' show
  Constant,
  runScan,
  runTestScan,
  Asset,
  Package,
  Hint,
  RuntimeHint,
  Runtime,
  ExecutableArgument,
  EqualsAndHashCode,
  Generic,
  RuntimeHintDescriptor,
  RuntimeHintProvider,
  GenerativeAsset,
  GenerativePackage,
  BuildException,
  RuntimeException,
  FieldAccessException,
  FieldMutationException,
  MethodNotFoundException,
  RuntimeResolverException,
  GenericResolutionException,
  ArgumentResolutionException,
  PrivateFieldAccessException,
  ConstructorNotFoundException,
  PrivateMethodInvocationException,
  UnresolvedTypeInstantiationException,
  UnsupportedRuntimeOperationException,
  PrivateConstructorInvocationException,
  UnexpectedArgumentException,
  FewerPositionalArgumentException,
  MorePositionalArgumentException,
  MissingRequiredNamedParameterException,
  MissingRequiredPositionalParameterException,
  Throwable,
  PackageNames,
  ReflectableAnnotation,
  Author,
  JetleafEntry,
  JetleafTest,
  ToString,
  ToStringOptions,
  QualifiedName,
  System,
  SystemDetector,
  SystemProperties,
  StdExtension,
  SystemExtension
;