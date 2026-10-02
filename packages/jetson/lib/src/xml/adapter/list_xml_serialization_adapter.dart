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

import '../context/xml_deserialization_context.dart';
import '../context/xml_serialization_context.dart';
import '../generator/xml_generator.dart';
import '../parser/xml_parser.dart';
import '../xml_token.dart';
import 'xml_adapter.dart';

final class ListXmlSerializationAdapter extends XmlSerializationAdapter<List> {
  const ListXmlSerializationAdapter();

  @override
  bool canSerialize(Class type) => type == Class<List>() || type.getType() == List;

  @override
  void serialize(List value, XmlGenerator generator, XmlSerializationContext serializer) {
    for (final item in value) {
      generator.writeStartElement('item');
      serializer.serialize(item, generator);
      generator.writeEndElement();
    }
  }

  @override
  bool canDeserialize(Class type) => type == Class<List>() || type.getType() == List;

  @override
  List? deserialize(XmlParser parser, XmlDeserializationContext ctxt, Class toClass) {
    final list = [];
    
    while (parser.nextToken()) {
      if (parser.getCurrentToken() == XmlToken.END_ELEMENT) {
        break;
      }
      
      if (parser.getCurrentToken() == XmlToken.START_ELEMENT) {
        final elementType = toClass.componentType() ?? Class<Object>();
        final item = ctxt.deserialize(parser, elementType);
        list.add(item);
      }
    }
    
    return list;
  }

  @override
  Class<List> toClass() => Class<List>(null, PackageNames.DART);
}