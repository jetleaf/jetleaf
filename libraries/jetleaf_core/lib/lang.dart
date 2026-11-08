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
export 'src/lang/meta/executable/executable_argument.dart';

// ============================================================================
// EXTERNAL INTEGRATION INTERFACES & RUNTIME SYSTEM HOOKS
// ============================================================================

export 'src/lang/helpers/base.dart' hide equals, toString, toStringWith;
export 'src/lang/helpers/equals_and_hash_code.dart';
export 'src/lang/helpers/to_string.dart';
export 'src/lang/helpers/qualified_name.dart';

export 'declaration.dart';

export 'src/lang/meta/hint/abstract_runtime_hint.dart';
export 'src/lang/meta/hint/runtime_hint.dart';
export 'src/lang/meta/hint/runtime_hint_descriptor.dart';
export 'src/lang/meta/hint/runtime_hint_provider.dart';
export 'src/lang/meta/hint/default_runtime_hint_descriptor.dart';

export 'src/lang/annotation/reflectable_annotations.dart';
export 'src/lang/classes.dart';
export 'src/lang/utils/constant.dart' hide IterableExtension;
export 'src/lang/utils/generic_type_parser.dart';
export 'src/lang/utils/reflection_utils.dart';

export 'src/lang/runtime/provider/runtime_provider.dart' hide StringExte;

export 'src/lang/runtime/executor/aot/aot_runtime_executor.dart';
export 'src/lang/runtime/executor/jit/jit_runtime_executor.dart';
export 'src/lang/runtime/executor/default_runtime_executor.dart';
export 'src/lang/runtime/executor/runtime_executor.dart';
export 'src/lang/runtime/executor/resolving/runtime_executor_resolving.dart';

export 'src/lang/system/system.dart';
export 'src/lang/system/system_detector.dart' hide StandardSystemDetector;
export 'src/lang/system/properties.dart';
export 'src/lang/system/system_properties.dart';

export 'src/lang/byte/binary_builder.dart';
export 'src/lang/byte/binary_reader.dart';
export 'cache.dart';