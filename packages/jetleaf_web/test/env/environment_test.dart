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
import 'package:jetleaf_env/jetleaf_env.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';
import 'package:jetleaf_web/src/env/environment.dart';
import 'package:jetleaf_web/src/env/standard_web_environment.dart';

@JetleafTest()
void main() {
  // ========================================================================
  // WebEnvironment Interface
  // ========================================================================

  group('WebEnvironment', () {
    test('is a subtype of Environment', () {
      expect(WebEnvironment, isA<Type>());
    });

    test('can be assigned from StandardWebEnvironment', () {
      final env = StandardWebEnvironment();
      expect(env, isA<WebEnvironment>());
    });
  });

  group('ConfigurableWebEnvironment', () {
    test('is a subtype of WebEnvironment', () {
      expect(ConfigurableWebEnvironment, isA<Type>());
    });

    test('can be assigned from StandardWebEnvironment', () {
      final env = StandardWebEnvironment();
      expect(env, isA<ConfigurableWebEnvironment>());
    });
  });

  // ========================================================================
  // StandardWebEnvironment — Construction
  // ========================================================================

  group('StandardWebEnvironment - Construction', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('creates a new instance', () {
      expect(env, isA<StandardWebEnvironment>());
    });

    test('implements ConfigurableWebEnvironment', () {
      expect(env, isA<ConfigurableWebEnvironment>());
    });

    test('implements Environment', () {
      expect(env, isA<Environment>());
    });

    test('has web environment property source registered', () {
      expect(
        env.getPropertySources().containsName('webEnvironment'),
        isTrue,
      );
    });

    test('has system environment property source', () {
      expect(
        env.getPropertySources().containsName('systemEnvironment'),
        isTrue,
      );
    });

    test('has system properties property source', () {
      expect(
        env.getPropertySources().containsName('systemProperties'),
        isTrue,
      );
    });
  });

  // ========================================================================
  // StandardWebEnvironment — Default Properties
  // ========================================================================

  group('StandardWebEnvironment - Default Properties', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('server.host defaults to localhost', () {
      expect(env.getProperty('server.host'), 'localhost');
    });

    test('server.port defaults to 8080', () {
      expect(env.getProperty('server.port'), '8080');
    });

    test('logging.enabled.server defaults to true', () {
      expect(env.getProperty('logging.enabled.server'), 'true');
    });

    test('server.context-path defaults to /', () {
      expect(env.getProperty('server.context-path'), '/');
    });

    test('all default properties are present', () {
      final keys = [
        'server.host',
        'server.port',
        'logging.enabled.server',
        'server.context-path',
      ];

      for (final key in keys) {
        expect(env.containsProperty(key), isTrue, reason: 'Missing: $key');
      }
    });
  });

  // ========================================================================
  // StandardWebEnvironment — Static Constants
  // ========================================================================

  group('StandardWebEnvironment - Static Constants', () {
    test('WEB_ENVIRONMENT_PROPERTY_SOURCE_NAME is webEnvironment', () {
      expect(
        StandardWebEnvironment.WEB_ENVIRONMENT_PROPERTY_SOURCE_NAME,
        'webEnvironment',
      );
    });

    test('LOGGING_ENABLED_PROPERTY_NAME is logging.enabled.server', () {
      expect(
        StandardWebEnvironment.LOGGING_ENABLED_PROPERTY_NAME,
        'logging.enabled.server',
      );
    });
  });

  // ========================================================================
  // StandardWebEnvironment — containsProperty
  // ========================================================================

  group('StandardWebEnvironment - containsProperty', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('returns true for server.host', () {
      expect(env.containsProperty('server.host'), isTrue);
    });

    test('returns true for server.port', () {
      expect(env.containsProperty('server.port'), isTrue);
    });

    test('returns true for logging.enabled.server', () {
      expect(env.containsProperty('logging.enabled.server'), isTrue);
    });

    test('returns true for server.context-path', () {
      expect(env.containsProperty('server.context-path'), isTrue);
    });

    test('returns false for missing key', () {
      expect(env.containsProperty('nonexistent.key'), isFalse);
    });

    test('returns false for empty string', () {
      expect(env.containsProperty(''), isFalse);
    });

    test('returns false for partial key match', () {
      expect(env.containsProperty('server'), isFalse);
      expect(env.containsProperty('server.host.extra'), isFalse);
    });
  });

  // ========================================================================
  // StandardWebEnvironment — getProperty
  // ========================================================================

  group('StandardWebEnvironment - getProperty', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('returns value for existing property', () {
      expect(env.getProperty('server.host'), 'localhost');
      expect(env.getProperty('server.port'), '8080');
    });

    test('returns null for missing property', () {
      expect(env.getProperty('missing.property'), isNull);
    });

    test('returns default value for missing property', () {
      expect(env.getProperty('missing.property', 'fallback'), 'fallback');
    });

    test('returns existing value even when default is provided', () {
      expect(env.getProperty('server.host', 'other-host'), 'localhost');
    });

    test('returns null for empty key', () {
      expect(env.getProperty(''), isNull);
    });

    test('returns null when default is null for missing key', () {
      expect(env.getProperty('missing', null), isNull);
    });
  });

  // ========================================================================
  // StandardWebEnvironment — getPropertyAs
  // ========================================================================

  group('StandardWebEnvironment - getPropertyAs', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('converts string port to int', () {
      final port = env.getPropertyAs('server.port', Class<int>());
      expect(port, 8080);
    });

    test('returns null for non-existent property', () {
      final value = env.getPropertyAs('nonexistent', Class<int>());
      expect(value, isNull);
    });

    test('returns default for non-existent property', () {
      final value = env.getPropertyAs('nonexistent', Class<int>(), 3000);
      expect(value, 3000);
    });

    test('returns null when value cannot be converted', () {
      expect(
        () => env.getPropertyAs('server.host', Class<int>()),
        throwsA(isA<ConversionFailedException>()),
      );
    });

    test('returns default when value cannot be converted', () {
      expect(
        () => env.getPropertyAs('server.host', Class<int>(), 9090),
        throwsA(isA<ConversionFailedException>()),
      );
    });

    test('converts string to String type', () {
      final value = env.getPropertyAs('server.host', Class<String>());
      expect(value, 'localhost');
    });

    test('converts string "true" to bool', () {
      final value = env.getPropertyAs('logging.enabled.server', Class<bool>());
      expect(value, isTrue);
    });

    test('returns default bool for non-existent property', () {
      final value = env.getPropertyAs('missing.bool', Class<bool>(), false);
      expect(value, false);
    });
  });

  // ========================================================================
  // StandardWebEnvironment — getRequiredProperty
  // ========================================================================

  group('StandardWebEnvironment - getRequiredProperty', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('returns value for existing property', () {
      expect(env.getRequiredProperty('server.host'), 'localhost');
      expect(env.getRequiredProperty('server.port'), '8080');
    });

    test('throws for non-existent property', () {
      expect(
        () => env.getRequiredProperty('nonexistent.property'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ========================================================================
  // StandardWebEnvironment — Property Sources
  // ========================================================================

  group('StandardWebEnvironment - Property Sources', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('getPropertySources returns non-null', () {
      expect(env.getPropertySources(), isNotNull);
    });

    test('property sources contain webEnvironment', () {
      expect(
        env.getPropertySources().containsName('webEnvironment'),
        isTrue,
      );
    });

    test('property sources contain systemEnvironment', () {
      expect(
        env.getPropertySources().containsName('systemEnvironment'),
        isTrue,
      );
    });

    test('property sources contain systemProperties', () {
      expect(
        env.getPropertySources().containsName('systemProperties'),
        isTrue,
      );
    });

    test('webEnvironment source can be retrieved by name', () {
      final source = env.getPropertySources().get('webEnvironment');
      expect(source, isNotNull);
      expect(source!.getProperty('server.host'), 'localhost');
    });
  });

  // ========================================================================
  // StandardWebEnvironment — Adding Properties (put)
  // ========================================================================

  group('StandardWebEnvironment - Adding Properties', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('can add a MapPropertySource', () {
      env.getPropertySources().addLast(
        MapPropertySource('custom', {'my.key': 'my.value'}),
      );
      expect(env.getProperty('my.key'), 'my.value');
    });

    test('new property source is visible in sources list', () {
      env.getPropertySources().addLast(
        MapPropertySource('custom', {'my.key': 'my.value'}),
      );
      expect(env.getPropertySources().containsName('custom'), isTrue);
    });

    test('higher precedence source overrides lower precedence', () {
      env.getPropertySources().addLast(
        MapPropertySource('low', {'shared.key': 'low-value'}),
      );
      env.getPropertySources().addFirst(
        MapPropertySource('high', {'shared.key': 'high-value'}),
      );
      expect(env.getProperty('shared.key'), 'high-value');
    });

    test('can override default properties with custom source', () {
      env.getPropertySources().addFirst(
        MapPropertySource('override', {'server.port': '9090'}),
      );
      expect(env.getProperty('server.port'), '9090');
    });

    test('can add multiple custom properties at once', () {
      env.getPropertySources().addLast(MapPropertySource('multi', {
        'app.name': 'MyApp',
        'app.version': '1.0.0',
        'app.debug': 'true',
      }));

      expect(env.getProperty('app.name'), 'MyApp');
      expect(env.getProperty('app.version'), '1.0.0');
      expect(env.getProperty('app.debug'), 'true');
    });

    test('custom properties do not affect existing defaults', () {
      env.getPropertySources().addLast(
        MapPropertySource('custom', {'new.key': 'new.value'}),
      );

      expect(env.getProperty('server.host'), 'localhost');
      expect(env.getProperty('server.port'), '8080');
      expect(env.getProperty('new.key'), 'new.value');
    });

    test('can remove a property source', () {
      env.getPropertySources().addLast(
        MapPropertySource('removable', {'temp.key': 'temp.value'}),
      );
      expect(env.getProperty('temp.key'), 'temp.value');

      env.getPropertySources().remove('removable');
      expect(env.getProperty('temp.key'), isNull);
    });

    test('addOrMerge merges into existing source', () {
      env.getPropertySources().addOrMerge({
        'merged.key': 'merged.value',
      }, 'custom');

      expect(env.getProperty('merged.key'), 'merged.value');

      env.getPropertySources().addOrMerge({
        'merged.key': 'updated.value',
      }, 'custom');

      expect(env.getProperty('merged.key'), 'updated.value');
    });
  });

  // ========================================================================
  // StandardWebEnvironment — Profiles
  // ========================================================================

  group('StandardWebEnvironment - Profiles', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('has default profile by default', () {
      expect(env.getDefaultProfiles(), contains('default'));
    });

    test('active profiles is empty by default', () {
      expect(env.getActiveProfiles(), isEmpty);
    });

    test('can set active profiles', () {
      env.setActiveProfiles(['dev', 'test']);
      expect(env.getActiveProfiles(), containsAll(['dev', 'test']));
    });

    test('can add an active profile', () {
      env.setActiveProfiles(['dev']);
      env.addActiveProfile('prod');
      expect(env.getActiveProfiles(), containsAll(['dev', 'prod']));
    });

    test('can set default profiles', () {
      env.setDefaultProfiles(['staging', 'prod']);
      expect(env.getDefaultProfiles(), containsAll(['staging', 'prod']));
    });

    test('setActiveProfiles replaces existing active profiles', () {
      env.setActiveProfiles(['dev']);
      env.setActiveProfiles(['prod']);
      expect(env.getActiveProfiles(), ['prod']);
      expect(env.getActiveProfiles(), isNot(contains('dev')));
    });

    test('matchesProfiles returns true for matching active profile', () {
      env.setActiveProfiles(['dev']);
      expect(env.matchesProfiles(['dev']), isTrue);
    });

    test('matchesProfiles returns false for non-matching profile', () {
      env.setActiveProfiles(['dev']);
      expect(env.matchesProfiles(['prod']), isFalse);
    });

    test('matchesProfiles with AND expression', () {
      env.setActiveProfiles(['dev', 'local']);
      expect(env.matchesProfiles(['dev & local']), isTrue);
    });

    test('matchesProfiles with OR expression', () {
      env.setActiveProfiles(['dev']);
      expect(env.matchesProfiles(['dev | prod']), isTrue);
    });

    test('matchesProfiles with NOT expression', () {
      env.setActiveProfiles(['dev']);
      expect(env.matchesProfiles(['!prod']), isTrue);
    });
  });

  // ========================================================================
  // StandardWebEnvironment — Suggestions
  // ========================================================================

  group('StandardWebEnvironment - Suggestions', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('returns suggestions for partial key match', () {
      final suggestions = env.suggestions('web');
      expect(suggestions, contains('webEnvironment'));
    });

    test('returns empty list for non-matching key', () {
      final suggestions = env.suggestions('totally.unrelated.key');
      expect(suggestions, isEmpty);
    });
  });

  // ========================================================================
  // StandardWebEnvironment — resolvePlaceholders
  // ========================================================================

  group('StandardWebEnvironment - resolvePlaceholders', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('resolves \${ placeholders', () {
      final resolved = env.resolvePlaceholders('Host: \${server.host}');
      expect(resolved, contains('localhost'));
    });

    test('leaves unresolvable placeholders intact', () {
      final resolved = env.resolvePlaceholders('Missing: \${nonexistent}');
      expect(resolved, contains('nonexistent'));
    });

    test('resolves multiple placeholders', () {
      final resolved = env.resolvePlaceholders(
        'http://\${server.host}:\${server.port}',
      );
      expect(resolved, contains('localhost'));
      expect(resolved, contains('8080'));
    });
  });

  // ========================================================================
  // StandardWebEnvironment — Edge Cases
  // ========================================================================

  group('StandardWebEnvironment - Edge Cases', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('handles deeply nested property key', () {
      expect(env.containsProperty('a.b.c.d.e'), isFalse);
      expect(env.getProperty('a.b.c.d.e'), isNull);
    });

    test('handles property key with special characters', () {
      expect(env.containsProperty('server.host:8080'), isFalse);
    });

    test('handles property key with spaces', () {
      expect(env.containsProperty('server host'), isFalse);
    });

    test('handles property key with unicode characters', () {
      expect(env.containsProperty('server.über'), isFalse);
    });

    test('getPropertyAs with Class<String>() returns string value', () {
      final value = env.getPropertyAs('server.port', Class<String>());
      expect(value, '8080');
    });

    test('multiple environments are independent', () {
      final env1 = StandardWebEnvironment();
      final env2 = StandardWebEnvironment();

      env1.getPropertySources().addFirst(
        MapPropertySource('custom1', {'key': 'value1'}),
      );
      env2.getPropertySources().addFirst(
        MapPropertySource('custom2', {'key': 'value2'}),
      );

      expect(env1.getProperty('key'), 'value1');
      expect(env2.getProperty('key'), 'value2');
    });

    test('environment maintains property source ordering', () {
      final sources = env.getPropertySources();
      final names = sources.getPropertyNames();

      // webEnvironment should be last (added in customizePropertySources)
      expect(names.last, 'webEnvironment');
    });
  });

  // ========================================================================
  // WebEnvironmentPropertySource
  // ========================================================================

  group('WebEnvironmentPropertySource', () {
    late WebEnvironmentPropertySource source;

    setUp(() {
      source = WebEnvironmentPropertySource('testSource');
    });

    test('has correct name', () {
      expect(source.getName(), 'testSource');
    });

    test('contains server.host', () {
      expect(source.containsProperty('server.host'), isTrue);
      expect(source.getProperty('server.host'), 'localhost');
    });

    test('contains server.port', () {
      expect(source.containsProperty('server.port'), isTrue);
      expect(source.getProperty('server.port'), '8080');
    });

    test('contains logging.enabled.server', () {
      expect(source.containsProperty('logging.enabled.server'), isTrue);
      expect(source.getProperty('logging.enabled.server'), 'true');
    });

    test('contains server.context-path', () {
      expect(source.containsProperty('server.context-path'), isTrue);
      expect(source.getProperty('server.context-path'), '/');
    });

    test('does not contain non-existent key', () {
      expect(source.containsProperty('nonexistent'), isFalse);
      expect(source.getProperty('nonexistent'), isNull);
    });

    test('has exactly 4 default properties', () {
      final keys = [
        'server.host',
        'server.port',
        'logging.enabled.server',
        'server.context-path',
      ];
      expect(keys.length, 4);
      for (final key in keys) {
        expect(source.containsProperty(key), isTrue, reason: 'Missing: $key');
      }
    });

    test('source is a MapPropertySource', () {
      expect(source, isA<MapPropertySource>());
    });
  });

  // ========================================================================
  // StandardWebEnvironment — Type Hierarchy
  // ========================================================================

  group('StandardWebEnvironment - Type Hierarchy', () {
    late StandardWebEnvironment env;

    setUp(() {
      env = StandardWebEnvironment();
    });

    test('is a WebEnvironment', () {
      expect(env, isA<WebEnvironment>());
    });

    test('is a ConfigurableWebEnvironment', () {
      expect(env, isA<ConfigurableWebEnvironment>());
    });

    test('is an Environment', () {
      expect(env, isA<Environment>());
    });

    test('is a ConfigurableEnvironment', () {
      expect(env, isA<ConfigurableEnvironment>());
    });

    test('is a PropertyResolver', () {
      expect(env, isA<PropertyResolver>());
    });

    test('is a ConfigurablePropertyResolver', () {
      expect(env, isA<ConfigurablePropertyResolver>());
    });
  });

  // ========================================================================
  // StandardWebEnvironment — Merge
  // ========================================================================

  group('StandardWebEnvironment - Merge', () {
    test('merges property sources from parent environment', () {
      final parent = StandardWebEnvironment();
      parent.getPropertySources().addLast(
        MapPropertySource('parent', {'parent.key': 'parent.value'}),
      );

      final child = StandardWebEnvironment();
      child.merge(parent);

      expect(child.getProperty('parent.key'), 'parent.value');
    });

    test('does not duplicate existing property source names', () {
      final parent = StandardWebEnvironment();
      final child = StandardWebEnvironment();

      child.merge(parent);

      // Should not have duplicate 'webEnvironment' sources
      final sources = child.getPropertySources();
      int count = 0;
      for (final source in sources) {
        if (source.getName() == 'webEnvironment') count++;
      }
      expect(count, 1);
    });

    test('merges active profiles from parent', () {
      final parent = StandardWebEnvironment();
      parent.setActiveProfiles(['parent-profile']);

      final child = StandardWebEnvironment();
      child.merge(parent);

      expect(child.getActiveProfiles(), contains('parent-profile'));
    });
  });
}
