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

import '../context/yaml_deserialization_context.dart';
import '../context/yaml_serialization_context.dart';
import '../generator/yaml_generator.dart';
import '../parser/yaml_parser.dart';
import '../yaml_token.dart';
import 'yaml_adapter.dart';

final class MapYamlSerializationAdapter extends YamlSerializationAdapter<Map> {
  const MapYamlSerializationAdapter();

  @override
  bool canDeserialize(Class type) => type == Class<Map>() || type.getType() == Map;

  @override
  Map? deserialize(YamlParser parser, YamlDeserializationContext ctxt, Class toClass) {
    final map = <String, Object>{};
    
    while (parser.nextToken()) {
      if (parser.getCurrentToken() == YamlToken.MAPPING_END) {
        break;
      }
      
      if (parser.getCurrentToken() == YamlToken.KEY) {
        final key = parser.getCurrentValue()?.toString() ?? 'unknown';
        parser.nextToken(); // Move to value
        
        final valueType = toClass.componentType() ?? Class<Object>();
        final value = ctxt.deserialize(parser, valueType);
        map[key] = value;
      }
    }
    
    return map;
  }

  @override
  bool canSerialize(Class type) => type == Class<Map>() || type.getType() == Map;

  @override
  void serialize(Map value, YamlGenerator generator, YamlSerializationContext serializer) {
    generator.writeStartMapping();
    for (final entry in value.entries) {
      generator.writeKey(entry.key.toString());
      serializer.serialize(entry.value, generator);
    }
    generator.writeEndMapping();
  }

  @override
  Class<Map> toClass() => Class<Map>(null, PackageNames.DART);
}