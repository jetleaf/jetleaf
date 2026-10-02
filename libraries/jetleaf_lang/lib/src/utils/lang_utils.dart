import 'package:dart_internal/extract_type_arguments.dart';
import 'package:jetleaf_build/jetleaf_build.dart';

import '../meta/class/class.dart';
import '../meta/class/class_type.dart';
import '../meta/protection_domain/protection_domain.dart';

/// {@template lang_utils}
/// Utility class providing **type resolution helpers** for Jetleaf meta-APIs.
///
/// `LangUtils` focuses on obtaining Jetleaf [Class] representations for:
/// - Runtime objects (`obtainClass`)  
/// - Link-time declarations (`obtainClassFromLink`)  
///
/// This allows Jetleaf to provide full meta-models for **functions**, **records**, 
/// generic collections, maps, and normal Dart classes, unifying link-time and runtime
/// type information.
///
/// The utilities handle:
/// - Functions → converted to [Class]  
/// - Records → converted to [Class]  
/// - Collections → generic type arguments extracted  
/// - Maps → key/value type arguments extracted  
/// - Dynamic / void types → mapped to Jetleaf singletons  
/// - Fallback resolution using qualified names or runtime `Type` objects
/// {@endtemplate}
abstract final class LangUtils {
  /// {@macro lang_utils}
  LangUtils._();

  /// Resolves the [Class] representation of a runtime [object].
  ///
  /// This method inspects the object and determines the appropriate Jetleaf
  /// [Class] instance, handling a wide range of cases:
  ///
  /// ### Behavior
  /// 1. **Functions** → returns a [Class] representing the function signature.  
  /// 2. **Records** → returns a [Class] representing the record shape.  
  /// 3. **Collections** (`List`, `Set`, `Iterable`) → extracts generic type arguments.  
  /// 4. **Maps** → extracts key and value type arguments.  
  /// 5. **Dynamic / Void / Other types** → uses qualified names or runtime type for resolution.  
  ///
  /// ### Parameters
  /// - [object]: The runtime object to resolve.  
  /// - [pd]: Optional [ProtectionDomain] to enforce access or security rules.  
  /// - [package]: Optional package name hint for resolution.  
  /// - [link]: Optional [LinkDeclaration] if the object originates from a link-time declaration.  
  ///
  /// ### Returns
  /// A fully resolved [Class<Object>] representing the object's type in Jetleaf.
  ///
  /// ### Example
  /// ```dart
  /// final list = [1, 2, 3];
  /// final clazz = LangUtils.obtainClass(list);
  /// print(clazz.getName()); // → "List<int>"
  /// ```
  static Class<Object> obtainClass(Object object, {ProtectionDomain? pd, String? package, LinkDeclaration? link}) {
    final Object self = object;

    try {
      if (self is Iterable<Object?>) {
        Class<Object?> Function<E>() f = switch (self) {
          List<Object?>() => <E>() => Class<List<E>>(null, null),
          Set<Object?>() => <E>() => Class<Set<E>>(null, null),
          _ => <E>() => Class<Iterable<E>>(null, null),
        };
        return extractIterableTypeArgument(self, f) as Class<Object>;
      }

      if (self is Iterable) {
        Class Function<E>() f = switch (self) {
          List() => <E>() => Class<List<E>>(null, null),
          Set() => <E>() => Class<Set<E>>(null, null),
          _ => <E>() => Class<Iterable<E>>(null, null),
        };
        return extractIterableTypeArgument(self, f) as Class<Object>;
      }

      if (self is Map<Object?, Object?>) {
        Class<Object?> Function<E, F>() f = switch (self) {
          Map<Object?, Object?>() => <E, F>() => Class<Map<E, F>>(null, null),
        };
        return extractMapTypeArguments(self, f) as Class<Object>;
      }

      if (self is Map) {
        Class Function<E, F>() f = switch (self) {
          Map() => <E, F>() => Class<Map<E, F>>(null, null),
        };
        return extractMapTypeArguments(self, f) as Class<Object>;
      }
      
      return Class.declared(Runtime.obtainClassDeclaration(object), pd ?? ProtectionDomain.current());
    } on ClassNotFoundException catch (_) {
      return Class.declared(Runtime.obtainClassDeclaration(object), pd ?? ProtectionDomain.current());
    }
  }

  /// Resolves a [Class] instance from a [LinkDeclaration].
  ///
  /// {@template class_from_link}
  /// This utility converts a build-time [LinkDeclaration] into a runtime
  /// [Class] object, handling Dart function types, dynamic types, void types,
  /// unresolved types, and fallback cases.
  ///
  /// The resolution process prioritizes:
  /// 1. **Function declarations**  
  ///    For [FunctionLinkDeclaration], the method resolves the **return type**
  ///    instead of treating the function itself as the class.
  ///
  /// 2. **Dynamic and void shortcuts**  
  ///    If the declaration represents `dynamic` or `void`, the corresponding
  ///    singleton ([DYNAMIC_CLASS] or [VOID_CLASS]) is returned immediately.
  ///
  /// 3. **Pointer-based type resolution**  
  ///    The system first attempts to resolve using the pointer type’s `Type`
  ///    object. If unavailable, it falls back to resolution by qualified name.
  ///
  /// 4. **Graceful degradation**  
  ///    If type resolution fails, the method falls back to:
  ///    - returning predefined dynamic/void classes,
  ///    - or resolving using the declaration's raw Dart `Type`.
  ///
  /// ## Parameters
  /// - `declaration`: The link-time declaration describing the type.
  /// - `[pd]`: Optional [ProtectionDomain] to enforce security constraints
  ///   during reflective resolution.
  ///
  /// ## Returns
  /// A fully resolved [Class] instance representing the declaration's type.
  ///
  /// ## Behavior Summary
  /// - Function declaration → resolve return type  
  /// - `dynamic` → [DYNAMIC_CLASS]  
  /// - `void` → [VOID_CLASS]  
  /// - Fallback: `Class.fromQualifiedName`  
  /// - Final fallback on failure: `Class.forType(declaration.getType())`
  ///
  /// ## Example
  /// ```dart
  /// final link = parameter.getLinkDeclaration();
  /// final clazz = Class.getClassFromLink(link);
  ///
  /// print(clazz.getName());      // e.g., "String"
  /// print(clazz.getQualifiedName()); // e.g., "dart:core.String"
  /// ```
  ///
  /// ## Notes
  /// - This method is used extensively in reflection, parameter resolution,
  ///   annotation analysis, and invocation metadata.
  /// - It ensures that different forms of type declarations (pointer types,
  ///   qualified names, raw `Type` objects) resolve consistently.
  /// - It intentionally aligns dynamic and void resolution across both the
  ///   link-time and runtime reflection layers.
  /// {@endtemplate}
  static Class<Object> obtainClassFromLink(LinkDeclaration declaration, [ProtectionDomain? pd]) {
    try {
      if (declaration is FunctionDeclaration) {
        return Class.declared(declaration, pd ?? ProtectionDomain.current());
      }

      if (declaration is RecordDeclaration) {
        return Class.declared(declaration, pd ?? ProtectionDomain.current());
      }

      if (declaration.getType() == Dynamic || declaration.getPointerQualifiedName() == Dynamic.getQualifiedName()) {
        return DYNAMIC_CLASS;
      }

      if (declaration.getType() == dynamic || declaration.getPointerQualifiedName() == Dynamic.getQualifiedName()) {
        return DYNAMIC_CLASS;
      }

      if (declaration.getType() == Void || declaration.getPointerQualifiedName() == Void.getQualifiedName()) {
        return VOID_CLASS;
      }

      return Class.fromQualifiedName(declaration.getPointerQualifiedName(), pd, declaration);
    } on ClassNotFoundException catch (e) {
      if (e.className == "dart:core.Object") {
        return VOID_CLASS;
      }

      if (e.className == "dart:core.dynamic") {
        return DYNAMIC_CLASS;
      }

      try {
        return obtainClass(declaration.getType(), pd: pd, link: declaration);
      } on ClassNotFoundException catch (_) {}

      try {
        return obtainClass(declaration.getPointerType(), pd: pd, link: declaration);
      } on ClassNotFoundException catch (_) {}

      try {
        return Class.forType(declaration.getType(), pd, null, declaration);
      } on ClassNotFoundException catch (_) {}

      return Class.forType(declaration.getPointerType(), pd, null, declaration);
    }
  }

  /// Resolves a **strongly-typed [Class]** from a [LinkDeclaration] using a
  /// multi-phase resolution strategy.
  ///
  /// This method is the **typed counterpart** to [obtainClassFromLink].
  /// It attempts to resolve a Jetleaf [Class] while preserving the **expected
  /// generic type parameter [K]** whenever possible.
  ///
  /// ---
  ///
  /// #### Resolution Strategy (in order)
  ///
  /// The method attempts the following strategies **in sequence**, stopping
  /// at the first successful resolution:
  ///
  /// 1. **Type-based resolution**
  /// 2. **Pointer-based resolution**
  /// 3. **Default combined logic**
  /// 4. **Type fallback**
  /// 5. **Pointer fallback**
  /// 6. **Final default fallback**
  ///
  /// Each phase exists to handle a specific failure mode in Dart’s
  /// reflection and type erasure behavior.
  ///
  /// ---
  ///
  /// #### Generic Behavior
  ///
  /// - If `K == dynamic`, resolution is relaxed and avoids forced casting
  /// - If generics are detected, resolution prefers
  ///   `Class.fromQualifiedName(...)`
  /// - If generics are not present, resolution prefers
  ///   `Class.forType(...)`
  ///
  /// ---
  ///
  /// #### Parameters
  /// - [link]: The link-time declaration describing the type
  /// - [pd]: The active [ProtectionDomain] for reflective access
  ///
  /// ---
  ///
  /// #### Returns
  /// A resolved [Class] instance aligned with the expected type [K].
  ///
  /// ---
  ///
  /// #### Example
  /// ```dart
  /// Class<String> clazz =
  ///   LangUtils.obtainTypedClassFromLink<String>(link, pd);
  ///
  /// print(clazz.getName()); // "String"
  /// ```
  static Class obtainTypedClassFromLink<K>(LinkDeclaration link, ProtectionDomain pd) {
    try {
      return _handleTypeLogic<K>(link, pd);
    } on ClassNotFoundException catch (_) {}

    try {
      return _handlePointerLogic<K>(link, pd);
    } on ClassNotFoundException catch (_) {}

    try {
      return _handleDefaultLogic<K>(link, pd);
    } on ClassNotFoundException catch (_) {}

    try {
      return _handleTypeFallback<K>(link, pd);
    } on ClassNotFoundException catch (_) {}

    try {
      return _handlePointerFallback<K>(link, pd);
    } on ClassNotFoundException catch (_) {}

    return _handleDefaultFallback<K>(link, pd);
  }

  /// Attempts **primary resolution using the declaration’s declared Dart type**.
  ///
  /// This is the most precise resolution path and is attempted first.
  ///
  /// ---
  ///
  /// ## Behavior
  /// - If the declared type contains generics, resolution uses the
  ///   qualified name to preserve structure
  /// - If [K] is `dynamic`, strict typing is relaxed
  /// - Otherwise, resolution binds directly to `Class<K>`
  ///
  /// ---
  ///
  /// ## Failure Mode
  /// Throws [ClassNotFoundException] when:
  /// - Generic metadata is incomplete
  /// - The type cannot be materialized directly
  static Class _handleTypeLogic<K>(LinkDeclaration link, ProtectionDomain pd) {
    if (GenericTypeParser.shouldCheckGeneric(link.getType())) {
      if (Dynamic.isDynamic<K>()) {
        return Class.fromQualifiedName(link.getPointerQualifiedName(), pd);
      }

      return Class<K>.fromQualifiedName(link.getPointerQualifiedName(), pd);
    }
    
    if (Dynamic.isDynamic<K>()) {
      return Class.forType(link.getType(), pd);
    }

    return Class.forType<K>(link.getType() as K, pd);
  }

  /// Attempts resolution using the **pointer type** instead of the declared type.
  ///
  /// Pointer types represent the *actual runtime target* and may differ
  /// from the declared type due to:
  /// - Aliases
  /// - Type forwarding
  /// - Analyzer indirections
  ///
  /// ---
  ///
  /// ## Behavior
  /// - Prefers qualified-name resolution when generics are present
  /// - Falls back to runtime type resolution when safe
  ///
  /// ---
  ///
  /// ## When This Is Used
  /// - Declared type failed to resolve
  /// - Pointer type provides more accurate runtime metadata
  static Class _handlePointerLogic<K>(LinkDeclaration link, ProtectionDomain pd) {
    if (link.getType() == link.getPointerType()) {
      if (Dynamic.isDynamic<K>()) {
        return Class.fromQualifiedName(link.getPointerQualifiedName());
      }

      return Class<K>.fromQualifiedName(link.getPointerQualifiedName());
    }

    if (GenericTypeParser.shouldCheckGeneric(link.getPointerType())) {
      if (Dynamic.isDynamic<K>()) {
        return Class.fromQualifiedName(link.getPointerQualifiedName(), pd);
      }

      return Class<K>.fromQualifiedName(link.getPointerQualifiedName(), pd);
    }

    if (Dynamic.isDynamic<K>()) {
      return Class.forType(link.getPointerType(), pd);
    }

    return Class.forType<K>(link.getPointerType() as K, pd);
  }

  /// Applies **combined default logic** when neither strict type nor pointer
  /// resolution succeeds.
  ///
  /// This method:
  /// - Compares declared type vs pointer type
  /// - Chooses the safest resolution path
  /// - Preserves generics when possible
  ///
  /// ---
  ///
  /// ## Design Intent
  /// This phase handles ambiguous cases where:
  /// - Declared and pointer types differ
  /// - Generic metadata exists but is partial
  /// - Runtime type information is inconsistent
  static Class _handleDefaultLogic<K>(LinkDeclaration link, ProtectionDomain pd) {
    if (link.getType() == link.getPointerType()) {
      if (Dynamic.isDynamic<K>()) {
        return Class.fromQualifiedName(link.getPointerQualifiedName());
      }

      return Class<K>.fromQualifiedName(link.getPointerQualifiedName());
    }
    
    if (GenericTypeParser.shouldCheckGeneric(link.getPointerType())) {
      if (Dynamic.isDynamic<K>()) {
        return Class.fromQualifiedName(link.getPointerQualifiedName(), pd);
      }

      return Class<K>.fromQualifiedName(link.getPointerQualifiedName(), pd);
    }
    
    if (GenericTypeParser.shouldCheckGeneric(link.getType())) {
      if (Dynamic.isDynamic<K>()) {
        return Class.fromQualifiedName(link.getPointerQualifiedName(), pd);
      }

      return Class<K>.fromQualifiedName(link.getPointerQualifiedName(), pd);
    }
    
    if (Dynamic.isDynamic<K>()) {
      return Class.forType(link.getType(), pd);
    }

    return Class.forType<K>(link.getType() as K, pd);
  }

  /// Fallback strategy prioritizing the **declared type**, even when generic
  /// integrity cannot be preserved.
  ///
  /// ---
  ///
  /// ## Use Case
  /// - Qualified-name resolution failed
  /// - Pointer type is unreliable
  ///
  /// ---
  ///
  /// ## Trade-off
  /// - Generic fidelity may be reduced
  /// - Type correctness is prioritized over structure
  static Class _handleTypeFallback<K>(LinkDeclaration link, ProtectionDomain pd) {
    if (GenericTypeParser.shouldCheckGeneric(link.getType())) {
      if (Dynamic.isDynamic<K>()) {
        return Class.forType(link.getPointerType(), pd);
      }

      return Class.forType<K>(link.getPointerType() as K, pd);
    }

    if (Dynamic.isDynamic<K>()) {
      return Class.forType(link.getType(), pd);
    }

    return Class.forType<K>(link.getType() as K, pd);
  }

  /// Fallback strategy prioritizing the **pointer type** when declared
  /// resolution fails.
  ///
  /// ---
  ///
  /// ## Use Case
  /// - Declared type is synthetic or erased
  /// - Pointer type represents the actual runtime instance
  static Class _handlePointerFallback<K>(LinkDeclaration link, ProtectionDomain pd) {
    if (link.getType() == link.getPointerType()) {
      if (Dynamic.isDynamic<K>()) {
        return Class.forType(link.getType(), pd);
      }

      return Class.forType<K>(link.getType() as K, pd);
    }
    
    if (Dynamic.isDynamic<K>()) {
      return Class.forType(link.getPointerType(), pd);
    }

    return Class.forType<K>(link.getPointerType() as K, pd);
  }

  /// Final resolution fallback guaranteeing a [Class] result.
  ///
  /// This method ensures that resolution **never fails catastrophically**.
  /// It selects the most reasonable remaining option based on:
  ///
  /// - Declared vs pointer type equality
  /// - Generic presence
  /// - Whether [K] is dynamic
  ///
  /// ---
  ///
  /// ## Guarantee
  /// This method **always returns a [Class]** unless the runtime itself
  /// cannot represent the type.
  static Class _handleDefaultFallback<K>(LinkDeclaration link, ProtectionDomain pd) {
    if (link.getType() == link.getPointerType()) {
      if (Dynamic.isDynamic<K>()) {
        return Class.forType(link.getType(), pd);
      }

      return Class.forType<K>(link.getType() as K, pd);
    }
    
    if (GenericTypeParser.shouldCheckGeneric(link.getPointerType())) {
      if (Dynamic.isDynamic<K>()) {
        return Class.forType(link.getType(), pd);
      }

      return Class.forType<K>(link.getType() as K, pd);
    }
    
    if (GenericTypeParser.shouldCheckGeneric(link.getType())) {
      if (Dynamic.isDynamic<K>()) {
        return Class.forType(link.getPointerType(), pd);
      }

      return Class.forType<K>(link.getPointerType() as K, pd);
    }
    
    if (link.getType() != link.getPointerType()) {
      if (Dynamic.isDynamic<K>()) {
        return Class.forType(link.getPointerType(), pd);
      }

      return Class.forType<K>(link.getPointerType() as K, pd);
    }
    
    if (Dynamic.isDynamic<K>()) {
      return Class.forType(link.getType(), pd);
    }

    return Class.forType<K>(link.getType() as K, pd);
  }
}