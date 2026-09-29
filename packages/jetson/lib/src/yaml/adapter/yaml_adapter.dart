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

import '../../serialization/deserialization_context.dart';
import '../../serialization/object_deserializer.dart';
import '../../serialization/object_serialization_adapter.dart';
import '../../serialization/object_serializer.dart';
import '../../serialization/serialization_context.dart';
import '../context/yaml_deserialization_context.dart';
import '../context/yaml_serialization_context.dart';
import '../generator/yaml_generator.dart';
import '../parser/yaml_parser.dart';

/// {@template yaml_deserializer}
/// Specialization of [ObjectDeserializer] for YAML deserialization using [YamlParser].
/// {@endtemplate}
@Generic(YamlDeserializer)
abstract interface class YamlDeserializer<T> implements ObjectDeserializer<T, YamlParser, YamlDeserializationContext> {}

/// {@template yaml_serializer}
/// Specialization of [ObjectSerializer] for YAML serialization using [YamlGenerator].
/// {@endtemplate}
@Generic(YamlSerializer)
abstract interface class YamlSerializer<T> implements ObjectSerializer<T, YamlGenerator, YamlSerializationContext> {}

/// {@template yaml_converter_adapter}
/// Bidirectional YAML converter implementing both serialization and deserialization.
/// {@endtemplate}
@Generic(YamlSerializationAdapter)
abstract class YamlSerializationAdapter<T> implements ObjectSerializationAdapter<T, YamlGenerator, YamlParser, YamlDeserializationContext, YamlSerializationContext> {
  static final Class<YamlSerializationAdapter> CLASS = Class<YamlSerializationAdapter>(null, PackageNames.JETSON);

  const YamlSerializationAdapter();

  @override
  bool supports(DeserializationContext context) => context is YamlDeserializationContext;

  @override
  bool supportsContext(SerializationContext context) => context is YamlSerializationContext;
}