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

import '../../jetson_utils.dart';
import '../context/xml_deserialization_context.dart';
import '../context/xml_serialization_context.dart';
import '../generator/xml_generator.dart';
import '../parser/xml_parser.dart';
import 'xml_adapter.dart';

final class DartXmlSerializationAdapter extends XmlSerializationAdapter<Object> {
  final Class _class;

  DartXmlSerializationAdapter(this._class);

  @override
  bool canDeserialize(Class type) => type == _class || type.getType() == _class.getType();

  @override
  Object? deserialize(XmlParser parser, XmlDeserializationContext ctxt, Class toClass) {
    final fieldValues = <String, Object>{};
    
    return JetsonUtils.construct(fieldValues, _class);
  }

  @override
  bool canSerialize(Class type) => type == _class || type.getType() == _class.getType();

  @override
  void serialize(Object? value, XmlGenerator generator, XmlSerializationContext serializer) {
  }

  @override
  Class<Object> toClass() => Class.fromQualifiedName(_class.getQualifiedName());
}