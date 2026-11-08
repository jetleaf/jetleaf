// ignore_for_file: avoid_print

import 'package:jetson/jetson.dart';

void main() {
  print('========================================================');
  print('  🍃 Jetson Object Mapper 2.0.0 Showcase');
  print('========================================================\n');

  final mapper = ObjectMapper();

  // 1. JSON Serialization
  print('[1] JSON Serialization (Map & Structured Data):');
  final payload = {
    'userName': 'alex_rivers',
    'emailAddress': 'alex@jetleaf.dev',
    'accountActive': true,
    'retryCount': 3,
    'metadata': {
      'tier': 'enterprise',
      'quota': 50000,
    },
  };

  final jsonString = mapper.writeValueAsString(payload);
  print('Serialized JSON:\n$jsonString\n');

  // 2. Naming Strategy Transformations
  print('[2] Naming Strategy (Snake Case):');
  final snakeCase = SnakeCaseNamingStrategy();
  print('camelCase "userName" -> "${snakeCase.toJsonName('userName')}"');
  print('camelCase "emailAddress" -> "${snakeCase.toJsonName('emailAddress')}"');
  print('camelCase "accountActive" -> "${snakeCase.toJsonName('accountActive')}"\n');

  // 3. Multi-Format Serialization: YAML
  print('[3] YAML Serialization:');
  final yamlString = mapper.writeValueAsString(payload, ObjectMapperType.YAML);
  print('Serialized YAML:\n$yamlString');

  // 4. JSON Validation & Node Tree
  print('[4] JSON Validation & Nodes:');
  JsonValidator.validateJsonString(jsonString);
  print('Validated JSON string successfully.');

  final textNode = JsonTextNode('jetleaf-core');
  final numNode = JsonNumberNode(200);
  print('JSON Node Tree: textNode=${textNode.toObject()}, numNode=${numNode.toObject()}');

  print('\n========================================================');
  print('  ✅ Jetson Example executed successfully!');
  print('========================================================');
}
