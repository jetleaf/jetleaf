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

import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_env/env.dart';
import 'package:jetleaf_lang/lang.dart';

import '../../base/object_mapper.dart';
import '../../exceptions.dart';
import '../../naming_strategy/naming_strategy.dart';
import '../../serialization/deserialization_context.dart';
import '../../serialization/object_deserializer.dart';
import '../adapter/dart_yaml_serialization_adapter.dart';
import '../parser/yaml_parser.dart';

/// {@template yaml_deserialization_context}
/// Manages [ObjectDeserializer] instances during YAML deserialization.
/// {@endtemplate}
class YamlDeserializationContext implements DeserializationContext<YamlParser> {
  final ObjectMapper _objectMapper;
  final Map<Class, ObjectDeserializer> _deserializers;
  final Map<Class, ObjectDeserializer> _configuredDeserializers = {};
  final Map<Class, ObjectDeserializer> _frameworkDeserializers = {};

  YamlDeserializationContext(this._objectMapper, this._deserializers) {
    for (final entry in _deserializers.entries) {
      final key = entry.key;
      final des = entry.value;

      if (des.getClass().getPackage().getName() == PackageNames.JETSON) {
        _frameworkDeserializers.add(key, des);
      } else {
        _configuredDeserializers.add(key, des);
      }
    }
  }

  @override
  ObjectMapper getObjectMapper() => _objectMapper;

  @override
  NamingStrategy getNamingStrategy() => _objectMapper.getNamingStrategy();

  @override
  ConversionService getConversionService() => _objectMapper.getConversionService();

  @override
  Environment getEnvironment() => _objectMapper.getEnvironment();

  @override
  ObjectDeserializer? findDeserializerForType(Class type) {
    final deserializer = _find(type, _configuredDeserializers) ?? _find(type, _frameworkDeserializers);

    if (deserializer != null) {
      return deserializer;
    }

    final dartDeserializer = DartYamlSerializationAdapter(type);
    _frameworkDeserializers[type] = dartDeserializer;
    return dartDeserializer;
  }

  ObjectDeserializer? _find(Class type, Map<Class, ObjectDeserializer> deserializers) {
    if (deserializers.containsKey(type)) {
      return deserializers[type];
    }

    ObjectDeserializer? deserializer = deserializers.values.find((d) => d.canDeserialize(type));
    if (deserializer != null) {
      return deserializer;
    }

    deserializer = deserializers.values.find((ss) => ss.toClass() == type || ss.toClass().getType() == type.getType());
    return deserializer;
  }

  @override
  T deserialize<T>(YamlParser parser, Class<T> type) {
    final deserializer = findDeserializerForType(type);

    if (parser.getCurrentToken() == null) {
      parser.nextToken();
    }

    if (deserializer == null) {
      throw NoDeserializerFoundException('No deserializer found for type: ${type.getName()}');
    }

    return deserializer.deserialize(parser, this, type) as T;
  }
}