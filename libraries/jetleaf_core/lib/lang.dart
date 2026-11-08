// ignore_for_file: deprecated_member_use

/// # Core Language Architecture: Metaprogramming Runtime, Reflection & System Topologies
///
/// A highly optimized reflection, metaprogramming, and asset resolution subsystem.
library;

export 'design.dart';

// ============================================================================
// ASSET LOADER LAYER & RESOURCE RESOLUTION ENGINES
// ============================================================================

export 'src/lang/meta/resource/asset_loader/_bundler.dart';
export 'src/lang/meta/resource/asset_loader/bundler.dart';
export 'src/lang/meta/resource/asset_loader/interface.dart';
export 'src/lang/meta/resource/class_path/class_path_resource.dart' hide DefaultClassPathResource;
export 'src/lang/meta/resource/asset_path/asset_resource.dart' hide DefaultAssetBuilder, DefaultAssetPathResource, FileAssetPathResource;

// ============================================================================
// METAPROGRAMMING MIRRORS & TYPE INTROSPECTION SYSTEM
// ============================================================================

export 'src/lang/meta/class/class.dart';
export 'src/lang/meta/class/class_gettable.dart';
export 'src/lang/meta/class/class_type.dart';
export 'src/lang/meta/field/field.dart';
export 'src/lang/meta/constructor/constructor.dart';
export 'src/lang/meta/method/method.dart';
export 'src/lang/meta/parameter/parameter.dart';
export 'src/lang/meta/enum/enum_value.dart';
export 'src/lang/meta/annotation/annotation.dart';
export 'src/lang/meta/protection_domain/protection_domain.dart';
export 'src/lang/meta/package_identifier.dart';
export 'src/lang/meta/core.dart';
export 'src/lang/meta/hint/materialized_runtime_hint.dart';
export 'src/lang/meta/record/record_field.dart';

// ============================================================================
// DYNAMIC ARGUMENT RESOLUTION & EXECUTABLE RUNTIMES
// ============================================================================

export 'src/lang/meta/executable/executable_argument_resolver.dart';
export 'src/lang/meta/executable/executable_selector.dart';
export 'src/lang/meta/executable/executable_instantiator.dart';

// ============================================================================
// EXTERNAL INTEGRATION INTERFACES & RUNTIME SYSTEM HOOKS
// ============================================================================

export 'package:jetleaf_tools/jetleaf_tools.dart' show
  Declaration,
  Constant,
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