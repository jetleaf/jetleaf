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
import '../../serialization/object_serializer.dart';
import '../../serialization/serialization_context.dart';
import '../adapter/dart_xml_serialization_adapter.dart';
import '../generator/xml_generator.dart';

/// {@template xml_serialization_context}
/// Manages [ObjectSerializer] instances during XML serialization.
/// {@endtemplate}
class XmlSerializationContext implements SerializationContext<XmlGenerator> {
  final Map<Class, ObjectSerializer> _serializers;
  final ObjectMapper _objectMapper;
  final Map<Class, ObjectSerializer> _configuredSerializers = {};
  final Map<Class, ObjectSerializer> _frameworkSerializers = {};

  XmlSerializationContext(this._objectMapper, this._serializers) {
    for (final entry in _serializers.entries) {
      final key = entry.key;
      final s = entry.value;

      if (s.getClass().getPackage().getName() == PackageNames.JETSON) {
        _frameworkSerializers.add(key, s);
      } else {
        _configuredSerializers.add(key, s);
      }
    }
  }

  @override
  ObjectSerializer? findSerializerForType(Class type) {
    final serializer = _find(type, _configuredSerializers) ?? _find(type, _frameworkSerializers);

    if (serializer != null) {
      return serializer;
    }

    final dartSerializer = DartXmlSerializationAdapter(type);
    _frameworkSerializers[type] = dartSerializer;
    return dartSerializer;
  }

  ObjectSerializer? _find(Class type, Map<Class, ObjectSerializer> serializers) {
    if (serializers.containsKey(type)) {
      return serializers[type];
    }

    ObjectSerializer? serializer = serializers.values.find((s) => s.canSerialize(type));
    if (serializer != null) {
      return serializer;
    }

    serializer = serializers.values.find((ss) => ss.toClass() == type || ss.toClass().getType() == type.getType());
    return serializer;
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
  void serialize(Object? object, XmlGenerator generator) {
    if (object == null) {
      generator.writeNull();
      return;
    }

    final clazz = object.getClass();
    final serializer = findSerializerForType(clazz);

    if (serializer == null) {
      throw NoSerializerFoundException('No serializer found for type: ${clazz.getName()}');
    }

    serializer.serialize(object as dynamic, generator, this);
  }
}