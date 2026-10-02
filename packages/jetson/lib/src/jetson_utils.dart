// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_lang/lang.dart';

import 'annotations.dart';

/// Utility class providing object construction helpers for Dart types.
abstract interface class JetsonUtils {
  /// Constructs a Dart instance of the specified [type] using the given [fields].
  ///
  /// This method attempts to resolve a constructor or factory for the type in the
  /// following order:
  ///
  /// 1. **[FromJson] annotation creator** – If the class has a `FromJson` annotation,
  ///    the provided creator function is invoked with the `fields` map.
  /// 2. **Constructor annotated with [JsonCreator]** – Uses a constructor annotated
  ///    with `JsonCreator` and passes the `fields` map as argument(s).
  /// 3. **Static `fromJson(Map<String, dynamic>)` method** – Invokes a static
  ///    `fromJson` method if present and compatible.
  /// 4. **Other static factory methods accepting a single map argument** – Finds a
  ///    static method that can accept the `fields` map as a positional argument.
  /// 5. **Default constructor with field assignments** – Attempts to instantiate
  ///    via the default constructor, passing `fields` where possible.
  ///
  /// Returns the created object if successful; otherwise, returns `null`.
  ///
  /// **Note:** This method handles any exceptions during instantiation gracefully
  /// and returns `null` on failure.
  static Object? construct(Map<String, Object> fields, Class type) {
    if (type.getDirectAnnotation<FromJson>() case final fromJson?) {
      return fromJson.creator(fields);
    }

    if (type.getConstructors().find((c) => c.hasDirectAnnotation<JsonCreator>()) case final constructor?) {
      final paramArgs = <String, Object>{};

      for (final param in constructor.getParameters()) {
        if (param.getReturnClass().isInstance(fields)) {
          paramArgs[param.getName()] = fields;
        } else if (param.hasDefaultValue()) {
          paramArgs[param.getName()] = param.getDefaultValue();
        }
      }

      return type.newInstance(paramArgs, constructor.getName());
    }

    if (type.getMethod("fromJson") case final fromJson?) {
      if (fromJson.getParameterCount() == 1 && fromJson.isStatic()) {
        final paramArgs = <String, Object>{};
        final paramPositional = <Object>[];

        for (final param in fromJson.getParameters()) {
          if (param.getReturnClass().isInstance(fields)) {
            if (param.isNamed()) {
              paramArgs[param.getName()] = fields;
            } else {
              paramPositional.insert(param.getIndex(), fields);
            }
          } else if (param.hasDefaultValue()) {
            if (param.isNamed()) {
              paramArgs[param.getName()] = param.getDefaultValue();
            } else {
              paramPositional.insert(param.getIndex(), param.getDefaultValue());
            }
          }
        }

        return fromJson.invoke(null, paramArgs, paramPositional);
      }
    }

    final invokable = type.getMethods().find((m) => m.canAcceptPositionalArguments([fields]));
    if (invokable != null && invokable.isStatic()) {
      return invokable.invoke(null, null, [fields]);
    }

    final constructors = type.getConstructors();
    final constructor = constructors.firstWhereOrNull((c) => c.canAcceptArguments(fields)) ?? type.getDefaultConstructor();
    return type.newInstance(_resolveFields(constructor, fields));
  }

  /// {@template jetson_utils_resolve_fields}
  /// Resolves and normalizes constructor arguments before object instantiation.
  ///
  /// This method prepares a finalized field map that can safely be passed
  /// to a constructor invocation. It ensures that:
  ///
  /// - All provided fields are preserved
  /// - Missing constructor parameters with **default values** are populated
  /// - Constructor argument mismatches do not immediately fail instantiation
  ///
  /// This is primarily used as a **fallback mechanism** when Jetson constructs
  /// objects via reflection and needs to reconcile dynamic input data with
  /// the constructor’s parameter definition.
  ///
  /// ### Resolution strategy
  /// 1. Clone the incoming [fields] map to avoid mutating the original input
  /// 2. If a [constructor] is provided:
  ///    - Compare constructor parameter count with the number of supplied fields
  ///    - For each constructor parameter:
  ///      - If the parameter is missing from [fields]
  ///      - And the parameter defines a default value
  ///      - Inject the default value into the resolved field map
  /// 3. Return the updated field map for instantiation
  ///
  /// ### Notes
  /// - This method does **not** validate types or required parameters
  /// - Missing required parameters without defaults are left unresolved
  /// - Intended for **internal use only**
  ///
  /// ### Used by
  /// - [JetsonUtils.construct]
  /// {@endtemplate}
  static Map<String, Object> _resolveFields(Constructor? constructor, Map<String, Object> fields) {
    final updatedFields = Map<String, Object>.from(fields);

    if (constructor != null) {
      if (constructor.getParameterCount() != fields.length) {
        for (final param in constructor.getParameters()) {
          if (!updatedFields.containsKey(param.getName()) && param.hasDefaultValue()) {
            updatedFields[param.getName()] = param.getDefaultValue();
          }
        }
      }
    }

    return updatedFields;
  }
}