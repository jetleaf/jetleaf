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

final class SetYamlSerializationAdapter extends YamlSerializationAdapter<Set> {
  const SetYamlSerializationAdapter();

  @override
  bool canDeserialize(Class type) => type == Class<Set>() || type.getType() == Set;

  @override
  Set? deserialize(YamlParser parser, YamlDeserializationContext ctxt, Class toClass) {
    final set = <Object>{};
    
    while (parser.nextToken()) {
      if (parser.getCurrentToken() == YamlToken.SEQUENCE_END) {
        break;
      }
      
      final elementType = toClass.componentType() ?? Class<Object>();
      final item = ctxt.deserialize(parser, elementType);
      set.add(item);
    }
    
    return set;
  }

  @override
  bool canSerialize(Class type) => type == Class<Set>() || type.getType() == Set;

  @override
  void serialize(Set value, YamlGenerator generator, YamlSerializationContext serializer) {
    generator.writeStartSequence();
    for (final item in value) {
      serializer.serialize(item, generator);
    }
    generator.writeEndSequence();
  }

  @override
  Class<Set> toClass() => Class<Set>(null, PackageNames.DART);
}