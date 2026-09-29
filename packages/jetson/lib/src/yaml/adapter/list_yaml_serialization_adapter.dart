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

final class ListYamlSerializationAdapter extends YamlSerializationAdapter<List> {
  const ListYamlSerializationAdapter();

  @override
  bool canDeserialize(Class type) => type == Class<List>() || type.getType() == List;

  @override
  List? deserialize(YamlParser parser, YamlDeserializationContext ctxt, Class toClass) {
    final list = [];
    
    while (parser.nextToken()) {
      if (parser.getCurrentToken() == YamlToken.SEQUENCE_END) {
        break;
      }
      
      // In YAML, sequence items don't have explicit start tokens like XML elements
      // The parser should emit values or nested structures directly
      final elementType = toClass.componentType() ?? Class<Object>();
      final item = ctxt.deserialize(parser, elementType);
      list.add(item);
    }
    
    return list;
  }

  @override
  bool canSerialize(Class type) => type == Class<List>() || type.getType() == List;

  @override
  void serialize(List value, YamlGenerator generator, YamlSerializationContext serializer) {
    generator.writeStartSequence();
    for (final item in value) {
      serializer.serialize(item, generator);
    }
    generator.writeEndSequence();
  }

  @override
  Class<List> toClass() => Class<List>(null, PackageNames.DART);
}